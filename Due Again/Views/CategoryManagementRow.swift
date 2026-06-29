import SwiftUI

struct CategoryManagementRow: View {
    let category: TaskCategory
    let taskCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.symbolName)
                .foregroundStyle(Color.dueAgainGreen)
                .frame(width: 32, height: 32)
                .background(Color.dueAgainGreenFill, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            Text(category.name)

            Spacer()

            Text("\(taskCount)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(taskCount) \(taskCount == 1 ? "task" : "tasks")")
    }
}
