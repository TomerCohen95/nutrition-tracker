import AVFoundation
import SwiftData
import SwiftUI
import WidgetKit

struct VoiceMealView: View {
    let date: Date
    var startsAutomatically = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("voiceMealEndpoint") private var endpoint =
        Bundle.main.object(forInfoDictionaryKey: "MarkEatVoiceEndpoint") as? String ?? ""
    @AppStorage(PersonalFood.storageKey) private var personalFoodData = Data()
    @StateObject private var recorder = VoiceMealRecorder()
    @State private var transcript = ""
    @State private var pendingAudio: Data?
    @State private var rows: [Draft] = []
    @State private var saved: [FoodItem] = []
    @State private var message: String?
    @State private var operation: Task<Void, Never>?
    @State private var meterTask: Task<Void, Never>?
    @State private var didAutoStart = false
    @State private var requestingMicrophone = false
    @State private var showServer = false

    private struct Draft: Identifiable {
        let id = UUID()
        var name: String
        var calories: String
        var protein: String
        var status: FoodItem.FoodStatus?
        let date: Date
        let source: String?
        let historySource: String?
        let personalSource: String?
        let estimateSource: String?

        init?(_ item: VoiceMealAnalysis.Item) {
            guard let date = VoiceMealService.date(item.date) else { return nil }
            self.date = date
            name = item.name
            calories = Self.nutrientText(item.calories, maximum: 30_000)
            protein = Self.nutrientText(item.protein, maximum: 3_000)
            status = FoodItem.FoodStatus(rawValue: item.status)
            source = item.source
            historySource = item.historySource
            personalSource = item.personalSource
            estimateSource = item.estimateSource
        }

        private static func nutrientText(_ value: Double?, maximum: Double) -> String {
            guard let value, (0...maximum).contains(value) else { return "" }
            return String(Int(value.rounded()))
        }

