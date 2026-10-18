import SwiftUI

/// 대화 가져오기: 붙여 넣은 대화 글을 미리 보고 내 시나리오로 저장한다. (형식은 ScenarioImporter)
struct ScenarioImportView: View {
    @EnvironmentObject var scenarioStore: UserScenarioStore
    @EnvironmentObject var replyStore: UserReplyStore
    @Environment(\.dismiss) private var dismiss

    var onSaved: ((UserScenario) -> Void)? = nil

    @State private var input = ""
    @State private var firstIsOther = true
    @State private var title = ""
    @State private var titleMeaning = ""
    @State private var emoji = "💬"
    @State private var situation = ""
    @State private var copiedPrompt = false
    /// 붙여 넣은 글에서 마지막으로 채운 제목 (사용자가 고쳤으면 덮어쓰지 않으려고)
    @State private var autoTitle = ""

    private var language: AppLanguage { AppLanguage.learning }
    private var parsed: ScenarioImporter.Result { ScenarioImporter.parse(input, firstIsOther: firstIsOther) }
    private var canSave: Bool {
        parsed.lines.count >= 2 && !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        let result = parsed
        NavigationStack {
            Form {
                Section {
                    ZStack(alignment: .topLeading) {
                        if input.isEmpty {
                            Text(verbatim: sample)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $input)
                            .font(.system(size: 14, design: .monospaced))
                            .frame(minHeight: 180)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    HStack {
                        Button {
                            if let s = UIPasteboard.general.string { input = s }
                        } label: { Label(String(localized: "붙여넣기"), systemImage: "doc.on.clipboard") }
                        Spacer()
                        if !input.isEmpty {
                            Button(role: .destructive) { input = "" } label: { Text("지우기") }
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 14, weight: .semibold))
                } header: {
                    Text("\(language.localizedName) 대화 붙여넣기")
                } footer: {
                    Text("한 줄에 한 마디씩 \"A: 문장 / 뜻\" 처럼 써 주세요. 뜻은 없어도 되고, 첫 줄에 \"제목: 제목 / 뜻\" 을 넣을 수 있어요.")
                }

                Section {
                    Picker(selection: $firstIsOther) {
                        Text("상대방").tag(true)
                        Text("나").tag(false)
                    } label: { Text("A 는 누구인가요?") }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("A 가 상대방이면 B 는 내가 말하는 쪽이에요.")
                }

                if !input.isEmpty { previewSection(result) }

                Section {
                    TextField(String(localized: "제목 (\(language.localizedName))"), text: $title)
                    TextField(String(localized: "제목 뜻"), text: $titleMeaning)
                    TextField(String(localized: "이모지"), text: $emoji)
                } header: {
                    Text("시나리오 이름")
                }

                promptSection
            }
            .navigationTitle(Text("대화 가져오기"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "취소")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "저장")) { save(result) }
                        .disabled(!canSave)
                }
            }
            .onChange(of: input) { _, _ in
                // 붙여 넣은 글에 제목이 있으면 채워 준다
                let r = parsed
                if !r.title.isEmpty, title.isEmpty || title == autoTitle {
                    title = r.title
                    titleMeaning = r.titleMeaning
                    autoTitle = r.title
                }
            }
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private func previewSection(_ result: ScenarioImporter.Result) -> some View {
        Section {
            if result.lines.isEmpty {
                Text("읽을 수 있는 대화가 아직 없어요.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            ForEach(result.lines) { line in
                previewRow(line)
            }
            ForEach(result.issues) { issue in
                VStack(alignment: .leading, spacing: 3) {
                    Label(String(localized: "\(issue.lineNumber)번째 줄"), systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    Text(verbatim: issue.raw.trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(2)
                    Text(issue.message)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("미리 보기 · \(result.lines.count)마디")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if result.lines.count == 1 {
                    Text("두 마디 이상이어야 저장할 수 있어요.")
                }
                if !result.issues.isEmpty {
                    Text("문제가 있는 \(result.issues.count)줄은 빼고 저장돼요.")
                }
                if result.mergedCount > 0 {
                    Text("같은 사람이 연달아 말한 \(result.mergedCount)줄은 앞 마디에 합쳤어요.")
                }
            }
        }
    }

    private func previewRow(_ line: ScenarioImporter.Line) -> some View {
        let isMe = line.speaker == .me
        return HStack(alignment: .top, spacing: 10) {
            Text(isMe ? "나" : "상대")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isMe ? .white : Brand.blue)
                .frame(width: 34, height: 20)
                .background(Capsule().fill(isMe ? Brand.solidBlue : Brand.blue.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: line.text)
                    .font(.system(size: 14, weight: .medium))
                if !line.meaning.isEmpty {
                    Text(verbatim: line.meaning)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Prompt

    private var promptSection: some View {
        Section {
            TextField(String(localized: "상황 (예: 카페에서 주문하기)"), text: $situation)
            Button {
                UIPasteboard.general.string = ScenarioImporter.prompt(situation: situation, language: language)
                copiedPrompt = true
            } label: {
                Label(copiedPrompt ? String(localized: "복사했어요") : String(localized: "AI 요청문 복사"),
                      systemImage: copiedPrompt ? "checkmark" : "doc.on.doc")
            }
            Button {
                input = sample
            } label: {
                Label(String(localized: "예시 넣어 보기"), systemImage: "text.badge.plus")
            }
        } header: {
            Text("대화가 없나요?")
        } footer: {
            Text("요청문을 ChatGPT 같은 AI 에 붙여 넣으면 이 형식으로 대화를 만들어 줘요. 받은 글을 위에 붙여 넣으세요.")
        }
    }

    // MARK: - Save

    private func save(_ result: ScenarioImporter.Result) {
        guard let saved = ScenarioImporter.save(
            result,
            title: title.trimmingCharacters(in: .whitespaces),
            titleMeaning: titleMeaning.trimmingCharacters(in: .whitespaces),
            emoji: emoji.trimmingCharacters(in: .whitespaces),
            scenarioStore: scenarioStore,
            replyStore: replyStore
        ) else { return }
        onSaved?(saved)
        dismiss()
    }

    /// 형식 예시 (배우는 언어 기본 회화의 첫 대화가 있으면 그것으로)
    private var sample: String {
        if let s = ScenarioLibrary.situations(for: language).first {
            var lines = ["\(String(localized: "제목")): \(s.title) / \(s.titleKo)"]
            var node: ConversationNode? = s.root
            while let n = node, lines.count < 5 {
                let label = (n.speaker == .other) == firstIsOther ? "A" : "B"
                lines.append("\(label): \(n.text) / \(n.meaning)")
                node = n.children.first
            }
            return lines.joined(separator: "\n")
        }
        return "A: ... / ...\nB: ... / ..."
    }
}
