import Foundation
import UserNotifications

@MainActor
protocol CadenceNotificationScheduling {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func scheduleNotification(for task: CadenceTask) async throws
    func cancelNotification(for task: CadenceTask)
}

struct CadenceNotificationScheduler: CadenceNotificationScheduling {
    static let shared = CadenceNotificationScheduler()

    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(center: UNUserNotificationCenter = .current(), calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
    }

    func requestAuthorizationIfNeeded() async throws -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        @unknown default:
            return false
        }
    }

    func scheduleNotification(for task: CadenceTask) async throws {
        guard !task.isArchived, let notificationTime = task.notificationTime else {
            cancelNotification(for: task)
            return
        }

        guard try await requestAuthorizationIfNeeded() else {
            return
        }

        cancelNotification(for: task)

        let content = UNMutableNotificationContent()
        content.title = "\(task.title) is due again"
        content.body = "Every \(task.cadenceDays) days · Next due today"
        content.sound = .default

        guard let triggerComponents = Self.triggerComponents(
            dueDate: task.nextDueAt,
            notificationTime: notificationTime,
            calendar: calendar
        ) else {
            return
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier(for: task.id),
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancelNotification(for task: CadenceTask) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier(for: task.id)])
    }

    static func notificationIdentifier(for id: UUID) -> String {
        "cadence-task-\(id.uuidString)"
    }

    static func triggerComponents(
        dueDate: Date,
        notificationTime: DateComponents,
        calendar: Calendar = .current
    ) -> DateComponents? {
        var components = calendar.dateComponents([.calendar, .timeZone, .year, .month, .day], from: dueDate)
        components.hour = notificationTime.hour ?? 9
        components.minute = notificationTime.minute ?? 0
        return components
    }
}
