---
name: xcode-ios-builder
description: >
  Build, iterate, and test iOS apps from a Cowork session by writing Swift files directly into an Xcode project folder,
  building via computer-use clicks, reading build errors from screenshots, and verifying in the iOS Simulator.
  Use this skill whenever the user asks to create an iOS app, build a SwiftUI project, write Swift code for Xcode,
  fix Xcode build errors, test in the Simulator, or do anything involving Xcode and iOS development from Cowork.
  Also trigger when the user mentions "Xcode", "SwiftUI", "SwiftData", "iOS app", "iPhone app", "Simulator",
  or wants to iterate on a native Apple platform project. This skill covers the full loop: write code → build → fix → verify.
---

# Xcode iOS Builder — Cowork Workflow

This skill documents the complete workflow for building iOS apps from a Cowork session. It covers writing Swift files directly into an Xcode project, triggering builds via computer-use, diagnosing and fixing compilation errors, and verifying the running app in the iOS Simulator.

## How It Works: The Big Picture

Cowork runs in a Linux sandbox that can read/write to the user's Mac filesystem via a mounted workspace folder. Xcode runs natively on the user's Mac. The workflow exploits two key facts:

1. **Modern Xcode projects (objectVersion 77) use `PBXFileSystemSynchronizedRootGroup`** — any `.swift` file you drop into the project folder is automatically discovered by Xcode. No need to touch `project.pbxproj`.
2. **Computer-use gives click-level access to Xcode** and full access to the Simulator — enough to trigger builds and read results visually.

So the loop is: write files to disk → click Play in Xcode → read the screenshot for errors → fix the files → repeat.

## Prerequisites

Before starting, make sure:

- The user has created an Xcode project (File → New → Project → App) with SwiftUI as the interface
- The project folder is accessible via the Cowork workspace mount (typically at `/sessions/.../mnt/<folder>/<ProjectName>/`)
- The Xcode project uses the default file-system-synced group (objectVersion 77, which is the default in Xcode 16+)
- A Simulator device is selected in Xcode's toolbar (e.g., "iPhone 17 Pro")

Verify the project structure exists:
```
<ProjectName>/
├── <ProjectName>.xcodeproj/
│   └── project.pbxproj  (DO NOT MODIFY — auto-syncs files)
└── <ProjectName>/
    ├── <ProjectName>App.swift
    ├── ContentView.swift
    └── ... (your Swift files go here)
```

## Step-by-Step Workflow

### 1. Request Computer Access

Before any build/test cycle, request access to Xcode and Simulator:

```
request_access(apps: ["Xcode", "Simulator"], reason: "Build and test the iOS app")
```

**Tier constraints to remember:**
- **Xcode → tier "click"**: You can see the screen and left-click buttons, but CANNOT type, use keyboard shortcuts, right-click, or drag. No Cmd+B — you must click the Play button.
- **Simulator → tier "full"**: Full control including clicks, typing, and screenshots. You can interact with the running app.

### 2. Write Swift Files

Write `.swift` files directly into the project's source folder using the `Write` or `Edit` tools:

```
/sessions/.../mnt/<Workspace>/<ProjectName>/<ProjectName>/Models/MyModel.swift
/sessions/.../mnt/<Workspace>/<ProjectName>/<ProjectName>/Views/MyView.swift
/sessions/.../mnt/<Workspace>/<ProjectName>/<ProjectName>/Services/MyService.swift
```

**Key points:**
- Files appear in Xcode's navigator automatically — no manual "Add Files" step needed
- Organize into subfolders (Models/, Views/, Services/) for clarity — Xcode picks them up recursively
- To delete files, you must first call `allow_cowork_file_delete`, then `rm`

### 3. Build the App

Trigger a build by clicking the **Play button** (▶ triangle) in Xcode's toolbar:

```python
# Stop any current run first (click the square Stop button)
left_click(coordinate=[stop_button_x, stop_button_y])
wait(duration=2)
# Click Play to build and run
left_click(coordinate=[play_button_x, play_button_y])
wait(duration=15-30)  # Give it time to compile
screenshot()  # Check the result
```

**Locating the buttons:** The Play (▶) and Stop (■) buttons are in Xcode's top-left toolbar area. Take a screenshot first to find their exact coordinates. They're typically near x: 340-360, y: 50 on a standard layout.

### 4. Read Build Results

After the build, take a screenshot and check for:

- **Success**: The Simulator launches and shows your app. The Xcode toolbar shows "Running <AppName> on <Device>".
- **Build errors**: Red annotations appear in the editor, and the Issue Navigator (⚠️ tab) shows error details.

If errors appear, **zoom into the error area** for readable text:
```python
zoom(region=[error_area_x0, error_area_y0, error_area_x1, error_area_y1])
```

Since you can't click on individual errors in the Issue Navigator (too small/precise), read the error messages from the zoomed screenshots and match them to your code.

### 5. Fix Errors and Rebuild

Edit the problematic files using the `Edit` tool (not Xcode's editor — you can't type in Xcode). Then click Play again to rebuild.

### 6. Verify in the Simulator

Once the build succeeds and the app is running:

```python
open_application(app: "Simulator")
screenshot()  # See the running app
# Interact with the app — tap buttons, scroll, navigate tabs
left_click(coordinate=[button_x, button_y])
screenshot()  # Verify the result
```

The Simulator has full-tier access, so you can tap, scroll, type into text fields, and take verification screenshots.

## Common SwiftData Pitfalls and Fixes

SwiftData has several sharp edges that cause confusing compilation errors. These patterns were discovered through extensive trial and error:

### Compound #Predicate Fails to Compile

