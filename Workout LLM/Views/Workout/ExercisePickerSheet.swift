import SwiftUI
import SwiftData

struct ExercisePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let category: String
    let dateString: String
    let existingExerciseIds: Set<String>

    @State private var searchText = ""

    private var categoryEntries: [ExerciseCatalog.Entry] {
        ExerciseCatalog.exercises(in: category)
    }

    private var filteredEntries: [ExerciseCatalog.Entry] {
        if searchText.isEmpty {
            return categoryEntries
        }
        return categoryEntries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.targets.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredEntries, id: \.id) { entry in
                    let alreadyAdded = existingExerciseIds.contains(entry.id)
                    Button {
                        if !alreadyAdded {
                            addExercise(entry)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.name)
                                    .font(.body)
                                    .foregroundColor(alreadyAdded ? .textMuted : .textPrimary)
                                if !entry.targets.isEmpty {
                                    Text(entry.targets)
                                        .font(.caption)
                                        .foregroundColor(.textMuted)
                                }
                                if !entry.defaultRx.isEmpty {
                                    Text(entry.defaultRx)
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            Spacer()
                            if alreadyAdded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                            }
                        }
                    }
                    .disabled(alreadyAdded)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises...")
            .navigationTitle("Add \(categoryDisplayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var categoryDisplayName: String {
        switch category {
        case "warmup_tool": return "Warm-Up"
        case "mobility": return "Mobility"
        case "recovery_tool": return "Recovery"
        default: return category.capitalized
        }
    }

    private func addExercise(_ catalogEntry: ExerciseCatalog.Entry) {
        // Store as an "add" override — no need to touch the static plan
        let maxSort = (existingExerciseIds.count + 1) * 10
        let override = PlanOverride(
            dateString: dateString,
            exerciseId: catalogEntry.id,
            action: "add",
            category: catalogEntry.category,
            sortOrder: maxSort,
            rx: catalogEntry.defaultRx
        )
        modelContext.insert(override)
        try? modelContext.save()
    }
}
