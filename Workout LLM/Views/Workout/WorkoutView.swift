import SwiftUI
import SwiftData

extension Foundation.Notification.Name {
    static let firstExerciseChecked = Foundation.Notification.Name("firstExerciseChecked")
}

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var preferences: [UserPreferences]
    @Query private var allSupplements: [Supplement]
    @Query private var userSupplements: [UserSupplement]
    @Query private var allChecks: [DailyCheck]
    @Query private var overrides: [PlanOverride]

    @State private var selectedDateStr: String = DateHelper.todayPacificString()
    @State private var showingExercisePicker = false
    @State private var pickerCategory: String = "warmup_tool"
    @State private var selectedExerciseEntry: PlanEntry?
    @State private var showReminderPrompt = false
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications = false

    private var todayStr: String { DateHelper.todayPacificString() }

    private var currentStreak: Int {
        var streak = 0
        var checkDate = todayStr

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

    private var weekDates: [String] {
        DateHelper.weekDates(containing: selectedDateStr)
    }

    private var startDate: Date {
        settings.first?.startDate ?? DateHelper.todayPacific()
    }

    /// Compute today's plan from StaticPlan + user overrides. Zero database reads for the plan.
    private func planEntries(for dateStr: String) -> [PlanEntry] {
        var entries = StaticPlan.planEntries(for: dateStr, startDate: startDate)

        // Apply overrides for this date
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

        return entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var currentPlanEntries: [PlanEntry] {
        planEntries(for: selectedDateStr)
    }

    private var daySummary: DaySummary {
        DaySummary.build(
            for: selectedDateStr,
            planEntries: currentPlanEntries,
            checks: allChecks,
            supplements: allSupplements,
            userSupplements: userSupplements
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dayNavigationBar
                    todaySummaryCard
                    calendarStrip
                    dayLabel
                    exerciseSections
                    supplementSections
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color.appBg)
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet(
                    category: pickerCategory,
                    dateString: selectedDateStr,
                    existingExerciseIds: Set(currentPlanEntries.map(\.exerciseId))
                )
            }
            .onReceive(Foundation.NotificationCenter.default.publisher(for: .firstExerciseChecked)) { _ in
                if !hasPromptedForNotifications {
                    hasPromptedForNotifications = true
                    // Small delay so the check animation finishes first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showReminderPrompt = true
                    }
                }
            }
            .alert("Stay on track?", isPresented: $showReminderPrompt) {
                Button("Enable Reminders") {
                    NotificationHelper.requestPermission { granted in
                        if granted {
                            NotificationHelper.scheduleDailyReminder(hour: 8, minute: 0)
                        }
                    }
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Nice work on your first exercise! Want a daily reminder so you never miss a session? You can change the time in Settings.")
            }
            .sheet(item: $selectedExerciseEntry) { entry in
                ExerciseDetailSheet(
                    entry: entry,
                    isToday: selectedDateStr == todayStr,
                    onSwap: {
                        pickerCategory = entry.category
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingExercisePicker = true
                        }
                    }
                )
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Today's Workout Summary Card

    private var todaySummaryCard: some View {
        let summary = daySummary
        let dayName = DateHelper.dayOfWeekName(selectedDateStr)

        return VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S WORKOUT")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.textMuted)
                .tracking(1.5)

            Text("\(dayName) · \(summary.dayLabel)")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            if !summary.categories.isEmpty {
                VStack(spacing: 10) {
                    ForEach(summary.categories) { cat in
                        CategoryProgressBar(category: cat)
                    }
                }
            }
        }
        .padding()
        .background(Color.surface1)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Day Navigation

    private var dayNavigationBar: some View {
        HStack {
            Button {
                navigateDay(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accent)
            }

            Spacer()

            // Streak counter
            if currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.warning)
                    Text("\(currentStreak)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.warning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.warning.opacity(0.12))
                .cornerRadius(12)
            }

            Button {
                selectedDateStr = todayStr
            } label: {
                Text("Today")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accent)
            }

            Spacer()

            Button {
                navigateDay(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accent)
            }
        }
        .padding(.top, 8)
    }

    private var calendarStrip: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { dateStr in
                VStack(spacing: 4) {
                    Text(DateHelper.shortDayName(dateStr))
                        .font(.caption2)
                        .foregroundColor(dateStr == selectedDateStr ? .white : .textMuted)
                    Text(DateHelper.dayNumber(dateStr))
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(dateStr == selectedDateStr ? .white :
                                            dateStr == todayStr ? .success : .textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(dateStr == selectedDateStr ? Color.accent : Color.clear)
                )
                .onTapGesture {
                    selectedDateStr = dateStr
                }
            }
        }
    }

    private var dayLabel: some View {
        let entries = currentPlanEntries
        let dayName = DateHelper.dayOfWeekName(selectedDateStr)
        let dayType = entries.first?.dayTypeDisplayName ?? "Rest"

        return HStack {
            Text(dayName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            Text("·")
                .foregroundColor(.textMuted)
            Text(dayType)
                .font(.title3)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    // MARK: - Exercise Sections

    private var exerciseSections: some View {
        let entries = currentPlanEntries
        let grouped = Dictionary(grouping: entries) { $0.category }
        let categoryOrder = ["warmup_tool", "mobility", "recovery_tool"]
        let dayType = entries.first?.dayType ?? "rest"

        return Group {
            // Completion banner (today only, all done)
            if selectedDateStr == todayStr && !entries.isEmpty {
                let checks = allChecks.filter { $0.dateString == selectedDateStr && $0.checked }
                if checks.count >= entries.count {
                    allDoneBanner
                }
            }

            // Rest/Recovery day card
            if entries.isEmpty || dayType == "rest" {
                restDayCard(dayType: dayType)
            }

            ForEach(categoryOrder, id: \.self) { category in
                if let catEntries = grouped[category], !catEntries.isEmpty {
                    CategorySectionView(
                        category: category,
                        entries: catEntries,
                        dateString: selectedDateStr,
                        isToday: selectedDateStr == todayStr,
                        isFuture: selectedDateStr > todayStr,
                        onExerciseTapped: { entry in
                            selectedExerciseEntry = entry
                        },
                        onAddTapped: {
                            pickerCategory = category
                            showingExercisePicker = true
                        }
                    )
                }
            }
        }
    }

    // MARK: - Rest Day Card

    private func restDayCard(dayType: String) -> some View {
        let isRecovery = dayType == "recovery"
        let icon = isRecovery ? "bed.double.fill" : "leaf.fill"
        let title = isRecovery ? "Recovery Day" : "Rest Day"
        let tips = isRecovery ? [
            "Focus on foam rolling and gentle stretching",
            "Stay hydrated — aim for half your body weight in ounces",
            "Prioritize 7-9 hours of quality sleep tonight",
            "Light walking helps flush metabolic waste",
        ] : [
            "Your joints heal and adapt during rest",
            "Light mobility keeps synovial fluid flowing",
            "Hydrate well — cartilage is 80% water",
            "Sleep is when the real repair happens",
        ]
        let tip = tips[abs(selectedDateStr.hashValue) % tips.count]

        return VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(isRecovery ? .appPurple : .success)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.surface1)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - All Done Banner

    private var allDoneBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .foregroundColor(.gold)
            Text("All exercises complete!")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "star.fill")
                .foregroundColor(.gold)
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.gold.opacity(0.15), Color.gold.opacity(0.05)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(12)
    }

    // MARK: - Supplement Sections

    private var supplementSections: some View {
        let activeSupps = userSupplements.compactMap { us in
            allSupplements.first { $0.id == us.supplementId }
        }
        let grouped = Dictionary(grouping: activeSupps) { $0.timeGroup }
        let groupOrder = ["am", "mid", "pm"]
        let groupNames = ["am": "Morning", "mid": "Midday", "pm": "Evening"]

        return ForEach(groupOrder, id: \.self) { group in
            if let supps = grouped[group], !supps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "pill.fill")
                            .foregroundColor(.appPurple)
                        Text(groupNames[group] ?? group)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.top, 8)

                    ForEach(supps, id: \.id) { supp in
                        SupplementRowView(
                            supplement: supp,
                            dateString: selectedDateStr,
                            isToday: selectedDateStr == todayStr
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func navigateDay(_ offset: Int) {
        if let date = DateHelper.parseDate(selectedDateStr) {
            let newDate = DateHelper.addDays(offset, to: date)
            selectedDateStr = DateHelper.formatDate(newDate)
        }
    }

}

// MARK: - Shared Progress Bar

struct CategoryProgressBar: View {
    let category: DaySummary.CategoryProgress

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.categoryColor(category.color))
                .frame(width: 8, height: 8)
            Text(category.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surface3)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.categoryColor(category.color))
                        .frame(width: geo.size.width * category.fraction, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: category.done)
                }
            }
            .frame(height: 8)

            Text("\(category.done)/\(category.total)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

// MARK: - Category Section

struct CategorySectionView: View {
    let category: String
    let entries: [PlanEntry]
    let dateString: String
    let isToday: Bool
    let isFuture: Bool
    var onExerciseTapped: ((PlanEntry) -> Void)?
    let onAddTapped: () -> Void

    private var categoryName: String {
        switch category {
        case "warmup_tool": return "Warm-Up"
        case "mobility": return "Mobility"
        case "recovery_tool": return "Recovery"
        default: return category.capitalized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.categoryColor(category))
                    .frame(width: 10, height: 10)
                Text(categoryName)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text("(\(entries.count))")
                    .font(.subheadline)
                    .foregroundColor(.textMuted)
                Spacer()
                if isToday {
                    Button {
                        onAddTapped()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.categoryColor(category))
                    }
                }
            }

            ForEach(entries, id: \.exerciseId) { entry in
                ExerciseRowView(
                    entry: entry,
                    dateString: dateString,
                    isToday: isToday,
                    isFuture: isFuture
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onExerciseTapped?(entry)
                }
            }
        }
        .padding()
        .background(Color.surface1)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Exercise Row

