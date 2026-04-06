# RubberJoints iOS — AI Workout Coach

iOS workout tracking app with AI coaching. SwiftUI + SwiftData + Claude API. The app is called "Workout LLM" internally.

## Architecture

```
Workout LLM/
  Models/          — SwiftData models (Exercise, Program, SessionLog, DailyCheck, etc.)
  Services/        — Claude API, coach prompt builder, exercise catalog, keychain
  Views/
    AI/            — AI chat/coaching views
    Library/       — Exercise library browser
    Progress/      — Progress tracking and milestones
    Settings/      — User preferences and API key config
    Week/          — Weekly plan view
    Workout/       — Active workout session views
    MainTabView    — Tab navigation root
```

## Tech Stack

- **UI:** SwiftUI, iOS 17+
- **Storage:** SwiftData (local persistence)
- **AI:** Claude API via ClaudeAPIService.swift (direct HTTP, no SDK)
- **Auth:** Anthropic API key stored in Keychain via KeychainHelper.swift

## Key Services

- `ClaudeAPIService.swift` — Direct Claude API calls for coaching responses
- `CoachPromptBuilder.swift` — Builds system prompts with user context (exercises, history, preferences)
- `ExerciseCatalog.swift` — Static exercise database with categories and muscle groups
- `StaticPlan.swift` — Pre-built workout plans (fallback when AI unavailable)
- `SeedData.swift` — Initial data population

## VybePM Integration

Project slug: `RubberJoints-iOS`
Task types: `dev`, `design`, `other`
Assignees: `angel`, `claude-code`

## Build

Open `Workout LLM.xcodeproj` in Xcode. No external dependencies (no SPM/CocoaPods).
Deployment target: iOS 17.0

## What NOT to Do

- Do NOT add server-side components — this is a local-first app
- Do NOT change the data model without checking SwiftData migration impact
- Do NOT hardcode API keys — everything goes through KeychainHelper
- Do NOT commit or push — Angel handles git
