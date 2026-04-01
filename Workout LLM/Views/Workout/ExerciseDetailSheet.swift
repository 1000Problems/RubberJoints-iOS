import SwiftUI
import SwiftData

struct ExerciseDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: PlanEntry
    let isToday: Bool
    var onSwap: (() -> Void)?

    private var catalogEntry: ExerciseCatalog.Entry? {
        ExerciseCatalog.byId[entry.exerciseId]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if !entry.rx.isEmpty {
                        rxSection(entry.rx)
                    }

                    if let cat = catalogEntry, !cat.description.isEmpty {
                        infoSection(title: "What", icon: "info.circle.fill", text: cat.description)
                    }

                    if let cat = catalogEntry, !cat.explanation.isEmpty {
                        infoSection(title: "Why", icon: "lightbulb.fill", text: cat.explanation, color: .warning)
                    }

                    if let cat = catalogEntry, !cat.cues.isEmpty {
                        cuesSection(cat.cues)
                    }

                    if let cat = catalogEntry, !cat.warning.isEmpty {
                        warningSection(cat.warning)
                    }

                    if isToday {
                        actionsSection
                    }
                }
                .padding()
            }
            .background(Color.appBg)
            .navigationTitle(catalogEntry?.name ?? entry.exerciseId)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.categoryColor(entry.category))
                    .frame(width: 12, height: 12)
                Text(categoryDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.categoryColor(entry.category))
            }

            Text(catalogEntry?.name ?? entry.exerciseId)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            if let targets = catalogEntry?.targets, !targets.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "figure.mixed.cardio")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(targets)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    // MARK: - Rx

    private func rxSection(_ rx: String) -> some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.accent)
            Text(rx)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.accent)
            Spacer()
        }
        .padding()
        .background(Color.accent.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Info Sections

    private func infoSection(title: String, icon: String, text: String, color: Color = .accent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            Text(text)
                .font(.body)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface1)
        .cornerRadius(12)
    }

    // MARK: - Cues

    private func cuesSection(_ cues: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(.success)
                Text("Cues")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }

            let cueItems = cues.components(separatedBy: " | ")
            ForEach(Array(cueItems.enumerated()), id: \.offset) { index, cue in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.success)
                        .clipShape(Circle())
                    Text(cue.trimmingCharacters(in: .whitespaces))
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface1)
        .cornerRadius(12)
    }

    // MARK: - Warning

    private func warningSection(_ warning: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warning)
            Text(warning)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warning.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if let onSwap = onSwap {
                Button {
                    onSwap()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Swap Exercise")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent.opacity(0.08))
                    .cornerRadius(12)
                }
            }

            Button(role: .destructive) {
                removeExercise()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "minus.circle")
                    Text("Remove from Today")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.error)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.error.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helpers

    private var categoryDisplayName: String {
        switch entry.category {
        case "warmup_tool": return "Warm-Up"
        case "mobility": return "Mobility"
        case "recovery_tool": return "Recovery"
        default: return entry.category.capitalized
        }
    }

    private func removeExercise() {
        // Add a "remove" override so this exercise won't appear for this date
        let override = PlanOverride(
            dateString: entry.dateString,
            exerciseId: entry.exerciseId,
            action: "remove"
        )
        modelContext.insert(override)
        try? modelContext.save()
    }
}
