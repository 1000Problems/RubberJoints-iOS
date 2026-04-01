import Foundation
import SwiftData

struct SeedData {

    // MARK: - Default no-gym exercise IDs

    static let defaultExerciseIds: [String] = [
        "brisk-walking", "arm-circles", "leg-swings", "glute-bridges", "marching-in-place",
        "cars-routine", "90-90-hip-switch", "cat-cow", "wall-slides", "bird-dog",
        "doorway-chest-stretch", "shinbox-getup", "worlds-greatest-stretch",
        "deep-squat-hold", "couch-stretch", "wall-ankle-mob", "open-book",
        "quadruped-rocking", "hip-flexor-pails-rails", "90-90-pails-rails", "ankle-pails-rails",
        "quality-sleep", "hydration", "foam-roller", "tennis-ball-release",
        "lacrosse-ball", "active-recovery-walk", "contrast-shower", "epsom-bath",
        "yoga-cooldown", "self-massage", "massage-gun",
    ]

    /// Ensures settings, preferences, supplements, milestones, and program exist.
    /// NO plan inserts — the plan comes from StaticPlan at render time.
    static func ensureDataExists(context: ModelContext) {
        ensureSettingsExist(context: context)
        seedSupplementsIfNeeded(context: context)
        seedMilestonesIfNeeded(context: context)
        seedProgramIfNeeded(context: context)
    }

    // MARK: - Settings & Preferences (created once)

    private static func ensureSettingsExist(context: ModelContext) {
        // Settings
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if (try? context.fetchCount(settingsDescriptor)) == 0 {
            let settings = UserSettings(id: "default")
            settings.startDate = DateHelper.todayPacific()
            context.insert(settings)
        }

        // Preferences
        let prefsDescriptor = FetchDescriptor<UserPreferences>()
        if (try? context.fetchCount(prefsDescriptor)) == 0 {
            let prefs = UserPreferences(id: "default")
            prefs.selectedExerciseIds = defaultExerciseIds
            prefs.daysPerWeek = 5
            prefs.onboardingStep = 7
            context.insert(prefs)
        }

        // Enrollment
        let enrollDescriptor = FetchDescriptor<UserEnrollment>()
        if (try? context.fetchCount(enrollDescriptor)) == 0 {
            context.insert(UserEnrollment(startDate: DateHelper.todayPacific()))
        }

        try? context.save()
    }

    // MARK: - Supplements (seeded once)

    private static func seedSupplementsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Supplement>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count > 0 { return }

        let supps: [(String, String, String?, String?, String)] = [
            ("supp-collagen", "Collagen + Vitamin C", "10-15g + 50mg C", "AM / Pre-workout", "am"),
            ("supp-omega3", "Omega-3 Fish Oil", "~1500mg EPA+DHA", "AM with food", "am"),
            ("supp-vitamind", "Vitamin D3 + K2", "2000-4000 IU + 100mcg K2", "AM with food", "am"),
            ("supp-creatine", "Creatine Monohydrate", "3-5g", "AM", "am"),
            ("supp-curcumin", "Curcumin (w/ piperine)", "500-1500mg", "With lunch", "mid"),
            ("supp-omega3b", "Omega-3 (2nd dose)", "~1500mg EPA+DHA", "PM with dinner", "pm"),
            ("supp-mag", "Magnesium Glycinate", "300-400mg", "Before bed", "pm"),
            ("supp-zinc", "Zinc", "15-30mg", "With food", "am"),
            ("supp-ashwagandha", "Ashwagandha", "300-600mg", "AM or PM", "am"),
            ("supp-glucosamine", "Glucosamine + Chondroitin", "1500mg + 1200mg", "With food", "am"),
            ("supp-bcomplex", "B-Complex", "1 capsule", "AM with food", "am"),
            ("supp-probiotics", "Probiotics", "10-50 billion CFU", "AM empty stomach", "am"),
            ("supp-coq10", "CoQ10", "100-200mg", "With food", "am"),
            ("supp-glutamine", "L-Glutamine", "5g", "Post-workout", "mid"),
            ("supp-electrolytes", "Electrolytes", "1 packet", "During workout", "mid"),
            ("supp-melatonin", "Melatonin", "0.5-3mg", "30 min before bed", "pm"),
            ("supp-tart-cherry", "Tart Cherry Extract", "500mg", "Before bed", "pm"),
            ("supp-iron", "Iron", "18-27mg", "AM empty stomach", "am"),
            ("supp-vitaminc", "Vitamin C", "500-1000mg", "AM with food", "am"),
        ]
        for (id, name, dose, time, group) in supps {
            context.insert(Supplement(id: id, name: name, dose: dose, time: time, timeGroup: group))
        }
        try? context.save()
    }

    // MARK: - Milestones (seeded once)

    private static func seedMilestonesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<MilestoneDefinition>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count > 0 { return }

        let milestones: [(String, String, String)] = [
            ("kneel", "Kneel without discomfort",
             "Kneel on a hard floor with no padding and hold comfortably for 30+ seconds."),
            ("squat60", "Deep squat hold — 60 sec",
             "Hold a deep squat (full depth, heels down) for 60 seconds."),
            ("squat120", "Deep squat hold — 2 min",
             "Hold a deep squat for 2 full minutes without support."),
            ("hang30", "Dead hang — 30 sec",
             "Hang from a pull-up bar with straight arms for 30 seconds."),
            ("hang60", "Dead hang — 60 sec",
             "Dead hang for a full minute."),
            ("shinbox", "Shinbox get-up without hands",
             "From a shinbox (90-90) position, stand up without using your hands."),
            ("tgu-kb", "Turkish get-up with KB",
             "Complete a full Turkish get-up holding a kettlebell."),
            ("cossack-floor", "Cossack squat — touch floor",
             "Perform a Cossack squat deep enough to touch the floor with your hand."),
            ("floor-nohand", "Floor to standing — no hands",
             "Get up from the floor to standing without using your hands or knees."),
        ]
        for (id, name, desc) in milestones {
            context.insert(MilestoneDefinition(id: id, name: name, milestoneDescription: desc))
        }
        try? context.save()
    }

    // MARK: - Program (seeded once)

    private static func seedProgramIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Program>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count > 0 { return }

        let program = Program(
            id: 1,
            name: "4-Week Joint & Mobility Program",
            durationDays: 28,
            programDescription: "A hilariously serious program to get your joints moving like they should."
        )
        context.insert(program)
        try? context.save()
    }
}
