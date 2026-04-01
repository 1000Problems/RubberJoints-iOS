import SwiftUI
import SwiftData

@main
struct Workout_LLMApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Supplement.self,
            UserPreferences.self,
            UserSettings.self,
            UserEnrollment.self,
            DailyCheck.self,
            UserSupplement.self,
            SessionLog.self,
            MilestoneDefinition.self,
            UserMilestone.self,
            Program.self,
            ChatMessage.self,
            PlanOverride.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Lightweight one-time seeding — only seeds supplements, milestones,
                    // settings, and preferences if they don't exist yet. No plan inserts.
                    // Runs on background thread so first frame renders instantly.
                    let container = sharedModelContainer
                    await Task.detached(priority: .utility) {
                        let bgContext = ModelContext(container)
                        bgContext.autosaveEnabled = false
                        SeedData.ensureDataExists(context: bgContext)
                    }.value
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