struct ExerciseRowView: View {
    @Environment(\.modelContext) private var modelContext
    let entry: PlanEntry
    let dateString: String
    let isToday: Bool
    let isFuture: Bool

    @State private var isChecked: Bool = false

    private var exerciseName: String {
        ExerciseCatalog.name(entry.exerciseId)
    }

    private var exerciseTargets: String {
        ExerciseCatalog.targets(entry.exerciseId)
    }

    var body: some View {
        HStack(spacing: 12) {
            if isToday {
                Button {
                    toggleCheck()
                } label: {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isChecked ? .success : .textMuted)
                }
            } else if !isFuture {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .success : .textMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseName)
                    .font(.body)
                    .foregroundColor(isChecked ? .textMuted : .textPrimary)
                    .strikethrough(isChecked)
                if !exerciseTargets.isEmpty {
                    Text(exerciseTargets)
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
            }

            Spacer()

            Text(entry.rx)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.surface2)
                .cornerRadius(6)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 4)
        .onAppear { loadCheckState() }
    }

    private func loadCheckState() {
        let dateStr = dateString
        let descriptor = FetchDescriptor<DailyCheck>(
            predicate: #Predicate<DailyCheck> { $0.dateString == dateStr }
        )
        let checks = (try? modelContext.fetch(descriptor)) ?? []
        if let check = checks.first(where: { $0.itemType == "step" && $0.itemId == entry.exerciseId }) {
            isChecked = check.checked
        }
    }

    private func toggleCheck() {
        isChecked.toggle()
        let dateStr = dateString
        let descriptor = FetchDescriptor<DailyCheck>(
            predicate: #Predicate<DailyCheck> { $0.dateString == dateStr }
        )
        let checks = (try? modelContext.fetch(descriptor)) ?? []
        if let existing = checks.first(where: { $0.itemType == "step" && $0.itemId == entry.exerciseId }) {
            existing.checked = isChecked
        } else {
            let check = DailyCheck(dateString: dateString, itemType: "step", itemId: entry.exerciseId, checked: isChecked)
            modelContext.insert(check)
        }
        try? modelContext.save()

        // Trigger reminder prompt after first exercise checked
        if isChecked {
            Foundation.NotificationCenter.default.post(name: .firstExerciseChecked, object: nil)
        }
    }
}

