import SwiftUI

/// 대본 보기: 시나리오 트리의 한 갈래를 메신저처럼 보여 준다. (나는 오른쪽, 상대는 왼쪽)
/// 갈림길에서는 다른 대답으로 바꿔 볼 수 있고, 말풍선을 누르면 읽어 준다.
struct ScriptView: View {
    let scenario: ConversationScenario

    @EnvironmentObject var userReplyStore: UserReplyStore
    @StateObject private var speech = SpeechManager()

    /// 갈림길 노드 id → 고른 자식 id
    @State private var picks: [String: String] = [:]
    @State private var showMeaning = true
    @State private var playingIndex: Int?
    @State private var isPlayingAll = false
    /// 한 번이라도 읽어 준 노드 (기록용)
    @State private var playedIds: Set<String> = []

    /// 사용자가 붙인 대답까지 합친 자식들
    private func children(of node: ConversationNode) -> [ConversationNode] {
        node.children + userReplyStore.replies(for: node.id).map { $0.toNode() }
    }

    /// 기본 갈래: 긍정적인 대답 → 없으면 첫 번째
    private func defaultChild(_ kids: [ConversationNode]) -> ConversationNode? {
        kids.first { $0.polarity == .positive } ?? kids.first
    }

    /// 지금 보여 줄 한 갈래
    private var path: [ConversationNode] {
        var result = [scenario.root]
        var node = scenario.root
        while result.count < 200 {
            let kids = children(of: node)
            guard let next = kids.first(where: { $0.id == picks[node.id] }) ?? defaultChild(kids) else { break }
            result.append(next)
            node = next
        }
        return result
    }

    var body: some View {
        let lines = path
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    header
                    ForEach(Array(lines.enumerated()), id: \.element.id) { i, node in
                        bubble(node, index: i)
                            .id(node.id)
                        let kids = children(of: node)
                        if kids.count > 1 { branchMenu(parent: node, kids: kids) }
                    }
                    if lines.count == 1 {
                        Text("아직 이어지는 대화가 없어요.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .onChange(of: playingIndex) { _, i in
                guard let i, lines.indices.contains(i) else { return }
                withAnimation { proxy.scrollTo(lines[i].id, anchor: .center) }
            }
        }
        .safeAreaInset(edge: .bottom) { playAllBar(lines) }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("대본 보기"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showMeaning.toggle() } label: {
                    Image(systemName: showMeaning ? "eye" : "eye.slash")
                }
                .accessibilityLabel(showMeaning ? Text("뜻 숨기기") : Text("뜻 보이기"))
            }
        }
        .onDisappear {
            stopPlaying()
            recordIfNeeded()
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(spacing: 12) {
            Text(scenario.emoji).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 3) {
                Text(scenario.title)
                    .font(.system(size: 16, weight: .bold))
                Text(scenario.titleKo)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.bottom, 6)
    }

    private func bubble(_ node: ConversationNode, index: Int) -> some View {
        let isMe = node.speaker == .me
        let playing = playingIndex == index
        return HStack(alignment: .bottom) {
            if isMe { Spacer(minLength: 50) }
            Button { play(node, index: index) } label: {
                VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                    Text(node.text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isMe ? .white : .primary)
                        .multilineTextAlignment(isMe ? .trailing : .leading)
                    if !node.displayRomanization.isEmpty {
                        Text(node.displayRomanization)
                            .font(.system(size: 12))
                            .foregroundColor(isMe ? .white.opacity(0.8) : Brand.blue)
                    }
                    if showMeaning && !node.meaning.isEmpty {
                        Text(node.meaning)
                            .font(.system(size: 12.5))
                            .foregroundColor(isMe ? .white.opacity(0.75) : .secondary)
                            .multilineTextAlignment(isMe ? .trailing : .leading)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isMe ? AnyShapeStyle(Brand.gradient) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(playing ? Brand.glow : Color.clear, lineWidth: 2.5)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(node.speaker.labelKo): \(node.text)"))
            .accessibilityHint(Text("눌러서 듣기"))
            if !isMe { Spacer(minLength: 50) }
        }
    }

    /// 갈림길: 다른 대답으로 바꾸기
    private func branchMenu(parent: ConversationNode, kids: [ConversationNode]) -> some View {
        let currentId = picks[parent.id] ?? defaultChild(kids)?.id
        let nextIsMe = kids.first?.speaker == .me
        return HStack {
            if nextIsMe { Spacer() }
            Menu {
                ForEach(kids, id: \.id) { kid in
                    Button {
                        picks[parent.id] = kid.id
                        stopPlaying()
                    } label: {
                        if kid.id == currentId {
                            Label(kid.text, systemImage: "checkmark")
                        } else {
                            Text(kid.text)
                        }
                    }
                }
            } label: {
                Label(String(localized: "다른 대답 \(kids.count - 1)개"), systemImage: "arrow.triangle.branch")
                    .font(.system(size: 11.5, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Brand.blue.opacity(0.1)))
                    .foregroundColor(Brand.blue)
            }
            if !nextIsMe { Spacer() }
        }
    }

    private func playAllBar(_ lines: [ConversationNode]) -> some View {
        Button {
            isPlayingAll ? stopPlaying() : playAll(lines, from: 0)
        } label: {
            Label(isPlayingAll ? String(localized: "멈추기") : String(localized: "전체 듣기"),
                  systemImage: isPlayingAll ? "stop.fill" : "play.fill")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(isPlayingAll ? Color.red : Brand.solidBlue))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Playback

    private func play(_ node: ConversationNode, index: Int) {
        isPlayingAll = false
        playingIndex = index
        playedIds.insert(node.id)
        speech.speak(node.text) {
            if playingIndex == index && !isPlayingAll { playingIndex = nil }
        }
    }

    private func playAll(_ lines: [ConversationNode], from start: Int) {
        guard lines.indices.contains(start) else {
            isPlayingAll = false
            playingIndex = nil
            return
        }
        isPlayingAll = true
        playingIndex = start
        playedIds.insert(lines[start].id)
        speech.speak(lines[start].text) {
            // 도중에 멈췄거나 갈래를 바꿨으면 이어 가지 않는다
            guard isPlayingAll, playingIndex == start else { return }
            playAll(lines, from: start + 1)
        }
    }

    private func stopPlaying() {
        isPlayingAll = false
        playingIndex = nil
        speech.stopSpeaking()
    }

    private func recordIfNeeded() {
        guard !playedIds.isEmpty else { return }
        PracticeHistoryStore.shared.record(scenario: scenario, mode: .script, lines: playedIds.count)
        playedIds = []
    }
}
