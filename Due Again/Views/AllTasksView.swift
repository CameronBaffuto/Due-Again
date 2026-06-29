import SwiftUI

struct AllTasksView: View {
    let tasks: [CadenceTask]
    let onAdd: () -> Void
    let onEdit: (CadenceTask) -> Void
    let onComplete: (CadenceTask) -> Void
    let onArchive: (CadenceTask) -> Void

    private var groupedTasks: [(CadenceTaskStatus, [CadenceTask])] {
        let statuses: [CadenceTaskStatus] = [.overdue, .dueToday, .upcoming, .archived]
        return statuses.compactMap { status in
            let group = tasks.filter { $0.status() == status }
            return group.isEmpty ? nil : (status, group)
        }
    }

    var body: some View {
        List {
            if tasks.isEmpty {
                ContentUnavailableView(
                    "No Cadences Yet",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Add upkeep tasks that become due again after a set number of days.")
                )
            } else {
                ForEach(groupedTasks, id: \.0.rawValue) { status, group in
                    Section(status.title) {
                        ForEach(group) { task in
                            CadenceTaskCard(
                                task: task,
                                prominence: status == .archived ? .muted : .quiet,
                                onDone: { onComplete(task) },
                                onEdit: { onEdit(task) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(task.isArchived ? "Restore" : "Archive") {
                                    onArchive(task)
                                }
                                .tint(task.isArchived ? Color.dueAgainGreen : Color.gray)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.dueAgainBackground)
        .navigationTitle("All")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add cadence")
            }
        }
    }
}