// MARK: - Supplement Row

struct SupplementRowView: View {
    @Environment(\.modelContext) private var modelContext
    let supplement: Supplement
    let dateString: String
    let isToday: Bool

    @State private var isChecked: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if isToday {
                Button {
                    toggleCheck()
                } label: {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isChecked ? .appPurple : .textMuted)
                }
            } else {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .appPurple : .textMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(.body)
                    .foregroundColor(isChecked ? .textMuted : .textPrimary)
                    .strikethrough(isChecked)
                if let dose = supplement.dose {
                    Text(dose)
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
            }

            Spacer()

            if let time = supplement.time {
                Text(time)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(Color.surface1)
        .cornerRadius(8)
        .onAppear { loadCheckState() }
    }

    private func loadCheckState() {
        let dateStr = dateString
        let descriptor = FetchDescriptor<DailyCheck>(
            predicate: #Predicate<DailyCheck> { $0.dateString == dateStr }
        )
        let checks = (try? modelContext.fetch(descriptor)) ?? []
        if let check = checks.first(where: { $0.itemType == "supplement" && $0.itemId == supplement.id }) {
            isChecked = check.checked
        }
    }

    private func toggleCheck() {
        isChecked.toggle()
        let dateStr = dateString
        let descriptor = FetchDescriptor<DailyCheck>(
            predicate: #Predicate<DailyCheck> { $0.dateString == dateStr }
        )
        let checks = (try? modelContext.fetch(descriptor)) ?? []
        if let existing = checks.first(where: { $0.itemType == "supplement" && $0.itemId == supplement.id }) {
            existing.checked = isChecked
        } else {
            let check = DailyCheck(dateString: dateString, itemType: "supplement", itemId: supplement.id, checked: isChecked)
            modelContext.insert(check)
        }
        try? modelContext.save()
    }
}
