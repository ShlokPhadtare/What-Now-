//
//  AssistantView.swift
//  What Now?
//

import SwiftUI
import SwiftData

struct AssistantView: View {
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var query: String = ""
    @State private var chatHistory: [ChatMessage] = []
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool

    enum MessageContent {
        case text(String)
        case actionResult(title: String, duration: Int?, deadline: Date?)
        case planProposal(blocks: [ProposedBlock])
        case planModification(actions: [PlanModification])
        case memorySaved(fact: String)
    }
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let isUser: Bool
        let content: MessageContent
        
        var text: String {
            switch content {
            case .text(let t): return t
            case .actionResult(let title, _, _): return "Created task: \(title)"
            case .planProposal: return "Proposed a plan."
            case .planModification: return "Modified the plan."
            case .memorySaved: return "Remembered a fact."
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            
            if chatHistory.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: WNTheme.Spacing.lg) {
                            ForEach(chatHistory) { message in
                                chatBubble(for: message)
                                    .id(message.id)
                            }
                            if isProcessing {
                                progressBubble
                                    .id("progress")
                            }
                        }
                        .padding(.horizontal, WNTheme.Spacing.lg)
                        .padding(.vertical, WNTheme.Spacing.md)
                    }
                    .onChange(of: chatHistory.count) { _, _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if let last = chatHistory.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isProcessing) { _, isProc in
                        if isProc {
                            withAnimation { proxy.scrollTo("progress", anchor: .bottom) }
                        }
                    }
                }
            }
            
            inputArea
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            isFocused = true
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.accentColor)
                .rotationEffect(Angle(degrees: isProcessing ? 180 : 0))
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: isProcessing)
            
            Text("Assistant")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: WNTheme.Spacing.xl) {
                Spacer().frame(height: 40)
                
                VStack(spacing: WNTheme.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Ask What Now?")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Plan your day, manage tasks, or figure out what to do next.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, WNTheme.Spacing.xl)
                }
                
                VStack(spacing: WNTheme.Spacing.sm) {
                    let suggestions = generateDynamicSuggestions()
                    ForEach(suggestions, id: \.self) { suggestion in
                        suggestionButton(suggestion)
                    }
                }
                .padding(.top, WNTheme.Spacing.lg)
                
                Spacer()
            }
        }
    }
    
    private func generateDynamicSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if let appState = appState {
            if appState.activeFocusSession != nil {
                suggestions.append("What should I do after this?")
            }
            
            let pending = appState.taskService.pendingTasks()
            if let topTask = pending.filter({ $0.priorityEnum == .high }).first ?? pending.first {
                suggestions.append("Help me finish \(topTask.title)")
            }
            
            if pending.isEmpty {
                suggestions.append("Add something to my day")
            } else {
                suggestions.append("Plan my day")
            }
            
            if suggestions.count < 3 {
                suggestions.append("I have 30 minutes")
            }
        } else {
            suggestions = ["What should I do now?", "Plan my day", "I have 30 minutes"]
        }
        
        return Array(suggestions.prefix(3))
    }
    
    private func suggestionButton(_ text: String) -> some View {
        Button {
            query = text
            submitQuery()
        } label: {
            Text(text)
                .font(.subheadline.weight(.medium))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private func chatBubble(for message: ChatMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .foregroundStyle(.white)
            } else {
                switch message.content {
                case .text(let text):
                    Text(text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .lineSpacing(4)
                case .actionResult(let title, let duration, let deadline):
                    actionResultBubble(title: title, duration: duration, deadline: deadline)
                case .planProposal(let blocks):
                    planProposalBubble(blocks: blocks)
                case .planModification(let actions):
                    planModificationBubble(actions: actions)
                case .memorySaved(let fact):
                    memoryBubble(fact: fact)
                }
                Spacer(minLength: 40)
            }
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: message.isUser ? .trailing : .leading)), removal: .opacity))
    }
    
    @ViewBuilder
    private func actionResultBubble(title: String, duration: Int?, deadline: Date?) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
            Label("Added", systemImage: "checkmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 6) {
                if let duration {
                    Text(duration.formattedMinutes)
                }
                if duration != nil && deadline != nil {
                    Text("·")
                }
                if let deadline {
                    Text(deadline.relativeDay)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private func planProposalBubble(blocks: [ProposedBlock]) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
            Label("Plan Generated", systemImage: "calendar.badge.plus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(blocks.prefix(5), id: \.title) { block in
                    HStack {
                        Text(formatIsoTime(block.startTimeIso))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)
                        Text(block.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(block.durationMinutes)m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if blocks.count > 5 {
                    Text("+ \(blocks.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5))
    }
    
    @ViewBuilder
    private func planModificationBubble(actions: [PlanModification]) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
            Label("Plan Updated", systemImage: "arrow.left.and.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            
            Text("Adjusted \(actions.count) item(s).")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5))
    }
    
    @ViewBuilder
    private func memoryBubble(fact: String) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
            Label("Remembered", systemImage: "brain")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.purple)
            
            Text(fact)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5))
    }
    
    private func formatIsoTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return "--:--" }
        let out = DateFormatter()
        out.timeStyle = .short
        return out.string(from: date)
    }
    
    private var progressBubble: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .scaleEffect(isProcessing ? 1.1 : 0.9)
                .opacity(isProcessing ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isProcessing)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            Spacer()
        }
        .transition(.opacity)
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask What Now...", text: $query, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                
                Button(action: submitQuery) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.white)
                        .frame(width: 32, height: 32)
                        .background(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(uiColor: .tertiarySystemFill) : Color.accentColor)
                        .clipShape(Circle())
                        .animation(.easeInOut(duration: 0.2), value: query)
                }
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                .padding(.trailing, 8)
                .padding(.bottom, 6)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Actions
    
    private func submitQuery() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let appState = appState else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        withAnimation {
            chatHistory.append(ChatMessage(isUser: true, content: .text(text)))
            query = ""
            isProcessing = true
        }
        
        let history = chatHistory.dropLast().map { AIChatMessage(role: $0.isUser ? "user" : "assistant", content: $0.text) }
        
        Task {
            do {
                let contextBuilder = AIContextBuilder(
                    taskService: appState.taskService,
                    focusService: appState.focusService,
                    preferenceService: appState.preferenceService,
                    planService: appState.planService,
                    memoryService: appState.memoryService
                )
                
                let context = contextBuilder.buildContext(for: text)
                let intent = try await appState.aiService.processQuery(text, history: history, context: context)
                await handleIntent(intent)
            } catch {
                withAnimation {
                    chatHistory.append(ChatMessage(isUser: false, content: .text("I'm sorry, I couldn't process that right now.")))
                    isProcessing = false
                }
            }
        }
    }
    
    @MainActor
    private func handleIntent(_ intent: AIAssistantIntent) async {
        withAnimation {
            isProcessing = false
        }
        
        switch intent {
        case .chatResponse(let message):
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .text(message)))
            }
            
        case .planDay:
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .text("I've planned your day. You can view the timeline in the Plan tab.")))
            }
            appState?.planService.generatePlan(for: .now)
            appState?.streakService.recordPlanCreated()
            
        case .proposePlan(let blocks):
            appState?.planService.applyProposedPlan(blocks)
            appState?.streakService.recordPlanCreated()
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .planProposal(blocks: blocks)))
            }
            
        case .modifyPlan(let actions):
            appState?.planService.applyModifications(actions)
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .planModification(actions: actions)))
            }
            
        case .remember(let fact):
            appState?.memoryService.addMemory(content: fact)
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .memorySaved(fact: fact)))
            }
            
        case .createTask(let title, let duration, let deadline):
            appState?.taskService.createTask(
                title: title,
                taskDescription: "",
                category: nil,
                priority: .medium,
                deadline: deadline,
                estimatedMinutes: duration,
                preferredTimeOfDay: nil,
                notes: nil
            )
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .actionResult(title: title, duration: duration, deadline: deadline)))
            }
            
        case .startFocus(let taskTitleFragment):
            let pending = appState?.taskService.pendingTasks() ?? []
            if let match = pending.first(where: { $0.title.lowercased().contains(taskTitleFragment.lowercased()) }) {
                appState?.startFocus(for: match)
                dismiss()
            } else {
                withAnimation {
                    chatHistory.append(ChatMessage(isUser: false, content: .text("I couldn't find a task matching '\(taskTitleFragment)'.")))
                }
            }
            
        case .getRecommendations:
            withAnimation {
                chatHistory.append(ChatMessage(isUser: false, content: .text("Check your Home screen for my latest recommendation.")))
            }
            dismiss()
        }
    }
}

