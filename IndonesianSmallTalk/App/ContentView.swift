import SwiftUI

struct ContentView: View {
    @EnvironmentObject var aiScenarioStore: AIScenarioStore
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    @State private var showAddMenu = false
    @State private var showAddScenario = false
    @State private var showGenerateScenario = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { HomeView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(0)
                NavigationStack { MyPhrasesView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(1)
                NavigationStack { KeyboardManageView() }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(2)
            }
            .safeAreaInset(edge: .bottom) { floatingBar }

            if showAddMenu {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            showAddMenu = false
                        }
                    }
                    .transition(.opacity)

                addMenuSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: showAddMenu)
        .sheet(isPresented: $showAddScenario) {
            AddScenarioView()
        }
        .sheet(isPresented: $showGenerateScenario) {
            GenerateScenarioView()
                .environmentObject(aiScenarioStore)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .task {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
    }

    // MARK: Floating Bar

    private var floatingBar: some View {
        HStack {
            HStack(spacing: 0) {
                tabButton(tag: 0, icon: "bubble.left.and.bubble.right")
                tabButton(tag: 1, icon: "text.book.closed")
                tabButton(tag: 2, icon: "keyboard")
            }
            .padding(6)
            .glassOrMaterial(in: Capsule())

            Spacer()

            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    showAddMenu.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(showAddMenu ? 45 : 0))
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor, in: Circle())
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: Add Menu Sheet

    private var addMenuSheet: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                addMenuRow(
                    icon: "sparkles",
                    title: "AI로 생성하기",
                    subtitle: "주제를 입력하면 AI가 대화를 만들어줘요",
                    color: .purple
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { showAddMenu = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showGenerateScenario = true }
                }

                Divider()
                    .padding(.leading, 74)

                addMenuRow(
                    icon: "square.and.pencil",
                    title: "직접 만들기",
                    subtitle: "대화 노드를 직접 입력해요",
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { showAddMenu = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showAddScenario = true }
                }
            }
            .glassOrMaterial(in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { showAddMenu = false }
            } label: {
                Text("취소")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .glassOrMaterial(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 96)
    }

    private func addMenuRow(
        icon: String, title: String, subtitle: String,
        color: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: Tab Button

    @ViewBuilder
    private func tabButton(tag: Int, icon: String) -> some View {
        Button { selectedTab = tag } label: {
            Image(systemName: icon)
                .font(.system(size: 17, weight: selectedTab == tag ? .semibold : .regular))
                .symbolVariant(selectedTab == tag ? .fill : .none)
                .foregroundColor(selectedTab == tag ? .primary : Color(.secondaryLabel))
                .frame(width: 52, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass / Material helper

private extension View {
    @ViewBuilder
    func glassOrMaterial<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: shape)
        } else {
            self
                .background(.regularMaterial, in: shape)
                .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 4)
        }
    }
}
