# What Now? — Development Rules

> Authoritative coding standards for the What Now? project.  
> Every contributor (human or AI agent) must follow these rules.

---

## 1. Language & SDK

- **Swift 6** with strict concurrency enabled (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **iOS 26.5** deployment target
- **SwiftUI** for all UI — no UIKit unless wrapping an Apple-provided UIKit-only controller
- **SwiftData** for persistence — no Core Data, no Realm, no SQLite directly
- **Observation framework** (`@Observable`) — never use `ObservableObject` / `@Published`
- **async/await** for all asynchronous work — no completion handlers unless wrapping legacy APIs

---

## 2. Architecture Rules

### Pattern: Feature-Based Modular + Service Layer

```
App/         → Entry point, DI, app-level state
Core/        → Models, services, engines (no UI)
Features/    → Per-screen modules (View + ViewModel)
Design/      → Theme, reusable components, modifiers
Integrations/→ Apple framework wrappers
AI/          → AI service, tools, prompts
```

### Strict Layering

| Layer | May depend on | Must NOT depend on |
|-------|--------------|-------------------|
| View | ViewModel, Design | Core services directly |
| ViewModel | Services, Engines | Other ViewModels |
| Service | Models, other Services | Views, ViewModels |
| Engine | Models, Services | Views, ViewModels, other Engines |
| Model | Nothing | Anything |

### ViewModel Rules

- Every non-trivial screen gets a ViewModel
- Mark `@Observable @MainActor`
- Inject dependencies via `init()` — no singletons
- Never import SwiftUI in a ViewModel (import only `Foundation` / `SwiftData`)
- ViewModels own UI state; services own business logic

### Dependency Injection

- Use `@Environment` for ModelContext
- Use an `AppState` / `ServiceContainer` passed via `.environment()` for services
- In tests, inject in-memory `ModelContainer` and mock services

---

## 3. SwiftData Rules

- All model classes prefixed with `WN` (e.g., `WNTask`) to avoid naming conflicts
- Never name a model `Task` (conflicts with `Swift.Task`)
- Use `@Model` classes with `var` properties
- Store enums as `String` raw values for SwiftData compatibility
- Define `@Relationship` with explicit `deleteRule` on every relationship
- Always set `inverse` on bidirectional relationships
- Use `FetchDescriptor` in ViewModels/services — `@Query` only in simple views
- Test with `ModelConfiguration(isStoredInMemoryOnly: true)`
- Perform `context.save()` only at transaction boundaries, not after every change

---

## 4. Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Model | `WN` prefix, PascalCase | `WNTask`, `WNFocusSession` |
| Enum | PascalCase, raw `String` | `TaskPriority`, `TaskStatus` |
| ViewModel | `[Screen]ViewModel` | `HomeViewModel`, `PlanViewModel` |
| View | `[Name]View` | `HomeView`, `TaskDetailView` |
| Service | `[Domain]Service` | `TaskService`, `FocusService` |
| Engine | `[Domain]Engine` | `RecommendationEngine` |
| Protocol | Descriptive noun/adjective | `AIServiceProtocol` |
| File | Matches primary type | `WNTask.swift`, `HomeView.swift` |

---

## 5. SwiftUI Rules

- Use `NavigationStack` — never `NavigationView`
- Use typed `NavigationPath` for programmatic navigation
- Prefer `@State` for local view state
- Prefer `@Environment(\.modelContext)` for data access
- Use `.sheet()` / `.fullScreenCover()` for modals — never push onto NavStack
- Use `@Bindable` to create bindings from `@Observable` objects
- Support Dark Mode: use semantic colors (`Color.primary`, `.secondary`, asset colors)
- Support Dynamic Type: use system fonts or scaled custom fonts
- Support Reduced Motion: check `@Environment(\.accessibilityReduceMotion)`
- Add `.accessibilityLabel()` and `.accessibilityHint()` to all interactive elements
- Prefer `Label("Title", systemImage:)` over separate Image+Text
- Use `.sensoryFeedback()` for haptics — never `UIImpactFeedbackGenerator` directly

---

## 6. Concurrency Rules

- All ViewModels: `@MainActor`
- All Services touching UI state: `@MainActor`
- Heavy computation (recommendation scoring, scheduling): use `nonisolated` or dedicated actor
- Never block the main thread
- Use `Task { }` for launching async work from synchronous contexts
- Use `TaskGroup` when parallelizing independent operations
- Respect structured concurrency — avoid `Task.detached` unless necessary

---

## 7. Error Handling

- Never `try!` or `fatalError()` in production code paths
- Use `do/catch` with meaningful error propagation
- Services return `Result<T, Error>` or throw typed errors
- Views display user-friendly error states — never raw error messages
- Handle permission denial gracefully (explain benefit, offer Settings redirect)
- Handle empty states explicitly (no tasks, no history, no plan)

---

## 8. Privacy Rules

- All data stored locally in SwiftData by default
- AI processing via Foundation Models = on-device, no network
- If cloud AI is added later, clearly disclose data transmission
- Never hardcode API keys — use Keychain or secure configuration
- Never silently upload user schedules, tasks, or personal data
- Users can inspect, edit, and delete all personalization data
- Request permissions only when the feature is about to be used, not at launch

---

## 9. Testing Rules

- Every Engine gets unit tests (recommendation scoring, scheduling, time calculations)
- Every Service gets unit tests for business logic
- Use in-memory `ModelContainer` for all SwiftData tests
- Test edge cases: no tasks, many tasks, overdue tasks, overlapping events, no time
- AI tools: test validation logic independently of AI model
- Never test private implementation details — test behavior
- Test file naming: `[Type]Tests.swift` (e.g., `RecommendationEngineTests.swift`)

---

## 10. File Organization Rules

- One primary type per file
- Maximum ~300 lines per file — split if larger
- Group related files in folders matching the architecture diagram
- No "Utils" or "Helpers" dumping grounds — put extensions in `Extensions/`
- Keep `Assets.xcassets` organized with named folders

---

## 11. Dependency Rules

- **Zero** third-party dependencies unless absolutely unavoidable
- Pure Apple stack: SwiftUI, SwiftData, Foundation, EventKit, ActivityKit, etc.
- If a third-party library is considered, it must be justified in writing

---

## 12. API Rules

- Use only **public** Apple APIs
- Never use private/undocumented APIs
- Never use deprecated APIs when a modern alternative exists
- If an API requires a special entitlement, document it and handle the fallback
- Wrap all Apple framework access (EventKit, Family Controls, etc.) in service layers
  so the rest of the app is decoupled from framework-specific details

---

## 13. Build Rules

- Project must compile with zero warnings (treat warnings as errors in Release)
- Fix errors immediately after introducing them
- Run tests after every meaningful change
- Keep the app functional at the end of every implementation phase

---

## 14. AI Integration Rules

- AI enhances the app but does not control critical state
- All AI actions go through validated, structured tools
- The deterministic engine handles: persistence, timers, state, scheduling, notifications
- AI tool outputs are validated before applying changes
- AI conversations are stored locally
- Foundation Models (on-device) is the primary AI backend
- Graceful degradation if AI is unavailable (device doesn't support Apple Intelligence)
