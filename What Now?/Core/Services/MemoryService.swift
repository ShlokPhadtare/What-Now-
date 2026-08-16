//
//  MemoryService.swift
//  What Now?
//

import Foundation
import SwiftData
import SwiftUI

/// Manages persistent AI memories about the user's preferences.
@Observable
@MainActor
final class MemoryService: NSObject {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
        super.init()
    }
    
    func allMemories(enabledOnly: Bool = false) -> [WNMemory] {
        let descriptor = FetchDescriptor<WNMemory>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let all = (try? context.fetch(descriptor)) ?? []
        if enabledOnly {
            return all.filter { $0.isEnabled }
        }
        return all
    }
    
    func memoriesByCategory() -> [WNMemoryCategory: [WNMemory]] {
        let all = allMemories()
        return Dictionary(grouping: all, by: { $0.category })
    }
    
    func addMemory(content: String, category: WNMemoryCategory = .other, source: String = "User Conversation") {
        let memory = WNMemory(content: content, category: category)
        memory.source = source
        context.insert(memory)
        save()
    }
    
    func toggleMemory(_ memory: WNMemory) {
        memory.isEnabled.toggle()
        memory.updatedAt = .now
        save()
    }
    
    func deleteMemory(_ memory: WNMemory) {
        context.delete(memory)
        save()
    }
    
    func clearAll() {
        let all = allMemories()
        for mem in all {
            context.delete(mem)
        }
        save()
    }
    
    private func save() {
        try? context.save()
    }
}
