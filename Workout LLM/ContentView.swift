import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self, Supplement.self, UserPreferences.self,
            UserSettings.self, DailyCheck.self,
            UserSupplement.self, SessionLog.self, MilestoneDefinition.self,
            UserMilestone.self, Program.self, ChatMessage.self,
            UserEnrollment.self, PlanOverride.self,
        ], inMemory: true)
}
