import SwiftData
import SwiftUI

struct TaskEditorView: View {
    enum Mode {
        case add(categoryName: String?)
        case edit(CadenceTask)

        var title: String {
            switch self {
            case .add:
                "Add Cadence"
            case .edit:
                "Edit Cadence"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CadenceTask.nextDueAt) private var allTasks: [CadenceTask]
    @Query(sort: \TaskCategory.sortOrder) private var categories: [TaskCategory]

    let mode: Mode

    @State private var draft: CadenceTaskDraft
    @State private var hasNotificationTime = false
    @State private var notificationDate = Date()
    @State private var hasLastCompletedAt = false
    @State private var lastCompletedDate = Date()

    init(mode: Mode) {
        self.mode = mode

        let initialDraft: CadenceTaskDraft
        switch mode {
        case .add(let categoryName):
            var draft = CadenceTaskDraft()
            if let categoryName {
                draft.categoryName = categoryName
            }
            initialDraft = draft
        case .edit(let task):
            initialDraft = CadenceTaskDraft(task: task)
        }

        _draft = State(initialValue: initialDraft)
        _hasNotificationTime = State(initialValue: initialDraft.notificationTime != nil)
        _notificationDate = State(initialValue: Self.date(from: initialDraft.notificationTime) ?? Date())
        _hasLastCompletedAt = State(initialValue: initialDraft.lastCompletedAt != nil)
        _lastCompletedDate = State(initialValue: initialDraft.lastCompletedAt ?? Date())
    }

    var body: some View {
        Form {
            Section("Cadence") {
                TextField("Title", text: $draft.title)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("task-title")

                Stepper(value: $draft.cadenceDays, in: 1...730) {
                    HStack {
                        Text("Every")
                        Spacer()
                        Text(DisplayText.cadence(draft.cadenceDays).replacingOccurrences(of: "Every ", with: ""))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("cadence-days")

                Picker("Category", selection: $draft.categoryName) {
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.symbolName)
                            .tag(category.name)
                    }
                }
            }

            Section("Details") {
                TextField("Notes", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...6)

                Toggle("Last done", isOn: $hasLastCompletedAt.animation())
                if hasLastCompletedAt {
                    DatePicker(
                        "Date",
                        selection: $lastCompletedDate,
                        displayedComponents: [.date]
                    )
                }
            }

            Section("Reminder") {
                Toggle("Notification time", isOn: $hasNotificationTime.animation())
                if hasNotificationTime {
                    DatePicker(
                        "Time",
                        selection: $notificationDate,
                        displayedComponents: [.hourAndMinute]
                    )
                }
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let hasSelectedCategory = categories.contains {
                CategoryCatalog.normalizedKey($0.name) == CategoryCatalog.normalizedKey(draft.categoryName)
            }
            if !hasSelectedCategory {
                draft.categoryName = categories.first?.name ?? TaskCategory.fallbackName
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!draft.canSave)
                    .accessibilityIdentifier("save-task")
            }
        }
    }

    private func save() {
        draft.notificationTime = hasNotificationTime ? Calendar.current.dateComponents([.hour, .minute], from: notificationDate) : nil
        draft.lastCompletedAt = hasLastCompletedAt ? lastCompletedDate : nil

        let task: CadenceTask
        switch mode {
        case .add:
            task = CadenceTask(
                title: draft.title,
                notes: draft.notes,
                categoryName: draft.normalizedCategoryName,
                cadenceDays: draft.cadenceDays,
                lastCompletedAt: draft.lastCompletedAt,
                notificationTime: draft.notificationTime
            )
            modelContext.insert(task)
        case .edit(let existingTask):
            existingTask.updateFromDraft(draft)
            task = existingTask
        }

        do {
            try modelContext.save()
            WidgetSnapshotStore.write(from: allTasks)
            if task.notificationTime == nil {
                CadenceNotificationScheduler.shared.cancelNotification(for: task)
            } else {
                Task {
                    try? await CadenceNotificationScheduler.shared.scheduleNotification(for: task)
                }
            }
            dismiss()
        } catch {
            assertionFailure("Unable to save cadence task: \(error)")
        }
    }

    private static func date(from components: DateComponents?) -> Date? {
        guard let components else {
            return nil
        }

        return Calendar.current.date(from: components)
    }
}
