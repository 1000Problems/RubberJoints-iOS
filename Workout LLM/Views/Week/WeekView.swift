import SwiftUI
import SwiftData

struct WeekView: View {
    @Query private var settings: [UserSettings]
    @Query private var allChecks: [DailyCheck]
    @Query private var allSupplements: [Supplement]
    @Query private var userSupplements: [UserSupplement]
    @Query private var overrides: [PlanOverride]

    @State private var weekOffset: Int = 0

    private var startDate: Date {
        settings.first?.startDate ?? DateHelper.todayPacific()
    }

    private var currentWeekStart: Date {
        let today = DateHelper.todayPacific()
        return DateHelper.addDays(weekOffset * 7, to: today)
    }

    private var weekDates: [String] {
        let todayStr = DateHelper.formatDate(currentWeekStart)
        return DateHelper.weekDates(containing: todayStr)
    }

    private var weekNumber: Int {
        let days = DateHelper.daysBetween(start: startDate, end: weekDates.first ?? DateHelper.todayPacificString())
        return min(max((days / 7) + 1, 1), 4)
    }

    /// Compute plan entries for a date, applying user overrides.
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
        return entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    Text("WEEKLY ACTIVITY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.accent)
                        .tracking(1.5)

                    Text("Week \(weekNumber) of 4")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.surface2)
                        .cornerRadius(12)

                    // Week navigation
                    HStack(spacing: 24) {
                        Button {
                            weekOffset -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.accent)
                                .padding(8)
                                .background(Color.surface2)
                                .clipShape(Circle())
                        }

                        Button {
                            weekOffset += 1
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.accent)
                                .padding(8)
                                .background(Color.surface2)
                                .clipShape(Circle())
                        }
                    }

                    // Day cards
                    ForEach(weekDates, id: \.self) { dateStr in
                        let entries = planEntries(for: dateStr)
                        let summary = DaySummary.build(
                            for: dateStr,
                            planEntries: entries,
                            checks: allChecks,
                            supplements: allSupplements,
                            userSupplements: userSupplements
                        )
                        WeekDayCard(dateString: dateStr, summary: summary)
                    }
                }
                .padding()
            }
            .background(Color.appBg)
            .navigationTitle("Week")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WeekDayCard: View {
    let dateString: String
    let summary: DaySummary

    private var isToday: Bool {
        dateString == DateHelper.todayPacificString()
    }

    private var shortDay: String {
        DateHelper.shortDayName(dateString).capitalized
    }

    private var monthDay: String {
        guard let date = DateHelper.parseDate(dateString) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = DateHelper.pacificTimeZone
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Text(shortDay)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isToday ? .accent : .textPrimary)
                    if isToday {
                        Text("(Today)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.accent)
                    }
                }
                Spacer()
                Text(monthDay)
                    .font(.subheadline)
                    .foregroundColor(.textMuted)
            }

            Text("\(summary.dayLabel) · ~\(summary.estimatedMinutes) min")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            if !summary.categories.isEmpty {
                VStack(spacing: 8) {
                    ForEach(summary.categories) { cat in
                        HStack(spacing: 8) {
                            Text(cat.label)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.categoryColor(cat.color))
                                .frame(width: 70, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.surface3)
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.categoryColor(cat.color))
                                        .frame(width: geo.size.width * cat.fraction, height: 8)
                                        .animation(.easeInOut(duration: 0.3), value: cat.done)
                                }
                            }
                            .frame(height: 8)

                            Text("\(cat.done)/\(cat.total)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textSecondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.surface1)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isToday ? Color.accent : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
