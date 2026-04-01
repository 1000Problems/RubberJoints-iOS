import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var category: String          // "warmup_tool", "mobility", "recovery_tool"
    var targets: String?
    var exerciseDescription: String?
    var cues: String?
    var explanation: String?
    var warning: String?
    var phases: String?           // "1,2"
    var defaultRx: String?

    init(id: String, name: String, category: String, targets: String? = nil,
         exerciseDescription: String? = nil, cues: String? = nil,
         explanation: String? = nil, warning: String? = nil,
         phases: String? = nil, defaultRx: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.targets = targets
        self.exerciseDescription = exerciseDescription
        self.cues = cues
        self.explanation = explanation
        self.warning = warning
        self.phases = phases
        self.defaultRx = defaultRx
    }

    var isPhase1: Bool {
        guard let p = phases else { return true }
        return p.contains("1")
    }

    var isPhase2: Bool {
        guard let p = phases else { return true }
        return p.contains("2")
    }

    var categoryDisplayName: String {
        switch category {
        case "warmup_tool": return "Warm-Up"
        case "mobility": return "Mobility"
        case "recovery_tool": return "Recovery"
        default: return category.capitalized
        }
    }
}
