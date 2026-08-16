//
//  WNCategory.swift
//  What Now?
//

import Foundation
import SwiftData

/// A category for organizing tasks, routines, and focus sessions.
///
/// Default categories are seeded on first launch by `CategoryService`.
/// Users can create custom categories.
@Model
final class WNCategory: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "folder"
    var colorHex: String = "#007AFF"
    var isDefault: Bool = false
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \WNTask.category)
    var tasks: [WNTask] = []

    @Relationship(deleteRule: .nullify, inverse: \WNRoutine.category)
    var routines: [WNRoutine] = []

    init(
        name: String,
        symbolName: String = "folder",
        colorHex: String = "#007AFF",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}
