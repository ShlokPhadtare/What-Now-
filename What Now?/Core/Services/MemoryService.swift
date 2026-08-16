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
    
    func allMemories() -> [WNMemory] {
        let descriptor = FetchDescriptor<WNMemory>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func addMemory(content: String) {
        let memory = WNMemory(content: content)
        context.insert(memory)
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
