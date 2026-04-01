import Foundation

/// Lightweight value type for a single exercise in the daily plan.
/// NOT a SwiftData model — computed at runtime from StaticPlan.
struct PlanEntry: Identifiable, Hashable {
    let dateString: String
    let dayType: String          // "train", "recovery", "rest"
    let exerciseId: String
    let category: String
    let sortOrder: Int
    let rx: String

    var id: String { "\(dateString)-\(exerciseId)" }

    var dayTypeDisplayName: String {
        switch dayType {
        case "train", "gym", "home": return "Training"
        case "recovery": return "Recovery"
        case "rest": return "Rest"
        default: return dayType.capitalized
        }
    }
}
