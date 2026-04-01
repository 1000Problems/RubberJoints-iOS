import SwiftUI
import SwiftData

struct ProgressPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allChecks: [DailyCheck]
    @Query private var milestones: [MilestoneDefinition]
    @Query private var userMilestones: [UserMilestone]
    @Query private var settings: [UserSettings]
    @Query private var overrides: [PlanOverride]
    @Query private var supplements: [Supplement]
    @Query private var userSupplements: [UserSupplement]

    private var startDate: Date {
        settings.first?.startDate ?? DateHelper.todayPacific()
    }

    private func planEntries(for dateStr: String) -> [PlanEntry] {
        var entries = StaticPlan.planEntries(for: dateStr, startDate: startDate)
        let dateOverrides = overrides.filter { $0.dateString == dateStr }
        let removedIds = Set(dateOverrides.filter { $0.action == "remove" }.map(\.exerciseId))
        entries.removeAll { removedIds.contains($0.exerciseId) }
        let adds = dateOverrides.filter { $0.action == "add" }
        for add in adds {
            let dayType = entries.first?.dayType ?? StaticPlan.dayType(for: dateStr, startDate: startDate)
            entries.append(PlanEntry(
                dateString: dateStr, dayType: dayType,
                exerciseId: add.exerciseId, category: add.category,
                sortOrder: add.sortOrder, rx: add.rx
            ))
        }
        return entries
    }

    /// Days this week that have at least one checked item
    private var thisWeekActiveDays: Int {
        let weekDates = DateHelper.weekDates(containing: DateHelper.todayPacificString())
        let weekSet = Set(weekDates)
        let checkedDates = Set(allChecks.filter { $0.checked }.map(\.dateString))
        return weekSet.intersection(checkedDates).count
    }

    private var currentStreak: Int {
        let today = DateHelper.todayPacificString()
        var streak = 0
        var checkDate = today

        if hasChecks(on: checkDate) {
            streak = 1
        } else {
            if let date = DateHelper.parseDate(checkDate) {
                checkDate = DateHelper.formatDate(DateHelper.addDays(-1, to: date))
            }
        }

        while true {
            guard let date = DateHelper.parseDate(checkDate) else { break }
            let prevDate = DateHelper.formatDate(DateHelper.addDays(-1, to: date))
            if hasChecks(on: prevDate) {
                streak += 1
                checkDate = prevDate
            } else {
                break
            }
        }

        return streak
    }

    private func hasChecks(on dateStr: String) -> Bool {
        allChecks.contains { $0.dateString == dateStr && $0.checked }
    }

    /// Total unique days with any checked exercise (lifetime)
    private var lifetimeSessions: Int {
        let exerciseChecks = allChecks.filter { $0.checked && $0.itemType == "step" }
        return Set(exerciseChecks.map(\.dateString)).count
    }

    /// Vitamins completion percentage for today
    private var todayVitamins: Double {
        let activeSupplementIds = Set(userSupplements.map(\.supplementId))
        let totalVitamins = activeSupplementIds.count
        guard totalVitamins > 0 else { return 0 }
        let todayStr = DateHelper.todayPacificString()
        let vitaminChecks = allChecks.filter {
            $0.dateString == todayStr && $0.itemType == "supplement" && $0.checked
        }
        let done = vitaminChecks.filter { activeSupplementIds.contains($0.itemId) }.count
        return Double(min(done, totalVitamins)) / Double(totalVitamins) * 100
    }

    private var todayCompletion: Double {
        let todayStr = DateHelper.todayPacificString()
        let entries = planEntries(for: todayStr)
        let total = entries.count
        guard total > 0 else { return 0 }
        let done = allChecks.filter { $0.dateString == todayStr && $0.checked }.count
        return Double(done) / Double(total) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week indicator
                    HStack {
                        Text("Week \(DateHelper.currentWeek(startDate: startDate)) of 4")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }

                    // 2x2 stat grid
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        StatCard(title: "This Week", value: "\(thisWeekActiveDays)", subtitle: "sessions", icon: "calendar", color: .accent)
                        StatCard(title: "Lifetime", value: "\(lifetimeSessions)", subtitle: "sessions", icon: "flame.fill", color: .warning)
                        StatCard(title: "Today", value: "\(Int(todayCompletion))%", subtitle: "complete", icon: "checkmark.circle", color: .success)
                        StatCard(title: "Vitamins", value: "\(Int(todayVitamins))%", subtitle: "taken", icon: "pill.fill", color: .appPurple)
                    }

                    ActivityHeatmap(startDate: startDate, overrides: overrides)

                    WeeklyCompletionChart(startDate: startDate, overrides: overrides)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Milestones")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            let achieved = userMilestones.filter(\.done).count
                            Text("\(achieved)/\(milestones.count)")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }

                        ForEach(milestones, id: \.id) { milestone in
                            MilestoneRow(
                                milestone: milestone,
                                userMilestone: userMilestones.first { $0.milestoneId == milestone.id }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBg)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    var icon: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surface1)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Activity Heatmap

struct ActivityHeatmap: View {
    @Environment(\.modelContext) private var modelContext
    let startDate: Date
    let overrides: [PlanOverride]

    private var last28Days: [String] {
        let today = DateHelper.todayPacific()
        return (0..<28).reversed().map { offset in
            DateHelper.formatDate(DateHelper.addDays(-offset, to: today))
        }
    }

