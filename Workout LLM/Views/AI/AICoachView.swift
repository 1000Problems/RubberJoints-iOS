import SwiftUI
import SwiftData

struct AICoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var settings: [UserSettings]
    @Query(sort: \ChatMessage.timestamp) private var messages: [ChatMessage]
    @Query private var allChecks: [DailyCheck]
    @Query private var overrides: [PlanOverride]
    @Query private var supplements: [Supplement]
    @Query private var userSupplements: [UserSupplement]

    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showCustomizeSheet = false
    @State private var errorMessage: String?

    private var prefs: UserPreferences? { preferences.first }
    private var hasAPIKey: Bool { KeychainHelper.hasAPIKey }

    private var startDate: Date {
        settings.first?.startDate ?? DateHelper.todayPacific()
    }

    private func todayPlanEntries() -> [PlanEntry] {
        let todayStr = DateHelper.todayPacificString()
        var entries = StaticPlan.planEntries(for: todayStr, startDate: startDate)
        let dateOverrides = overrides.filter { $0.dateString == todayStr }
        let removedIds = Set(dateOverrides.filter { $0.action == "remove" }.map(\.exerciseId))
        entries.removeAll { removedIds.contains($0.exerciseId) }
        let adds = dateOverrides.filter { $0.action == "add" }
        for add in adds {
            let dayType = entries.first?.dayType ?? StaticPlan.dayType(for: todayStr, startDate: startDate)
            entries.append(PlanEntry(
                dateString: todayStr, dayType: dayType,
                exerciseId: add.exerciseId, category: add.category,
                sortOrder: add.sortOrder, rx: add.rx
            ))
        }
        return entries
    }

    private var currentWeek: Int {
        guard let start = settings.first?.startDate else { return 1 }
        return DateHelper.currentWeek(startDate: start)
    }

    private var phaseName: String {
        switch currentWeek {
        case 1: return "Foundation"
        case 2: return "Building"
        case 3: return "Momentum"
        case 4: return "Peak"
        default: return "Foundation"
        }
    }

    // Jokes
    private let jokes = [
        "I told my knees we're doing mobility work. They cracked up.",
        "My joints are like WiFi — they work better after a restart.",
        "My hips don't lie. They say 'please stretch me.'",
        "I asked my spine for flexibility. It said 'I'll bend, but I won't break.'",
        "My ankles have trust issues — they keep rolling on me.",
        "My shoulders carry the weight of the world. And it shows.",
        "I tried yoga. My body made sounds I didn't know were possible.",
        "My foam roller and I have a love-hate relationship.",
        "I don't always stretch, but when I do, I question all my life choices.",
        "My joints forecast the weather better than any app.",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week progress header
                weekHeader

                // Customize Your Plan button
                customizePlanButton

                // Quick prompts
                quickPromptsRow

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages, id: \.timestamp) { message in
                                ChatBubble(message: message)
                                    .id(message.timestamp)
                            }

                            if isTyping {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.timestamp, anchor: .bottom)
                            }
                        }
                    }
                }

                // Error banner
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.error)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.error)
                        Spacer()
                        Button { errorMessage = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textMuted)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.error.opacity(0.08))
                }

                // Medical disclaimer
                medicalDisclaimer

                // Input bar
                inputBar
            }
            .background(Color.appBg)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if messages.isEmpty {
                    sendWelcomeMessage()
                }
            }
        }
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Week \(currentWeek) of 4")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(phaseName)
                    .font(.subheadline)
                    .foregroundColor(.accent)
            }
            .padding(.horizontal)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surface3)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accent)
                        .frame(width: geo.size.width * Double(currentWeek) / 4.0, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)

            // AI mode indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(hasAPIKey ? Color.success : Color.warning)
                    .frame(width: 7, height: 7)
                Text(hasAPIKey ? "Claude AI connected" : "Offline mode — add API key in Settings")
                    .font(.caption2)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal)

            // Joke card
            Text(jokes.randomElement() ?? jokes[0])
                .font(.caption)
                .italic()
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.surface2)
                .cornerRadius(8)
                .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Quick Prompts

    private var quickPromptsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quickPromptChip(label: "My status", icon: "person.fill")
                quickPromptChip(label: "Today's focus", icon: "target")
                quickPromptChip(label: "Weekly progress", icon: "chart.bar.fill")
                quickPromptChip(label: "Recovery tips", icon: "heart.fill")
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 4)
    }

    private func quickPromptChip(label: String, icon: String) -> some View {
        Button {
            inputText = label
            sendMessage()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.surface1)
            .foregroundColor(.accent)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
        .disabled(isTyping)
    }

    // MARK: - Medical Disclaimer

    private var medicalDisclaimer: some View {
        Text("This app is for informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult your physician before starting any exercise program.")
            .font(.system(size: 10))
            .foregroundColor(.textMuted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(Color.surface2.opacity(0.5))
    }

    // MARK: - Customize Plan Button

    private var customizePlanButton: some View {
        Button {
            showCustomizeSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Customize Your Plan")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Adjust exercises, schedule & supplements")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.accent, Color.accent.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .sheet(isPresented: $showCustomizeSheet) {
            CustomizePlanSheet()
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask your AI Coach...", text: $inputText)
                .textFieldStyle(.roundedBorder)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.isEmpty ? .textMuted : .accent)
            }
            .disabled(inputText.isEmpty || isTyping)
        }
        .padding()
        .background(Color.surface1)
    }

    // MARK: - Actions

    private func sendWelcomeMessage() {
        addAssistantMessage("Hey there! Welcome to RubberJoints — your hilariously serious joint mobility program. Your 4-week plan is already loaded and ready to go! Check the Workout tab to see today's exercises. Ask me anything about your plan or mobility tips!")
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMsg = ChatMessage(role: "user", content: text)
        modelContext.insert(userMsg)
        inputText = ""
        try? modelContext.save()

        isTyping = true
        errorMessage = nil

        if hasAPIKey {
            sendViaAPI()
        } else {
            // Fallback: placeholder response
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isTyping = false
                addAssistantMessage("I'm running in offline mode — add your Anthropic API key in Settings to get real AI coaching! For now, check your Workout tab and keep showing up. Consistency beats perfection.")
            }
        }
    }

    private func sendViaAPI() {
        // Build conversation history (last 20 messages to keep context manageable)
        let recentMessages = messages.suffix(20)
        let apiMessages = recentMessages.compactMap { msg -> ClaudeAPIService.Message? in
            guard msg.role == "user" || msg.role == "assistant" else { return nil }
            return ClaudeAPIService.Message(role: msg.role, content: msg.content)
        }

        // Build context-rich system prompt
        let todayStr = DateHelper.todayPacificString()
        let todayChecks = allChecks.filter { $0.dateString == todayStr }
        let systemPrompt = CoachPromptBuilder.build(
            settings: settings.first,
            preferences: prefs,
            todayEntries: todayPlanEntries(),
            todayChecks: todayChecks,
            supplements: supplements,
            userSupplements: userSupplements,
            currentWeek: currentWeek
        )

        Task {
            do {
                let reply = try await ClaudeAPIService.shared.sendMessage(
                    messages: apiMessages,
                    systemPrompt: systemPrompt
                )
                await MainActor.run {
                    isTyping = false
                    addAssistantMessage(reply)
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func addAssistantMessage(_ text: String) {
        let msg = ChatMessage(role: "assistant", content: text)
        modelContext.insert(msg)
        try? modelContext.save()
    }
}

// MARK: - Customize Plan Sheet (placeholder — will use full onboarding flow once AI is working)

struct CustomizePlanSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundColor(.accent)

                Text("AI-Powered Customization")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text("Soon, the AI Coach will walk you through a personalized onboarding to tailor your plan — exercises, schedule, and supplements — based on your goals and ability level.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("For now, you can adjust your plan in the Settings tab.")
                    .font(.subheadline)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Got it!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            .background(Color.appBg)
            .navigationTitle("Customize Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.content)
                .font(.body)
                .foregroundColor(message.isUser ? .white : .textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.accent : Color.surface1)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)

            if message.isAssistant { Spacer() }
        }
        .padding(.horizontal)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotCount = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.textMuted)
                    .frame(width: 8, height: 8)
                    .opacity(dotCount == i ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surface1)
        .cornerRadius(16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}