**Problem:** Multiple `&&` conditions in a `#Predicate` cause a cryptic type error:
```
Cannot convert value of type 'PredicateExpressions.Conjunction<...>' to closure result type 'any StandardPredicateExpression<Bool>'
```

**Fix:** Use a single condition in the predicate and filter the rest in memory:
```swift
// BAD — won't compile
let pred = #Predicate<UserDailyPlan> { $0.dateString == today && $0.category == "mobility" }

// GOOD — single predicate + in-memory filter
let pred = #Predicate<UserDailyPlan> { $0.dateString == today }
let descriptor = FetchDescriptor<UserDailyPlan>(predicate: pred)
let results = (try? context.fetch(descriptor)) ?? []
let mobilityOnly = results.filter { $0.category == "mobility" }
```

### Missing Explicit Type on #Predicate

**Problem:** The compiler can't infer the predicate's model type.

**Fix:** Always specify the type explicitly:
```swift
// BAD
#Predicate { $0.dateString == today }

// GOOD
#Predicate<UserDailyPlan> { $0.dateString == today }
```

### Capturing Model Properties in Predicates

**Problem:** Referencing a SwiftData model's property directly inside a predicate closure fails.

**Fix:** Extract to a local variable first:
```swift
// BAD
let pred = #Predicate<UserDailyPlan> { $0.exerciseId == exercise.id }

// GOOD
let exerciseId = exercise.id
let pred = #Predicate<UserDailyPlan> { $0.exerciseId == exerciseId }
```

### Be Careful with replace_all on Predicates

When using the `Edit` tool's `replace_all` to fix predicate types across a file, be careful — different fetch descriptors may need different predicate types. A `FetchDescriptor<DailyCheck>` needs `#Predicate<DailyCheck>`, not `#Predicate<UserDailyPlan>`. Always review the context around each predicate.

## Common SwiftUI Pitfalls

### TabView — Use the Classic Pattern

The new `Tab()` initializer with `value:` parameter (introduced in iOS 18) can cause runtime white screens even though it compiles. Use the classic `.tabItem` + `.tag()` pattern instead:

```swift
// GOOD — reliable pattern
TabView(selection: $selectedTab) {
    FirstView()
        .tabItem { Label("First", systemImage: "house") }
        .tag(0)
    SecondView()
        .tabItem { Label("Second", systemImage: "gear") }
        .tag(1)
}

// RISKY — may cause blank screen at runtime
TabView(selection: $selectedTab) {
    Tab("First", systemImage: "house", value: 0) { FirstView() }
    Tab("Second", systemImage: "gear", value: 1) { SecondView() }
}
```

## File Deletion

The Cowork sandbox blocks `rm` by default on workspace files. To delete files:

```python
# Step 1: Request permission
allow_cowork_file_delete()

# Step 2: Now rm works
bash("rm /sessions/.../mnt/Workspace/Project/Project/OldFile.swift")
```

## Simulator Data Management

When you change seed data or initialization logic, the Simulator may still have old data from a previous run. Options:

1. **Device → Erase All Content and Settings** in the Simulator menu (requires clicking through the Simulator UI, which can be tricky with window layering)
2. **Add a startup check** in your app code that detects stale data and regenerates it — this is the more robust approach. For example, check if plan entries exist for today's date, and regenerate if they don't.

## Typical Development Session Flow

```
1. Write/edit Swift files in the project folder
2. open_application("Xcode")
3. Click Stop (■) then Play (▶) in toolbar
4. Wait 15-30 seconds for compilation
5. screenshot() → check for errors
6. If errors:
   a. zoom() into error messages
   b. Edit the files to fix
   c. Go to step 3
7. If success:
   a. open_application("Simulator")
   b. screenshot() → verify the app UI
   c. Interact with the app (tap buttons, scroll, navigate)
   d. screenshot() → confirm behavior
8. Repeat from step 1 for next feature
```

## Tips for Efficiency

- **Batch file writes**: Write all related files before triggering a build, rather than building after each file.
- **Use computer_batch**: Chain stop → wait → play → wait → screenshot into a single call to save round trips.
- **Read the Xcode preview pane**: The Canvas preview on the right side of Xcode often shows the app state without needing to switch to the Simulator.
- **Zoom liberally**: Small text in Xcode screenshots (error messages, line numbers) is often unreadable — always zoom into the relevant area.
- **Keep the Simulator visible**: Position windows so the Simulator doesn't get covered by Xcode or other apps.

## Project Structure Recommendation

For a SwiftUI + SwiftData app, organize files like this:

```
ProjectName/
├── ProjectNameApp.swift       # @main entry, schema, model container, seed on appear
├── ContentView.swift           # Root view / routing logic
├── Models/
│   ├── ModelA.swift            # @Model classes
│   └── ModelB.swift
├── Views/
│   ├── MainTabView.swift       # Tab navigation
│   ├── FeatureA/
│   │   └── FeatureAView.swift
│   └── FeatureB/
│       └── FeatureBView.swift
├── Services/
│   ├── SeedData.swift          # Data seeding logic
│   ├── DateHelper.swift        # Date utilities
│   └── AppColors.swift         # Color palette
└── Assets.xcassets/            # (managed by Xcode)
```

## Date Handling for Pacific Timezone

If your app needs consistent date handling (e.g., daily plans), use a DateHelper that pins everything to a specific timezone:

```swift
struct DateHelper {
    static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    static func todayPacific() -> Date {
        var cal = Calendar.current
        cal.timeZone = pacific
        return cal.startOfDay(for: Date())
    }

    static func todayPacificString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = pacific
        return f.string(from: Date())
    }
}
```

Store dates as `"yyyy-MM-dd"` strings rather than `Date` objects when you need day-level granularity — it avoids timezone shift bugs.
