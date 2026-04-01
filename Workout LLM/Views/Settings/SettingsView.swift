import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var settings: [UserSettings]
    @Query private var allSupplements: [Supplement]
    @Query private var userSupplements: [UserSupplement]

    @State private var showResetAlert = false
    @State private var hasAPIKey = KeychainHelper.hasAPIKey
    @State private var showAPIKeySheet = false
    @State private var remindersEnabled = false
    @State private var reminderTime = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var notificationPermissionDenied = false

    private var prefs: UserPreferences? { preferences.first }
    private var userSettings: UserSettings? { settings.first }

    var body: some View {
        NavigationStack {
            List {
                // Start Date
                Section("Program") {
                    if let s = userSettings {
                        DatePicker("Start Date",
                                   selection: Binding(
                                       get: { s.startDate ?? Date() },
                                       set: { s.startDate = $0; try? modelContext.save() }
                                   ),
                                   displayedComponents: .date)
                    }

                    if let p = prefs {
                        Picker("Training Days/Week", selection: Binding(
                            get: { p.daysPerWeek },
                            set: { p.daysPerWeek = $0; try? modelContext.save() }
                        )) {
                            ForEach(2...6, id: \.self) { n in
                                Text("\(n) days").tag(n)
                            }
                        }
                    }
                }

                // Reminders
                Section {
                    Toggle("Daily Reminder", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { _, newValue in
                            if newValue {
                                NotificationHelper.requestPermission { granted in
                                    if granted {
                                        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                                        NotificationHelper.scheduleDailyReminder(hour: comps.hour ?? 8, minute: comps.minute ?? 0)
                                    } else {
                                        remindersEnabled = false
                                        notificationPermissionDenied = true
                                    }
                                }
                            } else {
                                NotificationHelper.cancelReminder()
                            }
                        }

                    if remindersEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newValue in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                NotificationHelper.scheduleDailyReminder(hour: comps.hour ?? 8, minute: comps.minute ?? 0)
                            }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if notificationPermissionDenied {
                        Text("Notifications are disabled. Go to Settings > RubberJoints to enable them.")
                            .foregroundColor(.error)
                    } else if remindersEnabled {
                        Text("You'll get a daily reminder at the time above.")
                    }
                }

                // AI Coach
                Section {
                    if hasAPIKey {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.success)
                            Text("API Key Connected")
                                .font(.body)
                            Spacer()
                            Button("Remove") {
                                KeychainHelper.deleteAPIKey()
                                hasAPIKey = false
                            }
                            .font(.subheadline)
                            .foregroundColor(.error)
                        }
                    } else {
                        Button {
                            showAPIKeySheet = true
                        } label: {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.accent)
                                Text("Add Anthropic API Key")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textMuted)
                            }
                        }
                    }
                } header: {
                    Text("AI Coach")
                } footer: {
                    Text("Your key is stored securely in the device Keychain and never leaves your phone except to call the Anthropic API directly.")
                }

                // Exercises by category
                exerciseSection(category: "warmup_tool", title: "Warm-Up Exercises")
                exerciseSection(category: "mobility", title: "Mobility Exercises")
                exerciseSection(category: "recovery_tool", title: "Recovery Tools")

                // Supplements
                Section("Supplements") {
                    ForEach(allSupplements, id: \.id) { supp in
                        let isActive = userSupplements.contains { $0.supplementId == supp.id }
                        Toggle(isOn: Binding(
                            get: { isActive },
                            set: { newVal in toggleSupplement(supp, enabled: newVal) }
                        )) {
                            VStack(alignment: .leading) {
                                Text(supp.name)
                                    .font(.body)
                                if let dose = supp.dose {
                                    Text(dose)
                                        .font(.caption)
                                        .foregroundColor(.textMuted)
                                }
                            }
                        }
                    }
                }

                // Reset
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Progress")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeyEntrySheet(hasAPIKey: $hasAPIKey)
            }
            .alert("Reset Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetProgress() }
            } message: {
                Text("This will delete all check-ins, session logs, milestones, and exercise overrides. Your exercise selections will be kept.")
            }
        }
    }

    private func exerciseSection(category: String, title: String) -> some View {
        let exercises = ExerciseCatalog.exercises(in: category)
        let selectedIds = Set(prefs?.selectedExerciseIds ?? [])

        return Section(title) {
            ForEach(exercises, id: \.id) { exercise in
                let isSelected = selectedIds.contains(exercise.id)
                Toggle(isOn: Binding(
                    get: { isSelected },
                    set: { newVal in toggleExercise(exercise.id, enabled: newVal) }
                )) {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.body)
                        if !exercise.targets.isEmpty {
                            Text(exercise.targets)
                                .font(.caption)
                                .foregroundColor(.textMuted)
                        }
                    }
                }
            }
        }
    }

    private func toggleExercise(_ exerciseId: String, enabled: Bool) {
        guard let p = prefs else { return }
        var ids = p.selectedExerciseIds
        if enabled {
            if !ids.contains(exerciseId) { ids.append(exerciseId) }
        } else {
            ids.removeAll { $0 == exerciseId }
        }
        p.selectedExerciseIds = ids
        try? modelContext.save()
        // No plan regeneration needed — the plan is computed at render time from StaticPlan
    }

    private func toggleSupplement(_ supplement: Supplement, enabled: Bool) {
        if enabled {
            let us = UserSupplement(supplementId: supplement.id, timeGroup: supplement.timeGroup)
            modelContext.insert(us)
        } else {
            let suppId = supplement.id
            let descriptor = FetchDescriptor<UserSupplement>(
                predicate: #Predicate<UserSupplement> { $0.supplementId == suppId }
            )
            if let existing = try? modelContext.fetch(descriptor) {
                for item in existing {
                    modelContext.delete(item)
                }
            }
        }
        try? modelContext.save()
    }

    private func resetProgress() {
        // Delete all checks
        let checkDescriptor = FetchDescriptor<DailyCheck>()
        if let checks = try? modelContext.fetch(checkDescriptor) {
            for c in checks { modelContext.delete(c) }
        }
        // Delete session logs
        let logDescriptor = FetchDescriptor<SessionLog>()
        if let logs = try? modelContext.fetch(logDescriptor) {
            for l in logs { modelContext.delete(l) }
        }
        // Delete user milestones
        let msDescriptor = FetchDescriptor<UserMilestone>()
        if let ms = try? modelContext.fetch(msDescriptor) {
            for m in ms { modelContext.delete(m) }
        }
        // Delete plan overrides
        let overrideDescriptor = FetchDescriptor<PlanOverride>()
        if let ov = try? modelContext.fetch(overrideDescriptor) {
            for o in ov { modelContext.delete(o) }
        }
        try? modelContext.save()
    }
}

// MARK: - API Key Entry Sheet (isolated from heavy @Query views)

struct APIKeyEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasAPIKey: Bool
    @State private var keyText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accent)
                    .padding(.top, 20)

                Text("Enter your Anthropic API key to enable AI coaching powered by Claude.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                TextField("Paste API key here", text: $keyText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.surface2)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .focused($isFocused)

                Button {
                    let key = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !key.isEmpty else { return }
                    KeychainHelper.saveAPIKey(key)
                    hasAPIKey = true
                    dismiss()
                } label: {
                    Text("Save Key")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(keyText.isEmpty ? Color.textMuted : Color.accent)
                        .cornerRadius(12)
                }
                .disabled(keyText.isEmpty)
                .padding(.horizontal)

                Text("Your key is stored in the device Keychain and only sent to the Anthropic API.")
                    .font(.caption)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.appBg)
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}
