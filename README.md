# What Now?

**What Now?** is an intelligent personal day-management and decision assistant for iOS.

Its core question: **"What should I do right now?"**

Unlike a standard to-do list, What Now? understands your schedule, available time, priorities, deadlines, and context. It intelligently recommends the best next move, helps you plan a realistic timeline, and adapts to changes as your day unfolds.

## ✨ Features

### 🏡 Contextual Home Screen
An adaptive dashboard that answers "What should I do next?". It takes into account your active focus sessions, upcoming deadlines, and current energy levels, presenting a single, clear next step with a quick "Start" action.

### 📅 Intelligent Daily Planner
Automatically generate a realistic daily timeline from your pending tasks and recurring routines. 
- **Smart Replanning**: Tap "Replan" if you get off track. The app reschedules future tasks while locking past and completed activities, ensuring your schedule adapts without deleting your history.
- **Interactive Timeline**: Swipe or tap timeline blocks to quickly start a focus session, mark as complete, or postpone.

### 🤖 AI Assistant & Offline Intelligence
A natural language chat assistant that understands your tasks and manages your day.
- **Three-Tier Intelligence**: The app intelligently routes your requests. It uses powerful Cloud AI (OpenAI/LM Studio) when available, and seamlessly falls back to a deterministic offline engine when you have no connection.
- **Conversational Task Creation**: Add tasks naturally (e.g., "Add Python"). The assistant will prompt you for missing details ("When?", "How long?") using a state machine.
- **Option Scrollers**: Instead of typing out answers, use the beautiful, horizontally scrolling Liquid Glass option capsules (e.g., `[Today]`, `[Tomorrow]`) to instantly advance the conversation.
- **Persistent AI History**: All your conversations are saved securely on-device using SwiftData. Access your past chats via the History menu, complete with auto-generated session titles.
- **Floating Composer**: A beautiful, native "Liquid Glass" floating composer that stays out of the way while you type.

### 🧠 Persistent AI Memory
The assistant remembers your preferences (e.g. "I prefer to study in the evenings"). You have complete control over your data—view, edit, or delete any learned memories at any time via Settings.

### 🎯 Focus Mode
Start a task and enter a dedicated focus session. The app tracks your remaining time, prevents distractions, and logs your productivity.

## 📱 Screenshots & Visuals
*(Screenshots coming soon - attach visuals of the Home Dashboard, Interactive Timeline, and Floating AI Composer here)*

## 🛠 Tech Stack
- **Platform**: iOS 26.5+ (iPhone)
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData
- **Intelligence**: LM Studio / OpenAI APIs & Local Natural Language Parsing

## 🚀 Getting Started
1. Open `What Now?.xcodeproj` in Xcode.
2. Select an iOS Simulator (e.g., iPhone 17 Pro).
3. Build and Run (`Cmd + R`).
4. (Optional) Configure an AI Provider in Settings -> Intelligence to use advanced conversational AI.

---
*Built with care to keep you focused on what matters most.*
