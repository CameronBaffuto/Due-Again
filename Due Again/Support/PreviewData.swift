import SwiftData
import Foundation

enum PreviewData {
    @MainActor
    static var container: ModelContainer {
        let schema = Schema([CadenceTask.self, TaskCategory.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let today = Calendar.current.startOfDay(for: Date())
        let tasks = [
            CadenceTask(title: "Water cactus", categoryName: "Plants", cadenceDays: 12, lastCompletedAt: Calendar.current.date(byAdding: .day, value: -12, to: today)),
            CadenceTask(title: "Clean toilets", categoryName: "Cleaning", cadenceDays: 7, lastCompletedAt: Calendar.current.date(byAdding: .day, value: -9, to: today)),
            CadenceTask(title: "Replace air filter", categoryName: "Home", cadenceDays: 90, lastCompletedAt: Calendar.current.date(byAdding: .day, value: -84, to: today))
        ]

        tasks.forEach { container.mainContext.insert($0) }
        for (index, definition) in CategoryCatalog.defaults.enumerated() {
            container.mainContext.insert(
                TaskCategory(
                    name: definition.name,
                    symbolName: definition.symbol,
                    sortOrder: index,
                    isFallback: definition.name == TaskCategory.fallbackName
                )
            )
        }
        return container
    }
}
