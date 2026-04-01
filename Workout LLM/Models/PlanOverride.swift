import Foundation
import SwiftData

/// Stores user modifications to the static plan (add/remove exercises).
/// Tiny table — only created when user explicitly swaps or removes an exercise.
@Model
final class PlanOverride {
    var dateString: String       // "yyyy-MM-dd"
    var exerciseId: String
    var action: String           // "add" or "remove"
    var category: String
    var sortOrder: Int
    var rx: String

    init(dateString: String, exerciseId: String, action: String,
         category: String = "", sortOrder: Int = 0, rx: String = "") {
        self.dateString = dateString
        self.exerciseId = exerciseId
        self.action = action
        self.category = category
        self.sortOrder = sortOrder
        self.rx = rx
    }
}
