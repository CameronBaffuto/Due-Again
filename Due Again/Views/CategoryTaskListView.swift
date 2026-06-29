import SwiftUI

struct CategoryTaskListView: View {
    let category: TaskCategory
    let tasks: [CadenceTask]
    let onAdd: () -> Void
    let onEdit: (CadenceTask) -> Void
    let onComplete: (CadenceTask) -> Void
    let onArchive: (CadenceTask) -> Void
    let onDelete: (CadenceTask) -> Void

    @State private var taskPendingDeletion: CadenceTask?
    @State private var isShowingDeleteConfirmation = false

    private var categoryTasks: [CadenceTask] {
        tasks
            .filter { CategoryCatalog.normalizedKey($0.categoryName) == CategoryCatalog.normalizedKey(category.name) }
            .sorted { $0.nextDueAt < $1.nextDueAt }
    }

    private var groupedTasks: [(CadenceTaskStatus, [CadenceTask])] {
        let statuses: [CadenceTaskStatus] = [.overdue, .dueToday, .upcoming, .archived]
        return statuses.compactMap { status in
            let matches = categoryTasks.filter { $0.status() == status }
            return matches.isEmpty ? nil : (status, matches)
        }
    }

    var body: some View {
        List {
            if categoryTasks.isEmpty {
                ContentUnavailableView {
                    Label("No \(category.name) Cadences", systemImage: category.symbolName)
                } description: {
                    Text("Add a cadence to keep this area organized.")
                } actions: {
                    Button("Add cadence", systemImage: "plus", action: onAdd)
                        .buttonStyle(.borderedProminent)
                        .tint(Color.dueAgainGreen)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedTasks, id: \.0.rawValue) { status, group in
                    Section(status.title) {
                        ForEach(group) { task in
                            CadenceTaskCard(
                                task: task,
                                categorySymbol: category.symbolName,
                                prominence: status == .archived ? .muted : .quiet,
                                onDone: { onComplete(task) },
                                onEdit: { onEdit(task) }
                            )
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    onArchive(task)
                                } label: {
                                    Label(
                                        task.isArchived ? "Restore" : "Archive",
                                        systemImage: task.isArchived ? "arrow.uturn.backward" : "archivebox"
                                    )
                                }
                                .tint(task.isArchived ? Color.dueAgainGreen : Color.gray)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    taskPendingDeletion = task
                                    isShowingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
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
        .navigationTitle(category.name)
        .alert(
            "Delete Cadence?",
            isPresented: $isShowingDeleteConfirmation,
            presenting: taskPendingDeletion
        ) {
            task in
            Button("Delete", role: .destructive) {
                taskPendingDeletion = nil
                onDelete(task)
            }
            Button("Cancel", role: .cancel) {
                taskPendingDeletion = nil
            }
        } message: {
            task in
            Text("\"\(task.title)\" and its completion history will be permanently deleted. This cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add cadence", systemImage: "plus", action: onAdd)
            }
        }
    }

}
