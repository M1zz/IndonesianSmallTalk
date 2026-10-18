import SwiftUI

/// 홈에 넣는 "연습 도구" 묶음: 발음 연습 · 대본 보기 · 연습 기록 · 대화 가져오기.
/// 홈의 NavigationStack 안 ScrollView 에 그대로 넣으면 된다.
struct PracticeToolsSection: View {
    @EnvironmentObject var userScenarioStore: UserScenarioStore
    @EnvironmentObject var userReplyStore: UserReplyStore
    @ObservedObject private var history = PracticeHistoryStore.shared

    @State private var showScriptPicker = false
    @State private var showImport = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 12))
                    .foregroundColor(Brand.blue)
                Text("연습 도구").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink {
                    PronunciationPracticeView()
                } label: {
                    tile(icon: "waveform", color: Brand.blue,
                         title: Text("발음 연습"), subtitle: Text("듣고 따라 말하면 점수를 알려 줘요"))
                }
                .buttonStyle(PressableButtonStyle())

                Button { showScriptPicker = true } label: {
                    tile(icon: "doc.plaintext", color: Brand.deep,
                         title: Text("대본 보기"), subtitle: Text("대화 전체를 메신저처럼 읽고 들어요"))
                }
                .buttonStyle(PressableButtonStyle())

                NavigationLink {
                    PracticeHistoryView()
                } label: {
                    tile(icon: "calendar", color: Brand.glow,
                         title: Text("연습 기록"), subtitle: historySubtitle)
                }
                .buttonStyle(PressableButtonStyle())

                Button { showImport = true } label: {
                    tile(icon: "square.and.arrow.down", color: .purple,
                         title: Text("대화 가져오기"), subtitle: Text("붙여 넣은 대화를 내 시나리오로"))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .sheet(isPresented: $showScriptPicker) {
            ScriptScenarioPicker()
                .environmentObject(userScenarioStore)
                .environmentObject(userReplyStore)
        }
        .sheet(isPresented: $showImport) {
            ScenarioImportView()
                .environmentObject(userScenarioStore)
                .environmentObject(userReplyStore)
        }
    }

    private var historySubtitle: Text {
        let stats = history.stats(for: AppLanguage.learning)
        if stats.totalSessions == 0 { return Text("연습한 날과 점수를 모아 봐요") }
        if stats.currentStreak > 0 { return Text("\(stats.currentStreak)일 연속 · 이번 주 \(stats.thisWeekCount)회") }
        return Text("이번 주 \(stats.thisWeekCount)회 · 모두 \(stats.totalSessions)회")
    }

    private func tile(icon: String, color: Color, title: Text, subtitle: Text) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            .accessibilityHidden(true)
            title
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)
            subtitle
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Script Scenario Picker

/// 대본 보기 전에 시나리오 고르기 (내 시나리오 → 기본 회화)
struct ScriptScenarioPicker: View {
    @EnvironmentObject var userScenarioStore: UserScenarioStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var language: AppLanguage { AppLanguage.learning }
    private var builtIn: [ConversationScenario] { filter(ScenarioLibrary.all(for: language)) }
    private var mine: [ConversationScenario] { filter(userScenarioStore.asScenarios) }

    private func filter(_ list: [ConversationScenario]) -> [ConversationScenario] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return list }
        return list.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.titleKo.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !mine.isEmpty {
                    Section(header: Text("내 시나리오")) {
                        ForEach(mine) { row($0) }
                    }
                }
                Section(header: Text("\(language.localizedName) 기본 회화")) {
                    ForEach(builtIn) { row($0) }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: Text("시나리오 찾기"))
            .overlay {
                if mine.isEmpty && builtIn.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle(Text("대본 보기"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "닫기")) { dismiss() }
                }
            }
        }
    }

    private func row(_ scenario: ConversationScenario) -> some View {
        NavigationLink {
            ScriptView(scenario: scenario)
        } label: {
            HStack(spacing: 12) {
                Text(scenario.emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Text(scenario.titleKo)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
