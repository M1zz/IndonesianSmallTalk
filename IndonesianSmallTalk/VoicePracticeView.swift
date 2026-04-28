import SwiftUI

struct VoicePracticeView: View {
    @StateObject var session: PracticeSession
    @StateObject private var speech = SpeechManager()
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .partnerSpeaking
    @State private var matchedChoice: ConversationNode?
    @State private var showResult = false
    @State private var pulseAmount = 1.0
    @State private var previewChoiceId: String?

    enum Phase {
        case partnerSpeaking   // 상대방 TTS 재생 중
        case waitingToRecord   // 녹음 대기
        case recording         // 녹음 중
        case processing        // 매칭 중
        case matched           // 매칭 완료, 다음 턴으로 전환
        case finished          // 대화 완료
    }

    var body: some View {
        ZStack {
            // 배경 그라데이션
            backgroundGradient

            VStack(spacing: 0) {
                // 상단 바
                topBar
                    .padding(.bottom, 8)

                Spacer()

                // 중앙 대화 영역
                conversationArea

                Spacer()

                // 하단 컨트롤
                bottomControl
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showResult) {
            ResultView(session: session, onRestart: {
                session.reset()
                showResult = false
                phase = .partnerSpeaking
                speakCurrentNode()
            })
        }
        .task {
            await speech.requestPermissions()
            // 시작 인사 후 첫 대사 재생
            speech.speak("Hai!") {
                speakCurrentNode()
            }
        }
        .onDisappear {
            speech.stopSpeaking()
            speech.stopListening()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: phase)
    }

    private var backgroundColors: [Color] {
        switch phase {
        case .partnerSpeaking:
            return [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.12, green: 0.18, blue: 0.32)]
        case .waitingToRecord, .recording:
            return [Color(red: 0.08, green: 0.15, blue: 0.22), Color(red: 0.10, green: 0.22, blue: 0.30)]
        case .processing:
            return [Color(red: 0.12, green: 0.12, blue: 0.20), Color(red: 0.15, green: 0.15, blue: 0.28)]
        case .matched:
            return [Color(red: 0.08, green: 0.18, blue: 0.12), Color(red: 0.10, green: 0.25, blue: 0.15)]
        case .finished:
            return [Color(red: 0.10, green: 0.10, blue: 0.18), Color(red: 0.15, green: 0.12, blue: 0.25)]
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                speech.stopSpeaking()
                speech.stopListening()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.scenario.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(session.scenario.titleKo)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // 점수
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                Text("\(session.score)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Conversation Area

    private var conversationArea: some View {
        VStack(spacing: 24) {
            // 스피커 아이콘
            speakerIcon

            // 현재 대사
            if let node = session.currentNode {
                VStack(spacing: 12) {
                    Text(node.indonesian)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    if !node.romanization.isEmpty {
                        Text(node.romanization)
                            .font(.system(size: 14, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Text(node.korean)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 30)
            }

            // 내 턴일 때 인식된 텍스트
            if phase == .recording || phase == .processing {
                VStack(spacing: 8) {
                    if !speech.recognizedText.isEmpty {
                        Text(speech.recognizedText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.cyan)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
                .transition(.opacity)
            }

            // 매칭 결과
            if phase == .matched, let matched = matchedChoice {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("매칭됨")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Text(matched.indonesian)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var speakerIcon: some View {
        ZStack {
            // 외곽 펄스
            Circle()
                .fill(speakerIconColor.opacity(0.1))
                .frame(width: 120, height: 120)
                .scaleEffect(pulseAmount)

            Circle()
                .fill(speakerIconColor.opacity(0.2))
                .frame(width: 90, height: 90)

            Image(systemName: speakerIconName)
                .font(.system(size: 36))
                .foregroundColor(.white)
        }
        .animation(
            phase == .partnerSpeaking || phase == .recording
                ? .easeInOut(duration: 1).repeatForever(autoreverses: true)
                : .default,
            value: pulseAmount
        )
        .onChange(of: phase) { newPhase in
            if newPhase == .partnerSpeaking || newPhase == .recording {
                pulseAmount = 1.15
            } else {
                pulseAmount = 1.0
            }
        }
    }

    private var speakerIconColor: Color {
        switch phase {
        case .partnerSpeaking: return .orange
        case .waitingToRecord, .recording: return .cyan
        case .processing: return .purple
        case .matched: return .green
        case .finished: return .yellow
        }
    }

    private var speakerIconName: String {
        switch phase {
        case .partnerSpeaking: return "speaker.wave.3.fill"
        case .waitingToRecord: return "mic.fill"
        case .recording: return "mic.fill"
        case .processing: return "ellipsis"
        case .matched: return "checkmark"
        case .finished: return "star.fill"
        }
    }

    // MARK: - Bottom Control

    private var bottomControl: some View {
        VStack(spacing: 16) {
            switch phase {
            case .partnerSpeaking:
                Text("상대방이 말하고 있어요...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))

            case .waitingToRecord:
                Text("아래 중 하나로 대답해보세요")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                choiceHints

                micButton

            case .recording:
                Text("듣고 있어요…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cyan)

                choiceHints

                stopButton

            case .processing:
                ProgressView()
                    .tint(.white)
                Text("매칭 중...")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))

            case .matched:
                Text("다음 대화로 넘어갑니다")
                    .font(.system(size: 14))
                    .foregroundColor(.green.opacity(0.8))

            case .finished:
                Text("대화가 끝났어요!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    private var micButton: some View {
        Button(action: startRecording) {
            ZStack {
                Circle()
                    .fill(.cyan.opacity(0.2))
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(.cyan)
                    .frame(width: 64, height: 64)
                Image(systemName: "mic.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .disabled(!speech.permissionGranted)
    }

    private var stopButton: some View {
        Button(action: stopRecordingAndMatch) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.2))
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(.red)
                    .frame(width: 64, height: 64)
                Image(systemName: "stop.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }

    private var choiceHints: some View {
        VStack(spacing: 8) {
            ForEach(Array(session.availableChoices.enumerated()), id: \.element.id) { idx, choice in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(polarityColor(choice.polarity).opacity(0.55)))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(choice.indonesian)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            if choice.polarity == .positive {
                                Text("+")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.green)
                            } else if choice.polarity == .negative {
                                Text("−")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.orange)
                            }
                        }
                        if !choice.romanization.isEmpty {
                            Text(choice.romanization)
                                .font(.system(size: 11, design: .serif))
                                .italic()
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Text(choice.korean)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer(minLength: 6)

                    Button(action: { previewChoice(choice) }) {
                        Image(systemName: previewChoiceId == choice.id ? "speaker.wave.2.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(previewChoiceId == choice.id ? .cyan : .white.opacity(0.75))
                            .symbolEffect(.bounce, value: previewChoiceId == choice.id)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private func polarityColor(_ p: Polarity) -> Color {
        switch p {
        case .positive: return .green
        case .negative: return .orange
        case .neutral: return Color(red: 0.4, green: 0.5, blue: 0.7)
        }
    }

    private func previewChoice(_ choice: ConversationNode) {
        speech.stopListening()
        previewChoiceId = choice.id
        let cleaned = SpeechManager.normalizeForMatch(choice.indonesian)
        let textToSpeak = cleaned.isEmpty ? choice.indonesian : cleaned
        speech.speak(textToSpeak) {
            previewChoiceId = nil
        }
    }

    // MARK: - Actions

    private func speakCurrentNode() {
        guard let node = session.currentNode else {
            phase = .finished
            return
        }

        if node.speaker == .other {
            phase = .partnerSpeaking
            speech.speak(node.indonesian) {
                if session.isFinished {
                    phase = .finished
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showResult = true
                    }
                } else if session.availableChoices.allSatisfy({ $0.speaker == .me }) {
                    startRecording()
                } else {
                    advanceToNextOther()
                }
            }
        } else {
            if !session.isFinished {
                startRecording()
            } else {
                phase = .finished
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showResult = true
                }
            }
        }
    }

    private func advanceToNextOther() {
        let choices = session.availableChoices
        if choices.count == 1, choices[0].speaker == .other {
            withAnimation(.spring(response: 0.35)) {
                session.choose(choices[0])
            }
            speakCurrentNode()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        withAnimation(.spring(response: 0.3)) {
            phase = .recording
        }
        do {
            try speech.startListening(onSilence: { [self] in
                // 정적 감지 → 자동으로 매칭 진행
                performMatch()
            })
        } catch {
            phase = .waitingToRecord
        }
    }

    private func stopRecordingAndMatch() {
        speech.stopListening()
        performMatch()
    }

    private func performMatch() {
        withAnimation(.spring(response: 0.3)) {
            phase = .processing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let matched = speech.bestMatch(from: session.availableChoices) {
                matchedChoice = matched
                withAnimation(.spring(response: 0.35)) {
                    phase = .matched
                    session.choose(matched)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    matchedChoice = nil
                    speakCurrentNode()
                }
            } else {
                // 매칭 실패 → 다시 시도
                withAnimation(.spring(response: 0.3)) {
                    phase = .waitingToRecord
                }
            }
        }
    }
}
