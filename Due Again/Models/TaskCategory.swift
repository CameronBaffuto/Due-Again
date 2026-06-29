import Foundation
import SwiftData

@Model
final class TaskCategory {
    #Index<TaskCategory>([\.sortOrder], [\.name])

    static let fallbackName = "Other"

    static let availableSymbols = [
        "house",
        "leaf",
        "pawprint",
        "heart",
        "car",
        "sparkles",
        "drop",
        "wrench.and.screwdriver",
        "pills",
        "fork.knife",
        "figure.run",
        "circle.grid.2x2"
    ]

    var id: UUID
    var name: String
    var symbolName: String
    var sortOrder: Int
    var isFallback: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "circle.grid.2x2",
        sortOrder: Int = 0,
        isFallback: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbolName = symbolName
        self.sortOrder = sortOrder
        self.isFallback = isFallback
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
