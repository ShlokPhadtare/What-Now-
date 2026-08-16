//
//  WNEmptyState.swift
//  What Now?
//

import SwiftUI

/// A reusable empty state view shown when a list or screen has no content.
struct WNEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview("No Tasks") {
    WNEmptyState(
        symbol: "checkmark.circle",
        title: "No Tasks",
        message: "Create your first task to get started.",
        actionTitle: "Create Task"
    ) { }
}

#Preview("No History") {
    WNEmptyState(
        symbol: "clock",
        title: "No History Yet",
        message: "Complete tasks and focus sessions to see your activity here."
    )
}
