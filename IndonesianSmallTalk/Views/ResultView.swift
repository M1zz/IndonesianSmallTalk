import SwiftUI
import LeeoKit

struct ResultView: View {
    @ObservedObject var session: PracticeSession
    /// 연습 기록에 남길 방식 (텍스트/음성)
    var mode: PracticeRecord.Mode = .text
    let onRestart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = MalmunPro.shared
    /// 방금 끝낸 연습이 기록되면 팁 순간을 다시 본다.
    @ObservedObject private var history = PracticeHistoryStore.shared
    @State private var recorded = false
    @State private var showTree = false
    @State private var animateScore = false

    private var positiveRatio: Double {
        guard session.totalChoices > 0 else { return 0 }
        return Double(session.positiveChoices) / Double(session.totalChoices)
    }

    private var gradeEmoji: String {
        if positiveRatio >= 0.8 { return "🏆" }
        if positiveRatio >= 0.6 { return "⭐" }
        if positiveRatio >= 0.4 { return "👍" }
        return "💪"
    }

    private var gradeLabel: String {
        if positiveRatio >= 0.8 { return String(localized: "훌륭해요!") }
        if positiveRatio >= 0.6 { return String(localized: "잘했어요!") }
        if positiveRatio >= 0.4 { return String(localized: "괜찮아요") }
        return String(localized: "연습이 더 필요해요")
    }

    var body: some View {
        content
            .onAppear {
                // 결과 화면이 처음 뜰 때 한 번만 기록
                guard !recorded else { return }
                recorded = true
                PracticeHistoryStore.shared.record(
                    scenario: session.scenario, mode: mode,
                    score: Int((positiveRatio * 100).rounded()),
                    lines: session.currentPath.count
                )
            }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── 결과 헤더
                resultHeader

                // ── 통계 카드
                statsGrid

                // ── 개발자 응원 부탁 — 이미 Pro 인 사람에게만, 드물게(LeeoTipAskPolicy)
                if pro.hasPro, let tipJar = pro.tipJar {
                    LeeoTipAskSlot<MalmunSpec>(tipJar: tipJar, reached: MalmunTipMoments.reachedNow)
                }

                // ── 대화 복습
                conversationReview

                // ── 버튼들
                actionButtons
            }
            .padding(18)
            .padding(.bottom, 90)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showTree) {
            TreeSheetView(scenario: session.scenario)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateScore = true
            }
        }
    }

    // MARK: Header
    private var resultHeader: some View {
        VStack(spacing: 12) {
            Text(gradeEmoji)
                .font(.system(size: 60))
                .scaleEffect(animateScore ? 1 : 0.3)
                .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1), value: animateScore)

            Text(gradeLabel)
                .scaledFont(size: 26, weight: .bold, design: .rounded)
                .foregroundColor(.primary)

            Text(session.feedbackKo)
                .scaledFont(size: 14)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(session.feedbackMessage)
                .scaledFont(size: 13)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    // MARK: Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "⭐", value: "\(session.score)", label: "점수", color: .yellow)
            StatCard(icon: "💬", value: String(localized: "\(session.totalChoices)턴"), label: "대화 턴", color: .blue)
            StatCard(icon: "😊", value: "\(session.positiveChoices)", label: "긍정 선택", color: .green)
            StatCard(
                icon: "📊",
                value: "\(Int(positiveRatio * 100))%",
                label: "긍정 비율",
                color: positiveRatio >= 0.5 ? .green : .orange
            )
        }
    }

    // MARK: Conversation Review
    private var conversationReview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🔁 대화 복습")
                    .scaledFont(size: 14, weight: .bold)
                Spacer()
            }

            ForEach(Array(session.currentPath.enumerated()), id: \.element.id) { idx, node in
                ReviewRow(node: node, index: idx)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                showTree = true
            }) {
                Label("대화 트리 보기", systemImage: "tree")
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.blue.opacity(0.3)))
                    )
            }

            Button(action: {
                onRestart()
                dismiss()
            }) {
                Label("다시 연습하기", systemImage: "arrow.clockwise")
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Brand.solidBlue, Brand.deep],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    )
            }

            Button(action: { dismiss() }) {
                Text("홈으로 돌아가기")
                    .scaledFont(size: 14)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(icon).scaledFont(size: 24)
            Text(value)
                .scaledFont(size: 22, weight: .bold, design: .rounded)
                .foregroundColor(color)
            Text(label)
                .scaledFont(size: 11)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Review Row
struct ReviewRow: View {
    let node: ConversationNode
    let index: Int
    @State private var showTranslation = false

    var isMe: Bool { node.speaker == .me }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(isMe ? "🧑" : "👤")
                .scaledFont(size: 14)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(node.speaker.labelKo)
                        .scaledFont(size: 9.5, weight: .bold)
                        .foregroundColor(isMe ? .blue : .orange)
                    if node.polarity != .neutral {
                        Text(node.polarity == .positive ? "+" : "−")
                            .scaledFont(size: 9, weight: .black)
                            .foregroundColor(node.polarity == .positive ? .green : .red)
                    }
                }
                Text(node.text)
                    .scaledFont(size: 12.5)
                    .foregroundColor(.primary)
                if showTranslation {
                    Text(node.meaning)
                        .scaledFont(size: 11)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            Spacer()
            Button(action: { withAnimation { showTranslation.toggle() } }) {
                Image(systemName: showTranslation ? "eye.slash" : "eye")
                    .scaledFont(size: 11)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .accessibilityLabel(showTranslation ? Text("뜻 숨기기") : Text("뜻 보기"))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(index % 2 == 0 ? Color(.tertiarySystemGroupedBackground) : Color.clear)
        )
    }
}

// MARK: - Tree Sheet
struct TreeSheetView: View {
    let scenario: ConversationScenario
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TreeMapView(scenario: scenario)
                .navigationTitle(Text("대화 트리 · \(scenario.titleKo)"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
        }
    }
}
