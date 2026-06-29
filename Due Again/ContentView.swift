import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CadenceTask.nextDueAt) private var tasks: [CadenceTask]
    @Query(sort: \TaskCategory.sortOrder) private var categories: [TaskCategory]

    @State private var selectedTab: AppTab = .today
    @State private var sheetDestination: SheetDestination?

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tabContent(for: tab)
                }
                .tabItem { tab.label }
                .tag(tab)
            }
        }
        .tint(Color.dueAgainGreen)
        .sheet(item: $sheetDestination) { destination in
            NavigationStack {
                switch destination {
                case .add(let categoryName):
                    TaskEditorView(mode: .add(categoryName: categoryName))
                case .edit(let task):
                    TaskEditorView(mode: .edit(task))
                }
            }
        }
        .onAppear {
            prepareCategories()
            refreshWidgetSnapshot()
        }
        .onChange(of: tasks.map(\.updatedAt)) { _, _ in
            refreshWidgetSnapshot()
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .today:
            TodayView(
                tasks: tasks,
                categories: categories,
                onAdd: { sheetDestination = .add(categoryName: nil) },
                onEdit: { sheetDestination = .edit($0) },
                onComplete: complete
            )
        case .categories:
            CategoriesView(
                tasks: tasks,
                categories: categories,
                onAdd: { sheetDestination = .add(categoryName: $0) },
                onEdit: { sheetDestination = .edit($0) },
                onComplete: complete,
                onArchive: archive,
                onDelete: delete
            )
        case .all:
            AllTasksView(
                tasks: tasks,
                categories: categories,
                onAdd: { sheetDestination = .add(categoryName: nil) },
                onEdit: { sheetDestination = .edit($0) },
                onComplete: complete,
                onArchive: archive,
                onDelete: delete
            )
        case .settings:
            SettingsView()
        }
    }

    private func complete(_ task: CadenceTask) {
        task.complete()
        saveChanges()

        Task {
            try? await CadenceNotificationScheduler.shared.scheduleNotification(for: task)
        }
    }

    private func archive(_ task: CadenceTask) {
        task.isArchived.toggle()
        task.updatedAt = Date()
        saveChanges()
        CadenceNotificationScheduler.shared.cancelNotification(for: task)
    }

    private func delete(_ task: CadenceTask) {
        let deletedTaskID = task.id
        CadenceNotificationScheduler.shared.cancelNotification(for: task)
        modelContext.delete(task)

        do {
            try modelContext.save()
            WidgetSnapshotStore.write(from: tasks.filter { $0.id != deletedTaskID })
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            assertionFailure("Unable to delete task: \(error)")
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
            refreshWidgetSnapshot()
        } catch {
            assertionFailure("Unable to save task changes: \(error)")
        }
    }

    private func prepareCategories() {
        do {
            try CategoryCatalog.bootstrap(in: modelContext, categories: categories, tasks: tasks)
        } catch {
            assertionFailure("Unable to prepare categories: \(error)")
        }
    }

    private func refreshWidgetSnapshot() {
        WidgetSnapshotStore.write(from: tasks)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case today
    case categories
    case all
    case settings

    var id: String { rawValue }

    @ViewBuilder
    var label: some View {
        switch self {
        case .today:
            Label("Today", systemImage: "sun.max")
        case .categories:
            Label("Categories", systemImage: "square.grid.2x2")
        case .all:
            Label("All", systemImage: "tray.full")
        case .settings:
            Label("Settings", systemImage: "gearshape")
        }
    }
}

enum SheetDestination: Identifiable {
    case add(categoryName: String?)
    case edit(CadenceTask)

    var id: String {
        switch self {
        case .add(let categoryName):
            "add-\(categoryName ?? "none")"
        case .edit(let task):
            "edit-\(task.id.uuidString)"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
