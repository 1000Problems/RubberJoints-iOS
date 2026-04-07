# RubberJoints iOS — AI Workout Coach

iOS workout tracking app with AI coaching. SwiftUI + SwiftData + Claude API. The app is called "Workout LLM" internally.

## Before Implementing Any TASK

1. **Read the full TASK spec** — understand scope, acceptance criteria, and the Do Not Change section.
2. **Query LightRAG** for cross-project context before touching shared patterns:
   ```bash
   curl -X POST http://localhost:9621/query \
     -H "Content-Type: application/json" \
     -d '{"query": "architectural context for [feature being implemented]", "mode": "hybrid"}'
   ```
3. **Stay in scope.** Only modify files and components explicitly listed in the TASK spec. If you discover something that needs changing outside the spec, create a new VybePM task — do NOT fix it inline.
4. **Verify before committing.** Build in Xcode (Cmd+B), confirm zero warnings, and check that nothing outside the TASK scope changed with `git diff`.

### Protected Areas (global — TASK specs may add more)

These components are stable and must NOT be modified unless the TASK spec explicitly names them:

- `Services/ClaudeAPIService.swift` — Direct Claude API client, tested and working.
- `Services/KeychainHelper.swift` — Keychain storage for API keys.
- `Services/ExerciseCatalog.swift` — Static exercise database. Additive changes only.
- SwiftData model files in `Models/` — schema changes require migration planning, never alter existing properties.

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
