# What Now? — Product Specification

> **Version**: 1.0  
> **Target**: iOS 26.5+ · iPhone  
> **Stack**: Swift · SwiftUI · SwiftData · Foundation Models

---

## Vision

"What Now?" is an intelligent personal day-management and decision assistant.

Its core question: **"What should I do right now?"**

The app understands the user's day — schedule, tasks, available time, priorities, deadlines,
routines, history, habits, focus sessions, preferences, and context — then helps the user
decide what to do, plan the day, execute the task, stay focused, track what happened, and
adapt future recommendations.

It is NOT:
- A generic to-do list
- A ChatGPT wrapper
- Several apps glued together
- A guilt-based productivity tracker

The intelligence is hidden behind a beautiful, simple interface.

---

## Core Loop

```
UNDERSTAND MY DAY
       ↓
UNDERSTAND MY AVAILABLE TIME
       ↓
UNDERSTAND WHAT MATTERS
       ↓
RECOMMEND WHAT I SHOULD DO
       ↓
HELP ME START
       ↓
HELP ME FOCUS
       ↓
TRACK WHAT HAPPENED
       ↓
LEARN FROM MY BEHAVIOR
       ↓
ADAPT THE REST OF MY DAY
```

---

## 1. Home Screen

The most important screen. Adaptive and contextual.

**Morning example:**
> "Good morning."  
> "You have 50 minutes before your next commitment."  
> "Best next move: Study."

**Afternoon example:**
> "You have 1h 20m free."  
> "Finish your DSA assignment."  
> 25 minutes · Due tomorrow  
> [ Start ]

**Evening example:**
> "Everything important is complete."  
> "You have 2 hours free."  
> "Want to play something?"

Quick alternatives: [ Study ] [ Code ] [ Gym ] [ Play ] [ Relax ]

Every recommendation optionally explains itself ("Why this?").

---

## 2. Daily Planner

Full-day planning capability with realistic scheduling.

**Must understand:**
- Fixed commitments (calendar events)
- Task deadlines and priorities
- Estimated task duration
- Available time windows
- Preferred working times
- Breaks and buffer time
- Routines
- Unfinished/postponed tasks

**Rules:**
- Never schedule every minute
- Leave realistic gaps
- Don't create impossible schedules
- If not enough time, tell the user

---

## 3. Recommendation Engine

Deterministic. Works without AI. Considers:

- Urgency / importance / deadline / remaining time
- Estimated duration vs. available time
- Current time vs. preferred time
- Previous completion behavior
- Postponement count
- Task dependencies
- Recent focus sessions
- Category balance
- Whether task has been started
- User energy level

**Key rule:** If only 15 minutes available, don't recommend a 90-minute task.

**Rest awareness:** Recommend breaks and entertainment when appropriate.
The system knows when NOT to recommend productivity.

---

## 4. Task System

**Properties:** title, description, category, priority (low/medium/high/critical),
deadline, estimated duration, preferred time, repeat schedule, subtasks, notes,
status, created/completed dates, postponement count, completion history.

**Actions:** create, edit, delete, complete, postpone, reschedule, split into steps,
start, attach to focus session.

**Postponement intelligence:** After repeated postponements, suggest breaking the
task into smaller steps. Never guilt the user.

---

## 5. Timeline

Visual daily timeline with beautiful blocks. NOT a spreadsheet.

**Interactions:** tap to open, swipe to complete, swipe to postpone,
drag to reschedule, long press for actions. Subtle animations and haptics.

---

## 6. AI Personal Assistant

Understands the user's data. Performs actions, not just descriptions.

**Example commands:**
- "Plan my day."
- "I have two hours free. What should I do?"
- "Add DSA assignment for tomorrow."
- "Move gym to 7 PM."
- "What am I behind on?"
- "I don't feel like studying. Give me something easier."
- "Start a 45-minute focus session."

**Architecture:** Structured tool calls, validated before modifying state.
The deterministic engine controls persistence, timers, scheduling, notifications.
AI enhances but does not directly control critical state.

---

