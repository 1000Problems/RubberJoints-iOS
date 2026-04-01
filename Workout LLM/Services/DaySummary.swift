import Foundation
import SwiftData

/// Computes per-category completion stats for a given date.
/// Used by both the "Today's Workout" summary card and the Week day cards.
struct DaySummary {

    struct CategoryProgress: Identifiable {
        let category: String
        let label: String
        let color: String
        let total: Int
        let done: Int
        var id: String { category }

        var fraction: Double {
            total == 0 ? 0 : Double(done) / Double(total)
        }
    }

    let dateString: String
    let dayType: String
    let dayLabel: String
    let estimatedMinutes: Int
    let categories: [CategoryProgress]

    var totalItems: Int { categories.reduce(0) { $0 + $1.total } }
    var totalDone: Int  { categories.reduce(0) { $0 + $1.done } }
    var overallFraction: Double {
        totalItems == 0 ? 0 : Double(totalDone) / Double(totalItems)
    }

    /// Build a summary from plan entries (computed from StaticPlan) and checks (from SwiftData).
    static func build(
        for dateStr: String,
        planEntries: [PlanEntry],
        checks: [DailyCheck],
        supplements: [Supplement],
        userSupplements: [UserSupplement]
    ) -> DaySummary {

        let dayChecks = checks.filter { $0.dateString == dateStr && $0.checked }
        let dayType = planEntries.first?.dayType ?? "rest"

        // Exercise categories
        let categoryOrder: [(key: String, label: String)] = [
            ("warmup_tool", "Warm-up"),
            ("mobility", "Mobility"),
            ("recovery_tool", "Recovery"),
        ]

        var cats: [CategoryProgress] = []
        for cat in categoryOrder {
            let catEntries = planEntries.filter { $0.category == cat.key }
            guard !catEntries.isEmpty else { continue }
            let done = catEntries.filter { entry in
                dayChecks.contains { $0.itemType == "step" && $0.itemId == entry.exerciseId }
            }.count
            cats.append(CategoryProgress(
                category: cat.key, label: cat.label,
                color: cat.key, total: catEntries.count, done: done
            ))
        }

        // Vitamins / Supplements
        let activeSupps = userSupplements.compactMap { us in
            supplements.first { $0.id == us.supplementId }
        }
        let suppList = activeSupps.isEmpty ? supplements : activeSupps
        if !suppList.isEmpty {
            let suppDone = suppList.filter { supp in
                dayChecks.contains { $0.itemType == "supplement" && $0.itemId == supp.id }
            }.count
            cats.append(CategoryProgress(
                category: "vitamins", label: "Vitamins",
                color: "vitamins", total: suppList.count, done: suppDone
            ))
        }

        // Day label & estimated time
        let label: String
        let minutes: Int
        switch dayType {
        case "train":
            label = "Training Session"
            minutes = max(planEntries.count * 6, 30)
        case "recovery":
            label = "Rest + Passive Recovery"
            minutes = max(planEntries.count * 8, 20)
        default:
            label = "Rest + Passive Recovery"
            minutes = max(planEntries.count * 8, 20)
        }

        return DaySummary(
            dateString: dateStr,
            dayType: dayType,
            dayLabel: label,
            estimatedMinutes: minutes,
            categories: cats
        )
    }
}
