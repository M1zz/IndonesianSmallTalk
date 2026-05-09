import SwiftUI

enum ScenarioEditTarget {
    case local(UserScenario)
    case shared(SharedScenario)
}

struct AddScenarioView: View {
    var editing: ScenarioEditTarget? = nil

    @EnvironmentObject var store: UserScenarioStore
    @EnvironmentObject var sharedStore: SharedScenarioStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechManager()

    @State private var title: String
    @State private var titleKo: String
    @State private var description: String
    @State private var emoji: String
    @State private var difficulty: ConversationScenario.Difficulty
    @State private var openerSpeakerIsOther: Bool
    @State private var openingIndonesian: String
    @State private var openingKorean: String
    @State private var openingRomanization: String
    @State private var shareWithFriends: Bool
    @State private var permissionAsked = false
    @State private var saving = false
    @State private var saveError: String?

    init(editing: ScenarioEditTarget? = nil) {
        self.editing = editing
        switch editing {
        case .local(let s):
            _title = State(initialValue: s.title)
            _titleKo = State(initialValue: s.titleKo)
            _description = State(initialValue: s.description)
            _emoji = State(initialValue: s.emoji)
            _difficulty = State(initialValue: ConversationScenario.Difficulty(rawValue: s.difficultyRaw) ?? .beginner)
            _openerSpeakerIsOther = State(initialValue: s.openerSpeakerIsOther)
            _openingIndonesian = State(initialValue: s.openingIndonesian)
            _openingKorean = State(initialValue: s.openingKorean)
            _openingRomanization = State(initialValue: s.openingRomanization)
            _shareWithFriends = State(initialValue: false)  // 로컬 → 공유 전환은 v2 (지금은 수정만)
        case .shared(let s):
            _title = State(initialValue: s.title)
            _titleKo = State(initialValue: s.titleKo)
            _description = State(initialValue: s.description)
            _emoji = State(initialValue: s.emoji)
            _difficulty = State(initialValue: ConversationScenario.Difficulty(rawValue: s.difficultyRaw) ?? .beginner)
            _openerSpeakerIsOther = State(initialValue: s.openerSpeakerIsOther)
            _openingIndonesian = State(initialValue: s.openingIndonesian)
            _openingKorean = State(initialValue: s.openingKorean)
            _openingRomanization = State(initialValue: s.openingRomanization)
            _shareWithFriends = State(initialValue: true)  // 이미 공유됨, 토글 잠금
        case .none:
            _title = State(initialValue: "")
            _titleKo = State(initialValue: "")
            _description = State(initialValue: "")
            _emoji = State(initialValue: "💬")
            _difficulty = State(initialValue: .beginner)
            _openerSpeakerIsOther = State(initialValue: true)
            _openingIndonesian = State(initialValue: "")
            _openingKorean = State(initialValue: "")
            _openingRomanization = State(initialValue: "")
            _shareWithFriends = State(initialValue: false)
        }
    }

    private let emojiChoices = ["💬", "🌅", "☀️", "☕️", "💼", "🍜", "🚌", "🛒", "🎬", "🏖️", "🌧️", "🎉", "🤝", "📱"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    EncouragementBanner(tone: .scenario)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                Section("스몰토크 정보") {
                    HStack {
                        Text("이모지").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Menu {
                            ForEach(emojiChoices, id: \.self) { e in
                                Button(action: { emoji = e }) { Text(e) }
                            }
                        } label: {
                            Text(emoji).font(.system(size: 28))
                        }
                    }
                    TextField("제목 (인도네시아어) — 예: Di Pasar", text: $title)
                    TextField("제목 (한국어) — 예: 시장에서", text: $titleKo)
                    TextField("간단한 설명", text: $description, axis: .vertical)
                        .lineLimit(1...3)
                    Picker("난이도", selection: $difficulty) {
                        ForEach([ConversationScenario.Difficulty.beginner, .intermediate, .advanced], id: \.self) { d in
                            Text(d.labelKo).tag(d)
                        }
                    }
                }

                Section {
                    Picker("누가 먼저 말해요?", selection: $openerSpeakerIsOther) {
                        Text("상대방").tag(true)
                        Text("나").tag(false)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("작은 대화는 보통 상대방이 먼저 말을 거는 상황에서 시작해요.")
                        .font(.caption2)
                }

                Section("첫 마디") {
                    HStack(alignment: .top, spacing: 8) {
                        TextField("인도네시아어 — 예: Selamat siang!", text: $openingIndonesian, axis: .vertical)
                            .lineLimit(1...3)
                            .autocorrectionDisabled()
                        Button(action: toggleDictation) {
                            Image(systemName: speech.isListening ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 22))
                                .foregroundColor(speech.isListening ? .red : .blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(!speech.permissionGranted && permissionAsked)
                    }
                    if speech.isListening {
                        Text("듣는 중… 말이 끝나면 자동 종료").font(.caption).foregroundColor(.secondary)
                    }
                    TextField("한국어 뜻 — 예: 안녕하세요!", text: $openingKorean, axis: .vertical)
                        .lineLimit(1...3)
                    TextField("발음 (선택) — 예: 슬라맛 시앙", text: $openingRomanization)
                }

                Section {
                    if editing == nil {
                        Toggle(isOn: $shareWithFriends) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill").foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("친구와 함께 보기").font(.system(size: 14, weight: .medium))
                                    Text("iCloud 로 공유 — 만든 후 카드에서 공유 링크 보내기")
                                        .font(.system(size: 11)).foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: shareWithFriends ? "person.2.fill" : "lock.fill")
                                .foregroundColor(shareWithFriends ? .purple : .secondary)
                            Text(shareWithFriends ? "친구와 함께 보는 시나리오" : "내 기기에만 저장")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let saveError {
                        Text(saveError).font(.caption).foregroundColor(.red)
                    }
                }

                Section {
                    Text(editing == nil
                        ? "저장 후 연습 화면에서 '+ 내 대답 추가하기'로 답변을 하나씩 늘릴 수 있어요."
                        : "이 시나리오의 첫 마디·메타데이터를 수정합니다. 추가된 응답은 그대로 유지돼요.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if saving {
                        ProgressView()
                    } else {
                        Button("저장") { save() }
                            .disabled(!isValid)
                    }
                }
            }
            .task {
                if !permissionAsked {
                    permissionAsked = true
                    await speech.requestPermissions()
                }
            }
            .onChange(of: speech.recognizedText) { _, newValue in
                if speech.isListening, !newValue.isEmpty {
                    openingIndonesian = newValue
                }
            }
        }
    }

