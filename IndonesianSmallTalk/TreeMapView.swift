import SwiftUI

// 트리 구조 시각화 뷰 (탭해서 경로 탐색)
struct TreeMapView: View {
    let scenario: ConversationScenario
    @State private var selectedId: String? = nil
    @State private var activePath: Set<String> = []

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            TreeNodeView(
                node: scenario.root,
                depth: 0,
                activePath: activePath,
                selectedId: selectedId,
                onSelect: { nodeId in
                    if selectedId == nodeId {
                        selectedId = nil
                        activePath = []
                    } else {
                        selectedId = nodeId
                        activePath = Set(pathIds(to: nodeId, in: scenario.root))
                    }
                }
            )
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func pathIds(to targetId: String, in root: ConversationNode) -> [String] {
        func dfs(_ node: ConversationNode, _ path: [String]) -> [String]? {
            let newPath = path + [node.id]
            if node.id == targetId { return newPath }
            for child in node.children {
                if let result = dfs(child, newPath) { return result }
            }
            return nil
        }
        return dfs(root, []) ?? []
    }
}

// MARK: - Tree Node View
struct TreeNodeView: View {
    let node: ConversationNode
    let depth: Int
    let activePath: Set<String>
    let selectedId: String?
    let onSelect: (String) -> Void

    private let nodeW: CGFloat = 160
    private let nodeH: CGFloat = 60
    private let colSpacing: CGFloat = 40
    private let rowSpacing: CGFloat = 20

    var isOnPath: Bool { activePath.contains(node.id) }
    var isSelected: Bool { node.id == selectedId }
    var isMe: Bool { node.speaker == .me }
    var hasSel: Bool { !activePath.isEmpty }

    var body: some View {
        HStack(alignment: .center, spacing: colSpacing) {
            // 이 노드
            nodeCell

            // 자식들
            if !node.children.isEmpty {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    ForEach(node.children) { child in
                        HStack(alignment: .center, spacing: 0) {
                            // 연결선
                            connectorLine(to: child)
                            TreeNodeView(
                                node: child,
                                depth: depth + 1,
                                activePath: activePath,
                                selectedId: selectedId,
                                onSelect: onSelect
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: Node Cell
    private var nodeCell: some View {
        let bg: Color
        let border: Color
        let textColor: Color

        if isSelected {
            bg = isMe ? Color(red: 0.18, green: 0.50, blue: 0.95) : Color(red: 0.90, green: 0.45, blue: 0.05)
            border = bg
            textColor = .white
        } else if isOnPath {
            bg = isMe ? Color(red: 0.88, green: 0.93, blue: 1.0) : Color(red: 1.0, green: 0.93, blue: 0.82)
            border = isMe ? Color.blue.opacity(0.6) : Color.orange.opacity(0.6)
            textColor = .primary
        } else if hasSel {
            bg = Color(.systemBackground).opacity(0.4)
            border = Color(.separator).opacity(0.3)
            textColor = Color(.tertiaryLabel)
        } else {
            bg = Color(.secondarySystemGroupedBackground)
            border = Color(.separator).opacity(0.5)
            textColor = .primary
        }

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(border, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? border.opacity(0.3) : .clear, radius: 6)
                .frame(width: nodeW, height: nodeH)

            VStack(alignment: .leading, spacing: 2) {
                // 상단: 화자 + 폴라리티
                HStack(spacing: 4) {
                    Text(node.id == "root" ? "시작" : isMe ? "나" : "상대")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : (isMe ? .blue : .orange))
                    if node.polarity != .neutral {
                        Text(node.polarity == .positive ? "+" : "−")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(node.polarity == .positive ? .green : .red)
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 5)

                // 텍스트
                Text(node.indonesian)
                    .font(.system(size: 10.5, weight: isOnPath ? .semibold : .regular))
                    .foregroundColor(textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: nodeW, height: nodeH)
        .onTapGesture { onSelect(node.id) }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .opacity(hasSel && !isOnPath ? 0.25 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: hasSel)
    }

    // MARK: Connector
    private func connectorLine(to child: ConversationNode) -> some View {
        let isActive = activePath.contains(node.id) && activePath.contains(child.id)
        return Rectangle()
            .fill(isActive ? Color.orange : Color(.separator).opacity(0.4))
            .frame(width: 30, height: isActive ? 2 : 1)
    }
}
