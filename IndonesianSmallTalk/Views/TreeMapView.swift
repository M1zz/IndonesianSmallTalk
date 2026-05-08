import SwiftUI

// MARK: - Entry point (same public API as before)

struct TreeMapView: View {
    let scenario: ConversationScenario
    @State private var mode: ViewMode = .explorer
    @State private var explorerPath: [ConversationNode] = []

    enum ViewMode { case explorer, outline }

    private var currentNode: ConversationNode {
        explorerPath.last ?? scenario.root
    }

    var body: some View {
        VStack(spacing: 0) {
            modeBar
            Divider()

            switch mode {
            case .explorer:
                ExplorerView(
                    scenario: scenario,
                    path: $explorerPath,
                    currentNode: currentNode
                )
            case .outline:
                OutlineView(root: scenario.root)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: mode)
    }

    // MARK: Mode toggle bar

    private var modeBar: some View {
        HStack(spacing: 0) {
            modeTab(label: "경로 탐색", icon: "arrow.right.circle", selected: mode == .explorer) {
                mode = .explorer
            }
            modeTab(label: "전체 보기", icon: "list.bullet.indent", selected: mode == .outline) {
                mode = .outline
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func modeTab(label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Color.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Explorer (drill-down path view)

private struct ExplorerView: View {
    let scenario: ConversationScenario
    @Binding var path: [ConversationNode]
    let currentNode: ConversationNode

    @State private var slideDirection: Int = 1  // 1 = forward, -1 = back

    var body: some View {
        VStack(spacing: 0) {
            breadcrumb
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    currentCard
                        .id(currentNode.id)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: slideDirection > 0 ? .trailing : .leading)
                                    .combined(with: .opacity),
                                removal: .move(edge: slideDirection > 0 ? .leading : .trailing)
                                    .combined(with: .opacity)
                            )
                        )

                    if currentNode.children.isEmpty {
                        leafView
                    } else {
                        branchSection
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    // MARK: Breadcrumb

    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                crumbButton(label: scenario.emoji + " 루트", index: -1)

                ForEach(Array(path.enumerated()), id: \.element.id) { idx, node in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.horizontal, 4)
                    crumbButton(
                        label: node.speaker == .me ? "나" : "상대",
                        index: idx
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func crumbButton(label: String, index: Int) -> some View {
        let isCurrent = index == path.count - 1
        return Button(action: {
            guard !isCurrent else { return }
            slideDirection = -1
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                if index == -1 {
                    path = []
                } else {
                    path = Array(path.prefix(index + 1))
                }
            }
        }) {
            Text(label)
                .font(.system(size: 12, weight: isCurrent ? .bold : .regular))
                .foregroundColor(isCurrent ? .primary : .blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isCurrent ? Color(.systemFill) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
    }

    // MARK: Current node card

    private var currentCard: some View {
        let isMe = currentNode.speaker == .me
        let accentColor: Color = isMe ? .blue : Color(red: 0.55, green: 0.40, blue: 0.20)

        return VStack(alignment: .leading, spacing: 0) {
            // Speaker strip
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(isMe ? "나" : "상대")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(accentColor)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(isMe ? "Kamu (나)" : "Orang lain (상대방)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentColor)
                    if currentNode.polarity != .neutral {
                        polarityPill(currentNode.polarity)
                    }
                }

                Spacer()

                if !path.isEmpty {
                    Text("깊이 \(path.count)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            // Indonesian text — large
            Text(currentNode.indonesian)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .padding(.horizontal, 20)

            // Romanization
            if !currentNode.romanization.isEmpty {
                Text(currentNode.romanization)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
            }

            // Korean
            Text(currentNode.korean)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)

            // Coach tip
            if let tip = currentNode.coachTip {
                coachTipStrip(tip)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)
                .padding(.vertical, 0),
            alignment: .leading
        )
    }

    private func coachTipStrip(_ tip: CoachTip) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(tip.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
                Text(tip.tip)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.07))
    }

    // MARK: Branch section

    private var branchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Branch count header
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("\(currentNode.children.count)가지 분기")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 10)

            VStack(spacing: 10) {
                ForEach(Array(currentNode.children.enumerated()), id: \.element.id) { idx, child in
                    BranchCard(node: child, index: idx) {
                        slideDirection = 1
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            path.append(child)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Leaf view

    private var leafView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.green.opacity(0.7))
            Text("대화 끝 — 이 분기는 여기서 마무리됩니다")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !path.isEmpty {
                Button(action: {
                    slideDirection = -1
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        path.removeLast()
                    }
                }) {
                    Label("이전으로", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
    }

    // MARK: Helpers

    private func polarityPill(_ polarity: Polarity) -> some View {
        let (label, color): (String, Color) = polarity == .positive
            ? ("긍정 ✓", .green)
            : ("부정 ✕", .red)
        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Branch Card

private struct BranchCard: View {
    let node: ConversationNode
    let index: Int
    let onTap: () -> Void

    private var isMe: Bool { node.speaker == .me }
    private var accentColor: Color { isMe ? .blue : Color(red: 0.55, green: 0.40, blue: 0.20) }
    private var childCount: Int { countDescendants(node) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Index circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Text(String(UnicodeScalar(65 + index)!))  // A, B, C…
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isMe ? "나" : "상대방")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentColor)
                        if node.polarity != .neutral {
                            Text(node.polarity == .positive ? "긍정" : "부정")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(node.polarity == .positive ? .green : .red)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    (node.polarity == .positive ? Color.green : Color.red)
                                        .opacity(0.1)
                                )
                                .clipShape(Capsule())
                        }
                        Spacer()
                        if childCount > 0 {
                            Text("\(childCount)개")
                                .font(.system(size: 10))
                                .foregroundColor(Color(.tertiaryLabel))
                        } else {
                            Text("끝")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.green.opacity(0.7))
                        }
                    }

                    Text(node.indonesian)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(node.korean)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private func countDescendants(_ n: ConversationNode) -> Int {
        n.children.reduce(0) { $0 + 1 + countDescendants($1) }
    }
}

// MARK: - Outline View (full tree, collapsible list)

private struct OutlineView: View {
    let root: ConversationNode
    @State private var selected: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                OutlineNodeRow(node: root, depth: 0, selected: $selected)
            }
            .padding(.vertical, 8)
        }
    }
}

private struct OutlineNodeRow: View {
    let node: ConversationNode
    let depth: Int
    @Binding var selected: String?
    @State private var expanded: Bool = true

    private var isMe: Bool { node.speaker == .me }
    private var isSelected: Bool { selected == node.id }
    private let accentBlue = Color(red: 0.18, green: 0.50, blue: 0.95)
    private var accentColor: Color { isMe ? accentBlue : Color(red: 0.55, green: 0.40, blue: 0.20) }
    private let indentWidth: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // Row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.18)) {
                    selected = isSelected ? nil : node.id
                }
            }) {
                HStack(spacing: 0) {
                    // Indent + connector
                    indentConnector

                    // Expand toggle
                    if !node.children.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                        }) {
                            Image(systemName: expanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                                .frame(width: 20)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer().frame(width: 20)
                    }

                    // Speaker dot
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .padding(.trailing, 8)

                    // Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.indonesian)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(.primary)
                            .lineLimit(isSelected ? 4 : 2)
                            .multilineTextAlignment(.leading)

                        if isSelected {
                            Text(node.korean)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            if !node.romanization.isEmpty {
                                Text(node.romanization)
                                    .font(.system(size: 10, design: .serif))
                                    .italic()
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .transition(.opacity)
                            }
                        }
                    }

                    Spacer()

                    // Polarity + child count
                    HStack(spacing: 4) {
                        if node.polarity != .neutral {
                            Text(node.polarity == .positive ? "+" : "−")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(node.polarity == .positive ? .green : .red)
                        }
                        if !node.children.isEmpty {
                            Text("\(node.children.count)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(.quaternaryLabel))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(.systemFill))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 9)
                .background(isSelected ? accentColor.opacity(0.07) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Connector line + children
            if expanded && !node.children.isEmpty {
                ForEach(node.children) { child in
                    OutlineNodeRow(node: child, depth: depth + 1, selected: $selected)
                }
            }
        }
    }

    private var indentConnector: some View {
        HStack(spacing: 0) {
            // Left padding
            Spacer().frame(width: 16)

            ForEach(0..<depth, id: \.self) { _ in
                Rectangle()
                    .fill(Color(.separator).opacity(0.4))
                    .frame(width: 1)
                    .padding(.horizontal, (indentWidth - 1) / 2)
            }
        }
        .frame(width: 16 + CGFloat(depth) * indentWidth)
    }
}

// MARK: - Button style for branch cards

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
