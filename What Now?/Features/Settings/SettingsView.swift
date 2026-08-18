//
//  SettingsView.swift
//  What Now?
//

import SwiftUI
import SwiftData

/// The Settings screen accessible from the Home toolbar.
struct SettingsView: View {
    @Environment(\.appState) private var appState

    var body: some View {
        List {
            // MARK: - Profile
            Section("Profile") {
                if let name = appState?.preferenceService.profile.name, !name.isEmpty {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(name)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Peak Energy")
                    Spacer()
                    Text(appState?.preferenceService.profile.peakEnergyTimeEnum.displayName ?? "")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Default Focus Duration")
                    Spacer()
                    Text("\(appState?.preferenceService.profile.preferredFocusMinutes ?? 25) min")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Categories
            Section("Categories") {
                NavigationLink("Manage Categories") {
                    CategorySettingsView()
                }
            }

            // MARK: - Intelligence
            Section("Intelligence") {
                NavigationLink("AI Configuration") {
                    AIConfigurationView()
                }
                NavigationLink("Memory") {
                    MemorySettingsView()
                }
            }

            // MARK: - Integrations (Phase 4)
            Section {
                Label("Calendar", systemImage: "calendar")
                    .foregroundStyle(.secondary)
                Label("Reminders", systemImage: "list.bullet")
                    .foregroundStyle(.secondary)
                Label("Notifications", systemImage: "bell")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Integrations — Coming Soon")
            }

            // MARK: - Privacy
            Section("Privacy") {
                NavigationLink("Your Data") {
                    PrivacyDataView()
                }

                HStack {
                    Label("Storage", systemImage: "internaldrive")
                    Spacer()
                    Text("On Device")
                        .font(.caption)
                        .padding(.horizontal, WNTheme.Spacing.sm)
                        .padding(.vertical, WNTheme.Spacing.xs)
                        .background(.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                }
            }

            // MARK: - About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Category Settings

struct CategorySettingsView: View {
    @Environment(\.appState) private var appState
    @State private var categories: [WNCategory] = []

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Image(systemName: category.symbolName)
                        .foregroundStyle(category.color)
                        .frame(width: 30)

                    Text(category.name)

                    Spacer()

                    if category.isDefault {
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .onAppear {
            categories = appState?.categoryService.allCategories() ?? []
        }
    }
}

// MARK: - Privacy Data View

struct PrivacyDataView: View {
    @Environment(\.appState) private var appState
    @State private var showResetConfirmation = false

    var body: some View {
        List {
            Section {
                Label("All your data is stored locally on this device.", systemImage: "lock.shield")
                Label("AI processing uses on-device models.", systemImage: "brain")
                Label("No data is sent to external servers.", systemImage: "wifi.slash")
            } header: {
                Text("How Your Data Is Handled")
            }

            Section {
                Button("Reset Personalization", role: .destructive) {
                    showResetConfirmation = true
                }
            } footer: {
                Text("This resets your preferences to defaults. Tasks and history are not affected.")
            }
        }
        .navigationTitle("Your Data")
        .confirmationDialog("Reset Personalization?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                appState?.preferenceService.resetPersonalization()
            }
        } message: {
            Text("This will reset all preferences to their defaults.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

// MARK: - AI Configuration View

struct AIConfigurationView: View {
    @Environment(\.appState) private var appState
    
    @State private var provider: AIProviderType = .openAI
    
    // LM Studio
    @State private var lmStudioUrl: String = ""
    @State private var lmStudioModel: String = ""
    @State private var availableModels: [String] = []
    @State private var isLoadingModels: Bool = false
    
    // API Keys
    @State private var openAIKey: String = ""
    @State private var lmStudioKey: String = ""
    
    // Connection Status
    @State private var isCheckingConnection: Bool = false
    
    var providerStatus: ProviderConnectionStatus {
        appState?.intelligenceRouter.providerStatus ?? .unknown
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: $provider) {
                    ForEach(AIProviderType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical, WNTheme.Spacing.sm)
            }
            
            // Connection Status Row
            Section {
                HStack {
                    Label("Status", systemImage: statusIcon)
                        .foregroundStyle(statusColor)
                    Spacer()
                    if isCheckingConnection {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(providerStatus.displayName)
                            .foregroundStyle(statusColor)
                            .font(.subheadline)
                    }
                }
                
                Button("Test Connection") {
                    checkConnection()
                }
                .disabled(isCheckingConnection)
            }
            
            if provider == .openAI {
                openAISection
            } else {
                lmStudioSection
            }
        }
        .navigationTitle("AI Configuration")
        .onAppear {
            loadSettings()
        }
        .onChange(of: provider) { _, newValue in
            appState?.preferenceService.aiProvider = newValue
            // Check connection when provider changes
            checkConnection()
        }
    }
    
    private var statusIcon: String {
        switch providerStatus {
        case .unknown: return "circle.dotted"
        case .connected: return "checkmark.circle.fill"
        case .unavailable: return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch providerStatus {
        case .unknown: return .secondary
        case .connected: return .green
        case .unavailable: return .red
        }
    }
    
    private var openAISection: some View {
        Section("OpenAI Configuration") {
            SecureField("API Key (sk-...)", text: $openAIKey)
                .onChange(of: openAIKey) { _, newValue in
                    appState?.preferenceService.saveAPIKey(for: .openAI, key: newValue)
                }
            
            Text("Your API key is securely stored in the on-device Keychain.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var lmStudioSection: some View {
        Section(content: {
            TextField("Server URL", text: $lmStudioUrl)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .onChange(of: lmStudioUrl) { _, newValue in
                    appState?.preferenceService.lmStudioUrl = newValue
                }
            
            if isLoadingModels {
                HStack {
                    Text("Fetching models...")
                        .foregroundStyle(.secondary)
                    Spacer()
                    ProgressView()
                }
            } else if !availableModels.isEmpty {
                Picker("Model", selection: $lmStudioModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: lmStudioModel) { _, newValue in
                    appState?.preferenceService.lmStudioModel = newValue
                }
            } else {
                TextField("Model ID", text: $lmStudioModel)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: lmStudioModel) { _, newValue in
                        appState?.preferenceService.lmStudioModel = newValue
                    }
            }
            
            Button("Refresh Models") {
                fetchModels()
            }
            
            SecureField("Optional API Key", text: $lmStudioKey)
                .onChange(of: lmStudioKey) { _, newValue in
                    appState?.preferenceService.saveAPIKey(for: .lmStudio, key: newValue)
                }
        }, header: {
            Text("LM Studio (Local)")
        }, footer: {
            Text("Run LM Studio locally and start the local server. Ensure the URL matches your server settings (e.g., http://127.0.0.1:1234/v1).")
        })
    }
    
    private func loadSettings() {
        guard let prefService = appState?.preferenceService else { return }
        provider = prefService.aiProvider
        lmStudioUrl = prefService.lmStudioUrl
        lmStudioModel = prefService.lmStudioModel
        openAIKey = prefService.getAPIKey(for: .openAI) ?? ""
        lmStudioKey = prefService.getAPIKey(for: .lmStudio) ?? ""
        
        if provider == .lmStudio {
            fetchModels()
        }
        
        checkConnection()
    }
    
    private func checkConnection() {
        guard let router = appState?.intelligenceRouter else { return }
        isCheckingConnection = true
        Task {
            await router.checkProviderReachability()
            await MainActor.run {
                self.isCheckingConnection = false
            }
        }
    }
    
    private func fetchModels() {
        // Always use intelligenceRouter.lmStudioService directly — no unsafe casting needed
        guard let service = appState?.intelligenceRouter.lmStudioService else { return }
        
        isLoadingModels = true
        Task {
            do {
                let models = try await service.fetchAvailableModels()
                await MainActor.run {
                    self.availableModels = models
                    if self.lmStudioModel.isEmpty, let first = models.first {
                        self.lmStudioModel = first
                        appState?.preferenceService.lmStudioModel = first
                    }
                    self.isLoadingModels = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingModels = false
                }
            }
        }
    }
}

// MARK: - Memory Settings

struct MemorySettingsView: View {
    @Environment(\.appState) private var appState
    
    @State private var editingMemory: WNMemory?
    @State private var editedContent: String = ""
    
    var body: some View {
        List {
            if let appState = appState {
                let groupedMemories = appState.memoryService.memoriesByCategory()
                
                if groupedMemories.isEmpty {
                    ContentUnavailableView("No Memories", systemImage: "brain", description: Text("What Now? will remember your preferences as you chat with the Assistant."))
                } else {
                    ForEach(WNMemoryCategory.allCases, id: \.self) { category in
                        if let memories = groupedMemories[category], !memories.isEmpty {
                            Section(category.rawValue) {
                                ForEach(memories) { memory in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(memory.content)
                                                .font(.body)
                                            Text(memory.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        
                                        Toggle("", isOn: Binding(
                                            get: { memory.isEnabled },
                                            set: { _ in appState.memoryService.toggleMemory(memory) }
                                        ))
                                        .labelsHidden()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editedContent = memory.content
                                        editingMemory = memory
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        appState.memoryService.deleteMemory(memories[index])
                                    }
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button("Clear All Memories", role: .destructive) {
                            appState.memoryService.clearAll()
                        }
                    }
                }
            }
        }
        .navigationTitle("Memory")
        .sheet(item: $editingMemory) { memory in
            NavigationStack {
                Form {
                    Section("Memory Content") {
                        TextEditor(text: $editedContent)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("Edit Memory")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingMemory = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            memory.content = editedContent
                            try? appState?.modelContext.save()
                            editingMemory = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
