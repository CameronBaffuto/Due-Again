import Foundation

enum CategoryEditorMode: Identifiable {
    case add
    case edit(TaskCategory)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let category):
            "edit-\(category.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .add:
            "Add Category"
        case .edit:
            "Edit Category"
        }
    }
}
