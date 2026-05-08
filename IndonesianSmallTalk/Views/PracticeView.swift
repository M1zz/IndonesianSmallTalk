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
    @State private var showTreeView = false
    @State private var autoSpeak = true
    @State private var lastSpokenId: String?
    @State private var openerChosen = false
    @State private var selectedPreOpener: ConversationNode? = nil
    @State private var addReplyTarget: AddReplyTarget? = nil
    @State private var replyToEdit: UserReply? = nil
    @State private var finishCountdown: Int = 10
    @State private var countdownTask: Task<Void, Never>? = nil

    private var currentParentId: String {
        session.currentPath.last?.id ?? ""
    }

    private var openerParentId: String {
        "openers-\(session.scenario.id.uuidString)"
    }

    private var preOpenerParentId: String {
        "pre-openers-\(session.scenario.id.uuidString)"
    }

    private var alternativeOpeners: [ConversationNode] {
        userReplyStore.replies(for: openerParentId).map { $0.toNode() }
    }

    private var allOpeners: [ConversationNode] {
        [session.scenario.root] + alternativeOpeners
    }

    private var preOpeners: [ConversationNode] {
        userReplyStore.replies(for: preOpenerParentId).map { $0.toNode() }
    }

    /// 현재 시나리오 root의 반대 발화자 (pre-opener는 항상 root와 반대)
    private var preOpenerSpeaker: ConversationNode.Speaker {
        session.scenario.root.speaker == .other ? .me : .other
    }

    private var preOpenerSectionLabel: String {
        preOpenerSpeaker == .me ? "내가 먼저 말할 때" : "상대방이 먼저 말할 때"
    }

    private var preOpenerAddLabel: String {
        preOpenerSpeaker == .me ? "내가 먼저 말하는 대화 추가하기" : "상대방이 먼저 말하는 대화 추가하기"
    }

    private var defaultOpenerSectionLabel: String {
        session.scenario.root.speaker == .other ? "상대방이 먼저 말할 때" : "내가 먼저 말할 때"
    }

    private var shouldShowOpenerPicker: Bool {
        !openerChosen && session.currentPath.count == 1 && !preOpeners.isEmpty
    }

    /// 현재 시나리오가 공유 시나리오면 그 SharedScenario 반환 (없으면 nil)
    private var matchingSharedScenario: SharedScenario? {
        sharedScenarioStore.allScenarios.first { $0.id == session.scenario.id }
    }

    private var mergedChoices: [ConversationNode] {
        let local = userReplyStore.replies(for: currentParentId).map { $0.toNode() }
        let shared = sharedReplyStore.replies(for: currentParentId).map { $0.toNode() }
        let rootId = session.scenario.root.id

        // pre-opener 선택 직후: 원래 첫 마디들(allOpeners)이 응답 선택지로 노출
        if selectedPreOpener != nil && session.currentPath.count == 1 {
            return allOpeners + local + shared
        }
        // depth-1 + alternative opener selected: root-level replies still apply
        if session.currentPath.count == 1 && currentParentId != rootId {
            let rootLocal = userReplyStore.replies(for: rootId).map { $0.toNode() }
            let rootShared = sharedReplyStore.replies(for: rootId).map { $0.toNode() }
            return session.availableChoices + local + rootLocal + shared + rootShared
        }
        return session.availableChoices + local + shared
    }

    /// opener picker 가 보일 때 root.id 에 등록된 응답 — 오프너 선택 전에도 바로 보여줌
    private var rootLevelReplies: [ConversationNode] {
        let rootId = session.scenario.root.id
        let local = userReplyStore.replies(for: rootId).map { $0.toNode() }
        let shared = sharedReplyStore.replies(for: rootId).map { $0.toNode() }
        return local + shared
    }

    /// 루트에 있거나 선택지가 있거나 상대방이 방금 말했으면 선택지 영역 노출
    private var shouldShowChoices: Bool {
        !mergedChoices.isEmpty
            || session.currentPath.last?.speaker == .other
            || session.currentPath.count == 1
    }

    /// 루트가 아닌 상태에서 내 차례인데 선택지가 없으면 종료
    private var shouldShowFinish: Bool {
        mergedChoices.isEmpty
            && session.currentPath.last?.speaker == .me
            && session.currentPath.count > 1
    }

    /// 다음에 추가할 응답의 발화자 (현재 마지막 발화자의 반대)
    private var nextSpeaker: ConversationNode.Speaker {
        session.currentPath.last?.speaker == .me ? .other : .me
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
                            if shouldShowOpenerPicker {
                                // 첫 마디 선택 화면
                                openerPickerSection
                                    .id("openers")

                                // 오프너 선택 전에도 추가된 응답을 바로 볼 수 있게
                                if !rootLevelReplies.isEmpty {
                                    rootReplyPreviewSection
                                        .id("root-replies")
                                }
                            } else {
                                // 대화 히스토리
                                ForEach(Array(session.currentPath.enumerated()), id: \.element.id) { idx, node in
                                    chatBubbleView(idx: idx, node: node)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .move(edge: .trailing).combined(with: .opacity)
                                        ))
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
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .onChange(of: session.currentPath.count) { _ in
                        withAnimation(.spring()) {
                            proxy.scrollTo("choices", anchor: .center)
                        }
                        if autoSpeak, let last = session.currentPath.last {
                            speakNode(last)
                        }
                    }
                    .onAppear {
                        guard !shouldShowOpenerPicker else { return }
                        if autoSpeak, let last = session.currentPath.last {
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
        .sheet(isPresented: $showTreeView) {
            TreeSheetView(scenario: session.scenario)
        }
        .sheet(item: $selectedForTip) { node in
            CoachTipView(node: node)
        }
        .sheet(item: $addReplyTarget) { target in
            AddUserReplyView(
                parentNodeId: target.parentNodeId,
                nextSpeaker: target.speaker,
                sharedScenario: target.sharedScenario
            )
        }
        .sheet(item: $replyToEdit) { reply in
            AddUserReplyView(
                parentNodeId: reply.parentNodeId,
                nextSpeaker: reply.speakerRaw == "other" ? .other : .me,
                sharedScenario: nil,
                editingReply: reply
            )
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(session: session, onRestart: {
                session.reset()
                openerChosen = false
                selectedPreOpener = nil
                showResult = false
            })
        }
        .onChange(of: shouldShowFinish) { _, isShowing in
            if isShowing { startFinishCountdown() }
            else { cancelFinishCountdown() }
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

            // 트리 보기 버튼
            Button(action: { showTreeView = true }) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
                    .frame(width: 32, height: 32)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }

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
                Text(selectedPreOpener != nil
                     ? (nextSpeaker == .me ? "어떻게 대답할까요?" : "상대방이 뭐라고 할까요?")
                     : (nextSpeaker == .me ? "어떻게 대답할까요?" : "상대방이 뭐라고 할까요?"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                // 작은 + 아이콘 — 눌러서 직접 추가도 가능
                Button {
                    addReplyTarget = AddReplyTarget(
                        parentNodeId: currentParentId,
                        speaker: nextSpeaker,
                        sharedScenario: matchingSharedScenario
                    )
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.blue.opacity(0.6))
                }
                .buttonStyle(.plain)
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
                        if selectedPreOpener != nil { selectedPreOpener = nil }
                    },
                    onTipTap: { selectedForTip = choice }
                )
                .contextMenu {
                    // 같은 위치에 추가
                    Button {
                        addReplyTarget = AddReplyTarget(
                            parentNodeId: currentParentId,
                            speaker: choice.speaker,
                            sharedScenario: matchingSharedScenario
                        )
                    } label: {
                        Label("같은 위치에 추가하기", systemImage: "plus.circle")
                    }

                    if choice.isUserAdded, let rid = choice.userReplyId {
                        // 수정
                        if let reply = userReplyStore.replies.first(where: { $0.id == rid }) {
                            Button { replyToEdit = reply } label: {
                                Label("수정하기", systemImage: "pencil")
                            }
                        }
                        // 삭제
                        Button(role: .destructive) {
                            if let sharedScenario = matchingSharedScenario,
                               sharedReplyStore.replies.contains(where: { $0.id == rid }) {
                                Task { await sharedReplyStore.delete(id: rid, parentScenario: sharedScenario) }
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    userReplyStore.delete(id: rid)
                                }
                            }
                        } label: {
                            Label(choice.speaker == .me ? "내 대답 삭제" : "상대방 응답 삭제", systemImage: "trash")
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: mergedChoices.count)

            // 선택지가 없을 때만 빈 상태 힌트
            if mergedChoices.isEmpty {
                Text("길게 눌러서 추가하거나 위 + 버튼을 이용하세요")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
        .id("choices")
    }

    // MARK: Chat Bubble Helper

    @ViewBuilder
    private func chatBubbleView(idx: Int, node: ConversationNode) -> some View {
        let bubble = ChatBubbleView(
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

        bubble.contextMenu {
            // 같은 위치에 추가 (형제 노드)
            if idx == 0 {
                Button {
                    addReplyTarget = AddReplyTarget(
                        parentNodeId: openerParentId,
                        speaker: session.scenario.root.speaker,
                        sharedScenario: nil
                    )
                } label: {
                    Label("다른 첫 마디 추가하기", systemImage: "plus.bubble")
                }
                Button {
                    addReplyTarget = AddReplyTarget(
                        parentNodeId: preOpenerParentId,
                        speaker: preOpenerSpeaker,
                        sharedScenario: nil
                    )
                } label: {
                    Label(preOpenerAddLabel, systemImage: "text.bubble")
                }
            } else {
                let parentNode = session.currentPath[idx - 1]
                Button {
                    addReplyTarget = AddReplyTarget(
                        parentNodeId: parentNode.id,
                        speaker: node.speaker,
                        sharedScenario: matchingSharedScenario
                    )
                } label: {
                    Label("이 위치에 대화 추가하기", systemImage: "plus.bubble")
                }
            }

            // 수정 / 삭제 (사용자 추가 노드만)
            if node.isUserAdded {
                if let rid = node.userReplyId {
                    if let reply = userReplyStore.replies.first(where: { $0.id == rid }) {
                        Button { replyToEdit = reply } label: {
                            Label("수정하기", systemImage: "pencil")
                        }
                    }
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            userReplyStore.delete(id: rid)
                            if idx == 0 {
                                session.currentPath = [session.scenario.root]
                                openerChosen = false
                                selectedPreOpener = nil
                            } else {
                                session.currentPath = Array(session.currentPath[0..<idx])
                            }
                        }
                    } label: {
                        Label("삭제하기", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: Opener Picker

    private var openerPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("어떻게 시작할까요?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Bagaimana mulainya?")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.top, 16)

            // ── pre-opener (root와 반대 발화자 먼저) ────────────
            if !preOpeners.isEmpty {
                sectionLabel(preOpenerSectionLabel, color: .orange)

                ForEach(Array(preOpeners.enumerated()), id: \.element.id) { idx, opener in
                    preOpenerItem(opener: opener, idx: idx)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: preOpeners.count)
            }

            addButton(label: preOpenerAddLabel, icon: "text.bubble.fill", color: .orange) {
                addReplyTarget = AddReplyTarget(parentNodeId: preOpenerParentId,
                                               speaker: preOpenerSpeaker,
                                               sharedScenario: nil)
            }

            // ── 기본 opener: 루트는 항상 하나 ──────────────────
            sectionLabel(defaultOpenerSectionLabel, color: .blue)
                .padding(.top, 8)

            openerCard(opener: session.scenario.root, index: 0, accent: .blue)
                .onTapGesture {
                    openerChosen = true
                    if autoSpeak {
                        speakNode(session.scenario.root)
                    }
                }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 13)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.top, 4)
    }

    // Button 없이 순수 뷰만 반환 — contextMenu와 onTapGesture를 호출부에서 분리 적용
    private func openerCard(opener: ConversationNode, index: Int, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(opener.indonesian)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    if opener.isUserAdded {
                        Text("내가 추가")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.purple.opacity(0.12)))
                    }
                }
                if !opener.romanization.isEmpty {
                    Text(opener.romanization)
                        .font(.system(size: 10.5, design: .serif))
                        .italic()
                        .foregroundColor(Color(.tertiaryLabel))
                }
                Text(opener.korean)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }

    private func preOpenerItem(opener: ConversationNode, idx: Int) -> some View {
        openerCard(opener: opener, index: idx, accent: .orange)
            .onTapGesture {
                selectedPreOpener = opener
                session.setPreOpener(opener)
                openerChosen = true
                if autoSpeak { speakNode(opener) }
            }
            .contextMenu {
                Button {
                    addReplyTarget = AddReplyTarget(parentNodeId: preOpenerParentId,
                                                    speaker: preOpenerSpeaker,
                                                    sharedScenario: nil)
                } label: { Label("추가하기", systemImage: "plus.circle") }
                Button {
                    if let rid = opener.userReplyId,
                       let reply = userReplyStore.replies.first(where: { $0.id == rid }) {
                        replyToEdit = reply
                    }
                } label: { Label("수정하기", systemImage: "pencil") }
                Button(role: .destructive) {
                    if let rid = opener.userReplyId {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            userReplyStore.delete(id: rid)
                        }
                    }
                } label: { Label("삭제하기", systemImage: "trash") }
            }
    }

    @ViewBuilder
    private func addButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .foregroundColor(color)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(color.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.04)))
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: Root Reply Preview (opener picker 아래에 표시)

    private var rootReplyPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(nextSpeaker == .me ? "추가된 내 대답" : "추가된 상대방 응답")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("첫 마디 선택 후 바로 연습")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.top, 16)

            ForEach(Array(rootLevelReplies.enumerated()), id: \.element.id) { idx, choice in
                ChoiceButton(
                    node: choice,
                    index: idx,
                    onTap: {
                        // root opener 자동 선택 후 응답 진행
                        openerChosen = true
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            session.choose(choice)
                        }
                    },
                    onTipTap: { selectedForTip = choice }
                )
                .contextMenu {
                    Button {
                        addReplyTarget = AddReplyTarget(
                            parentNodeId: session.scenario.root.id,
                            speaker: choice.speaker,
                            sharedScenario: matchingSharedScenario
                        )
                    } label: { Label("같은 위치에 추가하기", systemImage: "plus.circle") }

                    if choice.isUserAdded {
                        if let rid = choice.userReplyId {
                            if let reply = userReplyStore.replies.first(where: { $0.id == rid }) {
                                Button { replyToEdit = reply } label: {
                                    Label("수정하기", systemImage: "pencil")
                                }
                            }
                            Button(role: .destructive) {
                                if let sharedScenario = matchingSharedScenario,
                                   sharedReplyStore.replies.contains(where: { $0.id == rid }) {
                                    Task { await sharedReplyStore.delete(id: rid, parentScenario: sharedScenario) }
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        userReplyStore.delete(id: rid)
                                    }
                                }
                            } label: {
                                Label(choice.speaker == .me ? "내 대답 삭제" : "상대방 응답 삭제", systemImage: "trash")
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: rootLevelReplies.count)
        }
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

    // MARK: Finish / Extend

    private var finishButton: some View {
        VStack(spacing: 22) {
            // ── 완료 표시
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.green)
                Text("대화 완료!")
                    .font(.system(size: 17, weight: .bold))
                Text("Percakapan selesai! 🎉")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // ── 카운트다운 + 결과 이동
            VStack(spacing: 12) {
                ZStack {
                    // 배경 링
                    Circle()
                        .stroke(Color(.systemFill), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    // 진행 링 (5 → 0)
                    Circle()
                        .trim(from: 0, to: CGFloat(finishCountdown) / 10.0)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: finishCountdown)
                    // 숫자
                    Text("\(finishCountdown)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.default, value: finishCountdown)
                }

                Text("\(finishCountdown)초 후 결과 화면으로 이동")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))

                Button {
                    cancelFinishCountdown()
                    showResult = true
                } label: {
                    Text("결과 화면으로 가기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            // ── 다음 뎁스 추가
            VStack(spacing: 6) {
                Text("또는 대화를 이어갈 수 있어요")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))

                Button {
                    cancelFinishCountdown()
                    addReplyTarget = AddReplyTarget(
                        parentNodeId: currentParentId,
                        speaker: nextSpeaker,
                        sharedScenario: matchingSharedScenario
                    )
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: nextSpeaker == .other
                              ? "bubble.right.fill" : "bubble.left.fill")
                            .font(.system(size: 13))
                        Text(nextSpeaker == .other
                             ? "상대방 다음 대화 추가"
                             : "내 다음 대화 추가")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .id("finish")
    }

    // MARK: Countdown

    private func startFinishCountdown() {
        finishCountdown = 10
        countdownTask?.cancel()
        countdownTask = Task {
            do {
                var remaining = 10
                while remaining > 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    remaining -= 1
                    await MainActor.run {
                        withAnimation { finishCountdown = remaining }
                    }
                }
                await MainActor.run { showResult = true }
            } catch {
                // 취소됨 — 아무것도 하지 않음
            }
        }
    }

    private func cancelFinishCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        finishCountdown = 10
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

// MARK: - Add Reply Target
struct AddReplyTarget: Identifiable {
    let id = UUID()
    let parentNodeId: String
    let speaker: ConversationNode.Speaker
    let sharedScenario: SharedScenario?
}