    private var isValid: Bool {
        !trimmed(title).isEmpty
            && !trimmed(titleKo).isEmpty
            && !trimmed(openingIndonesian).isEmpty
            && !trimmed(openingKorean).isEmpty
    }

    private func toggleDictation() {
        if speech.isListening {
            speech.stopListening()
            return
        }
        do {
            try speech.startListening(onSilence: nil)
        } catch {
            print("Dictation start failed: \(error)")
        }
    }

    private var navTitle: String {
        switch editing {
        case .none: return "새 스몰토크"
        case .some: return "스몰토크 수정"
        }
    }

    private func save() {
        switch editing {
        case .local(var existing):
            existing.title = trimmed(title)
            existing.titleKo = trimmed(titleKo)
            existing.description = trimmed(description)
            existing.emoji = emoji
            existing.difficultyRaw = difficulty.rawValue
            existing.openerSpeakerIsOther = openerSpeakerIsOther
            existing.openingIndonesian = trimmed(openingIndonesian)
            existing.openingKorean = trimmed(openingKorean)
            existing.openingRomanization = trimmed(openingRomanization)
            store.update(existing)
            dismiss()

        case .shared(var existing):
            existing.title = trimmed(title)
            existing.titleKo = trimmed(titleKo)
            existing.description = trimmed(description)
            existing.emoji = emoji
            existing.difficultyRaw = difficulty.rawValue
            existing.openerSpeakerIsOther = openerSpeakerIsOther
            existing.openingIndonesian = trimmed(openingIndonesian)
            existing.openingKorean = trimmed(openingKorean)
            existing.openingRomanization = trimmed(openingRomanization)
            saving = true
            saveError = nil
            Task {
                let ok = await sharedStore.update(existing)
                await MainActor.run {
                    saving = false
                    if ok { dismiss() }
                    else { saveError = sharedStore.lastError ?? "저장 실패" }
                }
            }

        case .none:
            if shareWithFriends { saveShared() } else { saveLocal() }
        }
    }

    private func saveLocal() {
        let s = UserScenario(
            title: trimmed(title),
            titleKo: trimmed(titleKo),
            description: trimmed(description),
            emoji: emoji,
            difficultyRaw: difficulty.rawValue,
            openerSpeakerIsOther: openerSpeakerIsOther,
            openingIndonesian: trimmed(openingIndonesian),
            openingKorean: trimmed(openingKorean),
            openingRomanization: trimmed(openingRomanization)
        )
        store.add(s)
        dismiss()
    }

    private func saveShared() {
        saving = true
        saveError = nil
        let scenario = SharedScenario(
            id: UUID(),
            title: trimmed(title),
            titleKo: trimmed(titleKo),
            description: trimmed(description),
            emoji: emoji,
            difficultyRaw: difficulty.rawValue,
            openerSpeakerIsOther: openerSpeakerIsOther,
            openingIndonesian: trimmed(openingIndonesian),
            openingKorean: trimmed(openingKorean),
            openingRomanization: trimmed(openingRomanization),
            createdAt: Date(),
            ownedByMe: true,
            zoneID: nil,
            ownerDisplay: nil
        )
        Task {
            let success = await sharedStore.add(scenario)
            await MainActor.run {
                saving = false
                if success {
                    dismiss()
                } else {
                    saveError = sharedStore.lastError ?? "저장에 실패했어요. iCloud 로그인을 확인해주세요."
                }
            }
        }
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
