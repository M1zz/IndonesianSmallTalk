import CloudKit
import SwiftUI

struct HomeView: View {
    let builtinScenarios = ConversationData.allScenarios
    @EnvironmentObject var userScenarioStore: UserScenarioStore
    @EnvironmentObject var sharedScenarioStore: SharedScenarioStore
    @EnvironmentObject var sharedReplyStore: SharedReplyStore
    @EnvironmentObject var aiScenarioStore: AIScenarioStore
    @State private var selectedScenario: ConversationScenario?
    @State private var selectedAIScenario: AIScenario?
    @State private var showPractice = false
    @State private var showVoicePractice = false
    @State private var showAIDetail = false
    @State private var sharePayload: SharePayload?
    @State private var shareError: String?
    @State private var isSharingUserScenario = false
    @State private var isStoppingShare = false
    @State private var addReplyScenario: ConversationScenario?
    @State private var showOnboarding = false

    struct SharePayload: Identifiable {
        let id = UUID()
        let share: CKShare
        let container: CKContainer
    }

    private var unsharedUserScenarios: [UserScenario] {
        userScenarioStore.scenarios.filter {
            !sharedScenarioStore.myScenarioIDs.contains($0.id)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── 헤더 배너
                headerBanner

                // ── 모드 선택 안내
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("탭 = 텍스트 모드")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                    Text("마이크 = 음성 모드")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                .padding(.top, 18)

                sharedSection
                myScenarioSection
                aiScenarioSection
                builtinSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showPractice) {
            if let scenario = selectedScenario {
                PracticeView(session: PracticeSession(scenario: scenario))
            }
        }
        .navigationDestination(isPresented: $showVoicePractice) {
            if let scenario = selectedScenario {
                VoicePracticeView(session: PracticeSession(scenario: scenario))
            }
        }
        .navigationDestination(isPresented: $showAIDetail) {
            if let ai = selectedAIScenario {
                AIScenarioDetailView(aiScenario: ai)
            }
        }

        .sheet(item: $addReplyScenario) { scenario in
            AddUserReplyView(
                parentNodeId: scenario.root.id,
                nextSpeaker: scenario.root.speaker == .me ? .other : .me,
                sharedScenario: sharedScenarioStore.allScenarios.first { $0.id == scenario.id }
            )
        }
        .sheet(item: $sharePayload) { payload in
            CloudKitShareSheet(share: payload.share, container: payload.container) {
                Task { await sharedScenarioStore.refresh() }
            }
            .ignoresSafeArea()
        }
        .alert("공유 실패", isPresented: Binding(
            get: { shareError != nil },
            set: { if !$0 { shareError = nil } }
        )) {
            Button("확인", role: .cancel) { shareError = nil }
        } message: {
            Text(shareError ?? "")
        }
        .overlay {
            if isSharingUserScenario || isStoppingShare {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(.white)
                        Text(isSharingUserScenario ? "iCloud에 업로드 중…" : "공유를 해제하는 중…")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(28)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .refreshable {
            await sharedScenarioStore.refresh()
            await sharedReplyStore.refresh(forScenarios: sharedScenarioStore.allScenarios)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }

    @ViewBuilder
    private var sharedSection: some View {
        if !sharedScenarioStore.allScenarios.isEmpty || sharedScenarioStore.lastError != nil {
            sharedSectionHeader
            VStack(spacing: 14) {
                ForEach(sharedScenarioStore.allScenarios) { shared in
                    ScenarioCard(
                        scenario: shared.toScenario(),
                        isUserAdded: false,
                        badge: shared.ownedByMe ? .sharedByMe : .sharedByFriend,
                        onTap: {
                            selectedScenario = shared.toScenario()
                            showPractice = true
                        },
                        onVoiceTap: {
                            selectedScenario = shared.toScenario()
                            showVoicePractice = true
                        },
                        onAddReply: { addReplyScenario = shared.toScenario() },
                        onShare: shared.ownedByMe ? { shareScenario(id: shared.id) } : nil,
                        onStopShare: shared.ownedByMe ? { stopSharedScenario(shared) } : nil,
                        onDelete: shared.ownedByMe ? { deleteSharedScenario(shared) } : nil
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            if let err = sharedScenarioStore.lastError {
                Text(err)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var aiScenarioSection: some View {
        if !aiScenarioStore.scenarios.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(.purple)
                Text("AI 생성 시나리오").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            VStack(spacing: 14) {
                ForEach(aiScenarioStore.scenarios) { ai in
                    AIScenarioCard(
                        ai: ai,
                        onStudyTap: { selectedAIScenario = ai; showAIDetail = true },
                        onPracticeTap: { selectedScenario = ai.toScenario(); showPractice = true },
                        onVoiceTap: { selectedScenario = ai.toScenario(); showVoicePractice = true },
                        onDelete: { aiScenarioStore.delete(id: ai.id) }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var builtinSection: some View {
        HStack {
            Text("기본 시나리오").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        VStack(spacing: 14) {
            ForEach(builtinScenarios) { scenario in
                ScenarioCard(
                    scenario: scenario,
                    onTap: { selectedScenario = scenario; showPractice = true },
                    onVoiceTap: { selectedScenario = scenario; showVoicePractice = true },
                    onAddReply: { addReplyScenario = scenario }
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var myScenarioSection: some View {
        if !unsharedUserScenarios.isEmpty {
            HStack {
                Text("내 스몰토크")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)

            VStack(spacing: 14) {
                ForEach(unsharedUserScenarios) { userScenario in
                    ScenarioCard(
                        scenario: userScenario.toScenario(),
                        isUserAdded: true,
                        onTap: {
                            selectedScenario = userScenario.toScenario()
                            showPractice = true
                        },
                        onVoiceTap: {
                            selectedScenario = userScenario.toScenario()
                            showVoicePractice = true
                        },
                        onAddReply: { addReplyScenario = userScenario.toScenario() },
                        onShare: { shareUserScenario(userScenario) },
                        onDelete: { userScenarioStore.delete(id: userScenario.id) }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    private var sharedSectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 12))
                .foregroundColor(.purple)
            Text("함께 보는 스몰토크")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
            if sharedScenarioStore.isLoading {
                ProgressView().scaleEffect(0.7)
            } else {
                Button(action: {
                    Task {
                        await sharedScenarioStore.refresh()
                        await sharedReplyStore.refresh(forScenarios: sharedScenarioStore.allScenarios)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
    }

    // 이미 CloudKit에 올라간 SharedScenario 공유 (내가 공유한 항목 재공유)
    private func shareScenario(id: UUID) {
        Task {
            do {
                let (share, container) = try await CloudKitService.shared.createShare(for: id)
                sharePayload = SharePayload(share: share, container: container)
            } catch {
                shareError = error.localizedDescription
            }
        }
    }

    private func deleteSharedScenario(_ shared: SharedScenario) {
        Task { await sharedScenarioStore.delete(id: shared.id) }
    }

    // 이미 SharedScenario로 올라간 것의 공유 해제 (sharedSection에서 호출)
    private func stopSharedScenario(_ shared: SharedScenario) {
        Task {
            isStoppingShare = true
            defer { isStoppingShare = false }
            let ok = await sharedScenarioStore.stopSharing(id: shared.id)
            if !ok { shareError = sharedScenarioStore.lastError }
        }
    }

    // 공유 해제 — CKShare 삭제 + CloudKit 레코드 삭제
    private func stopSharingUserScenario(_ userScenario: UserScenario) {
        Task {
            isStoppingShare = true
            defer { isStoppingShare = false }
            let ok = await sharedScenarioStore.stopSharing(id: userScenario.id)
            if !ok { shareError = sharedScenarioStore.lastError ?? "공유 해제에 실패했어요." }
        }
    }

    // 로컬 UserScenario → CloudKit 업로드 후 공유
    private func shareUserScenario(_ userScenario: UserScenario) {
        Task {
            isSharingUserScenario = true
            defer { isSharingUserScenario = false }

            // 1. SharedScenario로 변환해서 CloudKit에 저장
            let shared = SharedScenario(
                id: userScenario.id,
                title: userScenario.title,
                titleKo: userScenario.titleKo,
                description: userScenario.description,
                emoji: userScenario.emoji,
                difficultyRaw: userScenario.difficultyRaw,
                openerSpeakerIsOther: userScenario.openerSpeakerIsOther,
                openingIndonesian: userScenario.openingIndonesian,
                openingKorean: userScenario.openingKorean,
                openingRomanization: userScenario.openingRomanization,
                createdAt: userScenario.createdAt,
                ownedByMe: true
            )

            let ok = await sharedScenarioStore.add(shared)
            guard ok else {
                shareError = sharedScenarioStore.lastError ?? "iCloud 저장에 실패했어요."
                return
            }

            // 2. CKShare 생성 후 공유 시트 표시
            do {
                let (share, container) = try await CloudKitService.shared.createShare(for: userScenario.id)
                sharePayload = SharePayload(share: share, container: container)
            } catch {
                shareError = error.localizedDescription
            }
        }
    }

    // MARK: Header
    private var headerBanner: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("🇮🇩")
                        .font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Belajar Bahasa Indonesia")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("인도네시아어 스몰토크 연습")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                HStack(spacing: 8) {
                    StatPill(icon: "🎯", value: "\(builtinScenarios.count + userScenarioStore.scenarios.count + sharedScenarioStore.allScenarios.count)", label: "시나리오")
                    StatPill(icon: "💬", label: "균형 대화")
                    StatPill(icon: "💡", label: "코치 팁")
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showOnboarding = true }) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.18)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
            }
            .padding(.top, 14)
            .padding(.trailing, 16)
        }
        .background {
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.50, blue: 0.95), Color(red: 0.10, green: 0.35, blue: 0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    var value: String = ""
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Text(icon).font(.caption)
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.18))
        .cornerRadius(12)
    }
}

// MARK: - Scenario Card
enum ScenarioCardBadge {
    case none, userAdded, sharedByMe, sharedByFriend
}

struct ScenarioCard: View {
    let scenario: ConversationScenario
    var isUserAdded: Bool = false
    var badge: ScenarioCardBadge = .none
    let onTap: () -> Void
    let onVoiceTap: () -> Void
    var onAddReply: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onStopShare: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    private var effectiveBadge: ScenarioCardBadge {
        if badge != .none { return badge }
        return isUserAdded ? .userAdded : .none
    }

    private var diffColor: Color {
        switch scenario.difficulty {
        case .beginner: return .green
        case .intermediate: return Color.orange
        case .advanced: return .red
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // 메인 카드 영역 (텍스트 모드)
            Button(action: onTap) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(diffColor.opacity(0.12))
                            .frame(width: 58, height: 58)
                        Text(scenario.emoji)
                            .font(.system(size: 30))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(scenario.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text(scenario.titleKo)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text(scenario.description)
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(.tertiaryLabel))
                            .lineLimit(2)
                        HStack(spacing: 5) {
                            Text(scenario.difficulty.labelKo)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(diffColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(diffColor.opacity(0.12))
                                .cornerRadius(5)
                                .fixedSize()
                            switch effectiveBadge {
                            case .userAdded:
                                badgeChip(text: "내가 만든", color: .purple)
                            case .sharedByMe:
                                badgeChip(text: "내가 공유", color: .blue, icon: "person.2.fill")
                            case .sharedByFriend:
                                badgeChip(text: "친구가 공유", color: Color(red: 0.55, green: 0.35, blue: 0.85), icon: "person.2.fill")
                            case .none:
                                EmptyView()
                            }
                        }
                        .padding(.top, 1)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .buttonStyle(PressableButtonStyle())

            // 음성 모드 버튼
            Button(action: onVoiceTap) {
                VStack(spacing: 3) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                    Text("음성")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.blue)
                }
                .frame(width: 44)
                .frame(maxHeight: .infinity)
                .background(Color.blue.opacity(0.06))
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            if let onAddReply {
                Button(action: onAddReply) {
                    Label(
                        scenario.root.speaker == .me ? "상대방 대답 추가하기" : "내 대답 추가하기",
                        systemImage: "plus.bubble"
                    )
                }
            }
            if let onShare {
                Button(action: onShare) {
                    Label("친구에게 공유하기", systemImage: "person.2.fill")
                }
            }
            if let onStopShare {
                Button(role: .destructive, action: onStopShare) {
                    Label("공유 끊기", systemImage: "person.2.slash.fill")
                }
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("이 스몰토크 삭제", systemImage: "trash")
                }
            }
        }
    }

    private func badgeChip(text: String, color: Color, icon: String? = nil) -> some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon).font(.system(size: 8, weight: .bold))
            }
            Text(text).font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .cornerRadius(5)
        .fixedSize()
    }
}

// MARK: - AI Scenario Card

struct AIScenarioCard: View {
    let ai: AIScenario
    let onStudyTap: () -> Void
    let onPracticeTap: () -> Void
    let onVoiceTap: () -> Void
    let onDelete: () -> Void

    private var diffColor: Color {
        switch ConversationScenario.Difficulty(rawValue: ai.difficultyRaw) ?? .beginner {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 메인 영역
            Button(action: onStudyTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.purple.opacity(0.10))
                            .frame(width: 58, height: 58)
                        Text(ai.emoji)
                            .font(.system(size: 30))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(ai.titleKo)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(.purple)
                        }
                        Text(ai.title)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            Label("\(ai.vocabulary.count) 단어", systemImage: "textbook")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue)
                            Label("\(ai.grammarPoints.count) 문법", systemImage: "book.pages")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(14)
            }
            .buttonStyle(PressableButtonStyle())

            // 하단 액션 바
            Divider().padding(.horizontal, 14)
            HStack(spacing: 0) {
                Button(action: onPracticeTap) {
                    Label("대화 연습", systemImage: "bubble.left.and.right.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider().frame(height: 20)

                Button(action: onVoiceTap) {
                    Label("음성", systemImage: "mic.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .background(Color.blue.opacity(0.04))
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ContentView()
}
