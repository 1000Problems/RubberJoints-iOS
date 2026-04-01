import Foundation
import SwiftData

@Model
final class UserEnrollment {
    var programId: Int = 1
    var startDate: Date
    var status: String = "active"    // "active", "completed", "paused"

    init(programId: Int = 1, startDate: Date, status: String = "active") {
        self.programId = programId
        self.startDate = startDate
        self.status = status
    }

    var isActive: Bool {
        status == "active"
    }
}
