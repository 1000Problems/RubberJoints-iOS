import SwiftUI

struct LibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var expandedId: String? = nil

    private let categories: [(id: String, label: String, icon: String)] = [
        ("warmup_tool", "Warm-Up Tools", "flame.fill"),
        ("mobility", "Mobility", "figure.flexibility"),
        ("recovery_tool", "Recovery Tools", "heart.fill"),
    ]

    private var filteredExercises: [ExerciseCatalog.Entry] {
        var results = ExerciseCatalog.all

        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                $0.targets.lowercased().contains(query) ||
                $0.description.lowercased().contains(query)
            }
        }

        return results
    }

    private func exerciseCount(for category: String) -> Int {
        ExerciseCatalog.all.filter { $0.category == category }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textMuted)
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textMuted)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.surface1)
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryChip(label: "All", id: nil, icon: "square.grid.2x2.fill")
                            ForEach(categories, id: \.id) { cat in
                                categoryChip(label: cat.label, id: cat.id, icon: cat.icon)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Results count
                    HStack {
                        Text("\(filteredExercises.count) exercises")
                            .font(.caption)
                            .foregroundColor(.textMuted)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Exercise cards
                    LazyVStack(spacing: 10) {
                        ForEach(filteredExercises, id: \.id) { exercise in
                            ExerciseLibraryCard(
                                exercise: exercise,
                                isExpanded: expandedId == exercise.id,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        expandedId = expandedId == exercise.id ? nil : exercise.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBg)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func categoryChip(label: String, id: String?, icon: String) -> some View {
        let isSelected = selectedCategory == id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = id
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accent : Color.surface1)
            .foregroundColor(isSelected ? .white : .textSecondary)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
    }
}

// MARK: - Exercise Library Card

struct ExerciseLibraryCard: View {
    let exercise: ExerciseCatalog.Entry
    let isExpanded: Bool
    let onTap: () -> Void

    private var categoryLabel: String {
        switch exercise.category {
        case "warmup_tool": return "Warm-Up"
        case "mobility": return "Mobility"
        case "recovery_tool": return "Recovery"
        default: return exercise.category
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.categoryColor(exercise.category).opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: categoryIcon)
                                .font(.system(size: 16))
                                .foregroundColor(Color.categoryColor(exercise.category))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 8) {
                            Text(categoryLabel)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Color.categoryColor(exercise.category))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.categoryColor(exercise.category).opacity(0.1))
                                .cornerRadius(4)

                            Text(exercise.targets)
                                .font(.caption)
                                .foregroundColor(.textMuted)
                        }
                    }

                    Spacer()

                    Text(exercise.defaultRx)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.surface2)
                        .cornerRadius(6)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
            }
            .padding(14)

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Label("What", systemImage: "doc.text")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                        Text(exercise.description)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }

                    // Cues
                    if !exercise.cues.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Cues", systemImage: "list.bullet")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textSecondary)
                            ForEach(Array(exercise.cues.components(separatedBy: ", ").enumerated()), id: \.offset) { index, cue in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.accent)
                                        .frame(width: 18, alignment: .trailing)
                                    Text(cue)
                                        .font(.subheadline)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }

                    // Explanation
                    if !exercise.explanation.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Why it works", systemImage: "lightbulb.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.warning)
                            Text(exercise.explanation)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)
                        }
                    }

                    // Warning
                    if !exercise.warning.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.error)
                                .font(.caption)
                            Text(exercise.warning)
                                .font(.caption)
                                .foregroundColor(.error)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.error.opacity(0.08))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(Color.surface1)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var categoryIcon: String {
        switch exercise.category {
        case "warmup_tool": return "flame.fill"
        case "mobility": return "figure.flexibility"
        case "recovery_tool": return "heart.fill"
        default: return "circle.fill"
        }
    }
}