    private func completionFor(_ dateStr: String) -> Double {
        var entries = StaticPlan.planEntries(for: dateStr, startDate: startDate)
        let dateOverrides = overrides.filter { $0.dateString == dateStr }
        let removedIds = Set(dateOverrides.filter { $0.action == "remove" }.map(\.exerciseId))
        entries.removeAll { removedIds.contains($0.exerciseId) }
        entries += dateOverrides.filter { $0.action == "add" }.map { add in
            PlanEntry(dateString: dateStr, dayType: "train",
                      exerciseId: add.exerciseId, category: add.category,
                      sortOrder: add.sortOrder, rx: add.rx)
        }
        let total = entries.count
        guard total > 0 else { return -1 }

        let checkDescriptor = FetchDescriptor<DailyCheck>(
            predicate: #Predicate<DailyCheck> { $0.dateString == dateStr }
        )
        let checks = (try? modelContext.fetch(checkDescriptor)) ?? []
        let done = checks.filter(\.checked).count
        return Double(done) / Double(total)
    }

    private func colorFor(_ completion: Double) -> Color {
        if completion < 0 { return Color.surface2 }
        if completion == 0 { return Color.surface3 }
        if completion < 0.5 { return Color.success.opacity(0.3) }
        if completion < 1.0 { return Color.success.opacity(0.6) }
        return Color.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(last28Days, id: \.self) { dateStr in
                    let completion = completionFor(dateStr)
                    let isToday = dateStr == DateHelper.todayPacificString()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorFor(completion))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isToday ? Color.accent : Color.clear, lineWidth: 2)
                        )
                        .overlay {
                            Text(DateHelper.dayNumber(dateStr))
                                .font(.system(size: 9))
                                .foregroundColor(completion >= 0.5 ? .white : .textMuted)
                        }
                }
            }

            HStack(spacing: 12) {
                legendItem(color: Color.surface2, label: "Rest")
                legendItem(color: Color.surface3, label: "None")
                legendItem(color: Color.success.opacity(0.3), label: "Some")
                legendItem(color: Color.success, label: "Done")
            }
            .font(.caption2)
            .foregroundColor(.textMuted)
        }
        .padding()
        .background(Color.surface1)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }
}

// MARK: - Weekly Completion Chart

struct WeeklyCompletionChart: View {
    @Environment(\.modelContext) private var modelContext
    let startDate: Date
    let overrides: [PlanOverride]

    private struct WeekData: Identifiable {
        let id: Int
        let label: String
        let completion: Double
    }

    private func planCount(for dateStr: String) -> Int {
        var entries = StaticPlan.planEntries(for: dateStr, startDate: startDate)
        let dateOverrides = overrides.filter { $0.dateString == dateStr }
        let removedIds = Set(dateOverrides.filter { $0.action == "remove" }.map(\.exerciseId))
        entries.removeAll { removedIds.contains($0.exerciseId) }
        return entries.count + dateOverrides.filter { $0.action == "add" }.count
    }

    private var weekData: [WeekData] {
        let today = DateHelper.todayPacific()
        return (0..<4).reversed().map { weekOffset in
            let weekStart = DateHelper.addDays(-weekOffset * 7, to: today)
            let weekDates = DateHelper.weekDates(containing: DateHelper.formatDate(weekStart))
            var totalExercises = 0
            var totalDone = 0

            for dateStr in weekDates {
                totalExercises += planCount(for: dateStr)
                let checkDescriptor = FetchDescriptor<DailyCheck>(
                    predicate: #Predicate<DailyCheck> { $0.dateString == dateStr }
                )
                let checks = (try? modelContext.fetch(checkDescriptor)) ?? []
                totalDone += checks.filter(\.checked).count
            }

            let pct = totalExercises > 0 ? Double(totalDone) / Double(totalExercises) : 0
            let label = weekOffset == 0 ? "This Week" : "\(weekOffset)w ago"
            return WeekData(id: weekOffset, label: label, completion: pct)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weekData) { week in
                    VStack(spacing: 6) {
                        Text("\(Int(week.completion * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.textSecondary)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accent.opacity(0.6), Color.accent],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(4, CGFloat(week.completion) * 100))

                        Text(week.label)
                            .font(.caption2)
                            .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.surface1)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    @Environment(\.modelContext) private var modelContext
    let milestone: MilestoneDefinition
    let userMilestone: UserMilestone?

    @State private var isExpanded = false

    private var isDone: Bool {
        userMilestone?.done ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row — always visible
            HStack(spacing: 12) {
                Button {
                    toggleMilestone()
                } label: {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isDone ? .gold : .textMuted)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDone ? .textMuted : .textPrimary)
                        .strikethrough(isDone)
                    Text(isDone ? "Achieved \(userMilestone?.achievedDate.map { DateHelper.formatDate($0) } ?? "")" : "Not yet")
                        .font(.caption)
                        .foregroundColor(isDone ? .gold : .textMuted)
                }

                Spacer()

                // Done button (matches web app)
                Button {
                    toggleMilestone()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.success)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.success.opacity(0.1))
                        .cornerRadius(8)
                }

                // Expand chevron — right when collapsed, down when expanded
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .padding()

            // Expanded detail
            if isExpanded, let desc = milestone.milestoneDescription {
                Divider()
                    .padding(.horizontal)

                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .background(Color.surface1)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func toggleMilestone() {
        if let existing = userMilestone {
            existing.done.toggle()
            existing.achievedDate = existing.done ? Date() : nil
        } else {
            let um = UserMilestone(milestoneId: milestone.id, done: true, achievedDate: Date())
            modelContext.insert(um)
        }
        try? modelContext.save()
    }
}
