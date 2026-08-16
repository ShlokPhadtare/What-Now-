# What Now? — Technical Architecture

> **Version**: 1.0  
> **Target**: iOS 26.5+ · iPhone  
> **Xcode**: 26.6  
> **Swift**: 6 (strict concurrency, MainActor default isolation)

---

## Table of Contents

1. [Overall Architecture](#1-overall-architecture)
2. [Project Structure](#2-project-structure)
3. [SwiftUI Architecture](#3-swiftui-architecture)
4. [SwiftData Models](#4-swiftdata-models)
5. [Navigation Architecture](#5-navigation-architecture)
6. [Home Screen Architecture](#6-home-screen-architecture)
7. [Timeline / Day-Planning Architecture](#7-timeline--day-planning-architecture)
8. [Recommendation Engine](#8-recommendation-engine)
9. [Scheduling Engine](#9-scheduling-engine)
10. [Task System](#10-task-system)
11. [Focus System](#11-focus-system)
12. [Focus Protection Architecture](#12-focus-protection-architecture)
13. [AI Assistant Architecture](#13-ai-assistant-architecture)
14. [AI Tool / Action Architecture](#14-ai-tool--action-architecture)
15. [Calendar Integration](#15-calendar-integration)
16. [Reminders Integration](#16-reminders-integration)
17. [Notifications](#17-notifications)
18. [Widgets](#18-widgets)
19. [Live Activities](#19-live-activities)
20. [App Intents / Siri](#20-app-intents--siri)
21. [Privacy Architecture](#21-privacy-architecture)
22. [Offline-First Architecture](#22-offline-first-architecture)
23. [Required Apple Capabilities & Entitlements](#23-required-apple-capabilities--entitlements)
24. [Testing Strategy](#24-testing-strategy)
25. [Feature Dependencies](#25-feature-dependencies)
26. [Phased Implementation Roadmap](#26-phased-implementation-roadmap)

---

## 1. Overall Architecture

### Pattern: Feature-Based Modular Architecture with Service Layer

```
┌─────────────────────────────────────────────────────────┐
│                     SwiftUI Views                       │
│         (Home, Plan, Tasks, Focus, Insights, AI)        │
├─────────────────────────────────────────────────────────┤
│                    ViewModels (@Observable)              │
│           (HomeVM, PlanVM, TasksVM, FocusVM, ...)       │
├─────────────────────────────────────────────────────────┤
│                    Service Layer                        │
│    (TaskService, FocusService, HistoryService, ...)     │
├──────────────────────┬──────────────────────────────────┤
│    Engine Layer      │       Integration Layer          │
│  (Recommendation,   │  (Calendar, Reminders,           │
│   Scheduling,       │   Notifications,                 │
│   Insight)          │   FocusProtection)               │
├──────────────────────┼──────────────────────────────────┤
│                    AI Layer                              │
│  (Foundation Models, Tool Router, Structured Tools)     │
├─────────────────────────────────────────────────────────┤
│                  Persistence Layer                       │
│             (SwiftData ModelContainer)                   │
└─────────────────────────────────────────────────────────┘
```

### Key Principles

- **No external dependencies.** Pure Apple stack.
- **Offline-first.** SwiftData is local. Foundation Models is on-device.
- **AI is an enhancement, not the backbone.** The deterministic engine is the source of truth.
- **Feature isolation.** Each screen is a self-contained module with its own View + ViewModel.
- **Dependency injection.** Services injected via Environment, testable with mock/in-memory stores.
- **Single ModelContainer** shared via `.modelContainer()` at the App level.

---

## 2. Project Structure

```
What Now?/
├── What Now?/                          # Main app target
│   ├── App/
│   │   ├── What_Now_App.swift          # @main, ModelContainer setup, root view
│   │   └── AppState.swift             # App-level observable state & service container
│   │
│   ├── Core/
│   │   ├── Models/                    # SwiftData @Model classes
│   │   │   ├── WNTask.swift
│   │   │   ├── WNSubtask.swift
│   │   │   ├── WNCategory.swift
│   │   │   ├── WNRoutine.swift
│   │   │   ├── WNScheduleBlock.swift
│   │   │   ├── WNDailyPlan.swift
│   │   │   ├── WNFocusSession.swift
│   │   │   ├── WNHistoryEntry.swift
│   │   │   ├── WNUserProfile.swift
│   │   │   ├── WNAIConversation.swift
│   │   │   └── WNAIMessage.swift
│   │   │
│   │   ├── Enums/                     # Shared enumerations
│   │   │   ├── TaskPriority.swift
│   │   │   ├── TaskStatus.swift
│   │   │   ├── TimeOfDay.swift
│   │   │   ├── ScheduleBlockType.swift
│   │   │   ├── RepeatSchedule.swift
│   │   │   ├── EnergyLevel.swift
│   │   │   └── InsightType.swift
│   │   │
│   │   ├── Services/                  # Business logic layer
│   │   │   ├── TaskService.swift
│   │   │   ├── ScheduleService.swift
│   │   │   ├── FocusService.swift
│   │   │   ├── HistoryService.swift
│   │   │   ├── RoutineService.swift
│   │   │   ├── PreferenceService.swift
│   │   │   └── CategoryService.swift
│   │   │
│   │   ├── Engines/                   # Pure logic, no framework deps
│   │   │   ├── RecommendationEngine.swift
│   │   │   ├── SchedulingEngine.swift
│   │   │   ├── AvailableTimeCalculator.swift
│   │   │   └── InsightEngine.swift
│   │   │
│   │   └── Extensions/
│   │       ├── Date+WN.swift
│   │       ├── TimeInterval+WN.swift
│   │       └── Collection+WN.swift
│   │
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   ├── HomeViewModel.swift
│   │   │   ├── RecommendationCardView.swift
│   │   │   ├── GreetingView.swift
│   │   │   └── QuickActionsView.swift
│   │   │
│   │   ├── Plan/
│   │   │   ├── PlanView.swift
│   │   │   ├── PlanViewModel.swift
│   │   │   ├── TimelineView.swift
│   │   │   ├── TimelineBlockView.swift
│   │   │   └── DayPlannerView.swift
│   │   │
│   │   ├── Tasks/
│   │   │   ├── TaskListView.swift
│   │   │   ├── TasksViewModel.swift
│   │   │   ├── TaskDetailView.swift
│   │   │   ├── TaskEditorView.swift
│   │   │   ├── TaskRowView.swift
│   │   │   └── SubtaskListView.swift
│   │   │
│   │   ├── Focus/
│   │   │   ├── FocusView.swift
│   │   │   ├── FocusViewModel.swift
│   │   │   ├── FocusTimerView.swift
│   │   │   ├── FocusSetupView.swift
│   │   │   └── FocusHistoryView.swift
│   │   │
│   │   ├── Insights/
│   │   │   ├── InsightsView.swift
│   │   │   ├── InsightsViewModel.swift
│   │   │   ├── DayReviewView.swift
│   │   │   ├── WeekReviewView.swift
│   │   │   └── InsightCardView.swift
│   │   │
│   │   ├── Assistant/
│   │   │   ├── AssistantView.swift
│   │   │   ├── AssistantViewModel.swift
│   │   │   ├── MessageBubbleView.swift
│   │   │   └── ToolResultView.swift
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── PrivacySettingsView.swift
│   │   │   ├── NotificationSettingsView.swift
│   │   │   ├── CategorySettingsView.swift
│   │   │   └── PersonalizationView.swift
│   │   │
│   │   └── Onboarding/
│   │       ├── OnboardingView.swift
│   │       ├── OnboardingViewModel.swift
│   │       └── OnboardingStepView.swift
│   │
│   ├── Design/
│   │   ├── Theme.swift                # Colors, spacing, typography tokens
│   │   ├── Components/
│   │   │   ├── WNCard.swift
│   │   │   ├── WNButton.swift
│   │   │   ├── WNProgressRing.swift
│   │   │   ├── WNTimeDisplay.swift
│   │   │   └── WNEmptyState.swift
│   │   └── Modifiers/
│   │       ├── CardStyle.swift
│   │       └── ShimmerModifier.swift
│   │
│   ├── Integrations/
│   │   ├── CalendarService.swift      # EventKit wrapper
│   │   ├── RemindersService.swift     # EventKit/Reminders wrapper
│   │   ├── NotificationService.swift  # UNUserNotificationCenter wrapper
│   │   └── FocusProtection/
│   │       ├── FocusProtectionService.swift
│   │       └── FocusProtectionModels.swift
│   │
│   ├── AI/
│   │   ├── AIServiceProtocol.swift    # Protocol abstraction
│   │   ├── FoundationModelService.swift # On-device implementation
│   │   ├── AIToolRouter.swift         # Routes tool calls to services
│   │   ├── AIPrompts.swift            # System prompts and context builders
│   │   └── Tools/
│   │       ├── TaskTools.swift        # createTask, updateTask, etc.
│   │       ├── PlanTools.swift        # generateDailyPlan, scheduleActivity, etc.
│   │       ├── FocusTools.swift       # createFocusSession, startFocus, etc.
│   │       └── QueryTools.swift       # getHistory, getAnalytics, etc.
│   │
│   └── Resources/
│       └── Assets.xcassets
│
├── WhatNowWidget/                     # Widget extension target (Phase 4)
│   ├── WhatNowWidget.swift
│   ├── WhatNowWidgetBundle.swift
│   └── Providers/
│       ├── RecommendationProvider.swift
│       └── PlanProvider.swift
│
├── WhatNowLiveActivity/               # Can be part of widget bundle
│   └── FocusLiveActivity.swift
│
├── ShieldConfigurationExtension/      # Shield UI extension (Phase 5)
│   └── ShieldConfigurationExtension.swift
│
├── DeviceActivityMonitorExtension/    # Device activity extension (Phase 5)
│   └── DeviceActivityMonitorExtension.swift
│
├── WhatNowTests/                      # Unit test target
│   ├── Engines/
│   │   ├── RecommendationEngineTests.swift
│   │   ├── SchedulingEngineTests.swift
│   │   └── AvailableTimeCalculatorTests.swift
│   ├── Services/
│   │   ├── TaskServiceTests.swift
│   │   ├── FocusServiceTests.swift
│   │   └── HistoryServiceTests.swift
│   └── AI/
│       └── AIToolValidationTests.swift
│
├── PRODUCT_SPEC.md
├── WHAT_NOW_ARCHITECTURE.md
└── DEVELOPMENT_RULES.md
```

### Targets Summary

| Target | Type | Purpose |
|--------|------|---------|
| `What Now?` | App | Main application |
| `WhatNowWidget` | Widget Extension | Home screen widgets |
| `ShieldConfigurationExtension` | Extension | Custom shield UI (Phase 5) |
| `DeviceActivityMonitorExtension` | Extension | Usage monitoring (Phase 5) |
| `WhatNowTests` | Unit Test Bundle | All unit tests |

### App Group

All targets that share data must belong to the same App Group:
`group.shlokphadtare.whatnow`

This enables the widget and extensions to access the shared SwiftData store.

---

## 3. SwiftUI Architecture

### Pattern: @Observable ViewModels + Environment DI

```swift
// ViewModel pattern
@Observable
@MainActor
final class HomeViewModel {
    private let taskService: TaskService
    private let recommendationEngine: RecommendationEngine
    private let scheduleService: ScheduleService

    var greeting: String = ""
    var recommendation: Recommendation?
    var availableTime: TimeInterval = 0
    var quickActions: [WNCategory] = []

    init(taskService: TaskService,
         recommendationEngine: RecommendationEngine,
         scheduleService: ScheduleService) {
        self.taskService = taskService
        self.recommendationEngine = recommendationEngine
        self.scheduleService = scheduleService
    }

    func onAppear() async { ... }
}
```

```swift
// View pattern
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(taskService: TaskService, ...) {
        _viewModel = State(initialValue: HomeViewModel(taskService: taskService, ...))
    }

    var body: some View { ... }
}
```

### Service Container

```swift
@Observable
@MainActor
final class AppState {
    let modelContext: ModelContext
    let taskService: TaskService
    let scheduleService: ScheduleService
    let focusService: FocusService
    let historyService: HistoryService
    let recommendationEngine: RecommendationEngine
    let schedulingEngine: SchedulingEngine
    let calendarService: CalendarService
    let notificationService: NotificationService
    // ... additional services

    var isOnboardingComplete: Bool
    var activeFocusSession: WNFocusSession?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.taskService = TaskService(context: modelContext)
        // ... initialize all services
    }
}
```

Injected into the environment at the App level:

```swift
@main
struct What_Now_App: App {
    let container: ModelContainer

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
```

### Key SwiftUI Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | `@Observable` | Modern, no Combine boilerplate |
| Navigation | `NavigationStack` per tab | Type-safe, programmatic |
| Data queries | `FetchDescriptor` in VMs | More control than `@Query` |
| Modals | `.sheet()` / `.fullScreenCover()` | Native patterns |
| Lists | `List` with `ForEach` | Native swipe actions, performance |
| Animations | `withAnimation` + `.animation()` | Declarative, respects reduce-motion |
| Haptics | `.sensoryFeedback()` | Modern SwiftUI modifier |

---

## 4. SwiftData Models

### Complete Model Diagram

```
WNUserProfile (1)
    │
    ├── has many → WNPreference
    │
WNCategory (many)
    │
    ├── has many → WNTask
    ├── has many → WNRoutine
    ├── has many → WNFocusSession
    │
WNTask (many)
    │
    ├── has many → WNSubtask
    ├── has many → WNFocusSession
    ├── has many → WNHistoryEntry
    ├── has many → WNScheduleBlock
    │
WNDailyPlan (many)
    │
    ├── has many → WNScheduleBlock
    │
WNAIConversation (many)
    │
    ├── has many → WNAIMessage
```

### Model Definitions

#### WNTask

```swift
@Model
final class WNTask {
    var id: UUID = UUID()
    var title: String = ""
    var taskDescription: String = ""
    var priority: String = TaskPriority.medium.rawValue   // stored as String
    var deadline: Date?
    var estimatedMinutes: Int?
    var preferredTimeOfDay: String?                        // TimeOfDay raw value
    var repeatScheduleRaw: Data?                           // Codable RepeatSchedule
    var status: String = TaskStatus.pending.rawValue
    var notes: String?
    var createdAt: Date = Date()
    var completedAt: Date?
    var postponementCount: Int = 0
    var sortOrder: Int = 0

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WNSubtask.parentTask)
    var subtasks: [WNSubtask] = []

    @Relationship(deleteRule: .nullify, inverse: \WNFocusSession.task)
    var focusSessions: [WNFocusSession] = []

    @Relationship(deleteRule: .nullify, inverse: \WNHistoryEntry.task)
    var historyEntries: [WNHistoryEntry] = []

    @Relationship(deleteRule: .nullify, inverse: \WNScheduleBlock.linkedTask)
    var scheduleBlocks: [WNScheduleBlock] = []

    var category: WNCategory?

    // Computed helpers (transient)
    var priorityEnum: TaskPriority {
        get { TaskPriority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }
    var statusEnum: TaskStatus {
        get { TaskStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < Date() && statusEnum != .completed
    }
}
```

#### WNSubtask

```swift
@Model
final class WNSubtask {
    var id: UUID = UUID()
    var title: String = ""
    var estimatedMinutes: Int?
    var isCompleted: Bool = false
    var completedAt: Date?
    var sortOrder: Int = 0
    var parentTask: WNTask?
}
```

#### WNCategory

```swift
@Model
final class WNCategory {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "folder"          // SF Symbol name
    var colorHex: String = "#007AFF"
    var isDefault: Bool = false
    var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \WNTask.category)
    var tasks: [WNTask] = []

    @Relationship(deleteRule: .nullify, inverse: \WNRoutine.category)
    var routines: [WNRoutine] = []
}
```

#### WNRoutine

```swift
@Model
final class WNRoutine {
    var id: UUID = UUID()
    var name: String = ""
    var estimatedMinutes: Int = 30
    var preferredHour: Int = 8                 // 0-23
    var preferredMinute: Int = 0               // 0-59
    var activeDaysRaw: String = "1,2,3,4,5"   // comma-separated day numbers (1=Sun..7=Sat)
    var isActive: Bool = true
    var category: WNCategory?

    var activeDays: Set<Int> {
        get { Set(activeDaysRaw.split(separator: ",").compactMap { Int($0) }) }
        set { activeDaysRaw = newValue.sorted().map(String.init).joined(separator: ",") }
    }
}
```

#### WNScheduleBlock

```swift
@Model
final class WNScheduleBlock {
    var id: UUID = UUID()
    var date: Date = Date()                    // calendar day (midnight-normalized)
    var startTime: Date = Date()
    var endTime: Date = Date()
    var title: String = ""
    var blockType: String = ScheduleBlockType.freeTime.rawValue
    var isCompleted: Bool = false
    var calendarEventIdentifier: String?       // EKEvent.eventIdentifier

    var linkedTask: WNTask?
    var linkedRoutine: WNRoutine?

    @Relationship(deleteRule: .nullify, inverse: \WNDailyPlan.blocks)
    var dailyPlan: WNDailyPlan?
}
```

#### WNDailyPlan

```swift
@Model
final class WNDailyPlan {
    var id: UUID = UUID()
    var date: Date = Date()                    // calendar day
    var createdAt: Date = Date()
    var isAutoGenerated: Bool = false
    var reflectionNote: String?                // end-of-day reflection

    @Relationship(deleteRule: .cascade, inverse: \WNScheduleBlock.dailyPlan)
    var blocks: [WNScheduleBlock] = []
}
```

#### WNFocusSession

```swift
@Model
final class WNFocusSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var plannedMinutes: Int = 25
    var actualMinutes: Int?
    var endedAt: Date?
    var wasCompleted: Bool = false
    var wasAbandoned: Bool = false
    var categoryName: String?                  // denormalized for fast queries

    var task: WNTask?
}
```

#### WNHistoryEntry

```swift
@Model
final class WNHistoryEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var entryType: String = ""                 // HistoryEntryType raw value
    var durationMinutes: Int?
    var categoryName: String?                  // denormalized
    var notes: String?

    var task: WNTask?
}
```

#### WNUserProfile

```swift
@Model
final class WNUserProfile {
    var id: UUID = UUID()
    var name: String?
    var peakEnergyTime: String = TimeOfDay.morning.rawValue
    var preferredFocusMinutes: Int = 25
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()

    // Onboarding selections (stored as comma-separated strings)
    var helpCategoriesRaw: String = ""         // "study,work,fitness"
    var obstaclesRaw: String = ""              // "procrastination,distractions"
}
```

#### WNAIConversation & WNAIMessage

```swift
@Model
final class WNAIConversation {
    var id: UUID = UUID()
    var title: String?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \WNAIMessage.conversation)
    var messages: [WNAIMessage] = []
}

@Model
final class WNAIMessage {
    var id: UUID = UUID()
    var role: String = "user"                  // "user", "assistant", "system"
    var content: String = ""
    var toolCallsRaw: Data?                    // JSON-encoded tool calls/results
    var createdAt: Date = Date()
    var conversation: WNAIConversation?
}
```

### Enumerations

```swift
enum TaskPriority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending, inProgress, completed, abandoned
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning, afternoon, evening, anytime
}

enum ScheduleBlockType: String, Codable, CaseIterable {
    case task, routine, calendarEvent, breakTime, freeTime
}

enum EnergyLevel: String, Codable, CaseIterable {
    case low, normal, high
}

enum RepeatFrequency: String, Codable {
    case daily, weekdays, weekends, weekly, custom
}
```

### Default Categories (seeded on first launch)

| Name | SF Symbol | Color |
|------|-----------|-------|
| Study | `book.fill` | `#5856D6` |
| Work | `briefcase.fill` | `#007AFF` |
| Coding | `chevron.left.forwardslash.chevron.right` | `#34C759` |
| Fitness | `figure.run` | `#FF9500` |
| Personal | `person.fill` | `#AF52DE` |
| Gaming | `gamecontroller.fill` | `#FF2D55` |
| Relaxation | `cup.and.saucer.fill` | `#5AC8FA` |

---

## 5. Navigation Architecture

### Root: TabView with 5 Tabs

```swift
TabView(selection: $selectedTab) {
    Tab("Home", systemImage: "house", value: .home) {
        NavigationStack(path: $homePath) {
            HomeView(...)
        }
    }
    Tab("Plan", systemImage: "calendar", value: .plan) {
        NavigationStack(path: $planPath) {
            PlanView(...)
        }
    }
    Tab("Tasks", systemImage: "checklist", value: .tasks) {
        NavigationStack(path: $tasksPath) {
            TaskListView(...)
        }
    }
    Tab("Focus", systemImage: "target", value: .focus) {
        NavigationStack(path: $focusPath) {
            FocusView(...)
        }
    }
    Tab("Insights", systemImage: "chart.bar", value: .insights) {
        NavigationStack(path: $insightsPath) {
            InsightsView(...)
        }
    }
}
```

### Why 5 tabs (not 6):

The AI Assistant is accessed via a floating button or a modal sheet from any screen,
rather than its own tab. This is because:
1. The assistant is a cross-cutting tool, not a destination
2. Users may want to invoke it from any context (Home, Plan, Tasks, etc.)
3. 5 tabs is the Apple-recommended maximum
4. Settings is accessed via a gear icon on the Home or Insights screen

### Navigation Destinations (per tab)

| Tab | Push destinations |
|-----|------------------|
| Home | TaskDetail, FocusSetup, DayReview |
| Plan | TimelineDetail, TaskEditor, BlockDetail |
| Tasks | TaskDetail, TaskEditor, SubtaskList |
| Focus | FocusTimer (full screen), FocusHistory |
| Insights | WeekReview, CategoryDetail, PersonalizationData |

### Sheet Presentations

| Sheet | Presented from |
|-------|---------------|
| TaskEditor (new) | Tasks tab, Home, Plan, Assistant |
| AssistantView | Floating button (any tab) |
| SettingsView | Home/Insights gear icon |
| OnboardingView | App launch (if not completed) |
| FocusSetup | Focus tab, Home "Start" button |
| WhyThisView | Home recommendation card |

---

## 6. Home Screen Architecture

### State Machine

```
┌─────────────┐
│   Loading   │ → Fetch tasks, calendar, compute recommendation
└──────┬──────┘
       ▼
┌─────────────────────────────────────────┐
│  Contextual State (one of):             │
│                                         │
│  1. HAS_RECOMMENDATION                 │
│     → Show greeting + recommendation    │
│     → "Why this?" expandable            │
│     → Quick action alternatives         │
│     → Start button                      │
│                                         │
│  2. ALL_DONE                            │
│     → "Everything important is done."   │
│     → Suggest entertainment/rest        │
│     → Show remaining optional tasks     │
│                                         │
│  3. IN_FOCUS                            │
│     → Show active focus session card    │
│     → Timer + task name                 │
│     → Quick actions: Pause, End         │
│                                         │
│  4. NO_TASKS                            │
│     → "Nothing planned."               │
│     → Suggest creating tasks            │
│     → Quick add button                  │
│                                         │
│  5. OVERWHELMED                         │
│     → "Let's simplify."                │
│     → Top 3 priorities only             │
│     → Guided questions                  │
└─────────────────────────────────────────┘
```

### HomeViewModel Responsibilities

1. **Compute greeting** based on time of day
2. **Calculate available time** until next commitment (calendar event or scheduled block)
3. **Get top recommendation** from RecommendationEngine
4. **Prepare quick actions** (top categories with pending tasks)
5. **Check active focus session** from FocusService
6. **Determine contextual state** from above inputs

### Data Flow

```
HomeView.onAppear
    → HomeViewModel.refresh()
        → CalendarService.todayEvents()       // external calendar
        → TaskService.pendingTasks()          // from SwiftData
        → ScheduleService.todayPlan()         // today's schedule
        → AvailableTimeCalculator.compute()   // gap until next event
        → RecommendationEngine.recommend()    // scored recommendation
    → HomeViewModel updates @Observable properties
    → SwiftUI re-renders
```

---

## 7. Timeline / Day-Planning Architecture

### Visual Timeline

The Plan tab shows a vertical timeline for the selected day (default: today).

```
┌──────────────────────────────┐
│  ◄  Today, Aug 16  ►        │  ← Day picker (swipeable)
├──────────────────────────────┤
│  8:00  ┌─────────────────┐   │
│        │ Morning Routine  │  │  ← Routine block (teal)
│  8:30  └─────────────────┘   │
│        ┌─────────────────┐   │
│  9:00  │ CS 201 Lecture   │  │  ← Calendar event (blue)
│ 10:00  └─────────────────┘   │
│        ┌ ─ ─ ─ ─ ─ ─ ─ ─┐   │
│ 10:00  │ Free — 20 min   │   │  ← Free gap (dashed)
│ 10:20  └ ─ ─ ─ ─ ─ ─ ─ ─┘   │
│        ┌─────────────────┐   │
│ 10:20  │ DSA Assignment   │  │  ← Task block (purple)
│ 11:00  │ ★ Due tomorrow  │   │
│        └─────────────────┘   │
│  ...                         │
└──────────────────────────────┘
```

### Block Interactions

| Gesture | Action |
|---------|--------|
| Tap | Open block detail / task detail |
| Swipe right | Mark complete |
| Swipe left | Postpone |
| Long press | Context menu (edit, reschedule, delete) |
| Drag | Reschedule to different time (within plan) |

### PlanViewModel Flow

```
PlanView.onAppear / day change
    → PlanViewModel.loadDay(date)
        → ScheduleService.getPlan(for: date)
            → If plan exists: load blocks
            → If no plan: offer to generate
        → CalendarService.events(for: date)
        → Merge calendar events into timeline
    → Display sorted blocks
```

### Plan Generation

The "Generate Plan" action invokes the SchedulingEngine (see §9).

---

## 8. Recommendation Engine

### Design: Deterministic, Weighted Scoring — No AI Required

```swift
struct Recommendation {
    let task: WNTask
    let score: Double              // 0.0 – 100.0
    let reasons: [RecommendationReason]
}

enum RecommendationReason: String {
    case dueToday
    case dueTomorrow
    case overdue
    case highPriority
    case alreadyStarted
    case fitsAvailableTime
    case matchesPreferredTime
    case frequentlyPostponed
    case categoryBalance
    case matchesEnergy
}
```

### Scoring Algorithm

```
FinalScore = Σ (weight_i × normalizedFactor_i)
```

| Factor | Weight | Score Range | Logic |
|--------|--------|-------------|-------|
| **Deadline urgency** | 0.30 | 0–100 | Overdue=100, today=90, tomorrow=70, this week=40, later=10, none=5 |
| **Priority** | 0.25 | 0–100 | Critical=100, high=75, medium=50, low=25 |
| **Time fit** | 0.15 | 0–100 | Task fits in available gap=100, slightly over=50, way over=0 (filtered) |
| **Postponement** | 0.10 | 0–50 | `min(postponementCount × 12.5, 50)` |
| **Already started** | 0.08 | 0 or 30 | Status == .inProgress → 30, else 0 |
| **Preferred time** | 0.05 | 0 or 25 | Current TimeOfDay matches task preference → 25 |
| **Category balance** | 0.04 | -20 to 20 | Category not worked recently → +20, over-worked → -20 |
| **Energy match** | 0.03 | 0 or 20 | High-priority task + high energy → 20 |

### Hard Filters (before scoring)

- **Exclude** completed/abandoned tasks
- **Exclude** tasks whose `estimatedMinutes` > `availableMinutes` × 1.5
  (allow some overflow — the user might continue past the gap)
- **Exclude** tasks with `preferredTimeOfDay` that strongly conflicts with current time
  (unless deadline is today/overdue)

### Special Recommendation Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Rest** | User has focused >2 hours OR all important tasks done | Recommend break/entertainment |
| **Quick wins** | Available time < 20 minutes | Only show tasks ≤ 20 min estimated |
| **Overwhelmed** | User has > 10 pending tasks due within 2 days | Show only top 3 |
| **Energy-based** | User provides energy level | Adjust priority weights |

### "Why This?" Explanation Builder

```swift
func buildExplanation(for recommendation: Recommendation) -> [String] {
    recommendation.reasons.map { reason in
        switch reason {
        case .dueToday: "It's due today"
        case .alreadyStarted: "You've already started it"
        case .fitsAvailableTime: "You have enough time to finish"
        case .matchesPreferredTime: "You usually do this type of work at this time"
        case .frequentlyPostponed: "You've postponed this \(task.postponementCount) times"
        // ...
        }
    }
}
```

---

## 9. Scheduling Engine

### Purpose

Generate a day plan by fitting tasks into available time slots around fixed commitments.

### Algorithm

```
Input:
  - targetDate: Date
  - calendarEvents: [EKEvent]           (fixed, from EventKit)
  - routines: [WNRoutine]               (semi-fixed, preferred times)
  - pendingTasks: [WNTask]              (flexible, scored by recommendation engine)
  - preferences: UserPreferences        (break frequency, max work duration, etc.)

Output:
  - WNDailyPlan with ordered [WNScheduleBlock]

Steps:

1. PLACE FIXED EVENTS
   - Convert calendar events to ScheduleBlocks (type: .calendarEvent)
   - These cannot be moved

2. PLACE ROUTINES
   - For each active routine whose activeDays includes targetDate:
     - Place at preferredHour:preferredMinute
     - If slot conflicts with calendar event, find nearest gap
     - Create ScheduleBlock (type: .routine)

3. IDENTIFY FREE GAPS
   - Scan the day (user's waking hours, default 7:00–23:00)
   - Find contiguous gaps between placed blocks
   - Each gap = { startTime, endTime, durationMinutes }

4. ASSIGN TASKS TO GAPS
   - Score all pending tasks via RecommendationEngine
   - Sort by score (descending)
   - For each task:
     a. Find the best gap:
        - Gap duration ≥ task.estimatedMinutes
        - If task has preferredTimeOfDay, prefer gaps in that window
     b. Place task in gap, create ScheduleBlock (type: .task)
     c. Add 5-minute buffer after the task
     d. Shrink the gap

5. INSERT BREAKS
   - After every 90 minutes of consecutive work, insert a 15-minute break
   - Create ScheduleBlock (type: .breakTime)

6. MARK REMAINING GAPS
   - Any unassigned gap > 15 minutes → ScheduleBlock (type: .freeTime)

7. OVERFLOW CHECK
   - If tasks remain unplaced:
     - Return them as "overflow" list
     - ViewModel displays: "Not enough time for 3 tasks. Prioritize?"
```

### Edge Cases

- **No calendar permission:** Schedule around routines only; warn user
- **No tasks:** Plan shows only routines and calendar events
- **All-day events:** Treat as fixed blocks consuming the whole day
- **Overnight tasks:** Clamp to waking hours

---

## 10. Task System

### TaskService API

```swift
@Observable @MainActor
final class TaskService {
    private let context: ModelContext

    func createTask(title: String, category: WNCategory?, priority: TaskPriority,
                    deadline: Date?, estimatedMinutes: Int?, ...) -> WNTask

    func updateTask(_ task: WNTask, changes: TaskChanges)
    func deleteTask(_ task: WNTask)

    func completeTask(_ task: WNTask)
        // → Sets status = .completed, completedAt = now
        // → Creates WNHistoryEntry (type: .taskCompleted)

    func postponeTask(_ task: WNTask)
        // → Increments postponementCount
        // → Creates WNHistoryEntry (type: .taskPostponed)
        // → If postponementCount >= 4, trigger decomposition suggestion

    func startTask(_ task: WNTask)
        // → Sets status = .inProgress

    func pendingTasks() -> [WNTask]
    func tasksDueSoon(within hours: Int) -> [WNTask]
    func overdueTasks() -> [WNTask]

    func decomposeTask(_ task: WNTask, into subtitles: [String], estimates: [Int?])
        // → Creates WNSubtask entries
}
```

### Postponement Intelligence

```swift
func shouldSuggestDecomposition(for task: WNTask) -> Bool {
    task.postponementCount >= 3 && task.subtasks.isEmpty
}

func generateDecompositionSuggestion(for task: WNTask) -> [SubtaskSuggestion] {
    // Heuristic: split estimated duration into 15-25 minute chunks
    // Name them "Part 1", "Part 2", etc.
    // Or, if AI is available, use Foundation Models for smarter decomposition
}
```

---

## 11. Focus System

### FocusService

```swift
@Observable @MainActor
final class FocusService {
    var activeSession: WNFocusSession?
    var timerRemaining: TimeInterval = 0
    var isRunning: Bool = false

    private var timer: Timer?

    func startSession(task: WNTask?, minutes: Int) -> WNFocusSession
        // → Create WNFocusSession
        // → Start countdown timer
        // → Update Live Activity
        // → Optionally activate Focus Protection

    func pauseSession()
    func resumeSession()

    func endSession(completed: Bool)
        // → Set wasCompleted / wasAbandoned
        // → Calculate actualMinutes
        // → Create WNHistoryEntry
        // → End Live Activity
        // → Deactivate Focus Protection

    func todaySessions() -> [WNFocusSession]
    func totalFocusTime(for dateRange: DateInterval) -> TimeInterval
}
```

### Timer Architecture

- Use `Timer.scheduledTimer(withTimeInterval: 1.0)` for the display countdown
- Store `startedAt` and `plannedMinutes` in SwiftData — if the app is killed, the session
  can be reconstructed on relaunch by computing elapsed time
- The Live Activity provides the real-time countdown independently via `Date.RelativeTimer`

### Focus Session States

```
┌──────────┐    startSession()    ┌─────────┐
│  Idle    │ ─────────────────▶  │ Running  │
└──────────┘                     └────┬─────┘
                                      │
                            ┌─────────┼─────────┐
                        pause()       │      endSession()
                            ▼         │         ▼
                      ┌─────────┐     │   ┌───────────┐
                      │ Paused  │     │   │ Completed  │
                      └────┬────┘     │   └───────────┘
                       resume()       │
                            │    timer expires
                            ▼         ▼
                      ┌─────────┐  ┌───────────┐
                      │ Running │  │ Completed  │
                      └─────────┘  └───────────┘
```

### Exit Confirmation

When user attempts to leave the Focus screen while a session is active:

```swift
.confirmationDialog("Leave Focus?", isPresented: $showExitConfirmation) {
    Button("Keep Focusing", role: .cancel) { }
    Button("End Anyway", role: .destructive) {
        focusService.endSession(completed: false)
    }
} message: {
    Text("You still have \(remaining) remaining.")
}
```

---

## 12. Focus Protection Architecture

### Framework Stack

| Framework | Purpose | Entitlement |
|-----------|---------|-------------|
| `FamilyControls` | Authorization to access Screen Time data | `com.apple.developer.family-controls` |
| `ManagedSettings` | Apply/remove app shields | Same entitlement |
| `DeviceActivity` | Schedule monitoring intervals | Same entitlement |

### ⚠️ Critical Limitation: Entitlement Approval

The `Family Controls (Distribution)` entitlement **must be approved by Apple** for
App Store / TestFlight distribution. It is a **restricted entitlement**.

**For development:** Xcode auto-provisions a development entitlement. Works on device.

**For distribution:** Submit a request to Apple explaining the digital wellbeing use case.
Approval is **not guaranteed** but is commonly granted for focus/wellbeing apps.

### Authorization Flow

```swift
import FamilyControls

class FocusProtectionService {
    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared
            .requestAuthorization(for: .individual)
        // .individual = self-restriction (not parental control)
        // Prompts for biometric / passcode authentication
    }

    var isAuthorized: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }
}
```

### Shielding Apps

```swift
import ManagedSettings

class FocusProtectionService {
    private let store = ManagedSettingsStore()

    // User selects distracting apps via FamilyActivityPicker
    func shieldApps(_ selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories =
            ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    func removeShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
```

### FamilyActivityPicker

```swift
import FamilyControls

// This is the ONLY way to let users select apps to block.
// It runs out-of-process — the app never sees actual app names/bundle IDs.
FamilyActivityPicker(selection: $activitySelection)
```

### Device Activity Monitor Extension

For timed shielding during focus sessions:

```swift
// DeviceActivityMonitorExtension target
class FocusActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        // Apply shields when focus session starts
        let store = ManagedSettingsStore()
        store.shield.applications = savedSelection.applicationTokens
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Remove shields when focus session ends
        let store = ManagedSettingsStore()
        store.clearAllSettings()
    }
}
```

### Fallback (If Entitlement Not Approved)

If Apple denies the entitlement, the fallback is:

1. **System Focus Filter integration** — suggest the user enable a Focus mode in Settings
2. **Gentle reminders** — if the user leaves the app during a focus session, send a notification:
   "Your focus session is still running. Come back?"
3. **No app blocking** — clearly document this limitation to the user

---

## 13. AI Assistant Architecture

### Primary Backend: Foundation Models (On-Device)

iOS 26 introduces the Foundation Models framework, which provides access to Apple's
on-device language models. This is **ideal** for What Now? because:

- **Privacy:** No data leaves the device
- **Offline:** Works without internet
- **No API keys:** No cost per request
- **Tool calling:** Native support for structured function calls
- **Structured generation:** `@Generable` macro for typed outputs

### ⚠️ Limitation: Hardware Requirement

Foundation Models requires an **Apple Intelligence-capable device**:
- iPhone 15 Pro / Pro Max or later
- All iPhone 16 models
- All iPhone 17 models

**Fallback for unsupported devices:**
1. Check `LanguageModel.isAvailable` at runtime
2. If unavailable, disable the AI Assistant tab and show explanation
3. All non-AI features (recommendation engine, scheduling, focus, etc.) work fully
4. Optional: Add a cloud AI service conforming to `AIServiceProtocol` in a future update

### Service Protocol

```swift
protocol AIServiceProtocol {
    func sendMessage(_ text: String,
                     context: AIContext,
                     tools: [any Tool]) async throws -> AIResponse
}

struct AIContext {
    let systemPrompt: String
    let conversationHistory: [WNAIMessage]
    let currentTasks: [WNTask]
    let todayPlan: WNDailyPlan?
    let availableTime: TimeInterval
    let recentHistory: [WNHistoryEntry]
}

struct AIResponse {
    let text: String
    let toolCalls: [ToolCallResult]
}
```

### Foundation Models Implementation

```swift
import FoundationModels

final class FoundationModelService: AIServiceProtocol {
    func sendMessage(_ text: String,
                     context: AIContext,
                     tools: [any Tool]) async throws -> AIResponse {

        let session = LanguageModelSession(
            model: .default,
            tools: tools,
            instructions: context.systemPrompt
        )

        let response = try await session.respond(to: text)
        return AIResponse(
            text: response.content,
            toolCalls: response.toolCalls.map { ... }
        )
    }
}
```

### System Prompt Strategy

```
You are the AI assistant for "What Now?", a personal day planner.
You have access to the user's tasks, schedule, and focus history.
You can perform actions using the provided tools.

Current context:
- Time: {currentTime}
- Available time: {availableMinutes} minutes
- Pending tasks: {taskCount}
- Today's focus time: {focusMinutes} minutes
- Active focus session: {yes/no}

Rules:
- Be concise and actionable
- Perform actions directly, don't just describe them
- If unsure about a parameter, ask the user
- Never invent tasks or events the user hasn't mentioned
- Respect the user's stated preferences and energy level
```

---

## 14. AI Tool / Action Architecture

### Design: Validated Structured Tools

Every tool is a Swift type conforming to the Foundation Models `Tool` protocol.
Every tool validates its arguments before modifying state.
The `AIToolRouter` maps tool calls to service methods.

### Tool Catalog

```swift
// Task Tools
final class CreateTaskTool: Tool { ... }
final class UpdateTaskTool: Tool { ... }
final class DeleteTaskTool: Tool { ... }
final class CompleteTaskTool: Tool { ... }
final class PostponeTaskTool: Tool { ... }

// Plan Tools
final class GenerateDailyPlanTool: Tool { ... }
final class ScheduleActivityTool: Tool { ... }
final class RescheduleActivityTool: Tool { ... }

// Focus Tools
final class StartFocusSessionTool: Tool { ... }
final class StopFocusSessionTool: Tool { ... }

// Query Tools
final class GetTodayPlanTool: Tool { ... }
final class GetUpcomingTasksTool: Tool { ... }
final class GetHistoryTool: Tool { ... }
final class GetAnalyticsTool: Tool { ... }
final class RecommendNextActionTool: Tool { ... }
```

### Tool Example (CreateTask)

```swift
final class CreateTaskTool: Tool {
    let name = "createTask"
    let description = "Creates a new task with the given details."

    @Generable
    struct Arguments {
        @Guide(description: "The task title")
        let title: String

        @Guide(description: "Category: study, work, coding, fitness, personal, gaming, relaxation")
        let category: String?

        @Guide(description: "Priority: low, medium, high, critical")
        let priority: String?

        @Guide(description: "Deadline as ISO 8601 date string")
        let deadline: String?

        @Guide(description: "Estimated duration in minutes")
        let estimatedMinutes: Int?
    }

    private let taskService: TaskService
    private let categoryService: CategoryService

    func call(arguments: Arguments) async throws -> ToolOutput {
        // VALIDATE
        guard !arguments.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return ToolOutput("Error: Task title cannot be empty.")
        }

        // RESOLVE CATEGORY
        let category = arguments.category.flatMap {
            categoryService.findCategory(named: $0)
        }

        // PARSE DEADLINE
        let deadline = arguments.deadline.flatMap {
            ISO8601DateFormatter().date(from: $0)
        }

        // CREATE (via service, not direct DB access)
        let task = taskService.createTask(
            title: arguments.title,
            category: category,
            priority: TaskPriority(rawValue: arguments.priority ?? "") ?? .medium,
            deadline: deadline,
            estimatedMinutes: arguments.estimatedMinutes
        )

        return ToolOutput("Created task: \"\(task.title)\"" +
                         (deadline != nil ? " due \(deadline!.formatted())" : ""))
    }
}
```

### Validation Rules (enforced by AIToolRouter)

1. All string inputs are trimmed and non-empty validated
2. Dates are parsed safely — invalid dates return an error, never crash
3. Task lookups by title use fuzzy matching (contains, case-insensitive)
4. Delete/modify operations require finding an existing task — return error if not found
5. Focus session operations check for active session conflicts
6. No tool may bypass the service layer to access ModelContext directly

---

## 15. Calendar Integration

### Framework: EventKit

```swift
import EventKit

@Observable @MainActor
final class CalendarService {
    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func events(for date: Date) -> [EKEvent] {
        guard authorizationStatus == .fullAccess else { return [] }
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}
```

### Required Info.plist Key

```
NSCalendarsFullAccessUsageDescription =
"What Now? reads your calendar events to plan your day around your commitments.
Your calendar data stays on your device."
```

### Behavior on Permission Denied

- App works without calendar events
- Scheduling engine plans around routines and tasks only
- Home screen shows available time based on tasks/routines only
- Settings shows option to enable calendar access with benefit explanation

---

## 16. Reminders Integration

### Framework: EventKit (EKReminder)

```swift
@Observable @MainActor
final class RemindersService {
    private let eventStore = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToReminders()
        } catch {
            return false
        }
    }

    func importReminders() async -> [EKReminder] {
        guard authorizationStatus == .fullAccess else { return [] }
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: nil)
        return try await withCheckedThrowingContinuation { cont in
            eventStore.fetchReminders(matching: predicate) { reminders in
                cont.resume(returning: reminders ?? [])
            }
        }
    }
}
```

### Required Info.plist Key

```
NSRemindersFullAccessUsageDescription =
"What Now? can import your reminders as tasks so everything is in one place.
Your reminders data stays on your device."
```

### Design Decision

Reminders integration is **import-only** (one-way sync). The app does NOT write back
to Reminders to avoid complex bidirectional sync issues for a solo developer. Users can
import reminders as WNTasks.

---

## 17. Notifications

### Framework: UserNotifications

```swift
@Observable @MainActor
final class NotificationService {
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleTaskReminder(for task: WNTask, at date: Date) { ... }
    func scheduleFocusReminder(minutesBefore: Int, eventTitle: String) { ... }
    func scheduleAvailableTimeNotification(gapMinutes: Int, taskTitle: String) { ... }
    func cancelAll(for taskID: UUID) { ... }
}
```

### Notification Types

| Type | Trigger | Content |
|------|---------|---------|
| Task deadline | Time-based (30 min before deadline) | "DSA is due in 30 minutes" |
| Available gap | Time-based (when gap starts) | "You have 30 min free — finish Python?" |
| Focus reminder | Time-based | "Focus session starts in 5 minutes" |
| Break suggestion | After 2h focus | "Take a 15-minute break?" |
| Daily plan | Morning (configurable) | "Your day is planned. 5 tasks ready." |
| End-of-day review | Evening (configurable) | "Ready to review your day?" |

### Notification Preferences (user-configurable)

- Enable/disable each notification type independently
- Quiet hours (e.g., no notifications after 10 PM)
- Maximum notifications per day
- Time-sensitive vs. standard delivery

---

## 18. Widgets

### Extension Target: `WhatNowWidget`

Requires **App Group** (`group.shlokphadtare.whatnow`) to share SwiftData.

### Widget Families

| Size | Name | Content |
|------|------|---------|
| `.systemSmall` | What Now? | Top recommendation: task name + estimated time |
| `.systemMedium` | Your Next Move | Recommendation + "Start" button (App Intent) |
| `.systemLarge` | Today's Plan | Timeline of today's schedule blocks |

### Data Access

The widget extension creates its own `ModelContainer` pointing to the shared
App Group container:

```swift
struct WhatNowWidgetEntryView: View {
    let entry: RecommendationEntry

    var body: some View {
        // Simple, glanceable display
    }
}

struct RecommendationProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let container = try! ModelContainer(
            for: WNTask.self, WNScheduleBlock.self,
            configurations: ModelConfiguration(
                url: FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: "group.shlokphadtare.whatnow")!
                    .appendingPathComponent("WhatNow.store")
            )
        )
        let context = ModelContext(container)
        // Fetch and compute recommendation
        // Return timeline with 15-minute refresh interval
    }
}
```

### Interactive Widgets (iOS 17+)

The medium widget's "Start" button uses an App Intent:

```swift
struct StartRecommendedTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Recommended Task"

    func perform() async throws -> some IntentResult {
        // Navigate app to focus setup for the recommended task
        return .result()
    }
}
```

---

## 19. Live Activities

### Framework: ActivityKit

```swift
struct FocusActivityAttributes: ActivityAttributes {
    let taskTitle: String
    let categorySymbol: String

    struct ContentState: Codable, Hashable {
        let endTime: Date             // for countdown timer
        let isPaused: Bool
    }
}
```

### Live Activity Lifecycle

```swift
// START (when focus session begins)
let attributes = FocusActivityAttributes(
    taskTitle: task.title,
    categorySymbol: task.category?.symbolName ?? "target"
)
let state = FocusActivityAttributes.ContentState(
    endTime: Date().addingTimeInterval(TimeInterval(minutes * 60)),
    isPaused: false
)
let activity = try Activity.request(
    attributes: attributes,
    content: .init(state: state, staleDate: nil),
    pushType: nil  // local-only
)

// UPDATE (on pause/resume)
await activity.update(.init(state: updatedState, staleDate: nil))

// END (when focus session ends)
await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .default)
```

### Dynamic Island Layout

```swift
// Compact Leading: SF Symbol for category
// Compact Trailing: Countdown timer
// Expanded: Task title + timer + Pause/End buttons
// Lock Screen: Task title + progress ring + timer
```

### ⚠️ Live Activity Limitations

- Maximum duration: **8 hours** (system auto-ends after that)
- System may end the activity if memory is constrained
- Cannot perform complex computation in the Live Activity view
- Timer display uses `Text(.timer)` with the `endTime` — the system handles countdown
  rendering without app involvement

---

## 20. App Intents / Siri

### Framework: AppIntents

```swift
struct WhatShouldIDoIntent: AppIntent {
    static var title: LocalizedStringResource = "What Should I Do"
    static var description = IntentDescription("Get your next recommended task")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let recommendation = recommendationEngine.topRecommendation()
        guard let rec = recommendation else {
            return .result(dialog: "You have no pending tasks. Enjoy your free time!")
        }
        return .result(dialog: "I recommend: \(rec.task.title). \(rec.reasons.first?.description ?? "")")
    }
}

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus"

    @Parameter(title: "Duration in minutes")
    var minutes: Int?

    func perform() async throws -> some IntentResult {
        let duration = minutes ?? 25
        focusService.startSession(task: nil, minutes: duration)
        return .result(dialog: "Focus session started for \(duration) minutes.")
    }
}

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"

    @Parameter(title: "Task title")
    var title: String

    func perform() async throws -> some IntentResult {
        taskService.createTask(title: title, ...)
        return .result(dialog: "Added: \(title)")
    }
}
```

### AppShortcutsProvider

```swift
struct WhatNowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WhatShouldIDoIntent(),
            phrases: [
                "What should I do in \(.applicationName)",
                "\(.applicationName) what now",
                "What's next in \(.applicationName)"
            ],
            shortTitle: "What Now?",
            systemImageName: "questionmark.circle"
        )
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Focus mode in \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "target"
        )
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: ["Add task in \(.applicationName)"],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
    }
}
```

---

## 21. Privacy Architecture

### Data Residency

| Data | Storage | Transmission |
|------|---------|-------------|
| Tasks, subtasks | SwiftData (local) | Never |
| Schedule, plans | SwiftData (local) | Never |
| Focus sessions | SwiftData (local) | Never |
| History, analytics | SwiftData (local) | Never |
| AI conversations | SwiftData (local) | Never |
| User preferences | SwiftData (local) | Never |
| Calendar events | Read from EventKit (local) | Never |
| Reminders | Read from EventKit (local) | Never |
| AI processing | Foundation Models (on-device) | Never |

**Result:** Zero data leaves the device in the default configuration.

### If Cloud AI Is Added Later

- Clearly display "Data will be sent to [provider]" before any transmission
- Show exactly what data is included
- Require explicit opt-in
- Store API keys in Keychain, never in code or UserDefaults
- Allow users to switch back to on-device-only mode

### User Data Control

- Settings → Privacy → "Your Data" section
- View all stored personalization data
- Edit/delete individual preferences
- "Delete All Data" option with confirmation
- Export data (optional future feature)

---

## 22. Offline-First Architecture

### Fully Offline Features (no network required)

| Feature | Mechanism |
|---------|-----------|
| Tasks (CRUD) | SwiftData local |
| Daily plans | SwiftData local |
| Timeline | SwiftData + EventKit (local) |
| Recommendation engine | Pure Swift computation |
| Scheduling engine | Pure Swift computation |
| Focus sessions + timer | Local timer + SwiftData |
| History + analytics | SwiftData queries |
| Insights | Local computation |
| Notifications | UNUserNotificationCenter (local) |
| Widgets | Shared SwiftData via App Group |
| Live Activities | ActivityKit (local) |
| Focus Protection | ManagedSettings (local) |
| Calendar events | EventKit (local) |

### Requires Apple Intelligence Hardware (but not network)

| Feature | Mechanism |
|---------|-----------|
| AI Assistant | Foundation Models (on-device, no network) |
| Natural language task creation | Foundation Models |
| AI-powered task decomposition | Foundation Models |

### Graceful Degradation

```swift
// Check AI availability at runtime
if LanguageModel.isAvailable {
    // Show AI Assistant button/tab
} else {
    // Hide AI features
    // Show "AI features require iPhone 15 Pro or later"
    // All other features work fully
}
```

---

## 23. Required Apple Capabilities & Entitlements

### Info.plist Keys

| Key | Required for | When to request |
|-----|-------------|-----------------|
| `NSCalendarsFullAccessUsageDescription` | EventKit calendar read | When user enables calendar integration |
| `NSRemindersFullAccessUsageDescription` | EventKit reminders read | When user taps "Import Reminders" |

### Entitlements

| Entitlement | Required for | Status |
|-------------|-------------|--------|
| `com.apple.developer.family-controls` | Focus Protection (app blocking) | **Restricted** — requires Apple approval |

### Capabilities (Xcode → Signing & Capabilities)

| Capability | Required for |
|------------|-------------|
| App Groups | Widget + extension data sharing |
| Push Notifications | Local notifications (UNUserNotificationCenter) |
| Family Controls | Screen Time app shielding |

### ⚠️ Entitlement Risk Matrix

| Feature | Risk | Mitigation |
|---------|------|-----------|
| Family Controls Distribution | Apple may deny | Full fallback UX (see §12) |
| Foundation Models | Hardware-limited | AI features disabled on older devices; all other features unaffected |
| Live Activities | 8-hour limit | Timer reconstruction on app relaunch |
| Calendar access | User may deny | Plan works without calendar events |
| Notification access | User may deny | App works without push; in-app reminders |

---

## 24. Testing Strategy

### Unit Tests (XCTest)

| Component | Test Coverage |
|-----------|--------------|
| `RecommendationEngine` | Scoring algorithm, factor weights, edge cases (no tasks, all overdue, time fit filtering) |
| `SchedulingEngine` | Gap finding, task placement, break insertion, overflow detection, conflict resolution |
| `AvailableTimeCalculator` | Gap calculation with varying calendar events and routines |
| `TaskService` | Create, complete, postpone, decompose, status transitions |
| `FocusService` | Start, pause, end, completion tracking, time calculations |
| `HistoryService` | Entry creation, aggregation queries, date range filtering |
| `InsightEngine` | Trend calculations, category distribution, planned vs actual |
| AI Tool validation | Argument parsing, error handling, fuzzy task matching |

### Test Data Strategy

```swift
// Every test uses an in-memory ModelContainer
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: WNTask.self, ..., configurations: config)
let context = ModelContext(container)

// Factory methods for test data
extension WNTask {
    static func sample(
        title: String = "Test Task",
        priority: TaskPriority = .medium,
        deadline: Date? = nil,
        estimatedMinutes: Int? = 30
    ) -> WNTask { ... }
}
```

### Edge Cases to Test

| Scenario | Expected behavior |
|----------|------------------|
| Zero tasks | Home shows "No tasks" state; scheduler produces empty plan |
| 50+ tasks | Recommendation returns top result; scheduler handles overflow |
| All tasks overdue | Top 3 shown in overwhelmed mode |
| Available time = 0 | "No free time" message; no recommendation |
| Overlapping calendar events | Scheduler deduplicates; gaps computed correctly |
| Task with 0 estimated minutes | Treated as 15-minute default |
| Postponement count = 10 | Decomposition strongly suggested |
| Focus session in progress | Home shows active session; new session blocked |
| Calendar permission denied | Scheduler works with tasks/routines only |
| AI unavailable (old device) | All non-AI features work; assistant hidden |

### UI Testing (later phases)

- Snapshot tests for key screens (Home, Plan, Focus)
- Accessibility audit (VoiceOver navigation)
- Dynamic Type rendering at all sizes

---

## 25. Feature Dependencies

```
                    ┌─────────────────┐
                    │   SwiftData     │
                    │   Models        │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌───────────┐  ┌──────────┐
        │TaskService│  │ScheduleSvc│  │FocusSvc  │
        └─────┬────┘  └─────┬─────┘  └─────┬────┘
              │              │              │
              ▼              ▼              │
        ┌──────────┐  ┌───────────┐        │
        │Recommend │  │Scheduling │        │
        │Engine    │  │Engine     │        │
        └─────┬────┘  └─────┬─────┘        │
              │              │              │
              ▼              ▼              ▼
        ┌──────────────────────────────────────┐
        │            Home Screen               │
        │       (depends on all above)         │
        └──────────────────────────────────────┘
              │
              ▼
     ┌────────────────┐
     │ Calendar Svc   │ (optional enrichment)
     │ Notifications  │ (optional enrichment)
     │ Widgets        │ (reads from shared store)
     │ Live Activities│ (triggered by FocusService)
     │ App Intents    │ (calls into services)
     │ AI Assistant   │ (calls tools → services)
     │ Focus Protect  │ (triggered by FocusService)
     └────────────────┘
```

### Build Order (what must exist before what)

1. **Models** → everything depends on these
2. **Services** → depend on Models
3. **Engines** → depend on Services + Models
4. **Features/UI** → depend on Engines + Services
5. **Integrations** → depend on Services (enrichment layer)
6. **AI** → depends on Services + Engines (tool calling)

---

## 26. Phased Implementation Roadmap

### PHASE 1 — Foundation (~2-3 weeks)

**Goal:** Core data layer, navigation shell, basic UI for all primary screens.

**Deliverables:**
- Project folder structure as defined in §2
- All SwiftData models (§4) with enums
- `AppState` service container with basic DI
- `TaskService` (CRUD operations)
- `CategoryService` with default category seeding
- Design system: `Theme.swift`, `WNCard`, `WNButton`, `WNEmptyState`
- `TabView` navigation with 5 tabs
- `HomeView` — static greeting + placeholder recommendation
- `TaskListView` — list tasks, swipe to complete/delete
- `TaskEditorView` — create/edit tasks with all fields
- `TaskDetailView` — view task details + subtasks
- `PlanView` — placeholder timeline
- `FocusView` — placeholder
- `InsightsView` — placeholder
- `SettingsView` — basic settings shell
- Sample data for development/preview

**Tests:** TaskService CRUD, model relationships, category seeding

---

### PHASE 2 — Intelligence (~2-3 weeks)

**Goal:** The recommendation and scheduling engines — the brain of the app.

**Depends on:** Phase 1 (Models, TaskService)

**Deliverables:**
- `RecommendationEngine` with full scoring algorithm (§8)
- `AvailableTimeCalculator` — compute free time from schedule
- `SchedulingEngine` — generate daily plans (§9)
- `ScheduleService` — manage `WNDailyPlan` persistence
- `RoutineService` — CRUD for routines
- `HomeView` update — live recommendation card with "Why this?" + quick actions
- `HomeViewModel` — contextual state machine (§6)
- `PlanView` update — real timeline with generated plan
- `PlanViewModel` — day plan loading and generation
- `TimelineBlockView` with visual block styles per type
- Postponement intelligence — decomposition suggestions
- "Overwhelmed mode" — top 3 priorities

**Tests:** Recommendation scoring (all factors), scheduling (gap finding, overflow,
breaks), available time calculations, edge cases

---

### PHASE 3 — Execution (~2 weeks)

**Goal:** Focus sessions, history tracking, basic analytics.

**Depends on:** Phase 2 (Engines, Schedule)

**Deliverables:**
- `FocusService` — full session lifecycle (start, pause, end)
- `FocusTimerView` — beautiful countdown timer with progress ring
- `FocusSetupView` — duration picker, task association
- Exit confirmation dialog
- `HistoryService` — record completions, postponements, focus sessions
- `InsightsView` update — daily/weekly summary cards
- `InsightEngine` — compute trends, category distribution, focus analytics
- `DayReviewView` — end-of-day summary with reflection
- `WeekReviewView` — weekly summary with trends
- `FocusHistoryView` — session history list
- Timeline interactions — swipe complete/postpone, tap to open

**Tests:** Focus timer accuracy, session state transitions, history aggregation,
insight calculations

---

### PHASE 4 — Apple Integrations (~2-3 weeks)

**Goal:** Calendar, notifications, widgets, Live Activities, Siri.

**Depends on:** Phase 3 (FocusService, HistoryService)

**Deliverables:**
- `CalendarService` — EventKit read, permission flow
- Calendar events integrated into scheduling engine
- `NotificationService` — local notifications for all types (§17)
- Notification preferences in Settings
- **Widget extension target** with App Group
  - Small widget: recommendation
  - Medium widget: recommendation + Start button
  - Large widget: today's timeline
- **Live Activity** — focus session timer + Dynamic Island
- **App Intents** — "What should I do?", "Start Focus", "Add Task", "Plan my day"
- `AppShortcutsProvider` for Siri phrases
- `RemindersService` — import reminders as tasks

**Tests:** Calendar event parsing, notification scheduling, widget data provider

---

### PHASE 5 — Focus Protection (~1-2 weeks)

**Goal:** App blocking during focus sessions using Screen Time APIs.

**Depends on:** Phase 3 (FocusService)

**Deliverables:**
- **Family Controls entitlement** request to Apple
- `FocusProtectionService` — authorization, shield management
- `FamilyActivityPicker` integration in Settings
- Focus presets (pre-configured app selections)
- **ShieldConfigurationExtension** target — custom shield UI
- **DeviceActivityMonitorExtension** target — timed shielding
- Integration with `FocusService` — auto-shield on focus start, remove on end
- Fallback UX if entitlement unavailable
- Privacy explanation screens

**Tests:** Authorization state handling, shield apply/remove logic

---

### PHASE 6 — AI Assistant (~2-3 weeks)

**Goal:** On-device AI assistant with structured tool calling.

**Depends on:** Phase 2 (Engines), Phase 3 (FocusService)

**Deliverables:**
- `AIServiceProtocol` abstraction
- `FoundationModelService` — Foundation Models integration
- All AI tools (§14): task CRUD, plan generation, focus control, queries
- `AIToolRouter` — maps tool calls to service methods with validation
- `AIPrompts` — system prompt with dynamic context injection
- `AssistantView` — chat UI with message bubbles
- `AssistantViewModel` — conversation management
- `ToolResultView` — inline display of tool actions (created task, started focus, etc.)
- AI availability check (`LanguageModel.isAvailable`)
- Fallback for unsupported devices
- Natural language task creation
- "Plan my day" via AI
- History/analytics queries via AI

**Tests:** Tool argument validation, tool routing, error handling, context building

---

### PHASE 7 — Polish & Ship (~2 weeks)

**Goal:** Onboarding, visual polish, accessibility, performance, final testing.

**Depends on:** All previous phases

**Deliverables:**
- `OnboardingView` — 3-4 step flow (interests, energy, obstacles, permissions)
- `OnboardingViewModel` — profile creation, category selection
- Animations — view transitions, card appearance, timeline blocks
- Haptic feedback — task completion, focus start/end, swipe actions
- Accessibility — VoiceOver labels on all elements, Dynamic Type audit
- Reduced motion support — disable animations when enabled
- Dark mode audit — all screens
- Empty states — custom illustrations/messages for each screen
- Error states — graceful handling with retry options
- Loading states — skeleton views or progress indicators
- Performance audit — profile with Instruments
- Privacy Settings — "Your Data" view, delete all data option
- App icon and launch screen
- Comprehensive test pass
- Bug fixes from all phases

**Tests:** Full regression, accessibility audit, edge case sweep

---

## Appendix A: Technical Limitations Summary

| Limitation | Impact | Mitigation |
|-----------|--------|-----------|
| Family Controls requires Apple-approved entitlement | App blocking may not be available at App Store launch | Full fallback UX; submit entitlement request early in Phase 5 |
| Foundation Models requires Apple Intelligence hardware | AI assistant unavailable on iPhone 14 and earlier | All non-AI features work fully; runtime check disables AI gracefully |
| Live Activities max 8 hours | Focus sessions over 8 hours lose Live Activity | Extremely rare use case; acceptable limitation |
| Widgets have limited memory | Cannot do complex computation in widget | Pre-compute recommendation in main app; widget reads result |
| EventKit calendar is read-only from our perspective | Cannot create calendar events from the app | Not needed; the app manages its own schedule |
| No true background execution | Cannot update recommendations while app is backgrounded | Update on foreground; widgets use timeline refresh |
| SwiftData in widget must use shared App Group | Setup complexity | Documented in §18; tested in Phase 4 |
| Siri phrase matching is imperfect | Users may need exact phrases | Provide multiple phrase variants in AppShortcutsProvider |

---

## Appendix B: Files That Must Be Created Per Phase

### Phase 1 (34 files)
Models: 11 · Enums: 6 · Services: 3 · Design: 5 · Features: 7 · App: 2

### Phase 2 (12 files)
Engines: 3 · Services: 2 · Features: 5 · Tests: 2

### Phase 3 (10 files)
Services: 2 · Features: 6 · Tests: 2

### Phase 4 (12 files)
Integrations: 3 · Widget: 4 · LiveActivity: 1 · AppIntents: 2 · Tests: 2

### Phase 5 (6 files)
Extensions: 2 · Services: 1 · UI: 2 · Tests: 1

### Phase 6 (12 files)
AI: 6 · Features: 4 · Tests: 2

### Phase 7 (8 files)
Onboarding: 3 · Polish: 3 · Tests: 2

**Total: ~94 files** across all phases — manageable for a solo developer.
