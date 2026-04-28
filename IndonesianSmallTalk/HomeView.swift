import CloudKit
import SwiftUI

struct HomeView: View {
    let builtinScenarios = ConversationData.allScenarios
    @EnvironmentObject var userScenarioStore: UserScenarioStore
    @EnvironmentObject var sharedScenarioStore: SharedScenarioStore
    @State private var selectedScenario: ConversationScenario?
    @State private var showPractice = false
    @State private var showVoicePractice = false
    @State private var showAddPhrase = false
    @State private var showMyPhrases = false
    @State private var showAddScenario = false
    @State private var sharePayload: SharePayload?

    struct SharePayload: Identifiable {
        let id = UUID()
        let share: CKShare
        let container: CKContainer
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

                // ── 함께 보는 스몰토크 (CloudKit)
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
                                onShare: shared.ownedByMe ? { shareScenario(id: shared.id) } : nil,
                                onDelete: shared.ownedByMe ? { Task { await sharedScenarioStore.delete(id: shared.id) } } : nil
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

                // ── 내 시나리오 (있을 때만)
                if !userScenarioStore.scenarios.isEmpty {
                    HStack {
                        Text("내 스몰토크")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 22)

                    VStack(spacing: 14) {
                        ForEach(userScenarioStore.asScenarios) { scenario in
                            ScenarioCard(scenario: scenario, isUserAdded: true, onTap: {
                                selectedScenario = scenario
                                showPractice = true
                            }, onVoiceTap: {
                                selectedScenario = scenario
                                showVoicePractice = true
                            }, onDelete: {
                                userScenarioStore.delete(id: scenario.id)
                            })
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }

                // ── 기본 시나리오
                HStack {
                    Text("기본 시나리오")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)

                VStack(spacing: 14) {
                    ForEach(builtinScenarios) { scenario in
                        ScenarioCard(scenario: scenario, onTap: {
                            selectedScenario = scenario
                            showPractice = true
                        }, onVoiceTap: {
                            selectedScenario = scenario
                            showVoicePractice = true
                        })
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 160) // FAB 가 마지막 카드를 가리지 않도록
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarHidden(true)
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
        .navigationDestination(isPresented: $showMyPhrases) {
            MyPhrasesView()
        }

            // 플로팅 액션 버튼
            VStack(spacing: 12) {
                Button(action: { showMyPhrases = true }) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.gray.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                }
                Menu {
                    Button(action: { showAddScenario = true }) {
                        Label("새 스몰토크", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    Button(action: { showAddPhrase = true }) {
                        Label("새 표현", systemImage: "text.bubble.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.18, green: 0.50, blue: 0.95),
                                         Color(red: 0.10, green: 0.35, blue: 0.75)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showAddPhrase) {
            AddPhraseView()
        }
        .sheet(isPresented: $showAddScenario) {
            AddScenarioView()
        }
        .sheet(item: $sharePayload) { payload in
            CloudKitShareSheet(share: payload.share, container: payload.container) {
                Task { await sharedScenarioStore.refresh() }
            }
            .ignoresSafeArea()
        }
        .refreshable {
            await sharedScenarioStore.refresh()
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
                Button(action: { Task { await sharedScenarioStore.refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
    }

    private func shareScenario(id: UUID) {
        Task {
            do {
                let (share, container) = try await CloudKitService.shared.createShare(for: id)
                await MainActor.run {
                    sharePayload = SharePayload(share: share, container: container)
                }
            } catch {
                print("CKShare 생성 실패: \(error)")
            }
        }
    }

    // MARK: Header
    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.50, blue: 0.95), Color(red: 0.10, green: 0.35, blue: 0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
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
        }
        .frame(maxWidth: .infinity)
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
    var onShare: (() -> Void)? = nil
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
            if let onShare {
                Button(action: onShare) {
                    Label("친구에게 공유하기", systemImage: "person.2.fill")
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

#Preview {
    ContentView()
}
