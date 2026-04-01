import Foundation

/// Static exercise catalog — baked into the app, no database needed.
/// Use ExerciseCatalog.name("brisk-walking") to get "Brisk Walking", etc.
struct ExerciseCatalog {

    struct Entry {
        let id: String
        let name: String
        let category: String
        let targets: String
        let description: String
        let cues: String
        var explanation: String = ""
        var warning: String = ""
        let defaultRx: String
    }

    /// Fast lookup by exercise ID
    static let byId: [String: Entry] = {
        var dict: [String: Entry] = [:]
        for e in all { dict[e.id] = e }
        return dict
    }()

    /// Get display name for an exercise ID
    static func name(_ id: String) -> String {
        byId[id]?.name ?? id.replacingOccurrences(of: "-", with: " ").capitalized
    }

    /// Get targets for an exercise ID
    static func targets(_ id: String) -> String {
        byId[id]?.targets ?? ""
    }

    /// All exercises by category
    static func exercises(in category: String) -> [Entry] {
        all.filter { $0.category == category }
    }

    // MARK: - Full catalog

    static let all: [Entry] = [
        // ── WARM-UP: Home ──
        Entry(id: "brisk-walking", name: "Brisk Walking", category: "warmup_tool",
              targets: "Full Body", description: "A 5-minute walk to raise your heart rate and warm up joints.",
              cues: "Stand tall, swing arms naturally, breathe rhythmically", defaultRx: "5 min"),
        Entry(id: "arm-circles", name: "Arm Circles", category: "warmup_tool",
              targets: "Shoulders", description: "Forward and backward circles to warm up the shoulder girdle.",
              cues: "Start small, gradually increase circle size, keep core engaged", defaultRx: "2 min"),
        Entry(id: "leg-swings", name: "Leg Swings", category: "warmup_tool",
              targets: "Hips, Hamstrings", description: "Front-to-back and side-to-side leg swings for hip mobility.",
              cues: "Hold a wall for balance, keep standing leg slightly bent", defaultRx: "2 min"),
        Entry(id: "glute-bridges", name: "Glute Bridges", category: "warmup_tool",
              targets: "Glutes, Hips", description: "Lying hip raises to activate glutes and warm up the posterior chain.",
              cues: "Drive through heels, squeeze glutes at top, avoid hyperextension", defaultRx: "2 min"),
        Entry(id: "marching-in-place", name: "Marching in Place", category: "warmup_tool",
              targets: "Full Body", description: "Gentle marching to raise core temperature and activate stabilizers.",
              cues: "Lift knees to hip height, swing opposite arm, stay tall", defaultRx: "2 min"),
        // ── WARM-UP: Gym ──
        Entry(id: "hot-tub", name: "Hot Tub", category: "warmup_tool",
              targets: "Full Body", description: "Warm water immersion to relax muscles and increase blood flow.",
              cues: "5 minutes; move joints gently underwater", defaultRx: "5 min"),
        Entry(id: "vibration-plate", name: "Vibration Plate", category: "warmup_tool",
              targets: "Full Body", description: "Whole-body vibration to activate neuromuscular pathways.",
              cues: "Stand with soft knees, try different stances", defaultRx: "1 min"),
        Entry(id: "stationary-bike", name: "Stationary Bike", category: "warmup_tool",
              targets: "Legs, Cardio", description: "Low-resistance cycling to warm up knee and hip joints.",
              cues: "Keep RPM moderate (60-80), adjust seat height properly", defaultRx: "5 min"),
        Entry(id: "elliptical", name: "Elliptical", category: "warmup_tool",
              targets: "Full Body", description: "Low-impact full-body warm-up that engages arms and legs.",
              cues: "Use both handles, keep a steady moderate pace", defaultRx: "5 min"),
        Entry(id: "rowing-machine", name: "Rowing Machine", category: "warmup_tool",
              targets: "Full Body", description: "Full-body pull movement for cardiovascular warm-up.",
              cues: "Drive with legs first, then lean back, then pull arms", defaultRx: "5 min"),
        Entry(id: "incline-treadmill", name: "Incline Treadmill Walk", category: "warmup_tool",
              targets: "Legs, Glutes", description: "Walking at an incline to activate glutes and calves.",
              cues: "Set 5-10% incline, walk at comfortable pace", defaultRx: "5 min"),
        Entry(id: "stair-climber", name: "Stair Climber", category: "warmup_tool",
              targets: "Legs, Cardio", description: "Step machine for lower body warm-up and cardiovascular readiness.",
              cues: "Stand upright, don't lean on handles", defaultRx: "5 min"),
        // ── MOBILITY: Home ──
        Entry(id: "cars-routine", name: "CARs Routine", category: "mobility",
              targets: "All Joints", description: "Controlled Articular Rotations — slow, full-range circles for every joint.",
              cues: "Move slowly, create tension, explore full range of motion", defaultRx: "5 min"),
        Entry(id: "90-90-hip-switch", name: "90/90 Hip Switch", category: "mobility",
              targets: "Hips", description: "Seated hip rotation drill switching between internal and external rotation.",
              cues: "Keep both knees at 90°, sit tall, move from the hips", defaultRx: "30 sec each"),
        Entry(id: "cat-cow", name: "Cat-Cow Stretch", category: "mobility",
              targets: "Spine", description: "Alternating spinal flexion and extension on all fours.",
              cues: "Inhale on cow (arch), exhale on cat (round), move slowly", defaultRx: "2 min"),
        Entry(id: "wall-slides", name: "Wall Slides", category: "mobility",
              targets: "Shoulders, T-Spine", description: "Sliding arms up a wall to improve shoulder overhead mobility.",
              cues: "Keep lower back flat against wall, slide arms up and down", defaultRx: "10 reps"),
        Entry(id: "bird-dog", name: "Bird-Dog", category: "mobility",
              targets: "Core, Spine", description: "Opposite arm/leg extension from all fours for core stability.",
              cues: "Extend opposite arm and leg, keep hips level, hold 2 sec", defaultRx: "8 reps each"),
        Entry(id: "doorway-chest-stretch", name: "Doorway Chest Stretch", category: "mobility",
              targets: "Chest, Shoulders", description: "Passive chest opener using a doorframe.",
              cues: "Place forearms on doorframe at 90°, lean forward gently", defaultRx: "30 sec each"),
        Entry(id: "shinbox-getup", name: "Shinbox Get-Up", category: "mobility",
              targets: "Hips, Glutes", description: "Rising from a shinbox position to standing without hands.",
              cues: "Drive through front hip, keep chest tall", defaultRx: "5 reps"),
        Entry(id: "worlds-greatest-stretch", name: "World's Greatest Stretch", category: "mobility",
              targets: "Full Body", description: "Multi-step lunge stretch hitting hips, T-spine, and hamstrings.",
              cues: "Lunge, plant hand, rotate and reach to sky, straighten front leg", defaultRx: "8 reps each"),
        Entry(id: "deep-squat-hold", name: "Deep Squat Hold", category: "mobility",
              targets: "Hips, Ankles", description: "Holding a full-depth squat to build lower body mobility.",
              cues: "Heels down, knees tracking toes, chest up", defaultRx: "60 sec"),
        Entry(id: "couch-stretch", name: "Couch Stretch", category: "mobility",
              targets: "Hip Flexors, Quads", description: "Deep hip flexor and quad stretch using a wall or couch.",
              cues: "Back knee near wall, squeeze glute, stay upright", defaultRx: "90 sec each"),
        Entry(id: "wall-ankle-mob", name: "Wall Ankle Mobilization", category: "mobility",
              targets: "Ankles", description: "Knee-over-toe ankle stretch facing a wall.",
              cues: "Foot 3-4 inches from wall, drive knee forward over toes", defaultRx: "90 sec each"),
        Entry(id: "open-book", name: "Open Book (T-Spine)", category: "mobility",
              targets: "T-Spine", description: "Side-lying thoracic rotation drill.",
              cues: "Knees stacked, rotate top arm and follow with eyes", defaultRx: "10 reps each"),
        Entry(id: "quadruped-rocking", name: "Quadruped Rocking", category: "mobility",
              targets: "Hips, Spine", description: "Rocking back toward heels from all fours.",
              cues: "Keep spine neutral, sit back toward heels as far as possible", defaultRx: "20 reps"),
        Entry(id: "hip-flexor-pails-rails", name: "Hip Flexor PAILs/RAILs", category: "mobility",
              targets: "Hip Flexors", description: "Progressive angular isometric loading for hip flexor end-range.",
              cues: "Hold stretch 2 min, then push into floor (PAILs), then lift (RAILs)", defaultRx: "8 reps"),
        Entry(id: "90-90-pails-rails", name: "90/90 PAILs/RAILs", category: "mobility",
              targets: "Hips", description: "Isometric loading at end-range hip rotation.",
              cues: "Hold 90/90, push into floor (PAILs), then lift (RAILs)", defaultRx: "8 reps each"),
        Entry(id: "ankle-pails-rails", name: "Ankle PAILs/RAILs", category: "mobility",
              targets: "Ankles", description: "End-range ankle dorsiflexion training.",
              cues: "Wall ankle position, push into wall (PAILs), pull toes up (RAILs)", defaultRx: "8 reps"),
        // ── MOBILITY: Gym ──
        Entry(id: "dead-hang", name: "Dead Hang", category: "mobility",
              targets: "Shoulders, Grip", description: "Passive hanging from a pull-up bar for shoulder decompression.",
              cues: "Relax shoulders, breathe deeply, let gravity do the work", defaultRx: "30 sec"),
        Entry(id: "trx-squat", name: "TRX Assisted Squat", category: "mobility",
              targets: "Hips, Ankles", description: "Using TRX straps for support in a deep squat.",
              cues: "Hold straps, sit deep, keep weight in heels", defaultRx: "30 sec"),
        Entry(id: "cable-face-pulls", name: "Cable Face Pulls", category: "mobility",
              targets: "Shoulders, Upper Back", description: "Light corrective pulling movement for shoulder health.",
              cues: "Pull to face level, squeeze shoulder blades, control the return", defaultRx: "12 reps"),
        Entry(id: "bench-tspine-stretch", name: "Bench T-Spine Stretch", category: "mobility",
              targets: "T-Spine, Lats", description: "Kneeling lat/T-spine stretch using a bench.",
              cues: "Kneel, place elbows on bench, sink chest toward floor", defaultRx: "30 sec"),
        Entry(id: "banded-ankle-distraction", name: "Banded Ankle Distraction", category: "mobility",
              targets: "Ankles", description: "Using a resistance band to create joint space in the ankle.",
              cues: "Band pulls backward, drive knee forward over toes", defaultRx: "30 sec each"),
        Entry(id: "smith-machine-stretch", name: "Smith Machine Stretch", category: "mobility",
              targets: "Full Body", description: "Using a fixed bar for various assisted stretches.",
              cues: "Hold bar for support, explore different stretch positions", defaultRx: "30 sec each"),
        // ── RECOVERY: Gym ──
        Entry(id: "hydro-massager", name: "Hydro Massager", category: "recovery_tool",
              targets: "Full Body", description: "Water-jet massage bed for passive muscle recovery.",
              cues: "Relax completely, let water jets target sore areas", defaultRx: "5 min"),
        Entry(id: "steam-sauna", name: "Steam Sauna", category: "recovery_tool",
              targets: "Full Body", description: "Moist heat therapy for circulation and relaxation.",
              cues: "Stay hydrated, limit to 15 min, cool down gradually", defaultRx: "15 min"),
        Entry(id: "dry-sauna", name: "Dry Sauna", category: "recovery_tool",
              targets: "Full Body", description: "Dry heat therapy for recovery and stress relief.",
              cues: "Stay well hydrated before, during, and after", defaultRx: "15 min"),
        Entry(id: "compex-warmup", name: "Compex — Warmup", category: "recovery_tool",
              targets: "Targeted Muscles", description: "Electrical muscle stimulation warmup program.",
              cues: "Follow device placement guide, start at low intensity", defaultRx: "10 min"),
        Entry(id: "compex-recovery", name: "Compex — Recovery", category: "recovery_tool",
              targets: "Targeted Muscles", description: "EMS recovery program for post-workout muscle recovery.",
              cues: "Place pads on worked muscles, use active recovery program", defaultRx: "15 min"),
        Entry(id: "compression-boots", name: "Compression Boots", category: "recovery_tool",
              targets: "Legs", description: "Pneumatic compression therapy for leg recovery.",
              cues: "Start at low pressure, work up gradually", defaultRx: "20 min"),
        // ── RECOVERY: Home ──
        Entry(id: "quality-sleep", name: "Quality Sleep", category: "recovery_tool",
              targets: "Full Body", description: "Prioritize 7-9 hours of quality sleep for recovery.",
              cues: "Cool room, dark environment, consistent schedule", defaultRx: "7-9 hrs"),
        Entry(id: "hydration", name: "Hydration", category: "recovery_tool",
              targets: "Full Body", description: "Consistent water intake throughout the day.",
              cues: "Aim for half your body weight in ounces, more on active days", defaultRx: "All day"),
        Entry(id: "foam-roller", name: "Foam Roller", category: "recovery_tool",
              targets: "Full Body", description: "Self-myofascial release using a foam roller.",
              cues: "Roll slowly, pause on tender spots, avoid joints and spine", defaultRx: "10 min"),
        Entry(id: "tennis-ball-release", name: "Tennis Ball Release", category: "recovery_tool",
              targets: "Targeted Areas", description: "Targeted release work using a tennis ball.",
              cues: "Apply pressure to tight spots, hold 30-60 sec per area", defaultRx: "8 min"),
        Entry(id: "lacrosse-ball", name: "Lacrosse Ball Release", category: "recovery_tool",
              targets: "Targeted Areas", description: "Deep tissue release using a lacrosse ball.",
              cues: "More intense than tennis ball, avoid bony areas", defaultRx: "8 min"),
        Entry(id: "active-recovery-walk", name: "Active Recovery Walk", category: "recovery_tool",
              targets: "Full Body", description: "Easy-paced walk to promote blood flow on recovery days.",
              cues: "Keep it easy, focus on breathing and relaxation", defaultRx: "15 min"),
        Entry(id: "contrast-shower", name: "Contrast Shower", category: "recovery_tool",
              targets: "Full Body", description: "Alternating hot and cold water for circulation.",
              cues: "3 min hot, 1 min cold, repeat 3 cycles", defaultRx: "12 min"),
        Entry(id: "epsom-bath", name: "Epsom Salt Bath", category: "recovery_tool",
              targets: "Full Body", description: "Warm bath with Epsom salts for magnesium absorption.",
              cues: "2 cups Epsom salt in warm water, soak 15-20 min", defaultRx: "20 min"),
        Entry(id: "yoga-cooldown", name: "Yoga Cool-Down Flow", category: "recovery_tool",
              targets: "Full Body", description: "Gentle yoga sequence for post-activity recovery.",
              cues: "Move slowly, breathe deeply, hold poses 30-60 sec", defaultRx: "15 min"),
        Entry(id: "self-massage", name: "Self-Massage (Hands/Stick)", category: "recovery_tool",
              targets: "Targeted Areas", description: "Manual massage using hands or a massage stick.",
              cues: "Work along muscle fibers, moderate pressure", defaultRx: "10 min"),
        Entry(id: "massage-gun", name: "Massage Gun", category: "recovery_tool",
              targets: "Targeted Areas", description: "Percussive therapy for muscle recovery.",
              cues: "Float over muscle, don't press hard, avoid joints", defaultRx: "8 min"),
        Entry(id: "cold-plunge", name: "Cold Plunge", category: "recovery_tool",
              targets: "Full Body", description: "Cold water immersion for recovery and inflammation reduction.",
              cues: "50-59°F, start with 1 min, build up gradually", defaultRx: "3 min"),
    ]
}
