import Foundation
import SwiftData

@Model
final class MilestoneDefinition {
    @Attribute(.unique) var id: String
    var name: String
    var milestoneDescription: String?

    init(id: String, name: String, milestoneDescription: String? = nil) {
        self.id = id
        self.name = name
        self.milestoneDescription = milestoneDescription
    }
}

@Model
final class UserMilestone {
    var milestoneId: String
    var done: Bool = false
    var achievedDate: Date?

    init(milestoneId: String, done: Bool = false, achievedDate: Date? = nil) {
        self.milestoneId = milestoneId
        self.done = done
        self.achievedDate = achievedDate
    }
}
