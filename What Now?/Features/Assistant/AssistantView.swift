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
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool
    
    @State private var showHistory: Bool = false
    @State private var voiceInput = VoiceInputService()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                if appState?.activeChatSession?.messages.isEmpty ?? true {
                    emptyState
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: WNTheme.Spacing.lg) {
                                ForEach(appState?.activeChatSession?.messages.sorted(by: { $0.timestamp < $1.timestamp }) ?? []) { message in
                                    chatBubble(for: message.chatMessage)
                                        .id(message.id)
                                }
                                if isProcessing {
                                    progressBubble
                                        .id("progress")
                                }
                            }
                            .padding(.horizontal, WNTheme.Spacing.lg)
                            .padding(.top, WNTheme.Spacing.md)
                            .padding(.bottom, 120) // space for floating composer
                        }
                        .onChange(of: appState?.activeChatSession?.messages.count ?? 0) { _, _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if let last = appState?.activeChatSession?.messages.max(by: { $0.timestamp < $1.timestamp }) {
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
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isFocused = false
                    }
                }
                
                inputArea
                    .padding(.bottom, 16)
            }
            .navigationTitle(appState?.activeChatSession?.title ?? "What Now?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .onAppear {
                isFocused = true
                voiceInput.requestPermissions()
                
                // Auto-create a session if none exists
                if appState?.activeChatSession == nil, let context = appState?.modelContext {
                    let session = WNChatSession(title: "New Chat")
                    context.insert(session)
                    try? context.save()
                    appState?.activeChatSession = session
                }
            }
            .onChange(of: voiceInput.recognizedText) { _, text in
                if voiceInput.isRecording && !text.isEmpty {
                    query = text
                }
            }
            .sheet(isPresented: $showHistory) {
                AssistantHistoryView()
            }
        }
    }
    
    // MARK: - Components
    
    // Header removed per design requirements
    
    @ViewBuilder
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: WNTheme.Spacing.lg) {
                VStack(spacing: WNTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Ask What Now?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Plan your day, manage tasks, or figure out what to do next.")
                        .font(.subheadline)
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
                .padding(.top, WNTheme.Spacing.sm)
            }
            .padding(.vertical, WNTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            isFocused = false
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
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
        }
        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
        .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    private func chatBubble(for message: ChatMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
                Text(LocalizedStringKey(message.text))
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .foregroundStyle(.white)
            } else {
                switch message.content {
                case .text(let text):
                    Text(LocalizedStringKey(text))
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
                case .question(let prompt, let options, _):
                    questionBubble(prompt: prompt, options: options)
                }
                Spacer(minLength: 40)
            }
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: message.isUser ? .trailing : .leading)), removal: .opacity))
    }
    
    @ViewBuilder
    private func actionResultBubble(title: String, duration: Int?, deadline: Date?) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: WNTheme.Spacing.xs) {
                Label("Added", systemImage: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.bottom, 2)
                
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
            
            Button {
                if let appState = appState {
                    let pending = appState.taskService.pendingTasks()
                    if let match = pending.first(where: { $0.title == title }) {
                        appState.startFocus(for: match)
                    }
                }
            } label: {
                Text("Start")
                    .font(.subheadline.weight(.medium))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
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
    
    @ViewBuilder
    private func questionBubble(prompt: String, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: WNTheme.Spacing.sm) {
            Text(LocalizedStringKey(prompt))
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .lineSpacing(4)
            
            if !options.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                query = option
                                submitQuery()
                            } label: {
                                Text(option)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        Button {
                            query = "× Cancel"
                            submitQuery()
                        } label: {
                            Text("× Cancel")
                                .font(.subheadline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
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
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse, options: .repeating, isActive: isProcessing)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            Spacer()
        }
        .transition(.opacity)
    }
    
    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask What Now...", text: $query, axis: .vertical)
                .lineLimit(1...5)
                .focused($isFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !voiceInput.isRecording {
                Button(action: {
                    if voiceInput.isAuthorized {
                        isFocused = false
                        voiceInput.toggleRecording()
                    } else {
                        voiceInput.requestPermissions()
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }
                .padding(.trailing, 8)
                .padding(.bottom, 6)
            } else if voiceInput.isRecording {
                Button(action: {
                    voiceInput.stopRecording()
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                        .symbolEffect(.pulse, options: .repeating, isActive: true)
                }
                .padding(.trailing, 8)
                .padding(.bottom, 6)
            } else {
                Button(action: submitQuery) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .scaleEffect(1.05)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: query.isEmpty)
                }
                .disabled(isProcessing)
                .padding(.trailing, 8)
                .padding(.bottom, 6)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Actions
    
    private func appendMessage(_ message: ChatMessage) {
        guard let session = appState?.activeChatSession else { return }
        
        let wnMessage = WNChatMessage(isUser: message.isUser, content: message.content)
        wnMessage.timestamp = message.timestamp
        wnMessage.session = session
        session.messages.append(wnMessage)
        session.updatedAt = .now
        
        // Auto-generate title for first user message
        if message.isUser && session.messages.filter({ $0.isUser }).count == 1 {
            if case .text(let t) = message.content {
                session.title = String(t.prefix(30)) + (t.count > 30 ? "..." : "")
            }
        }
        
        try? appState?.modelContext.save()
    }
    
    private func submitQuery() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let appState = appState else { return }
        
        isFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if voiceInput.isRecording {
            voiceInput.stopRecording()
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        withAnimation {
            appendMessage(ChatMessage(isUser: true, content: .text(text)))
            query = ""
            isProcessing = true
        }
        
        guard let session = appState.activeChatSession else { return }
        
        let history = session.messages.dropLast().suffix(10).map { AIChatMessage(role: $0.isUser ? "user" : "assistant", content: $0.chatMessage.text) }
        
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
                print("Total routing failure: \(error)")
                withAnimation {
                    appendMessage(ChatMessage(isUser: false, content: .text("I'm currently offline and couldn't process that.")))
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
            // Handle special system intents returned by LocalAssistantService
            if message == "SYSTEM_QUERY_MEMORY" {
                let memories = appState?.memoryService.allMemories(enabledOnly: true) ?? []
                let responseText: String
                if memories.isEmpty {
                    responseText = "I don't have anything remembered about you yet. As we chat, I'll pick up your preferences automatically."
                } else {
                    let memLines = memories.map { "• \($0.content)" }.joined(separator: "\n")
                    responseText = "Here's what I remember about you:\n\n\(memLines)"
                }
                withAnimation {
                    appendMessage(ChatMessage(isUser: false, content: .text(responseText)))
                }
            } else if message == "SYSTEM_FORGET_ALL" {
                appState?.memoryService.clearAll()
                withAnimation {
                    appendMessage(ChatMessage(isUser: false, content: .text("Done — I've cleared all my memories about you.")))
                }
            } else {
                withAnimation {
                    appendMessage(ChatMessage(isUser: false, content: .text(message)))
                }
            }
            
        case .planDay:
            appState?.planService.replanRemainingDay(for: .now)
            appState?.streakService.recordPlanCreated()
            withAnimation {
                appendMessage(ChatMessage(isUser: false, content: .text("I've planned your day. You can view the timeline in the Plan tab.")))
            }
            
        case .proposePlan(let blocks):
            appState?.planService.applyProposedPlan(blocks)
            appState?.streakService.recordPlanCreated()
            withAnimation {
                appendMessage(ChatMessage(isUser: false, content: .planProposal(blocks: blocks)))
            }
            
        case .modifyPlan(let actions):
            appState?.planService.applyModifications(actions)
            withAnimation {
                appendMessage(ChatMessage(isUser: false, content: .planModification(actions: actions)))
            }
            
        case .remember(let fact):
            appState?.memoryService.addMemory(content: fact)
            withAnimation {
                appendMessage(ChatMessage(isUser: false, content: .memorySaved(fact: fact)))
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
                appendMessage(ChatMessage(isUser: false, content: .actionResult(title: title, duration: duration, deadline: deadline)))
            }
            
        case .startFocus(let taskTitleFragment):
            let pending = appState?.taskService.pendingTasks() ?? []
            if let match = pending.first(where: { $0.title.lowercased().contains(taskTitleFragment.lowercased()) }) {
                appState?.startFocus(for: match)
            } else {
                withAnimation {
                    appendMessage(ChatMessage(isUser: false, content: .text("I couldn't find a task matching '\(taskTitleFragment)'.")))
                }
            }
            
        case .getRecommendations:
            withAnimation {
                appendMessage(ChatMessage(isUser: false, content: .text("Check your Home screen for my latest recommendation.")))
            }
            appState?.selectedTab = .home
            
        case .askQuestion(let prompt, let options, let expectedField):
            withAnimation {
                appendMessage(ChatMessage(isUser: false, content: .question(prompt: prompt, options: options, expectedField: expectedField)))
            }
        }
    }
}

