import SwiftUI

struct CoachTipView: View {
    let node: ConversationNode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── 상단 배너
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.55, blue: 0.05), Color(red: 0.85, green: 0.40, blue: 0.00)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("💡")
                                    .font(.system(size: 32))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("코치 팁")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    if let tip = node.coachTip {
                                        Text(tip.label)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                            }
                            // 해당 대화
                            Text("\"\(node.indonesian)\"")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .italic()
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.top, 2)
                        }
                        .padding(20)
                    }
                    .frame(maxWidth: .infinity, minHeight: 130)

                    VStack(spacing: 16) {
                        // ── 폴라리티 배지
                        if node.polarity != .neutral {
                            HStack {
                                PolarityDetailBadge(polarity: node.polarity)
                                Spacer()
                            }
                        }

                        // ── 한국어 번역
                        InfoCard(
                            icon: "🇰🇷",
                            title: "한국어 번역",
                            content: node.korean
                        )

                        // ── 발음 가이드
                        if !node.romanization.isEmpty {
                            InfoCard(
                                icon: "🔊",
                                title: "발음 가이드",
                                content: node.romanization,
                                contentStyle: .serif
                            )
                        }

                        // ── 코치 팁
                        if let tip = node.coachTip {
                            TipCard(
                                icon: "💬",
                                title: "스몰토크 전략",
                                content: tip.tip,
                                accentColor: .orange
                            )
                            TipCard(
                                icon: "📌",
                                title: "왜 효과적인가요?",
                                content: tip.why,
                                accentColor: .blue
                            )
                        }

                        // ── 화자 정보
                        InfoCard(
                            icon: node.speaker == .me ? "🧑" : "👤",
                            title: "화자",
                            content: node.speaker.label + " (" + node.speaker.labelKo + ")"
                        )
                    }
                    .padding(18)
                }
            }
            .background(Color(.systemGroupedBackground))
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

// MARK: - Polarity Detail Badge
struct PolarityDetailBadge: View {
    let polarity: Polarity
    var body: some View {
        HStack(spacing: 6) {
            Text(polarity == .positive ? "😊" : "😟")
            Text(polarity.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(polarity == .positive ? Color(red: 0.15, green: 0.5, blue: 0.1) : Color(red: 0.6, green: 0.1, blue: 0.1))
            Text(polarity == .positive ? "긍정적인 반응" : "부정적인 반응")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(polarity == .positive ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(polarity == .positive ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                )
        )
    }
}

// MARK: - Info Card
enum ContentStyle { case normal, serif }

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    var contentStyle: ContentStyle = .normal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 14))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text(content)
                .font(contentStyle == .serif
                    ? .system(size: 15, design: .serif).italic()
                    : .system(size: 15))
                .foregroundColor(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Tip Card
struct TipCard: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 14))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accentColor)
            }
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
