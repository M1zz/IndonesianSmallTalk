import SwiftUI

/// 첫 실행 시 자동 노출. 도움말 메뉴에서 재진입 가능.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(LanguagePrefs.learningKey, store: LanguagePrefs.defaults) private var learningRaw = ""
    @State private var page = 0
    @State private var language = AppLanguage.learning

    private let pageCount = 7

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(light: Color(red: 0.96, green: 0.97, blue: 1.0), dark: Color(red: 0.06, green: 0.07, blue: 0.13)),
                         Color(light: Color(red: 0.90, green: 0.92, blue: 0.99), dark: Color(red: 0.10, green: 0.12, blue: 0.22))],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // 페이지
                TabView(selection: $page) {
                    scrollsIfNeeded(welcomePage).tag(0)
                    languagePage.tag(1)
                    scrollsIfNeeded(methodPage).tag(2)
                    whyManualPage.tag(3)
                    scrollsIfNeeded(flowPage).tag(4)
                    scrollsIfNeeded(drivePage).tag(5)
                    scrollsIfNeeded(extrasPage).tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // 하단 컨트롤
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
            }

            // 우상단 건너뛰기
            VStack {
                HStack {
                    Spacer()
                    Button("건너뛰기") { finish() }
                        .scaledFont(size: 13, weight: .medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                        .padding(.trailing, 18)
                }
                Spacer()
            }
        }
    }

    /// 큰 글자에서 한 화면을 넘으면 스크롤된다 (넘지 않으면 지금 모양 그대로)
    private func scrollsIfNeeded<Page: View>(_ page: Page) -> some View {
        ViewThatFits(in: .vertical) {
            page
            ScrollView { page }
        }
    }

    // MARK: Pages

    private var welcomePage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image("BrandMark")
                .resizable()
                .accessibilityHidden(true)
                .scaledToFit()
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: Brand.deep.opacity(0.25), radius: 14, y: 6)
            Text("말문")
                .scaledFont(size: 34, weight: .bold, design: .rounded)
                .accessibilityAddTraits(.isHeader)
            Text("한 줄씩 트이는 외국어 회화")
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(.secondary)
            VStack(spacing: 6) {
                Text("실제로 듣고 본 외국어 한 줄을")
                    .scaledFont(size: 16)
                Text("내 입에 붙을 때까지 연습하는 앱")
                    .scaledFont(size: 16, weight: .semibold)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 6)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var languagePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("배울 언어")
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundColor(.blue)
                    Text("무슨 언어를 연습할까요?").accessibilityAddTraits(.isHeader)
                        .scaledFont(size: 26, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)
                LanguageGrid(selection: $language)
                Text("홈 화면 위쪽 국기를 눌러 언제든 바꿀 수 있어요.")
                    .scaledFont(size: 12)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var drivePage: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("퇴근길 모드")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(.orange)
                Text("운전하면서 귀로 연습").accessibilityAddTraits(.isHeader)
                    .scaledFont(size: 26, weight: .bold)
            }
            .padding(.top, 24)

            stepCard(
                emoji: "🚗",
                title: "차에 연결하고 재생",
                desc: "CarPlay나 블루투스로 연결한 뒤 퇴근길 모드를 켜면 화면을 보지 않아도 대화가 차례로 흘러나와요"
            )
            stepCard(
                emoji: "🗣️",
                title: "뜻 듣고 → 먼저 말해 보고 → 정답 듣기",
                desc: "뜻을 들려준 뒤 잠깐 기다려 줘요. 소리 내어 말해 본 다음 원어민 발음으로 확인하세요"
            )
            stepCard(
                emoji: "🎛️",
                title: "운전대 버튼으로 조작",
                desc: "다음 버튼은 다음 문장, 이전 버튼은 한 번 더. Siri에게 \"말문 퇴근길 연습 시작\"이라고 말해도 돼요"
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var methodPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("학습 방법")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(.blue)
                Text("들음 → 적음 → 키움").accessibilityAddTraits(.isHeader)
                    .scaledFont(size: 26, weight: .bold)
            }
            .padding(.top, 24)

            stepCard(
                emoji: "👂",
                title: "들음",
                desc: "카페에서, 길에서, 영상에서 — 어라 이 말이 뭐지? 싶은 한 줄을 발견"
            )
            stepCard(
                emoji: "✍️",
                title: "적음",
                desc: "그 한 줄을 직접 입력. 그리고 \"이 말에 나는 어떻게 답할 수 있지?\" 가능한 답변 옵션도 적어둠"
            )
            stepCard(
                emoji: "🌳",
                title: "키움",
                desc: "답변을 골라보고, 그 다음 대화도 직접 이어 적어 트리를 확장 — 그 상황의 모든 가능성을 학습"
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var whyManualPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("학습 철학")
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundColor(.orange)
                    Text("왜 굳이 직접 입력하나요?").accessibilityAddTraits(.isHeader)
                        .scaledFont(size: 26, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)

                Text("이 앱은 자동 번역으로 빈칸을 채우지 않습니다.")
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundColor(.primary)

                whyBlock(
                    icon: "🧠",
                    title: "직접 적는 그 순간이 학습입니다",
                    body: "단어를 떠올리고, 한 글자씩 입력하는 그 짧은 시간 동안 뇌가 그 표현을 \"내 것\"으로 만듭니다. 자동 채움은 빠르지만, 머리에는 남지 않아요."
                )

                whyBlock(
                    icon: "🪨",
                    title: "불편한 것은 사실입니다",
                    body: "한 줄 한 줄 적는 게 번거롭다는 걸 인정합니다. 이 앱은 그 불편함을 일부러 둔 앱이에요. 빠른 입력 = 빠른 학습이 아니라, 천천히 직접 = 오래 남는 학습이라는 가설로 만들어졌습니다."
                )

                whyBlock(
                    icon: "🌱",
                    title: "당신이 적은 만큼 자랍니다",
                    body: "오늘 한 줄, 내일 또 한 줄. 트리가 자라는 만큼 그 상황에서의 본인 대화 능력도 자랍니다. 누가 대신 채워준 트리는 본인 트리가 아니에요."
                )

                Text("그래서 모든 시나리오·표현·답변은 본인이 직접 입력합니다. 불편하셔도 이 한 가지만 지켜주세요.")
                    .scaledFont(size: 13)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func whyBlock(icon: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(icon).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).scaledFont(size: 15, weight: .bold)
                Text(body).scaledFont(size: 13)
                    .foregroundColor(.secondary).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var flowPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("사용 흐름")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(.blue)
                Text("4단계로 끝").accessibilityAddTraits(.isHeader)
                    .scaledFont(size: 26, weight: .bold)
            }
            .padding(.top, 24)

            flowStep(
                num: 1,
                title: "+ 새 스몰토크",
                desc: "홈 우하단 + 버튼 → \"새 스몰토크\". 상황 제목과 첫 마디(배우는 언어 + 뜻) 입력"
            )
            flowStep(
                num: 2,
                title: "+ 내 대답 추가하기",
                desc: "시나리오 진입 → 점선 버튼으로 \"이 상황에서 내가 할 수 있는 답변\" 한두 개 적기"
            )
            flowStep(
                num: 3,
                title: "다음 대화로 잇기",
                desc: "답변 선택 → 그 답변에 상대가 어떻게 반응할까? → 또 추가. 트리가 점점 자람"
            )
            flowStep(
                num: 4,
                title: "익숙해질 때까지 반복",
                desc: "같은 시나리오에 다시 들어와서 분기 추가. 그 상황의 가능한 대화가 머릿속에 그려질 때까지"
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var extrasPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("부가 기능")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(.blue)
                Text("필요할 때 꺼내 쓰기").accessibilityAddTraits(.isHeader)
                    .scaledFont(size: 26, weight: .bold)
            }
            .padding(.top, 24)

            extraRow(icon: "🎙️", title: "음성 모드 / 음성 매칭",
                     desc: "텍스트 모드에서 \"음성으로\" 칩 → 발화 → 가장 가까운 선택지 자동 매칭")
            extraRow(icon: "📚", title: "내 표현",
                     desc: "한 줄짜리 표현 라이브러리. 따라말하기로 발음 연습, 긍·부정 분류")
            extraRow(icon: "⌨️", title: "표현 키보드",
                     desc: "다른 앱에서도 말문 키보드 → 뜻을 보고 탭하면 배우는 언어로 입력")
            extraRow(icon: "🤝", title: "친구와 함께",
                     desc: "iCloud 로 시나리오 양방향 공유 — 둘이 같이 트리를 키울 수 있음")

            Spacer()

            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .scaledFont(size: 18)
                        .foregroundColor(.blue)
                    Text("이제 첫 시나리오를 만들어볼까요?")
                        .scaledFont(size: 13, weight: .semibold)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - Cards

    private func stepCard(emoji: String, title: LocalizedStringKey, desc: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).scaledFont(size: 15, weight: .bold)
                Text(desc).scaledFont(size: 13)
                    .foregroundColor(.secondary).lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground).opacity(0.7))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }

    private func flowStep(num: Int, title: LocalizedStringKey, desc: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(num)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.blue))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).scaledFont(size: 14, weight: .bold)
                Text(desc).scaledFont(size: 12)
                    .foregroundColor(.secondary).lineSpacing(2)
            }
        }
    }

    private func extraRow(icon: String, title: LocalizedStringKey, desc: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon).scaledFont(size: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).scaledFont(size: 14, weight: .bold)
                Text(desc).scaledFont(size: 12)
                    .foregroundColor(.secondary).lineSpacing(2)
            }
        }
    }

    // MARK: - Bottom

    @ViewBuilder
    private var bottomBar: some View {
        if page < pageCount - 1 {
            Button(action: { withAnimation { page += 1 } }) {
                Text("다음")
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(
                        LinearGradient(
                            colors: [Brand.solidBlue, Brand.deep],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        } else {
            Button(action: { finish() }) {
                Text("시작하기")
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(
                        LinearGradient(
                            colors: [Brand.solidBlue, Brand.deep],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func finish() {
        learningRaw = language.rawValue
        hasSeenOnboarding = true
        dismiss()
    }
}