        var ready: Bool {
            guard let calories = Int(calories), let protein = Int(protein) else { return false }
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && (0...30_000).contains(calories) && (0...3_000).contains(protein) && status != nil
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recorder.isRecording {
                    recordingScreen
                } else {
                    Form {
                        if saved.isEmpty {
                            input
                            if !rows.isEmpty { review }
                        } else {
                            result
                        }
                        if let message {
                            Section {
                                Label(message, systemImage: "exclamationmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log a meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(saved.isEmpty ? "Close" : "Done") { dismiss() }
                }
                if saved.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Voice server", systemImage: "gearshape") { showServer = true }
                            .labelStyle(.iconOnly)
                            .disabled(operation != nil || recorder.isRecording)
                    }
                }
            }
            .sheet(isPresented: $showServer) {
                NavigationStack {
                    Form {
                        TextField("Tailscale HTTPS address", text: $endpoint)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                    .navigationTitle("Voice server")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { Button("Done") { showServer = false } }
                }
            }
            .task { autoStartIfReady() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { autoStartIfReady() }
                if phase == .background && recorder.isRecording {
                    meterTask?.cancel()
                    recorder.discard()
                    message = "Recording stopped when you left the app."
                }
            }
            .onDisappear {
                operation?.cancel()
                meterTask?.cancel()
                recorder.discard()
            }
        }
    }

    private var recordingScreen: some View {
        VStack(spacing: AppTheme.paddingL) {
            Label("מקליט בעברית", systemImage: "circle.fill")
                .font(.headline)
                .foregroundStyle(Color(uiColor: .systemRed))

            Button(action: finishRecording) {
                VStack(spacing: AppTheme.paddingM) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 142, height: 142)
                        .background(Color(uiColor: .systemRed), in: Circle())
                        .accessibilityHidden(true)

                    Label("עצור ועבד הקלטה", systemImage: "stop.fill")
                        .font(.headline)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("מסיים את ההקלטה ומתחיל לעבד את הארוחה")

            Text("ההקלטה תיעצר אוטומטית כשתסיים לדבר")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.paddingL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var input: some View {
        Section {
            Button("Record what you ate", systemImage: "mic.circle.fill", action: startRecording)
                .tint(AppTheme.primaryGreen)
                .disabled(operation != nil || requestingMicrophone)

            TextField("Or describe your meal here", text: $transcript, axis: .vertical)
                .lineLimit(2...6)
                .disabled(operation != nil)
            if operation != nil {
                ProgressView("Analyzing meal…")
            } else if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("Analyze description") {
                    analyze(Data(transcript.utf8), isRecording: false)
                }
            } else if let pendingAudio {
                Button("Retry recording") { analyze(pendingAudio, isRecording: true) }
            }
        } footer: {
            Text("Record in Hebrew. Your recording is sent to OpenAI for transcription.")
        }
    }

    private var review: some View {
        Section("Check and complete") {
            ForEach($rows) { $row in
                VStack(alignment: .leading, spacing: AppTheme.paddingS) {
                    TextField("Food name", text: $row.name)
                        .font(.headline)
                    Text(row.date, style: .date)
                        .foregroundStyle(.secondary)
                    TextField("Calories (kcal)", text: $row.calories)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $row.protein)
                        .keyboardType(.numberPad)
                    Picker("Status", selection: $row.status) {
                        Text("Choose status").tag(nil as FoodItem.FoodStatus?)
                        Text("Eaten").tag(Optional(FoodItem.FoodStatus.eaten))
                        Text("Planned").tag(Optional(FoodItem.FoodStatus.planned))
                    }
                    nutritionSources(row)
                }
            }
            Button("Add to diary", action: save)
                .disabled(!rows.allSatisfy(\.ready) || operation != nil)
        }
    }

    private var result: some View {
        Section("Added to your diary") {
            ForEach(Array(zip(rows, saved)), id: \.0.id) { row, item in
                VStack(alignment: .leading) {
                    Text(item.name).font(.headline)
                    Text("\(item.calories) kcal · \(item.proteinGrams) g protein · \(item.status.displayName)")
                    Text(item.date, style: .date)
                    nutritionSources(row)
                }
            }
            Button("Undo", role: .destructive, action: undo)
        }
    }

    @ViewBuilder
    private func nutritionSources(_ row: Draft) -> some View {
        Group {
            if let personalSource = row.personalSource {
                Text("מהמאכלים שלי · \(personalSource)")
            }
            if let historySource = row.historySource {
                Text("From your history · \(historySource)")
            }
            if let source = row.source {
                Text("USDA estimate · \(source)")
            }
            if let estimate = row.estimateSource {
                Text(estimate.isEmpty ? "אומדן תזונתי" : "אומדן תזונתי · \(estimate)")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func autoStartIfReady() {
        guard startsAutomatically, !didAutoStart, scenePhase == .active else { return }
        didAutoStart = true
        startRecording()
    }

    private func startRecording() {
        guard operation == nil, !recorder.isRecording else { return }
        guard !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showServer = true
            return
        }
        requestingMicrophone = true
        operation = Task {
            defer {
                operation = nil
                requestingMicrophone = false
            }
            guard await AVAudioApplication.requestRecordPermission() else {
                if !Task.isCancelled { message = "Allow microphone access in Settings, or type your meal." }
                return
            }
            guard !Task.isCancelled else { return }
            do {
                try recorder.start()
                transcript = ""
                pendingAudio = nil
                rows = []
                message = nil
                monitorRecording()
            } catch {
                message = error.localizedDescription
            }
        }
    }

    private func monitorRecording() {
        meterTask = Task {
            let started = ProcessInfo.processInfo.systemUptime
            var silence = VoiceMealSilence()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                guard let level = recorder.level() else {
                    recorder.discard()
                    message = "Recording was interrupted. Try again."
                    return
                }
                switch silence.update(level: level, elapsed: ProcessInfo.processInfo.systemUptime - started) {
                case .keepRecording:
                    continue
                case .finish:
                    finishRecording()
                    return
                case .noSpeech:
                    recorder.discard()
                    message = "No speech detected. Tap Record to try again."
                    return
                }
            }
        }
    }

    private func finishRecording() {
        meterTask?.cancel()
        do {
            let audio = try recorder.finish()
            pendingAudio = audio
            analyze(audio, isRecording: true)
        } catch {
            message = error.localizedDescription
        }
    }

    private func analyze(_ data: Data, isRecording: Bool) {
        guard operation == nil else { return }
        guard !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showServer = true
            return
        }
        rows = []
        message = nil
        let history = recentFoods()
        let personalFoods = PersonalFood.read(personalFoodData)
        operation = Task {
            defer { operation = nil }
            do {
                let response = try await VoiceMealService(endpoint: endpoint).analyze(data, isRecording: isRecording, date: date, history: history, personalFoods: personalFoods)
                try Task.checkCancellation()
                transcript = response.transcript
                pendingAudio = nil
                if let clarification = response.clarification {
                    message = clarification
                    return
                }
                rows = response.items.compactMap(Draft.init)
                guard !rows.isEmpty, rows.count == response.items.count else {
                    rows = []
                    message = "No valid diary entries were found. Try rephrasing the description."
                    return
                }
                if rows.allSatisfy(\.ready) { save() }
            } catch {
                if !Task.isCancelled { message = error.localizedDescription }
            }
        }
    }

    private func recentFoods() -> [VoiceMealService.SavedFood] {
        var descriptor = FetchDescriptor<FoodItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 300
        let recent = (try? context.fetch(descriptor)) ?? []
        // Older records used zero for unknown protein. Keep their calories available for reuse.
        let diary = recent.map {
            VoiceMealService.SavedFood(name: $0.name, calories: $0.calories,
                                       protein: $0.proteinGrams > 0 ? $0.proteinGrams : nil)
        }
        let quickPick = FoodHistoryManager.shared.history.map {
            VoiceMealService.SavedFood(name: $0.name, calories: $0.calories,
                                       protein: $0.proteinGrams > 0 ? $0.proteinGrams : nil)
        }
        var seen: Set<VoiceMealService.SavedFood> = []
        return Array((quickPick + diary).filter { seen.insert($0).inserted }.prefix(60))
    }

    private func save() {
        guard saved.isEmpty, !rows.isEmpty, rows.allSatisfy(\.ready) else { return }
        let items = rows.compactMap { row -> FoodItem? in
            guard let calories = Int(row.calories), let protein = Int(row.protein), let status = row.status else { return nil }
            let item = FoodItem(name: row.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                calories: calories, proteinGrams: protein, date: row.date)
            item.status = status
            return item
        }
        do {
            try context.transaction {
                for item in items { context.insert(item) }
            }
            saved = items
            message = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            context.rollback()
            message = "Could not save the meal. Try again."
        }
    }

    private func undo() {
        do {
            try context.transaction {
                for item in saved { context.delete(item) }
            }
            saved = []
            rows = []
            message = nil
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } catch {
            context.rollback()
            message = "Could not undo the meal. Try again."
        }
    }
}
