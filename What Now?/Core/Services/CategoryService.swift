//
//  CategoryService.swift
//  What Now?
//

import Foundation
import SwiftData

/// Manages categories including seeding defaults on first launch.
@Observable
final class CategoryService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Default Categories

    /// Seed default categories if none exist. Called once on first launch.
    func seedDefaultsIfNeeded() {
        let descriptor = FetchDescriptor<WNCategory>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let defaults: [(name: String, symbol: String, color: String, order: Int)] = [
            ("Study",      "book.fill",                                "#5856D6", 0),
            ("Work",       "briefcase.fill",                           "#007AFF", 1),
            ("Coding",     "chevron.left.forwardslash.chevron.right",  "#34C759", 2),
            ("Fitness",    "figure.run",                               "#FF9500", 3),
            ("Personal",   "person.fill",                              "#AF52DE", 4),
            ("Gaming",     "gamecontroller.fill",                      "#FF2D55", 5),
            ("Relaxation", "cup.and.saucer.fill",                      "#5AC8FA", 6),
        ]

        for item in defaults {
            let category = WNCategory(
                name: item.name,
                symbolName: item.symbol,
                colorHex: item.color,
                isDefault: true,
                sortOrder: item.order
            )
            context.insert(category)
        }

        try? context.save()
    }

    // MARK: - CRUD

    func allCategories() -> [WNCategory] {
        let descriptor = FetchDescriptor<WNCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func findCategory(named name: String) -> WNCategory? {
        let lowercased = name.lowercased()
        let descriptor = FetchDescriptor<WNCategory>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first { $0.name.lowercased() == lowercased }
    }

    func createCategory(name: String, symbolName: String, colorHex: String) -> WNCategory {
        let maxOrder = allCategories().map(\.sortOrder).max() ?? -1
        let category = WNCategory(
            name: name,
            symbolName: symbolName,
            colorHex: colorHex,
            isDefault: false,
            sortOrder: maxOrder + 1
        )
        context.insert(category)
        try? context.save()
        return category
    }

    func deleteCategory(_ category: WNCategory) {
        context.delete(category)
        try? context.save()
    }
}
