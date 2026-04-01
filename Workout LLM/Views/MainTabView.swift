import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 1  // Default to Workout tab

    var body: some View {
        TabView(selection: $selectedTab) {
            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }
                .tag(0)

            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.walk")
                }
                .tag(1)

            WeekView()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
                .tag(2)

            ProgressPageView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.accent)
    }
}

#Preview {
    MainTabView()
}
