import SwiftUI

struct CategorySummaryRow: View {
    let category: TaskCategory
    let tasks: [CadenceTask]

    private var categoryTasks: [CadenceTask] {
        tasks.filter { !$0.isArchived && CategoryCatalog.normalizedKey($0.categoryName) == CategoryCatalog.normalizedKey(category.name) }
    }

    private var dueCount: Int {
        categoryTasks.filter { $0.daysRemaining() <= 0 }.count
    }

    private var nextTask: CadenceTask? {
        categoryTasks.sorted { $0.nextDueAt < $1.nextDueAt }.first
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.symbolName)
                .font(.title3)
                .foregroundStyle(dueCount > 0 ? Color.dueAgainClay : Color.dueAgainGreen)
                .frame(width: 44, height: 44)
                .background(
                    dueCount > 0 ? Color.dueAgainClayFill : Color.dueAgainGreenFill,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(Color.dueAgainInk)

                    Spacer()

                    Text(taskCountText)
                        .font(.subheadline)
                        .foregroundStyle(Color.dueAgainSecondaryText)
                }

                if dueCount > 0 {
                    Label(dueText, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.dueAgainClay)
                } else if let nextTask {
                    Text("Next: \(nextTask.title) - \(DisplayText.countdown(for: nextTask))")
                        .font(.subheadline)
                        .foregroundStyle(Color.dueAgainSecondaryText)
                        .lineLimit(1)
                } else {
                    Text("No active cadences")
                        .font(.subheadline)
                        .foregroundStyle(Color.dueAgainSecondaryText)
                }
            }
        }
        .padding(14)
        .background(Color.dueAgainSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.dueAgainSeparator.opacity(0.22))
        }
        .accessibilityElement(children: .combine)
    }

    private var taskCountText: String {
        "\(categoryTasks.count) \(categoryTasks.count == 1 ? "task" : "tasks")"
    }

    private var dueText: String {
        "\(dueCount) \(dueCount == 1 ? "task" : "tasks") due"
    }
}
