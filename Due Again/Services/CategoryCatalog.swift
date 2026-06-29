import Foundation
import SwiftData

@MainActor
enum CategoryCatalog {
    static let defaults: [(name: String, symbol: String)] = [
        ("Home", "house"),
        ("Plants", "leaf"),
        ("Pets", "pawprint"),
        ("Health", "heart"),
        ("Car", "car"),
        ("Cleaning", "sparkles"),
        (TaskCategory.fallbackName, "circle.grid.2x2")
    ]

    static func bootstrap(
        in modelContext: ModelContext,
        categories: [TaskCategory],
        tasks: [CadenceTask]
    ) throws {
        var existingNames = Set(categories.map { normalizedKey($0.name) })
        var nextSortOrder = (categories.map(\.sortOrder).max() ?? -1) + 1
        var changed = false

        if categories.isEmpty {
            for definition in defaults {
                modelContext.insert(
                    TaskCategory(
                        name: definition.name,
                        symbolName: definition.symbol,
                        sortOrder: nextSortOrder,
                        isFallback: definition.name == TaskCategory.fallbackName
                    )
                )
                existingNames.insert(normalizedKey(definition.name))
                nextSortOrder += 1
                changed = true
            }
        }

        for category in categories where normalizedKey(category.name) == normalizedKey(TaskCategory.fallbackName) && !category.isFallback {
            category.isFallback = true
            changed = true
        }

        for task in tasks {
            let trimmedName = task.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            let categoryName = trimmedName.isEmpty ? TaskCategory.fallbackName : trimmedName
            if task.categoryName != categoryName {
                task.categoryName = categoryName
                changed = true
            }

            guard !existingNames.contains(normalizedKey(categoryName)) else {
                continue
            }

            modelContext.insert(
                TaskCategory(name: categoryName, sortOrder: nextSortOrder)
            )
            existingNames.insert(normalizedKey(categoryName))
            nextSortOrder += 1
            changed = true
        }

        if changed {
            try modelContext.save()
        }
    }

    static func symbol(for categoryName: String, in categories: [TaskCategory]) -> String {
        categories.first { normalizedKey($0.name) == normalizedKey(categoryName) }?.symbolName
            ?? "circle.grid.2x2"
    }

    static func rename(
        _ category: TaskCategory,
        to name: String,
        symbolName: String,
        tasks: [CadenceTask],
        in modelContext: ModelContext
    ) throws {
        let oldName = category.name
        let newName = category.isFallback ? TaskCategory.fallbackName : name.trimmingCharacters(in: .whitespacesAndNewlines)

        category.name = newName
        category.symbolName = symbolName
        category.updatedAt = Date()

        for task in tasks where normalizedKey(task.categoryName) == normalizedKey(oldName) {
            task.categoryName = newName
            task.updatedAt = Date()
        }

        try modelContext.save()
    }

    static func delete(
        _ category: TaskCategory,
        categories: [TaskCategory],
        tasks: [CadenceTask],
        in modelContext: ModelContext
    ) throws {
        guard !category.isFallback else {
            return
        }

        let fallback = categories.first(where: \.isFallback) ?? makeFallback(in: modelContext, sortOrder: categories.count)
        for task in tasks where normalizedKey(task.categoryName) == normalizedKey(category.name) {
            task.categoryName = fallback.name
            task.updatedAt = Date()
        }

        modelContext.delete(category)
        let remaining = categories
            .filter { $0.id != category.id }
            .sorted { $0.sortOrder < $1.sortOrder }
        for (index, item) in remaining.enumerated() {
            item.sortOrder = index
        }
        try modelContext.save()
    }

    static func normalizedKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
    }

    private static func makeFallback(in modelContext: ModelContext, sortOrder: Int) -> TaskCategory {
        let fallback = TaskCategory(
            name: TaskCategory.fallbackName,
            symbolName: "circle.grid.2x2",
            sortOrder: sortOrder,
            isFallback: true
        )
        modelContext.insert(fallback)
        return fallback
    }
}
