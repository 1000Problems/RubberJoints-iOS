import Foundation
import SwiftData

/// Builds a context-rich system prompt for the AI Coach.
struct CoachPromptBuilder {

    static func build(
        settings: UserSettings?,
        preferences: UserPreferences?,
        todayEntries: [PlanEntry],
        todayChecks: [DailyCheck],
        supplements: [Supplement],
        userSupplements: [UserSupplement],
        currentWeek: Int
    ) -> String {
        let todayStr = DateHelper.todayPacificString()
        let startDate = settings?.startDate ?? Date()
        let dayType = StaticPlan.dayType(for: todayStr, startDate: startDate)

        // Build today's exercise list
        let exerciseLines = todayEntries.map { entry in
            let name = ExerciseCatalog.name(entry.exerciseId)
            let checked = todayChecks.contains {
                $0.itemType == "step" && $0.itemId == entry.exerciseId && $0.checked
            }
            return "  - [\(checked ? "x" : " ")] \(name) (\(entry.category)) — \(entry.rx)"
        }.joined(separator: "\n")

        // Build supplement list
        let activeIds = Set(userSupplements.map(\.supplementId))
        let activeSupps = supplements.filter { activeIds.contains($0.id) }
        let suppLines = activeSupps.map { supp in
            let checked = todayChecks.contains {
                $0.itemType == "supplement" && $0.itemId == supp.id && $0.checked
            }
            return "  - [\(checked ? "x" : " ")] \(supp.name) (\(supp.dose ?? "")) — \(supp.timeGroup)"
        }.joined(separator: "\n")

        // Completion stats
        let totalExercises = todayEntries.count
        let doneExercises = todayEntries.filter { entry in
            todayChecks.contains { $0.itemType == "step" && $0.itemId == entry.exerciseId && $0.checked }
        }.count
        let totalSupps = activeSupps.count
        let doneSupps = activeSupps.filter { supp in
            todayChecks.contains { $0.itemType == "supplement" && $0.itemId == supp.id && $0.checked }
        }.count

        return """
        You are the RubberJoints AI Coach — a knowledgeable, encouraging mobility and fitness assistant.

        PERSONALITY:
        - Warm, supportive, and occasionally funny
        - You speak like a friendly personal trainer who genuinely cares
        - Keep responses concise (2-4 sentences for simple questions, more for detailed explanations)
        - Use the user's actual data to give personalized answers
        - Never make up exercises or supplements — only reference what's in their plan

        EXPERTISE:
        - Joint mobility, flexibility, and movement quality
        - Warm-up protocols, recovery strategies, and supplement timing
        - Exercise form cues and progressions
        - When to push and when to rest

        SAFETY:
        - Always remind users to consult a physician for medical concerns
        - If someone reports pain (not normal stretch discomfort), advise them to stop and see a professional
        - Never diagnose injuries or medical conditions

        CURRENT CONTEXT:
        - Today: \(todayStr)
        - Program week: \(currentWeek) of 4
        - Day type: \(dayType)
        - Exercises completed: \(doneExercises)/\(totalExercises)
        - Supplements taken: \(doneSupps)/\(totalSupps)

        TODAY'S EXERCISES:
        \(exerciseLines.isEmpty ? "  (Rest day — no exercises scheduled)" : exerciseLines)

        TODAY'S SUPPLEMENTS:
        \(suppLines.isEmpty ? "  (No supplements configured)" : suppLines)

        EXERCISE CATALOG KNOWLEDGE:
        You know all exercises in the RubberJoints catalog. When asked about any exercise, provide:
        - What it does and why it's in the program
        - Form cues for proper execution
        - Common mistakes to avoid
        - Progressions or regressions if appropriate
        """
    }
}
