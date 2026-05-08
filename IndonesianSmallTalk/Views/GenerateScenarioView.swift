import SwiftUI

struct GenerateScenarioView: View {
    @EnvironmentObject var aiStore: AIScenarioStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("anthropic_api_key") private var apiKey = ""
    @State private var mode: InputMode = .topic
    @State private var prompt = ""
    @State private var htmlText = ""
    @State private var showAPIKey = false
    @State private var genState: GenState = .idle
    @State private var generated: AIScenario?
    @State private var errorMessage = ""

    enum InputMode { case topic, html }
    enum GenState { case idle, loading, success, error }

    private let suggestions = [
        "병원에서 진료 받기", "마트에서 장 보기", "택시 타고 목적지 말하기",
        "은행에서 환전하기", "호텔 체크인하기", "친구와 주말 계획 짜기",
        "미용실에서 머리 자르기", "약국에서 약 사기", "길 물어보기"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── 모드 탭
                    modePicker

                    // ── 입력 영역 (모드에 따라 다름)
                    if mode == .topic {
                        topicSection
                        suggestionsSection
                    } else {
                        htmlSection
                    }

                    // ── API 키
                    apiKeySection

                    // ── 생성 버튼 / 상태
                    actionSection

                    // ── 결과 미리보기
                    if let s = generated, genState == .success {
                        previewSection(s)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("AI 시나리오 생성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        Picker("입력 방식", selection: $mode) {
            Text("주제 설명").tag(InputMode.topic)
            Text("HTML 붙여넣기").tag(InputMode.html)
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in
            genState = .idle
            generated = nil
            errorMessage = ""
        }
    }

    // MARK: - Topic mode

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("배우고 싶은 상황을 입력하세요", systemImage: "sparkles")
                .font(.system(size: 15, weight: .semibold))
            Text("Claude AI가 대화 트리 + 단어장 + 문법 노트를 한 번에 만들어줍니다.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            TextEditor(text: $prompt)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 0.5))
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("예: 식당에서 주문하기, 약국에서 약 구입하기")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("추천 주제")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button(action: { prompt = s }) {
                        Text(s)
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(prompt == s ? Color.blue.opacity(0.15) : Color(.systemBackground))
                            .foregroundColor(prompt == s ? .blue : .primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(prompt == s ? Color.blue : Color(.separator), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - HTML mode

    private var htmlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("학습 사이트 HTML 붙여넣기", systemImage: "doc.on.clipboard")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("방법")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(alignment: .top, spacing: 8) {
                    Text("①")
                    Text("Safari에서 학습 페이지 열기")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                HStack(alignment: .top, spacing: 8) {
                    Text("②")
                    Text("공유 → \"페이지 소스 복사\" 또는 텍스트 전체 선택 복사")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                HStack(alignment: .top, spacing: 8) {
                    Text("③")
                    Text("아래에 붙여넣기")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.blue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $htmlText)
                    .frame(minHeight: 160, maxHeight: 260)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(10)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 0.5))

                if htmlText.isEmpty {
                    Text("HTML 소스 또는 텍스트를 여기에 붙여넣으세요")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }

            if !htmlText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text("\(htmlText.count.formatted())자 입력됨")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("지우기") { htmlText = "" }
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - API key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { showAPIKey.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11))
                        .foregroundColor(apiKey.isEmpty ? .orange : .green)
                    Text(apiKey.isEmpty ? "Anthropic API 키 설정 필요" : "API 키 설정됨")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(apiKey.isEmpty ? .orange : .green)
                    Spacer()
                    Image(systemName: showAPIKey ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showAPIKey {
                VStack(alignment: .leading, spacing: 6) {
                    SecureField("sk-ant-api03-...", text: $apiKey)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))
                    Link("API 키 발급 → console.anthropic.com",
                         destination: URL(string: "https://console.anthropic.com")!)
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action

    private var actionSection: some View {
        VStack(spacing: 12) {
            switch genState {
            case .idle, .error:
                Button(action: generate) {
                    Label(
                        mode == .topic ? "AI로 시나리오 생성" : "HTML에서 시나리오 추출",
                        systemImage: mode == .topic ? "sparkles" : "doc.text.magnifyingglass"
                    )
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canGenerate ? Color.blue : Color(.systemFill))
                    .foregroundColor(canGenerate ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canGenerate)
                .buttonStyle(.plain)

                if genState == .error {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }

            case .loading:
                VStack(spacing: 10) {
                    ProgressView().scaleEffect(1.3)
                    Text(mode == .topic
                         ? "Claude가 시나리오를 만들고 있어요…"
                         : "HTML에서 대화를 추출하고 있어요…")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("대화 트리 + 단어장 + 문법 노트 생성 중")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

            case .success:
                Button(action: generate) {
                    Label("다시 생성", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemFill))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Preview

    private func previewSection(_ s: AIScenario) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            HStack(spacing: 12) {
                Text(s.emoji).font(.system(size: 44))
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.titleKo)
                        .font(.system(size: 18, weight: .bold))
                    Text(s.title)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        StatBadge(icon: "bubble.left.and.right", value: "\(s.nodeCount)개", label: "대화")
                        StatBadge(icon: "textbook", value: "\(s.vocabulary.count)개", label: "단어")
                        StatBadge(icon: "book.pages", value: "\(s.grammarPoints.count)개", label: "문법")
                    }
                    .padding(.top, 2)
                }
                Spacer()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button(action: addAndDismiss) {
                Label("앱에 추가하기", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Logic

    private var canGenerate: Bool {
        let inputOK = mode == .topic
            ? !prompt.trimmingCharacters(in: .whitespaces).isEmpty
            : !htmlText.trimmingCharacters(in: .whitespaces).isEmpty
        return inputOK && !apiKey.isEmpty
    }

    private func generate() {
        guard canGenerate else { return }
        genState = .loading
        generated = nil

        Task {
            do {
                let scenario: AIScenario
                if mode == .topic {
                    scenario = try await ClaudeService.shared.generate(
                        prompt: prompt.trimmingCharacters(in: .whitespaces),
                        apiKey: apiKey
                    )
                } else {
                    scenario = try await ClaudeService.shared.generateFromHTML(
                        html: htmlText,
                        apiKey: apiKey
                    )
                }
                await MainActor.run {
                    generated = scenario
                    genState = .success
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    genState = .error
                }
            }
        }
    }

    private func addAndDismiss() {
        guard let s = generated else { return }
        aiStore.add(s)
        dismiss()
    }
}

// MARK: - Helper views

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.blue)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowH + spacing
                x = 0
                rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        height += rowH
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
