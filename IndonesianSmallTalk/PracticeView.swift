import SwiftUI

struct PracticeView: View {
    @StateObject var session: PracticeSession
    @EnvironmentObject var userReplyStore: UserReplyStore
    @EnvironmentObject var sharedReplyStore: SharedReplyStore
    @EnvironmentObject var sharedScenarioStore: SharedScenarioStore
    @StateObject private var speech = SpeechManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showCoachTip = false
    @State private var selectedForTip: ConversationNode?
    @State private var showResult = false
    @State private var animateChoice = false
    @State private var showTranslation: Set<String> = []
    @State private var showAddReply = false
    @State private var autoSpeak = true
    @State private var lastSpokenId: String?

    private var currentParentId: String {
        session.currentPath.last?.id ?? ""
    }

    /// 현재 시나리오가 공유 시나리오면 그 SharedScenario 반환 (없으면 nil)
    private var matchingSharedScenario: SharedScenario? {
        sharedScenarioStore.allScenarios.first { $0.id == session.scenario.id }
    }

    private var mergedChoices: [ConversationNode] {
        let local = userReplyStore.replies(for: currentParentId).map { $0.toNode() }
        let shared = sharedReplyStore.replies(for: currentParentId).map { $0.toNode() }
        return session.availableChoices + local + shared
    }

    /// 마지막 노드가 상대방 발화면 사용자 차례 — 선택지(+ 추가 버튼)를 항상 노출
    private var shouldShowChoices: Bool {
        !mergedChoices.isEmpty || session.currentPath.last?.speaker == .other
    }

