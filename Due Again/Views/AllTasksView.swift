import SwiftUI

struct AllTasksView: View {
    @AppStorage("showArchivedInAll") private var showArchivedInAll = true

    let tasks: [CadenceTask]
    let categories: [TaskCategory]
    let onAdd: () -> Void
    let onEdit: (CadenceTask) -> Void
    let onComplete: (CadenceTask) -> Void
    let onArchive: (CadenceTask) -> Void
    let onDelete: (CadenceTask) -> Void

    @State private var searchText = ""
    @State private var statusFilter: AllTasksStatusFilter = .all
    @State private var selectedCategoryID: UUID?
    @State private var taskPendingDeletion: CadenceTask?
    @State private var isShowingDeleteConfirmation = false

    private var selectedCategory: TaskCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    private var hasActiveFilters: Bool {
        statusFilter != .all || selectedCategoryID != nil
    }

    private var filteredTasks: [CadenceTask] {
        tasks.filter { task in
            matchesArchivePreference(task)
                && matchesStatus(task)
                && matchesCategory(task)
                && matchesSearch(task)
        }
    }

    private var groupedTasks: [(CadenceTaskStatus, [CadenceTask])] {
        let statuses: [CadenceTaskStatus] = [.overdue, .dueToday, .upcoming, .archived]
        return statuses.compactMap { status in
            let group = filteredTasks.filter { $0.status() == status }
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
                .listRowBackground(Color.clear)
            } else if filteredTasks.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Matching Cadences",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try a different status or category filter.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ContentUnavailableView.search
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groupedTasks, id: \.0.rawValue) { status, group in
                    Section(status.title) {
                        ForEach(group) { task in
                            CadenceTaskCard(
                                task: task,
                                categorySymbol: CategoryCatalog.symbol(for: task.categoryName, in: categories),
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
        .navigationTitle("All")
        .searchable(text: $searchText, prompt: "Search cadences")
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Reset Filters", systemImage: "arrow.counterclockwise", action: resetFilters)
                        .disabled(!hasActiveFilters)

                    Divider()

                    Picker("Status", selection: $statusFilter) {
                        ForEach(AllTasksStatusFilter.allCases) { filter in
                            Label(filter.title, systemImage: filter.symbolName)
                                .tag(filter)
                        }
                    }

                    Picker("Category", selection: $selectedCategoryID) {
                        Label("All Categories", systemImage: "square.grid.2x2")
                            .tag(UUID?.none)

                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.symbolName)
                                .tag(Optional(category.id))
                        }
                    }
                } label: {
                    Label(
                        hasActiveFilters ? "Filters active" : "Filter",
                        systemImage: hasActiveFilters
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                    )
                }

                Button("Add cadence", systemImage: "plus", action: onAdd)
            }
        }
    }

    private func matchesArchivePreference(_ task: CadenceTask) -> Bool {
        statusFilter == .archived || showArchivedInAll || !task.isArchived
    }

    private func matchesStatus(_ task: CadenceTask) -> Bool {
        switch statusFilter {
        case .all:
            true
        case .due:
            task.status() == .overdue || task.status() == .dueToday
        case .upcoming:
            task.status() == .upcoming
        case .archived:
            task.status() == .archived
        }
    }

    private func matchesCategory(_ task: CadenceTask) -> Bool {
        guard let selectedCategory else {
            return true
        }
        return CategoryCatalog.normalizedKey(task.categoryName) == CategoryCatalog.normalizedKey(selectedCategory.name)
    }

    private func matchesSearch(_ task: CadenceTask) -> Bool {
        guard !searchText.isEmpty else {
            return true
        }
        return task.title.localizedCaseInsensitiveContains(searchText)
            || task.notes.localizedCaseInsensitiveContains(searchText)
            || task.categoryName.localizedCaseInsensitiveContains(searchText)
    }

    private func resetFilters() {
        statusFilter = .all
        selectedCategoryID = nil
    }

}
