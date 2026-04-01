import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: String = "default"
    var startDate: Date?
    var disabledTools: String = ""    // CSV of disabled exercise IDs

    init(id: String = "default") {
        self.id = id
    }

    var disabledToolIds: [String] {
        get {
            disabledTools.isEmpty ? [] :
                disabledTools.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            disabledTools = newValue.joined(separator: ",")
        }
    }

    func isDisabled(_ exerciseId: String) -> Bool {
        disabledToolIds.contains(exerciseId)
    }
}
