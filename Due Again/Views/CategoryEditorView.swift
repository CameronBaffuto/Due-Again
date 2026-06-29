import SwiftData
import SwiftUI

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskCategory.sortOrder) private var categories: [TaskCategory]
    @Query private var tasks: [CadenceTask]

    let mode: CategoryEditorMode

    @State private var name: String
    @State private var symbolName: String
    @State private var errorMessage: String?

    init(mode: CategoryEditorMode) {
        self.mode = mode
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _symbolName = State(initialValue: "circle.grid.2x2")
        case .edit(let category):
            _name = State(initialValue: category.name)
            _symbolName = State(initialValue: category.symbolName)
        }
    }

    var body: some View {
        Form {
            Section("Category") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .disabled(isFallback)

                Picker("Icon", selection: $symbolName) {
                    ForEach(TaskCategory.availableSymbols, id: \.self) { symbol in
                        Label(symbolTitle(symbol), systemImage: symbol)
                            .tag(symbol)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.dueAgainClay)
                }
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(trimmedName.isEmpty)
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFallback: Bool {
        if case .edit(let category) = mode {
            return category.isFallback
        }
        return false
    }

    private func save() {
        let duplicate = categories.contains { category in
            let isCurrent: Bool
            if case .edit(let editedCategory) = mode {
                isCurrent = editedCategory.id == category.id
            } else {
                isCurrent = false
            }
            return !isCurrent && CategoryCatalog.normalizedKey(category.name) == CategoryCatalog.normalizedKey(trimmedName)
        }

        guard !duplicate else {
            errorMessage = "A category with this name already exists."
            return
        }

        do {
            switch mode {
            case .add:
                modelContext.insert(
                    TaskCategory(
                        name: trimmedName,
                        symbolName: symbolName,
                        sortOrder: (categories.map(\.sortOrder).max() ?? -1) + 1
                    )
                )
                try modelContext.save()
            case .edit(let category):
                try CategoryCatalog.rename(
                    category,
                    to: trimmedName,
                    symbolName: symbolName,
                    tasks: tasks,
                    in: modelContext
                )
            }
            dismiss()
        } catch {
            errorMessage = "The category could not be saved."
        }
    }

    private func symbolTitle(_ symbol: String) -> String {
        switch symbol {
        case "house": "Home"
        case "leaf": "Plants"
        case "pawprint": "Pets"
        case "heart": "Health"
        case "car": "Car"
        case "sparkles": "Cleaning"
        case "drop": "Water"
        case "wrench.and.screwdriver": "Maintenance"
        case "pills": "Medication"
        case "fork.knife": "Kitchen"
        case "figure.run": "Activity"
        default: "General"
        }
    }
}
