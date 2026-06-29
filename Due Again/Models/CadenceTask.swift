import Foundation
import SwiftData

@Model
final class CadenceTask {
    var id: UUID
    var title: String
    var notes: String
    var categoryName: String
    var cadenceDays: Int
    var lastCompletedAt: Date?
    var nextDueAt: Date
    var notificationHour: Int?
    var notificationMinute: Int?
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    var notificationTime: DateComponents? {
        get {
            guard let notificationHour else {
                return nil
            }

            return DateComponents(hour: notificationHour, minute: notificationMinute ?? 0)
        }
        set {
            notificationHour = newValue?.hour
            notificationMinute = newValue?.minute
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        categoryName: String = TaskCategory.fallbackName,
        cadenceDays: Int,
        lastCompletedAt: Date? = nil,
        nextDueAt: Date? = nil,
        notificationTime: DateComponents? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        calendar: Calendar = .current
    ) {
        let safeCadenceDays = max(1, cadenceDays)
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
        self.categoryName = categoryName.isEmpty ? TaskCategory.fallbackName : categoryName
        self.cadenceDays = safeCadenceDays
        self.lastCompletedAt = lastCompletedAt
        self.nextDueAt = nextDueAt ?? CadenceDateLogic.nextDueDate(
            lastCompletedAt: lastCompletedAt,
            cadenceDays: safeCadenceDays,
            createdAt: createdAt,
            calendar: calendar
        )
        self.notificationHour = nil
        self.notificationMinute = nil
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notificationTime = notificationTime
    }

    func daysRemaining(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        CadenceDateLogic.daysRemaining(from: date, to: nextDueAt, calendar: calendar)
    }

    func status(on date: Date = Date(), calendar: Calendar = .current) -> CadenceTaskStatus {
        if isArchived {
            return .archived
        }

        let remaining = daysRemaining(on: date, calendar: calendar)
        if remaining < 0 {
            return .overdue
        }

        if remaining == 0 {
            return .dueToday
        }

        return .upcoming
    }

    func isDueToday(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        status(on: date, calendar: calendar) == .dueToday
    }

    func isOverdue(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        status(on: date, calendar: calendar) == .overdue
    }

    func complete(on date: Date = Date(), calendar: Calendar = .current) {
        let completedDay = calendar.startOfDay(for: date)
        lastCompletedAt = date
        nextDueAt = CadenceDateLogic.dueDate(after: completedDay, cadenceDays: cadenceDays, calendar: calendar)
        updatedAt = date
    }

    func updateFromDraft(_ draft: CadenceTaskDraft, calendar: Calendar = .current) {
        title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        categoryName = draft.normalizedCategoryName
        cadenceDays = max(1, draft.cadenceDays)
        lastCompletedAt = draft.lastCompletedAt
        notificationTime = draft.notificationTime
        nextDueAt = CadenceDateLogic.nextDueDate(
            lastCompletedAt: draft.lastCompletedAt,
            cadenceDays: cadenceDays,
            createdAt: createdAt,
            calendar: calendar
        )
        updatedAt = Date()
    }
}

enum CadenceTaskStatus: String, CaseIterable {
    case overdue
    case dueToday
    case upcoming
    case archived

    var title: String {
        switch self {
        case .overdue:
            "Overdue"
        case .dueToday:
            "Due Today"
        case .upcoming:
            "Upcoming"
        case .archived:
            "Archived"
        }
    }
}

struct CadenceTaskDraft: Equatable {
    var title: String = ""
    var cadenceDays: Int = 7
    var categoryName: String = "Home"
    var notes: String = ""
    var notificationTime: DateComponents?
    var lastCompletedAt: Date?

    init() {}

    init(task: CadenceTask) {
        title = task.title
        cadenceDays = task.cadenceDays
        categoryName = task.categoryName
        notes = task.notes
        notificationTime = task.notificationTime
        lastCompletedAt = task.lastCompletedAt
    }

    var normalizedCategoryName: String {
        let trimmed = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? TaskCategory.fallbackName : trimmed
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && cadenceDays > 0
    }
}