    /// 사용자 차례에서 선택지가 비어있지 않은 한 종료로 보지 않음
    private var shouldShowFinish: Bool {
        mergedChoices.isEmpty && session.currentPath.last?.speaker == .me
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── 상단 헤더
                topBar

                // ── 진행도 바
                progressSection

                // ── 대화 히스토리 + 선택지
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // 대화 히스토리
                            ForEach(Array(session.currentPath.enumerated()), id: \.element.id) { idx, node in
                                ChatBubbleView(
                                    node: node,
                                    isLatest: idx == session.currentPath.count - 1,
                                    showTranslation: showTranslation.contains(node.id),
                                    isSpeakingThis: speech.isSpeaking && lastSpokenId == node.id,
                                    onToggleTranslation: {
                                        if showTranslation.contains(node.id) {
                                            showTranslation.remove(node.id)
                                        } else {
                                            showTranslation.insert(node.id)
                                        }
                                    },
                                    onSpeak: { speakNode(node) }
                                )
                                .id(node.id)
                            }

                            // 선택지
                            if shouldShowChoices {
                                choiceSection
                                    .id("choices")
                            }

                            // 완료 버튼
                            if shouldShowFinish {
                                finishButton
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .onChange(of: session.currentPath.count) { _ in
                        withAnimation(.spring()) {
                            proxy.scrollTo("choices", anchor: .center)
                        }
                        if autoSpeak, let last = session.currentPath.last, last.speaker == .other {
                            speakNode(last)
                        }
                    }
                    .onAppear {
                        if autoSpeak, let last = session.currentPath.last, last.speaker == .other {
                            speakNode(last)
                        }
                    }
                    .onChange(of: session.isFinished) { finished in
                        if finished {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                proxy.scrollTo("finish", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedForTip) { node in
            CoachTipView(node: node)
        }
        .sheet(isPresented: $showAddReply) {
            AddUserReplyView(
                parentNodeId: currentParentId,
                sharedScenario: matchingSharedScenario
            )
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(session: session, onRestart: {
                session.reset()
                showResult = false
            })
        }
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(session.scenario.title)
                    .font(.system(size: 16, weight: .bold))
                Text(session.scenario.titleKo + " · " + session.scenario.difficulty.labelKo)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 자동읽기 토글
            Button(action: {
                autoSpeak.toggle()
                if !autoSpeak { speech.stopSpeaking() }
            }) {
                Image(systemName: autoSpeak ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(autoSpeak ? .blue : Color(.tertiaryLabel))
                    .frame(width: 32, height: 32)
                    .background(autoSpeak ? Color.blue.opacity(0.12) : Color(.systemFill))
                    .clipShape(Circle())
            }

            // 점수
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                Text("\(session.score)")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: Progress
    private var progressSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("진행도")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(session.currentPath.count - 1)턴")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.blue, Color(red: 0.18, green: 0.50, blue: 0.95)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * session.progressRatio, height: 5)
                        .animation(.spring(response: 0.4), value: session.progressRatio)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: Choices
    private var choiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("어떻게 대답할까요?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Pilih jawaban kamu")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.top, 16)

            ForEach(Array(mergedChoices.enumerated()), id: \.element.id) { idx, choice in
                ChoiceButton(
                    node: choice,
                    index: idx,
                    onTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            session.choose(choice)
                        }
                        if session.isFinished {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                showResult = true
                            }
                        }
                    },
                    onTipTap: {
                        selectedForTip = choice
                    }
                )
                .contextMenu {
                    if choice.isUserAdded, let rid = choice.userReplyId {
                        Button(role: .destructive) {
                            if let sharedScenario = matchingSharedScenario,
                               sharedReplyStore.replies.contains(where: { $0.id == rid }) {
                                Task { await sharedReplyStore.delete(id: rid, parentScenario: sharedScenario) }
                            } else {
                                userReplyStore.delete(id: rid)
                            }
                        } label: {
                            Label("내 대답 삭제", systemImage: "trash")
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // + 내 대답 추가
            Button(action: { showAddReply = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("내 대답 추가하기")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.blue)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.04))
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .id("choices")
    }

    // MARK: TTS

    private func speakNode(_ node: ConversationNode) {
        speech.stopSpeaking()
        lastSpokenId = node.id
        // 비교용 정규화로 이모지/특수기호를 거른 후 읽어줌
        let cleaned = SpeechManager.normalizeForMatch(node.indonesian)
        let textToSpeak = cleaned.isEmpty ? node.indonesian : cleaned
        speech.speak(textToSpeak)
    }

    // MARK: Finish Button
    private var finishButton: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text("대화 완료!")
                .font(.system(size: 18, weight: .bold))
            Text("Percakapan selesai! 🎉")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .id("finish")
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let node: ConversationNode
    let isLatest: Bool
    let showTranslation: Bool
    var isSpeakingThis: Bool = false
    let onToggleTranslation: () -> Void
    var onSpeak: (() -> Void)? = nil

    private var isMe: Bool { node.speaker == .me }

    private var bubbleColor: Color {
        if isMe {
            return Color(red: 0.95, green: 0.96, blue: 1.0)
        } else {
            return Color(.secondarySystemGroupedBackground)
        }
    }

    private var borderColor: Color {
        if isLatest {
            return isMe ? Color.blue.opacity(0.5) : Color.orange.opacity(0.5)
        }
        return Color(.separator).opacity(0.5)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isMe { Spacer(minLength: 40) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                // 스피커 + 폴라리티 + 재생
                HStack(spacing: 6) {
                    if !isMe { speakerLabel }
                    if node.polarity != .neutral { polarityBadge }
                    if isMe { speakerLabel }
                    if let onSpeak {
                        Button(action: onSpeak) {
                            Image(systemName: isSpeakingThis ? "speaker.wave.2.fill" : "play.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(isSpeakingThis ? .blue : Color(.tertiaryLabel))
                                .symbolEffect(.bounce, value: isSpeakingThis)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 말풍선
                VStack(alignment: .leading, spacing: 6) {
                    // 인도네시아어 (메인)
                    Text(node.indonesian)
                        .font(.system(size: 15, weight: isLatest ? .semibold : .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    // 발음
                    if !node.romanization.isEmpty {
                        Text(node.romanization)
                            .font(.system(size: 11, design: .serif))
                            .italic()
                            .foregroundColor(Color(.tertiaryLabel))
                    }

                    // 번역 (탭 토글)
                    if showTranslation {
                        Divider()
                        Text(node.korean)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(bubbleColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(borderColor, lineWidth: isLatest ? 1.5 : 0.5)
                        )
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        onToggleTranslation()
                    }
                }

                Text("탭하면 한국어 번역")
                    .font(.system(size: 9))
                    .foregroundColor(Color(.quaternaryLabel))
            }

            if !isMe { Spacer(minLength: 40) }
        }
        .padding(.vertical, 5)
    }

    private var speakerLabel: some View {
        Text(isMe ? "나" : "상대방")
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundColor(isMe ? .blue : Color(.tertiaryLabel))
    }

    private var polarityBadge: some View {
        Text(node.polarity.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(node.polarity == .positive ? Color(red: 0.2, green: 0.55, blue: 0.1) : Color(red: 0.65, green: 0.1, blue: 0.1))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(node.polarity == .positive ? Color.green.opacity(0.12) : Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(
                                node.polarity == .positive ? Color.green.opacity(0.4) : Color.red.opacity(0.3),
                                lineWidth: 0.8
                            )
                    )
            )
    }
}

// MARK: - Choice Button
struct ChoiceButton: View {
    let node: ConversationNode
    let index: Int
    let onTap: () -> Void
    let onTipTap: () -> Void
    @State private var pressed = false

    private var accentColor: Color {
        node.polarity == .positive ? .green : node.polarity == .negative ? Color.orange : .blue
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 번호 배지
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(node.indonesian)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        if node.isUserAdded {
                            Text("내가 추가")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.purple.opacity(0.12))
                                )
                        }
                    }
                    if !node.romanization.isEmpty {
                        Text(node.romanization)
                            .font(.system(size: 10.5, design: .serif))
                            .italic()
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    Text(node.korean)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 폴라리티 + 팁 버튼 (세로 스택)
                VStack(spacing: 6) {
                    if node.polarity != .neutral {
                        Text(node.polarity == .positive ? "+" : "−")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(node.polarity == .positive ? .green : Color.orange)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(node.polarity == .positive ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                            )
                    }
                    if node.coachTip != nil {
                        Button(action: onTipTap) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.yellow.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Pressable Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
