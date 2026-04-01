import Foundation
import SwiftData

@Model
final class UserSupplement {
    var supplementId: String
    var timeGroup: String            // "am", "mid", "pm"
    var addedDate: Date = Date()

    init(supplementId: String, timeGroup: String) {
        self.supplementId = supplementId
        self.timeGroup = timeGroup
        self.addedDate = Date()
    }
}
