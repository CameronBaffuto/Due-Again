import SwiftUI

struct ComingSoonView: View {
    let tasks: [CadenceTask]
    let onAdd: () -> Void
    let onEdit: (CadenceTask) -> Void
    let onComplete: (CadenceTask) -> Void

    private var upcomingTasks: [CadenceTask] {
        CadenceTaskFilter.upcoming(tasks, dayLimit: 14)
    }

    var body: some View {
        List {
            if upcomingTasks.isEmpty {
                ContentUnavailableView(
                    "Nothing Coming Soon",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("Cadences due in the next two weeks will appear here.")
                )
            } else {
                ForEach(upcomingTasks) { task in
                    CadenceTaskCard(
                        task: task,
                        prominence: .quiet,
                        onDone: { onComplete(task) },
                        onEdit: { onEdit(task) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.dueAgainBackground)
        .navigationTitle("Coming Soon")
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
