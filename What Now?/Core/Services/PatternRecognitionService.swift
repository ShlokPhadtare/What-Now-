//
//  PatternRecognitionService.swift
//  What Now?
//

import Foundation
import SwiftData

/// Analyzes task completion history to identify routines and generate AI memories.
@Observable
final class PatternRecognitionService {
    private let context: ModelContext
    private let memoryService: MemoryService
    
    init(context: ModelContext, memoryService: MemoryService) {
        self.context = context
        self.memoryService = memoryService
    }
    
    /// Scans completed tasks to find repeated temporal patterns (e.g., "Gym" usually done at 7 AM).
    @MainActor
    func analyzeAndGenerateMemories() {
        let descriptor = FetchDescriptor<WNTask>(
            predicate: #Predicate<WNTask> { $0.status == "completed" },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        guard let completedTasks = try? context.fetch(descriptor), !completedTasks.isEmpty else { return }
        
        // Group by title
        var groupedByTitle: [String: [WNTask]] = [:]
        for task in completedTasks {
            let normalized = task.title.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            groupedByTitle[normalized, default: []].append(task)
        }
        
        for (title, tasks) in groupedByTitle {
            // We need at least 3 occurrences to form a pattern
            guard tasks.count >= 3 else { continue }
            
            // Check if they usually happen around the same hour (mode)
            var hourCounts: [Int: Int] = [:]
            for task in tasks {
                guard let completedAt = task.completedAt else { continue }
                let hour = Calendar.current.component(.hour, from: completedAt)
                hourCounts[hour, default: 0] += 1
            }
            
            // Find the most frequent hour
            if let maxHour = hourCounts.max(by: { $0.value < $1.value }) {
                // If more than 60% of completions happen within this hour (or adjacent)
                let adjacentCounts = (hourCounts[maxHour.key - 1] ?? 0) + maxHour.value + (hourCounts[maxHour.key + 1] ?? 0)
                let threshold = Int(Double(tasks.count) * 0.6)
                
                if adjacentCounts >= threshold {
                    let ampm = maxHour.key < 12 ? "AM" : "PM"
                    let displayHour = maxHour.key % 12 == 0 ? 12 : maxHour.key % 12
                    let memoryText = "User usually completes '\(title.capitalized)' around \(displayHour) \(ampm)."
                    
                    // Check if we already know this
                    let existing = memoryService.allMemories()
                    if !existing.contains(where: { $0.content == memoryText }) {
                        memoryService.addMemory(content: memoryText, category: .habits, source: "Pattern Recognition")
                    }
                }
            }
        }
    }
}
