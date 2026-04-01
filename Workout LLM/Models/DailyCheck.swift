import Foundation
import SwiftData

@Model
final class DailyCheck {
    var dateString: String           // "yyyy-MM-dd" in Pacific time
    var itemType: String             // "step" or "supplement"
    var itemId: String               // exercise or supplement ID
    var stepIndex: Int = 0
    var checked: Bool = false

    init(dateString: String, itemType: String, itemId: String,
         stepIndex: Int = 0, checked: Bool = false) {
        self.dateString = dateString
        self.itemType = itemType
        self.itemId = itemId
        self.stepIndex = stepIndex
        self.checked = checked
    }
}
