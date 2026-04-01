import Foundation

/// Pre-computed 28-day plan — identical for all users, no runtime generation needed.
/// Each entry: (dayOffset from start, dayType, [(exerciseId, category, sortOrder, rx)])
/// Pattern: 5 days/week = [train, train, train, rest, train, train, recovery]
/// Progressive loading: week 1 is lightest, week 4 is heaviest.
struct StaticPlan {

    struct PlanEntry {
        let exerciseId: String
        let category: String
        let sortOrder: Int
        let rx: String
    }

    struct PlanDay {
        let dayOffset: Int
        let dayType: String
        let entries: [PlanEntry]
    }

    // MARK: - Runtime Lookup

    /// Returns plan entries for a specific calendar date.
    /// Pure computation — no database, no I/O. Instant.
    static func entries(for dateString: String, startDate: Date) -> [PlanEntry] {
        let offset = DateHelper.daysBetween(start: startDate, end: dateString)
        guard offset >= 0, offset < days.count else { return [] }
        return days[offset].entries
    }

    /// Returns the day type ("train", "rest", "recovery") for a date.
    static func dayType(for dateString: String, startDate: Date) -> String {
        let offset = DateHelper.daysBetween(start: startDate, end: dateString)
        guard offset >= 0, offset < days.count else { return "rest" }
        return days[offset].dayType
    }

    /// Convert static entries to runtime PlanEntry structs for a given date.
    static func planEntries(for dateString: String, startDate: Date) -> [Workout_LLM.PlanEntry] {
        let offset = DateHelper.daysBetween(start: startDate, end: dateString)
        guard offset >= 0, offset < days.count else { return [] }
        let day = days[offset]
        return day.entries.map { e in
            Workout_LLM.PlanEntry(
                dateString: dateString,
                dayType: day.dayType,
                exerciseId: e.exerciseId,
                category: e.category,
                sortOrder: e.sortOrder,
                rx: e.rx
            )
        }
    }

    // MARK: - Static Data

