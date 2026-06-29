import Foundation

enum AppGroup {
    static let identifier = "group.com.cambaffuto.DueAgain"
}

struct DueAgainWidgetSnapshot: Codable, Equatable {
    var dueCount: Int
    var nextTaskTitle: String?
    var nextTaskDueText: String?
    var updatedAt: Date

    static let empty = DueAgainWidgetSnapshot(
        dueCount: 0,
        nextTaskTitle: nil,
        nextTaskDueText: nil,
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}

enum WidgetSnapshotStore {
    static let key = "dueAgain.widget.snapshot"

    static func snapshot(
        from tasks: [CadenceTask],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DueAgainWidgetSnapshot {
        let dueTasks = CadenceTaskFilter.dueToday(tasks, on: now, calendar: calendar)
        let activeTasks = CadenceTaskFilter.active(tasks)
        let nextTask = dueTasks.first ?? activeTasks.first

        return DueAgainWidgetSnapshot(
            dueCount: dueTasks.count,
            nextTaskTitle: nextTask?.title,
            nextTaskDueText: nextTask.map { DisplayText.countdown(for: $0, on: now, calendar: calendar) },
            updatedAt: now
        )
    }

    static func write(from tasks: [CadenceTask], now: Date = Date(), calendar: Calendar = .current) {
        let snapshot = snapshot(from: tasks, now: now, calendar: calendar)
        write(snapshot)
    }

    static func write(_ snapshot: DueAgainWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    static func read() -> DueAgainWidgetSnapshot {
        guard
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(DueAgainWidgetSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.identifier) ?? .standard
    }
}

enum DisplayText {
    static func cadence(_ days: Int) -> String {
        days == 1 ? "Every day" : "Every \(days) days"
    }

    static func countdown(for task: CadenceTask, on date: Date = Date(), calendar: Calendar = .current) -> String {
        countdown(daysRemaining: task.daysRemaining(on: date, calendar: calendar))
    }

    static func countdown(daysRemaining: Int) -> String {
        switch daysRemaining {
        case ..<0:
            let days = abs(daysRemaining)
            return days == 1 ? "1 day overdue" : "\(days) days overdue"
        case 0:
            return "Due today"
        case 1:
            return "1 day left"
        default:
            return "\(daysRemaining) days left"
        }
    }

    static func lastDone(_ date: Date?, formatter: DateFormatter = .mediumDate) -> String {
        guard let date else {
            return "Never done"
        }

        return "Last done \(formatter.string(from: date))"
    }
}

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
