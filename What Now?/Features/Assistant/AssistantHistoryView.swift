//
//  AssistantHistoryView.swift
//  What Now?
//

import SwiftUI
import SwiftData

struct AssistantHistoryView: View {
    @Environment(\.appState) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \WNChatSession.updatedAt, order: .reverse) private var sessions: [WNChatSession]
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    createNewChat()
                } label: {
                    Label("New Chat", systemImage: "plus.message.fill")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
                
                if !sessions.isEmpty {
                    Section {
                        ForEach(sessions) { session in
                            Button {
                                appState?.activeChatSession = session
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    } header: {
                        Text("Recent Conversations")
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createNewChat() {
        let newSession = WNChatSession(title: "New Chat")
        modelContext.insert(newSession)
        try? modelContext.save()
        appState?.activeChatSession = newSession
        dismiss()
    }
    
    private func deleteSessions(offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            if appState?.activeChatSession?.id == session.id {
                appState?.activeChatSession = nil
            }
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}
