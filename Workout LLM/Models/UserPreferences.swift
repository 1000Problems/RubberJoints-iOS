import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var id: String = "default"
    var hasGym: Bool = false
    var daysPerWeek: Int = 5
    var onboardingStep: Int = 0       // 0-7 state machine
    var selectedExercises: String = "" // CSV of exercise IDs
    var selectedSupplements: String = "" // CSV of supplement IDs
    var profileNotes: String = ""     // AI-gathered user profile

    init(id: String = "default") {
        self.id = id
    }

    var selectedExerciseIds: [String] {
        get {
            selectedExercises.isEmpty ? [] :
                selectedExercises.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            selectedExercises = newValue.joined(separator: ",")
        }
    }

    var selectedSupplementIds: [String] {
        get {
            selectedSupplements.isEmpty ? [] :
                selectedSupplements.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            selectedSupplements = newValue.joined(separator: ",")
        }
    }

    var isOnboardingComplete: Bool {
        onboardingStep >= 7
    }
}
