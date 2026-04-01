import Foundation
import SwiftData

@Model
final class SessionLog {
    var dateString: String           // "yyyy-MM-dd" in Pacific time
    var stepsDone: Int = 0
    var stepsTotal: Int = 0

    init(dateString: String, stepsDone: Int, stepsTotal: Int) {
        self.dateString = dateString
        self.stepsDone = stepsDone
        self.stepsTotal = stepsTotal
    }

    var completionPercent: Double {
        guard stepsTotal > 0 else { return 0 }
        return Double(stepsDone) / Double(stepsTotal) * 100
    }
}
