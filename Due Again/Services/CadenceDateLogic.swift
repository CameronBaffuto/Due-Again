import Foundation

enum CadenceDateLogic {
    static func dueDate(after date: Date, cadenceDays: Int, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: max(1, cadenceDays), to: startOfDay) ?? startOfDay
    }

    static func nextDueDate(
        lastCompletedAt: Date?,
        cadenceDays: Int,
        createdAt: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        if let lastCompletedAt {
            return dueDate(after: lastCompletedAt, cadenceDays: cadenceDays, calendar: calendar)
        }

        return calendar.startOfDay(for: createdAt)
    }

    static func daysRemaining(from date: Date, to nextDueAt: Date, calendar: Calendar = .current) -> Int {
        let fromDay = calendar.startOfDay(for: date)
        let dueDay = calendar.startOfDay(for: nextDueAt)
        return calendar.dateComponents([.day], from: fromDay, to: dueDay).day ?? 0
    }
}

enum CadenceTaskFilter {
    static func dueToday(_ tasks: [CadenceTask], on date: Date = Date(), calendar: Calendar = .current) -> [CadenceTask] {
        tasks
            .filter { !$0.isArchived && $0.daysRemaining(on: date, calendar: calendar) <= 0 }
            .sorted { lhs, rhs in
                if lhs.nextDueAt == rhs.nextDueAt {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.nextDueAt < rhs.nextDueAt
            }
    }

    static func upcoming(
        _ tasks: [CadenceTask],
        dayLimit: Int = 14,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> [CadenceTask] {
        tasks
            .filter {
                let remaining = $0.daysRemaining(on: date, calendar: calendar)
                return !$0.isArchived && remaining > 0 && remaining <= dayLimit
            }
            .sorted { lhs, rhs in
                if lhs.nextDueAt == rhs.nextDueAt {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.nextDueAt < rhs.nextDueAt
            }
    }

    static func active(_ tasks: [CadenceTask]) -> [CadenceTask] {
        tasks
            .filter { !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.nextDueAt == rhs.nextDueAt {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.nextDueAt < rhs.nextDueAt
            }
    }
}
