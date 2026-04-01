import Foundation
import SwiftData

@Model
final class UserDailyPlan {
    var dateString: String           // "yyyy-MM-dd" in Pacific time
    var dayType: String              // "train", "recovery", "rest"
    var exerciseId: String
    var category: String
    var sortOrder: Int
    var rx: String?
    var aiAdjusted: Bool = false
    var isManual: Bool = false

    init(dateString: String, dayType: String, exerciseId: String,
         category: String, sortOrder: Int, rx: String? = nil,
         aiAdjusted: Bool = false, isManual: Bool = false) {
        self.dateString = dateString
        self.dayType = dayType
        self.exerciseId = exerciseId
        self.category = category
        self.sortOrder = sortOrder
        self.rx = rx
        self.aiAdjusted = aiAdjusted
        self.isManual = isManual
    }

    var dayTypeDisplayName: String {
        switch dayType {
        case "train", "gym", "home": return "Training"
        case "recovery": return "Recovery"
        case "rest": return "Rest"
        default: return dayType.capitalized
        }
    }
}
