import SwiftUI

struct CategoriesView: View {
    let tasks: [CadenceTask]
    let categories: [TaskCategory]
    let onAdd: (String?) -> Void
    let onEdit: (CadenceTask) -> Void
    let onComplete: (CadenceTask) -> Void
    let onArchive: (CadenceTask) -> Void
    let onDelete: (CadenceTask) -> Void

    var body: some View {
        List {
            if categories.isEmpty {
                ProgressView("Preparing categories")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(categories) { category in
                    NavigationLink(value: CategoryRoute(categoryID: category.id)) {
                        CategorySummaryRow(category: category, tasks: tasks)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.dueAgainBackground)
        .navigationTitle("Categories")
        .navigationDestination(for: CategoryRoute.self) { route in
            if let category = categories.first(where: { $0.id == route.categoryID }) {
                CategoryTaskListView(
                    category: category,
                    tasks: tasks,
                    onAdd: { onAdd(category.name) },
                    onEdit: onEdit,
                    onComplete: onComplete,
                    onArchive: onArchive,
                    onDelete: onDelete
                )
            } else {
                ContentUnavailableView("Category Not Found", systemImage: "folder.badge.questionmark")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add cadence", systemImage: "plus") {
                    onAdd(nil)
                }
            }
        }
    }
}