## 7. AI Tools (Structured Actions)

```
createTask, updateTask, deleteTask, completeTask, postponeTask,
scheduleActivity, rescheduleActivity, getTodayPlan, getUpcomingTasks,
getHistory, getAnalytics, generateDailyPlan, recommendNextAction,
createFocusSession, startFocusMode, stopFocusMode
```

Every action validated before modifying application state.

---

## 8. Focus Mode

Beautiful dedicated focus screen.

**Durations:** 15 / 25 / 45 / 60 / custom minutes.

**On start:** Start timer, track session, optionally enable distraction protection,
create Live Activity.

**On exit attempt:** Confirm dialog. Never trap the user.

**Tracks:** completion vs. abandonment, session history.

---

## 9. Focus Protection / App Blocking

Use Apple's Screen Time APIs (Family Controls, Managed Settings, Device Activity).

**Supports:** Selecting distracting apps/categories, timed shielding,
focus presets, focus-session integration.

**Requires:** `com.apple.developer.family-controls` entitlement (Apple approval needed).
Handle authorization flow properly. Provide fallback if unavailable.

---

## 10. Analytics & Insights

**Focus analytics:** Total focus time, sessions completed/abandoned,
average duration, best focus window, most productive category.

**History:** Daily/weekly activity breakdown by category and time.

**Insights:** Completion trends, postponement trends, category distribution,
time-of-day performance, planned vs. actual time.

Every insight answers: "What can I do differently?"

---

## 11. Entertainment & Rest

Entertainment is not bad. Users can configure activities (gaming, movies, hobbies).
The engine can recommend entertainment. Rest is a legitimate activity.

Break suggestions after extended focus. "You're done. Enjoy your evening."

---

## 12. Routines

Recurring routines (morning, study, gym, night) auto-appear in daily plans.

---

## 13. Reviews

**End-of-day review:** Tasks completed, focus time, postponements,
planned vs. actual, tomorrow preview, optional reflection.

**Weekly review:** Focus trends, best day, most postponed task,
most productive hours, actionable recommendation.

---

## 14. Unknown/Overwhelmed Modes

"I don't know what I want" → Ask minimum questions (time? energy?) → Recommend.

"Too much to do" → Reduce to the 3 most important things.

---

## 15. Memory / Personalization

Remember: preferred times, focus duration, routines, patterns,
postponement patterns, explicit preferences.

Users can inspect, edit, and delete personalization data.

---

## 16. Apple Integrations

- **Calendar** (EventKit): Read events as fixed commitments
- **Reminders** (EventKit): Useful synchronization
- **Notifications** (UNUserNotificationCenter): Intelligent, not spammy
- **Widgets** (WidgetKit): Small/Medium/Large — glanceable
- **Live Activities** (ActivityKit): Focus session timer + Dynamic Island
- **App Intents/Siri**: "What should I do?" "Start Focus." "Plan my day."

---

## 17. Privacy & Offline

- **Local-first:** SwiftData, all core features offline
- **AI on-device:** Foundation Models framework (no data leaves device)
- **Clear distinction:** What's local vs. what's sent to AI services
- **No silent uploads.** No hardcoded API keys.
- **User control** over all personalization data

---

## 18. Design Principles

- Premium native Apple experience (Liquid Glass on iOS 26)
- SF Symbols, semantic colors, native typography
- Dark mode / light mode
- Dynamic Type, VoiceOver, accessibility labels
- Reduced-motion support
- Subtle animations and haptic feedback
- No tutorials needed — intuitive by design

---

## 19. Navigation

Sections: **Home · Plan · Tasks · Focus · Insights · Assistant**

Settings accessible without cluttering primary experience.

---

## 20. Onboarding

Short. Ask only useful questions:
- What do you want help with? (Study/Work/Fitness/Personal/Hobbies/Gaming/Rest)
- When do you have the most energy? (Morning/Afternoon/Evening/Varies)
- What gets in your way? (Procrastination/Too many tasks/Distractions/Forgetting/Starting/Finishing)
- Permissions requested only when needed, with benefit explanation.
