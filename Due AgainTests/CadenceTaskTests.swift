import XCTest
import SwiftData
@testable import Due_Again

final class CadenceTaskTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testNewTaskDueDateCalculationWithNoLastDoneIsToday() {
        let createdAt = date(year: 2026, month: 6, day: 22, hour: 15)
        let task = CadenceTask(
            title: "Water cactus",
            cadenceDays: 12,
            createdAt: createdAt,
            calendar: calendar
        )

        XCTAssertEqual(task.nextDueAt, date(year: 2026, month: 6, day: 22))
    }

    func testNewTaskDueDateCalculationWithLastDoneUsesCadence() {
        let task = CadenceTask(
            title: "Replace air filter",
            cadenceDays: 90,
            lastCompletedAt: date(year: 2026, month: 6, day: 1, hour: 18),
            calendar: calendar
        )

        XCTAssertEqual(task.nextDueAt, date(year: 2026, month: 8, day: 30))
    }

    func testCompletingOnTimeResetsFromCompletionDate() {
        let task = CadenceTask(
            title: "Clean toilets",
            cadenceDays: 7,
            lastCompletedAt: date(year: 2026, month: 6, day: 15),
            calendar: calendar
        )

        task.complete(on: date(year: 2026, month: 6, day: 22, hour: 20), calendar: calendar)

        XCTAssertEqual(task.nextDueAt, date(year: 2026, month: 6, day: 29))
    }

    func testCompletingLateResetsFromActualCompletionDate() {
        let task = CadenceTask(
            title: "Clean toilets",
            cadenceDays: 7,
            lastCompletedAt: date(year: 2026, month: 6, day: 1),
            calendar: calendar
        )

        task.complete(on: date(year: 2026, month: 6, day: 22, hour: 20), calendar: calendar)

        XCTAssertEqual(task.nextDueAt, date(year: 2026, month: 6, day: 29))
    }

    func testDaysRemainingForUpcomingDueTodayAndOverdue() {
        let today = date(year: 2026, month: 6, day: 22, hour: 12)

        XCTAssertEqual(CadenceDateLogic.daysRemaining(from: today, to: date(year: 2026, month: 6, day: 25), calendar: calendar), 3)
        XCTAssertEqual(CadenceDateLogic.daysRemaining(from: today, to: date(year: 2026, month: 6, day: 22), calendar: calendar), 0)
        XCTAssertEqual(CadenceDateLogic.daysRemaining(from: today, to: date(year: 2026, month: 6, day: 20), calendar: calendar), -2)
    }

    func testFilteringDueUpcomingAndArchived() {
        let today = date(year: 2026, month: 6, day: 22)
        let due = CadenceTask(title: "Due", cadenceDays: 1, nextDueAt: today)
        let overdue = CadenceTask(title: "Overdue", cadenceDays: 1, nextDueAt: date(year: 2026, month: 6, day: 20))
        let upcoming = CadenceTask(title: "Upcoming", cadenceDays: 1, nextDueAt: date(year: 2026, month: 6, day: 25))
        let archived = CadenceTask(title: "Archived", cadenceDays: 1, nextDueAt: today, isArchived: true)

        let tasks = [due, overdue, upcoming, archived]

        XCTAssertEqual(CadenceTaskFilter.dueToday(tasks, on: today, calendar: calendar).map(\.title), ["Overdue", "Due"])
        XCTAssertEqual(CadenceTaskFilter.upcoming(tasks, dayLimit: 14, on: today, calendar: calendar).map(\.title), ["Upcoming"])
    }

    func testNotificationSchedulingHelperProducesExpectedTriggerDate() {
        let dueDate = date(year: 2026, month: 6, day: 29)
        let reminderTime = DateComponents(hour: 8, minute: 30)
        let components = CadenceNotificationScheduler.triggerComponents(
            dueDate: dueDate,
            notificationTime: reminderTime,
            calendar: calendar
        )

        XCTAssertEqual(components?.year, 2026)
        XCTAssertEqual(components?.month, 6)
        XCTAssertEqual(components?.day, 29)
        XCTAssertEqual(components?.hour, 8)
        XCTAssertEqual(components?.minute, 30)
    }

    func testWidgetSnapshotWritesDueCountAndNextDueTask() {
        let today = date(year: 2026, month: 6, day: 22)
        let due = CadenceTask(title: "Water cactus", cadenceDays: 12, nextDueAt: today)
        let upcoming = CadenceTask(title: "Replace air filter", cadenceDays: 90, nextDueAt: date(year: 2026, month: 6, day: 30))

        let snapshot = WidgetSnapshotStore.snapshot(from: [upcoming, due], now: today, calendar: calendar)

        XCTAssertEqual(snapshot.dueCount, 1)
        XCTAssertEqual(snapshot.nextTaskTitle, "Water cactus")
        XCTAssertEqual(snapshot.nextTaskDueText, "Due today")
    }

    @MainActor
    func testCategoryBootstrapCreatesDefaultsAndAdoptsLegacyCategory() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let task = CadenceTask(title: "Trim herbs", categoryName: "Garden", cadenceDays: 10)
        context.insert(task)
        try context.save()

        try CategoryCatalog.bootstrap(in: context, categories: [], tasks: [task])

        let categories = try context.fetch(FetchDescriptor<TaskCategory>())
        XCTAssertTrue(categories.contains { $0.name == "Home" })
        XCTAssertTrue(categories.contains { $0.name == "Garden" })
        XCTAssertEqual(categories.filter(\.isFallback).map(\.name), [TaskCategory.fallbackName])
    }

    @MainActor
    func testDeletingCategoryMovesTasksToOther() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let other = TaskCategory(name: TaskCategory.fallbackName, sortOrder: 0, isFallback: true)
        let pets = TaskCategory(name: "Pets", symbolName: "pawprint", sortOrder: 1)
        let task = CadenceTask(title: "Wash dog bed", categoryName: "Pets", cadenceDays: 14)
        context.insert(other)
        context.insert(pets)
        context.insert(task)
        try context.save()

        try CategoryCatalog.delete(
            pets,
            categories: [other, pets],
            tasks: [task],
            in: context
        )

        XCTAssertEqual(task.categoryName, TaskCategory.fallbackName)
        let categories = try context.fetch(FetchDescriptor<TaskCategory>())
        XCTAssertFalse(categories.contains { $0.name == "Pets" })
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([CadenceTask.self, TaskCategory.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
