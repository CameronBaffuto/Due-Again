import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CadenceTask.nextDueAt) private var tasks: [CadenceTask]

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
                case .add:
                    TaskEditorView(mode: .add)
                case .edit(let task):
                    TaskEditorView(mode: .edit(task))
                }
            }
        }
        .onAppear(perform: refreshWidgetSnapshot)
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
                onAdd: { sheetDestination = .add },
                onEdit: { sheetDestination = .edit($0) },
                onComplete: complete
            )
        case .comingSoon:
            ComingSoonView(
                tasks: tasks,
                onAdd: { sheetDestination = .add },
                onEdit: { sheetDestination = .edit($0) },
                onComplete: complete
            )
        case .all:
            AllTasksView(
                tasks: tasks,
                onAdd: { sheetDestination = .add },
                onEdit: { sheetDestination = .edit($0) },
                onComplete: complete,
                onArchive: archive
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

    private func saveChanges() {
        do {
            try modelContext.save()
            refreshWidgetSnapshot()
        } catch {
            assertionFailure("Unable to save task changes: \(error)")
        }
    }

    private func refreshWidgetSnapshot() {
        WidgetSnapshotStore.write(from: tasks)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case today
    case comingSoon
    case all
    case settings

    var id: String { rawValue }

    @ViewBuilder
    var label: some View {
        switch self {
        case .today:
            Label("Today", systemImage: "sun.max")
        case .comingSoon:
            Label("Coming Soon", systemImage: "calendar")
        case .all:
            Label("All", systemImage: "tray.full")
        case .settings:
            Label("Settings", systemImage: "gearshape")
        }
    }
}

enum SheetDestination: Identifiable {
    case add
    case edit(CadenceTask)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let task):
            "edit-\(task.id.uuidString)"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
