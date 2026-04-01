import Foundation
import SwiftData

@Model
final class Supplement {
    @Attribute(.unique) var id: String
    var name: String
    var dose: String?
    var time: String?
    var timeGroup: String         // "am", "mid", "pm"

    init(id: String, name: String, dose: String? = nil,
         time: String? = nil, timeGroup: String) {
        self.id = id
        self.name = name
        self.dose = dose
        self.time = time
        self.timeGroup = timeGroup
    }

    var timeGroupDisplayName: String {
        switch timeGroup {
        case "am": return "Morning"
        case "mid": return "Midday"
        case "pm": return "Evening"
        default: return timeGroup.uppercased()
        }
    }
}
