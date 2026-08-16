//
//  WhatNowWidget.swift
//  What Now?
//
//  Note: To use this widget, you must create a Widget Extension target in Xcode
//  (File > New > Target... > Widget Extension) and include this file in that target.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), task: WNTask(title: "Finish DSA assignment", estimatedMinutes: 25))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), task: WNTask(title: "Finish DSA assignment", estimatedMinutes: 25))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // In a real widget, you would fetch the model context and query the RecommendationEngine.
        // For simplicity, we are returning a mocked entry here since SwiftData in widgets
        // requires a shared app group container which isn't configured in Phase 1.
        let entry = SimpleEntry(date: currentDate, task: WNTask(title: "Ready to focus?", estimatedMinutes: 25))
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let task: WNTask?
}

struct WhatNowWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT NOW?")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            
            if let task = entry.task {
                Text(task.title)
                    .font(.headline)
                
                if let minutes = task.estimatedMinutes {
                    Text("\(minutes) min")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                Text("You're all caught up!")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// Commented out the @main so it doesn't conflict with the app target until a widget extension is made.
/*
@main
struct WhatNowWidget: Widget {
    let kind: String = "WhatNowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WhatNowWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WhatNowWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("What Now?")
        .description("See your next recommended action.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
*/