    static let days: [PlanDay] = [
        // ── Week 1 ──
        PlanDay(dayOffset: 0, dayType: "train", entries: [
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 2, rx: "5 min"),
            PlanEntry(exerciseId: "90-90-hip-switch", category: "mobility", sortOrder: 3, rx: "30 sec each"),
            PlanEntry(exerciseId: "90-90-pails-rails", category: "mobility", sortOrder: 4, rx: "8 reps each"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 5, rx: "8 reps"),
            PlanEntry(exerciseId: "active-recovery-walk", category: "recovery_tool", sortOrder: 6, rx: "15 min"),
        ]),
        PlanDay(dayOffset: 1, dayType: "train", entries: [
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 1, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "90-90-pails-rails", category: "mobility", sortOrder: 3, rx: "8 reps each"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 4, rx: "8 reps"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 5, rx: "8 reps each"),
            PlanEntry(exerciseId: "contrast-shower", category: "recovery_tool", sortOrder: 6, rx: "12 min"),
        ]),
        PlanDay(dayOffset: 2, dayType: "train", entries: [
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 3, rx: "8 reps"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 4, rx: "8 reps each"),
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 5, rx: "5 min"),
            PlanEntry(exerciseId: "epsom-bath", category: "recovery_tool", sortOrder: 6, rx: "20 min"),
        ]),
        PlanDay(dayOffset: 3, dayType: "rest", entries: [
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 1, rx: "8 reps each"),
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 2, rx: "5 min"),
        ]),
        PlanDay(dayOffset: 4, dayType: "train", entries: [
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 3, rx: "5 min"),
            PlanEntry(exerciseId: "cat-cow", category: "mobility", sortOrder: 4, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 5, rx: "90 sec each"),
            PlanEntry(exerciseId: "hydration", category: "recovery_tool", sortOrder: 6, rx: "All day"),
        ]),
        PlanDay(dayOffset: 5, dayType: "train", entries: [
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 2, rx: "5 min"),
            PlanEntry(exerciseId: "cat-cow", category: "mobility", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 4, rx: "90 sec each"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 5, rx: "60 sec"),
            PlanEntry(exerciseId: "lacrosse-ball", category: "recovery_tool", sortOrder: 6, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 6, dayType: "recovery", entries: [
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 1, rx: "90 sec each"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 2, rx: "60 sec"),
            PlanEntry(exerciseId: "massage-gun", category: "recovery_tool", sortOrder: 3, rx: "8 min"),
            PlanEntry(exerciseId: "quality-sleep", category: "recovery_tool", sortOrder: 4, rx: "7-9 hrs"),
        ]),
        // ── Week 2 ──
        PlanDay(dayOffset: 7, dayType: "train", entries: [
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 3, rx: "60 sec"),
            PlanEntry(exerciseId: "doorway-chest-stretch", category: "mobility", sortOrder: 4, rx: "30 sec each"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 5, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 6, rx: "10 reps each"),
            PlanEntry(exerciseId: "quality-sleep", category: "recovery_tool", sortOrder: 7, rx: "7-9 hrs"),
            PlanEntry(exerciseId: "self-massage", category: "recovery_tool", sortOrder: 8, rx: "10 min"),
        ]),
        PlanDay(dayOffset: 8, dayType: "train", entries: [
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "doorway-chest-stretch", category: "mobility", sortOrder: 3, rx: "30 sec each"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 4, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 5, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 6, rx: "20 reps"),
            PlanEntry(exerciseId: "self-massage", category: "recovery_tool", sortOrder: 7, rx: "10 min"),
            PlanEntry(exerciseId: "tennis-ball-release", category: "recovery_tool", sortOrder: 8, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 9, dayType: "train", entries: [
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 3, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 4, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 5, rx: "20 reps"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 6, rx: "5 reps"),
            PlanEntry(exerciseId: "tennis-ball-release", category: "recovery_tool", sortOrder: 7, rx: "8 min"),
            PlanEntry(exerciseId: "yoga-cooldown", category: "recovery_tool", sortOrder: 8, rx: "15 min"),
        ]),
        PlanDay(dayOffset: 10, dayType: "rest", entries: [
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 1, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 2, rx: "20 reps"),
        ]),
        PlanDay(dayOffset: 11, dayType: "train", entries: [
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 1, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 3, rx: "20 reps"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 4, rx: "5 reps"),
            PlanEntry(exerciseId: "wall-ankle-mob", category: "mobility", sortOrder: 5, rx: "90 sec each"),
            PlanEntry(exerciseId: "wall-slides", category: "mobility", sortOrder: 6, rx: "10 reps"),
            PlanEntry(exerciseId: "active-recovery-walk", category: "recovery_tool", sortOrder: 7, rx: "15 min"),
            PlanEntry(exerciseId: "contrast-shower", category: "recovery_tool", sortOrder: 8, rx: "12 min"),
        ]),
        PlanDay(dayOffset: 12, dayType: "train", entries: [
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 3, rx: "5 reps"),
            PlanEntry(exerciseId: "wall-ankle-mob", category: "mobility", sortOrder: 4, rx: "90 sec each"),
            PlanEntry(exerciseId: "wall-slides", category: "mobility", sortOrder: 5, rx: "10 reps"),
            PlanEntry(exerciseId: "worlds-greatest-stretch", category: "mobility", sortOrder: 6, rx: "8 reps each"),
            PlanEntry(exerciseId: "contrast-shower", category: "recovery_tool", sortOrder: 7, rx: "12 min"),
            PlanEntry(exerciseId: "epsom-bath", category: "recovery_tool", sortOrder: 8, rx: "20 min"),
        ]),
        PlanDay(dayOffset: 13, dayType: "recovery", entries: [
            PlanEntry(exerciseId: "wall-ankle-mob", category: "mobility", sortOrder: 1, rx: "90 sec each"),
            PlanEntry(exerciseId: "wall-slides", category: "mobility", sortOrder: 2, rx: "10 reps"),
            PlanEntry(exerciseId: "epsom-bath", category: "recovery_tool", sortOrder: 3, rx: "20 min"),
            PlanEntry(exerciseId: "foam-roller", category: "recovery_tool", sortOrder: 4, rx: "10 min"),
        ]),
        // ── Week 3 ──
        PlanDay(dayOffset: 14, dayType: "train", entries: [
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 3, rx: "5 min"),
            PlanEntry(exerciseId: "wall-slides", category: "mobility", sortOrder: 4, rx: "10 reps"),
            PlanEntry(exerciseId: "worlds-greatest-stretch", category: "mobility", sortOrder: 5, rx: "8 reps each"),
            PlanEntry(exerciseId: "90-90-hip-switch", category: "mobility", sortOrder: 6, rx: "30 sec each"),
            PlanEntry(exerciseId: "90-90-pails-rails", category: "mobility", sortOrder: 7, rx: "8 reps each"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 8, rx: "8 reps"),
            PlanEntry(exerciseId: "foam-roller", category: "recovery_tool", sortOrder: 9, rx: "10 min"),
            PlanEntry(exerciseId: "hydration", category: "recovery_tool", sortOrder: 10, rx: "All day"),
        ]),
        PlanDay(dayOffset: 15, dayType: "train", entries: [
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 2, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "worlds-greatest-stretch", category: "mobility", sortOrder: 4, rx: "8 reps each"),
            PlanEntry(exerciseId: "90-90-hip-switch", category: "mobility", sortOrder: 5, rx: "30 sec each"),
            PlanEntry(exerciseId: "90-90-pails-rails", category: "mobility", sortOrder: 6, rx: "8 reps each"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 7, rx: "8 reps"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 8, rx: "8 reps each"),
            PlanEntry(exerciseId: "hydration", category: "recovery_tool", sortOrder: 9, rx: "All day"),
            PlanEntry(exerciseId: "lacrosse-ball", category: "recovery_tool", sortOrder: 10, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 16, dayType: "train", entries: [
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 1, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "90-90-hip-switch", category: "mobility", sortOrder: 4, rx: "30 sec each"),
            PlanEntry(exerciseId: "90-90-pails-rails", category: "mobility", sortOrder: 5, rx: "8 reps each"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 6, rx: "8 reps"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 7, rx: "8 reps each"),
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 8, rx: "5 min"),
            PlanEntry(exerciseId: "lacrosse-ball", category: "recovery_tool", sortOrder: 9, rx: "8 min"),
            PlanEntry(exerciseId: "massage-gun", category: "recovery_tool", sortOrder: 10, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 17, dayType: "rest", entries: [
            PlanEntry(exerciseId: "90-90-pails-rails", category: "mobility", sortOrder: 1, rx: "8 reps each"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 2, rx: "8 reps"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 3, rx: "8 reps each"),
        ]),
        PlanDay(dayOffset: 18, dayType: "train", entries: [
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "ankle-pails-rails", category: "mobility", sortOrder: 4, rx: "8 reps"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 5, rx: "8 reps each"),
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 6, rx: "5 min"),
            PlanEntry(exerciseId: "cat-cow", category: "mobility", sortOrder: 7, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 8, rx: "90 sec each"),
            PlanEntry(exerciseId: "quality-sleep", category: "recovery_tool", sortOrder: 9, rx: "7-9 hrs"),
            PlanEntry(exerciseId: "self-massage", category: "recovery_tool", sortOrder: 10, rx: "10 min"),
        ]),
        PlanDay(dayOffset: 19, dayType: "train", entries: [
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 3, rx: "5 min"),
            PlanEntry(exerciseId: "bird-dog", category: "mobility", sortOrder: 4, rx: "8 reps each"),
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 5, rx: "5 min"),
            PlanEntry(exerciseId: "cat-cow", category: "mobility", sortOrder: 6, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 7, rx: "90 sec each"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 8, rx: "60 sec"),
            PlanEntry(exerciseId: "self-massage", category: "recovery_tool", sortOrder: 9, rx: "10 min"),
            PlanEntry(exerciseId: "tennis-ball-release", category: "recovery_tool", sortOrder: 10, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 20, dayType: "recovery", entries: [
            PlanEntry(exerciseId: "cars-routine", category: "mobility", sortOrder: 1, rx: "5 min"),
            PlanEntry(exerciseId: "cat-cow", category: "mobility", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 3, rx: "90 sec each"),
            PlanEntry(exerciseId: "tennis-ball-release", category: "recovery_tool", sortOrder: 4, rx: "8 min"),
            PlanEntry(exerciseId: "yoga-cooldown", category: "recovery_tool", sortOrder: 5, rx: "15 min"),
            PlanEntry(exerciseId: "active-recovery-walk", category: "recovery_tool", sortOrder: 6, rx: "15 min"),
        ]),
        // ── Week 4 ──
        PlanDay(dayOffset: 21, dayType: "train", entries: [
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 1, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "cat-cow", category: "mobility", sortOrder: 4, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 5, rx: "90 sec each"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 6, rx: "60 sec"),
            PlanEntry(exerciseId: "doorway-chest-stretch", category: "mobility", sortOrder: 7, rx: "30 sec each"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 8, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 9, rx: "10 reps each"),
            PlanEntry(exerciseId: "yoga-cooldown", category: "recovery_tool", sortOrder: 10, rx: "15 min"),
            PlanEntry(exerciseId: "active-recovery-walk", category: "recovery_tool", sortOrder: 11, rx: "15 min"),
            PlanEntry(exerciseId: "contrast-shower", category: "recovery_tool", sortOrder: 12, rx: "12 min"),
        ]),
        PlanDay(dayOffset: 22, dayType: "train", entries: [
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "couch-stretch", category: "mobility", sortOrder: 4, rx: "90 sec each"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 5, rx: "60 sec"),
            PlanEntry(exerciseId: "doorway-chest-stretch", category: "mobility", sortOrder: 6, rx: "30 sec each"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 7, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 8, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 9, rx: "20 reps"),
            PlanEntry(exerciseId: "active-recovery-walk", category: "recovery_tool", sortOrder: 10, rx: "15 min"),
            PlanEntry(exerciseId: "contrast-shower", category: "recovery_tool", sortOrder: 11, rx: "12 min"),
            PlanEntry(exerciseId: "epsom-bath", category: "recovery_tool", sortOrder: 12, rx: "20 min"),
        ]),
        PlanDay(dayOffset: 23, dayType: "train", entries: [
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "marching-in-place", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "deep-squat-hold", category: "mobility", sortOrder: 4, rx: "60 sec"),
            PlanEntry(exerciseId: "doorway-chest-stretch", category: "mobility", sortOrder: 5, rx: "30 sec each"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 6, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 7, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 8, rx: "20 reps"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 9, rx: "5 reps"),
            PlanEntry(exerciseId: "contrast-shower", category: "recovery_tool", sortOrder: 10, rx: "12 min"),
            PlanEntry(exerciseId: "epsom-bath", category: "recovery_tool", sortOrder: 11, rx: "20 min"),
            PlanEntry(exerciseId: "foam-roller", category: "recovery_tool", sortOrder: 12, rx: "10 min"),
        ]),
        PlanDay(dayOffset: 24, dayType: "rest", entries: [
            PlanEntry(exerciseId: "doorway-chest-stretch", category: "mobility", sortOrder: 1, rx: "30 sec each"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 2, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 3, rx: "10 reps each"),
        ]),
        PlanDay(dayOffset: 25, dayType: "train", entries: [
            PlanEntry(exerciseId: "arm-circles", category: "warmup_tool", sortOrder: 1, rx: "2 min"),
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 2, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "hip-flexor-pails-rails", category: "mobility", sortOrder: 4, rx: "8 reps"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 5, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 6, rx: "20 reps"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 7, rx: "5 reps"),
            PlanEntry(exerciseId: "wall-ankle-mob", category: "mobility", sortOrder: 8, rx: "90 sec each"),
            PlanEntry(exerciseId: "wall-slides", category: "mobility", sortOrder: 9, rx: "10 reps"),
            PlanEntry(exerciseId: "foam-roller", category: "recovery_tool", sortOrder: 10, rx: "10 min"),
            PlanEntry(exerciseId: "hydration", category: "recovery_tool", sortOrder: 11, rx: "All day"),
            PlanEntry(exerciseId: "lacrosse-ball", category: "recovery_tool", sortOrder: 12, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 26, dayType: "train", entries: [
            PlanEntry(exerciseId: "brisk-walking", category: "warmup_tool", sortOrder: 1, rx: "5 min"),
            PlanEntry(exerciseId: "glute-bridges", category: "warmup_tool", sortOrder: 2, rx: "2 min"),
            PlanEntry(exerciseId: "leg-swings", category: "warmup_tool", sortOrder: 3, rx: "2 min"),
            PlanEntry(exerciseId: "open-book", category: "mobility", sortOrder: 4, rx: "10 reps each"),
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 5, rx: "20 reps"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 6, rx: "5 reps"),
            PlanEntry(exerciseId: "wall-ankle-mob", category: "mobility", sortOrder: 7, rx: "90 sec each"),
            PlanEntry(exerciseId: "wall-slides", category: "mobility", sortOrder: 8, rx: "10 reps"),
            PlanEntry(exerciseId: "worlds-greatest-stretch", category: "mobility", sortOrder: 9, rx: "8 reps each"),
            PlanEntry(exerciseId: "hydration", category: "recovery_tool", sortOrder: 10, rx: "All day"),
            PlanEntry(exerciseId: "lacrosse-ball", category: "recovery_tool", sortOrder: 11, rx: "8 min"),
            PlanEntry(exerciseId: "massage-gun", category: "recovery_tool", sortOrder: 12, rx: "8 min"),
        ]),
        PlanDay(dayOffset: 27, dayType: "recovery", entries: [
            PlanEntry(exerciseId: "quadruped-rocking", category: "mobility", sortOrder: 1, rx: "20 reps"),
            PlanEntry(exerciseId: "shinbox-getup", category: "mobility", sortOrder: 2, rx: "5 reps"),
            PlanEntry(exerciseId: "wall-ankle-mob", category: "mobility", sortOrder: 3, rx: "90 sec each"),
            PlanEntry(exerciseId: "lacrosse-ball", category: "recovery_tool", sortOrder: 4, rx: "8 min"),
            PlanEntry(exerciseId: "massage-gun", category: "recovery_tool", sortOrder: 5, rx: "8 min"),
            PlanEntry(exerciseId: "quality-sleep", category: "recovery_tool", sortOrder: 6, rx: "7-9 hrs"),
        ]),
    ]
}
