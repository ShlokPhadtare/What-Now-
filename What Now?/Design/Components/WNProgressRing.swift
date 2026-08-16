//
//  WNProgressRing.swift
//  What Now?
//

import SwiftUI

/// A circular progress indicator used for focus timers and task progress.
struct WNProgressRing: View {
    let progress: Double // 0.0 to 1.0
    var lineWidth: CGFloat = 8
    var size: CGFloat = 120
    var accentColor: Color = .accentColor

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accentColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Progress: \(Int(progress * 100))%")
    }
}

#Preview {
    VStack(spacing: 24) {
        WNProgressRing(progress: 0.75)
        WNProgressRing(progress: 0.3, lineWidth: 4, size: 60, accentColor: .orange)
        WNProgressRing(progress: 1.0, accentColor: .green)
    }
    .padding()
}
