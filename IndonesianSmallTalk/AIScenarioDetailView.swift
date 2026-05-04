import SwiftUI

struct AIScenarioDetailView: View {
    let aiScenario: AIScenario
    @State private var tab = 0
    @State private var showPractice = false
    @State private var showVoicePractice = false
    @State private var showTreeView = false

    var body: some View {
        VStack(spacing: 0) {
            // ── 탭 선택
            Picker("탭", selection: $tab) {
                Text("단어장").tag(0)
                Text("문법 & 숙어").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))

            // ── 탭 콘텐츠
            TabView(selection: $tab) {
                VocabularyStudyView(items: aiScenario.vocabulary)
                    .tag(0)
                GrammarStudyView(points: aiScenario.grammarPoints)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // ── 연습 버튼
            practiceBar
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(aiScenario.titleKo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showTreeView = true }) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 14))
                }
            }
        }
        .sheet(isPresented: $showTreeView) {
            TreeSheetView(scenario: aiScenario.toScenario())
        }
        .navigationDestination(isPresented: $showPractice) {
            PracticeView(session: PracticeSession(scenario: aiScenario.toScenario()))
        }
        .navigationDestination(isPresented: $showVoicePractice) {
            VoicePracticeView(session: PracticeSession(scenario: aiScenario.toScenario()))
        }
    }

    private var practiceBar: some View {
        HStack(spacing: 12) {
            Button(action: { showVoicePractice = true }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: { showPractice = true }) {
                Label("대화 연습 시작", systemImage: "bubble.left.and.right.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

// MARK: - Vocabulary study

struct VocabularyStudyView: View {
    let items: [VocabItem]

    private let categories = ["전체", "동사", "명사", "형용사", "부사", "숙어"]
    @State private var filter = "전체"

    private var filtered: [VocabItem] {
        filter == "전체" ? items : items.filter { $0.category == filter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 카테고리 필터
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            let active = filter == cat
                            Button(action: { filter = cat }) {
                                Text(cat)
                                    .font(.system(size: 13, weight: active ? .semibold : .regular))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(active ? Color.blue : Color(.systemBackground))
                                    .foregroundColor(active ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(
                                        active ? Color.blue : Color(.separator), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 단어 그리드
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filtered) { item in
                        VocabCard(item: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .padding(.top, 14)
        }
    }
}

struct VocabCard: View {
    let item: VocabItem
    @State private var flipped = false

    var body: some View {
        ZStack {
            // 앞면 — 인도네시아어
            cardFace(
                main: item.indonesian,
                sub: item.romanization,
                accent: item.category,
                isBack: false
            )
            .opacity(flipped ? 0 : 1)
            .rotation3DEffect(.degrees(flipped ? -90 : 0), axis: (x: 0, y: 1, z: 0))

            // 뒷면 — 한국어
            cardFace(
                main: item.korean,
                sub: item.indonesian,
                accent: item.category,
                isBack: true
            )
            .opacity(flipped ? 1 : 0)
            .rotation3DEffect(.degrees(flipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
        }
        .animation(.easeInOut(duration: 0.25), value: flipped)
        .onTapGesture { flipped.toggle() }
        .frame(minHeight: 80)
    }

    private func cardFace(main: String, sub: String, accent: String, isBack: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(accent)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(isBack ? Color.green.opacity(0.15) : Color.blue.opacity(0.12))
                    .foregroundColor(isBack ? .green : .blue)
                    .clipShape(Capsule())
                Spacer()
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 10))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            Text(main)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            Text(sub)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Grammar study

struct GrammarStudyView: View {
    let points: [GrammarPoint]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(points) { point in
                    GrammarCard(point: point)
                }
            }
            .padding(16)
        }
    }
}

struct GrammarCard: View {
    let point: GrammarPoint
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }) {
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", point.number))
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(.quaternaryLabel))
                        .frame(width: 36, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(point.titleKo)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text(point.titleId)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    // 설명
                    Text(point.explanation)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)

                    // 예문
                    if !point.examples.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(point.examples.enumerated()), id: \.offset) { _, ex in
                                HStack(alignment: .top, spacing: 10) {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.6))
                                        .frame(width: 3)
                                        .clipShape(Capsule())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.indonesian)
                                            .font(.system(size: 14, weight: .semibold, design: .serif))
                                            .italic()
                                            .foregroundColor(.primary)
                                        Text(ex.korean)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                Divider().padding(.leading, 13)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}
