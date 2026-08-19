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
- **Option Scrollers**: Instead of typing out answers, use the horizontally scrolling option capsules (e.g., `Today`, `Tomorrow`) to instantly advance the conversation.
- **Persistent AI History**: All your conversations are saved securely on-device using SwiftData. Access your past chats via the History menu, complete with auto-generated session titles.
- **Floating Composer**: A native floating composer that stays out of the way while you type.

### 🧠 Persistent AI Memory & Pattern Recognition
The assistant remembers your preferences (e.g. "I prefer to study in the evenings"). A background pattern recognition engine passively learns your habits over time — if you regularly complete a task at the same hour, it becomes a memory automatically. You have complete control over your data — view, edit, or delete any learned memory at any time via Settings.

### 🧭 Conversational Onboarding
On first launch, the assistant learns about you through a short, natural conversation — your name, preferred energy period, and focus duration. No forms, no setup screens.

### 🎯 Focus Mode
Start a task and enter a dedicated, calm focus environment. A contained circular progress ring tracks elapsed time. The background breathes gently while you work. You can leave at any time with the visible `< Back` button.

## 📱 Screenshots & Visuals
*(Screenshots coming soon)*

## 🛠 Tech Stack
- **Platform**: iOS 17+
- **Language**: Swift 6 (strict concurrency)
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData
- **Intelligence**: LM Studio / OpenAI APIs & Local Natural Language Parsing

## 🚀 Getting Started
1. Open `What Now?.xcodeproj` in Xcode.
2. Select an iOS Simulator (e.g., iPhone 17 Pro).
3. Build and Run (`Cmd + R`).
4. (Optional) Configure an AI Provider in Settings → Intelligence to use advanced conversational AI.

## 🔄 Recent Changes

### Interaction & Polish pass
- Added a centralized `HapticManager` with a consistent haptic vocabulary across the app (start, complete, navigate)
- Task "Start" plays a medium impact haptic; "Complete" plays a success notification
- Focus view features a subtle radial ambient glow that breathes while a session is active
- `< Back` button pinned to top-left of Focus, always reachable
- Fixed a visual bug where the progress ring animation escaped its circular bounds — the ring is now correctly constrained and concentric

### Microcopy
- Replaced robotic system strings with human language throughout ("Added.", "You're all caught up.", "Let's do it.")
- AI action confirmations are now concise and conversational

### AI & Offline intelligence
- Expanded offline intent engine to natively handle: complete, delete, postpone, and plan commands without requiring any external AI
- Offline clarification options now render as native SwiftUI pill buttons, not generic list items
- Default option in offline flows is visually highlighted to reduce friction

### Personal Intelligence + Memory Engine
- Conversational onboarding on first launch (name, energy, focus duration)
- `PatternRecognitionService` runs in the background, analysing completed tasks to generate habit memories automatically
- Memories are injected into the LLM system prompt context for personalised planning

### Swift 6 concurrency
- Resolved all concurrency isolation diagnostics (no `@preconcurrency` suppression)
- All SwiftData access correctly isolated to `@MainActor`

---

## 🙏 Contributors

| Name | Role |
|---|---|
| Shlok Phadtare | Creator, product design, iOS development |
| Google Gemini (Antigravity) | AI pair programmer — architecture, intelligence layer, interaction design |
| OpenAI ChatGPT | AI pair programmer — early product specification and UI direction |

---

*Built with care to keep you focused on what matters most.*
