import SwiftUI

struct ResultView: View {
    @ObservedObject var session: PracticeSession
    let onRestart: () -> Void
    @Environment(\.dismiss) private var dismiss
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
        if positiveRatio >= 0.8 { return "Luar Biasa!" }
        if positiveRatio >= 0.6 { return "Bagus!" }
        if positiveRatio >= 0.4 { return "Cukup Baik" }
        return "Perlu Latihan"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── 결과 헤더
                resultHeader

                // ── 통계 카드
                statsGrid

                // ── 대화 복습
                conversationReview

                // ── 버튼들
                actionButtons
            }
            .padding(18)
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
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(session.feedbackKo)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(session.feedbackMessage)
                .font(.system(size: 13))
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    // MARK: Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "⭐", value: "\(session.score)", label: "점수", color: .yellow)
            StatCard(icon: "💬", value: "\(session.totalChoices)턴", label: "대화 턴", color: .blue)
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
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("Rekap percakapan")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
                    .font(.system(size: 15, weight: .semibold))
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.50, blue: 0.95), Color(red: 0.10, green: 0.35, blue: 0.75)],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    )
            }

            Button(action: { dismiss() }) {
                Text("홈으로 돌아가기")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(icon).font(.system(size: 24))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
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
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(node.speaker.labelKo)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(isMe ? .blue : .orange)
                    if node.polarity != .neutral {
                        Text(node.polarity == .positive ? "+" : "−")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(node.polarity == .positive ? .green : .red)
                    }
                }
                Text(node.indonesian)
                    .font(.system(size: 12.5))
                    .foregroundColor(.primary)
                if showTranslation {
                    Text(node.korean)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            Spacer()
            Button(action: { withAnimation { showTranslation.toggle() } }) {
                Image(systemName: showTranslation ? "eye.slash" : "eye")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
            }
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
                .navigationTitle("대화 트리 · " + scenario.titleKo)
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
