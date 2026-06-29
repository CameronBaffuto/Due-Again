import SwiftData
import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskCategory.sortOrder) private var categories: [TaskCategory]
    @Query private var tasks: [CadenceTask]

    @State private var editorMode: CategoryEditorMode?
    @State private var pendingDeletion: TaskCategory?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Button {
                        editorMode = .edit(category)
                    } label: {
                        CategoryManagementRow(
                            category: category,
                            taskCount: taskCount(for: category)
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !category.isFallback {
                            Button("Delete", role: .destructive) {
                                pendingDeletion = category
                                isShowingDeleteConfirmation = true
                            }
                        }
                    }
                }
                .onMove(perform: moveCategories)
            } footer: {
                Text("Deleting a category moves its tasks to Other. Other cannot be deleted.")
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add category", systemImage: "plus") {
                    editorMode = .add
                }
            }
        }
        .sheet(item: $editorMode) { mode in
            NavigationStack {
                CategoryEditorView(mode: mode)
            }
        }
        .confirmationDialog(
            "Delete \(pendingDeletion?.name ?? "category")?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete and Move Tasks to Other", role: .destructive, action: deletePendingCategory)
            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("No tasks will be deleted.")
        }
    }

    private func taskCount(for category: TaskCategory) -> Int {
        tasks.filter {
            CategoryCatalog.normalizedKey($0.categoryName) == CategoryCatalog.normalizedKey(category.name)
        }.count
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
            category.updatedAt = Date()
        }
        try? modelContext.save()
    }

    private func deletePendingCategory() {
        guard let pendingDeletion else {
            return
        }

        do {
            try CategoryCatalog.delete(
                pendingDeletion,
                categories: categories,
                tasks: tasks,
                in: modelContext
            )
        } catch {
            assertionFailure("Unable to delete category: \(error)")
        }
        self.pendingDeletion = nil
    }
}
