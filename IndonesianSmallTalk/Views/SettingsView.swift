import SwiftUI
import LeeoKit

/// 설정 — 말문 Pro · 배우는 언어 · 지원(의견 보내기·리뷰·정책 링크) · 앞으로 만들 기능 · 도움말.
/// 홈 머리말의 톱니바퀴로 연다.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = MalmunPro.shared
    @State private var showPaywall = false
    @State private var showLanguagePicker = false
    @State private var showOnboarding = false
    @State private var showDriveGuide = false

    var body: some View {
        NavigationStack {
            List {
                proSection
                // Pro 선물 보내기 · 받은 코드 넣기
                if let gift = pro.gift {
                    GiftRows(gift: gift, isPro: pro.hasPro)
                }
                // 개발자 응원하기 — 팁 상품이 있을 때만 선다
                if let tipJar = pro.tipJar {
                    Section { LeeoTipJarLink<MalmunSpec>(tipJar: tipJar) }
                }

                Section {
                    Button { showLanguagePicker = true } label: {
                        HStack {
                            Label("배우는 언어", systemImage: "globe")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(AppLanguage.learning.flag) \(AppLanguage.learning.localizedName)")
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("앱 화면 언어는 iPhone 설정 ▸ 말문 ▸ 언어에서 바꿀 수 있어요.")
                        if VoiceHint.isNeeded {
                            Text(VoiceHint.steps)
                        }
                    }
                }

                Section("지원") {
                    LeeoSupportSection<MalmunSpec>()
                    // 앞으로 만들 기능 — 원본은 MalmunRoadmap.swift
                    NavigationLink(LeeoRoadmapText.entry) { RoadmapScreen() }
                }

                DeveloperContactSection()

                Section("도움말") {
                    Button { showOnboarding = true } label: {
                        Label("사용 방법 다시 보기", systemImage: "questionmark.circle")
                    }
                    Button { showDriveGuide = true } label: {
                        Label("차에서 쓰는 법", systemImage: "car")
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .leeoPaywallSheet(MalmunSpec.self, isPresented: $showPaywall, features: MalmunPro.paywallFeatures)
            .sheet(isPresented: $showLanguagePicker) { LanguagePickerSheet() }
            .sheet(isPresented: $showDriveGuide) { DriveGuideSheet() }
            .fullScreenCover(isPresented: $showOnboarding) { OnboardingView() }
        }
        .tint(Brand.blue)
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if pro.hasPro {
                Label {
                    Text("말문 Pro 사용 중")
                } icon: {
                    Image(systemName: "crown.fill").foregroundColor(Brand.glow)
                }
            } else {
                Button { showPaywall = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(Brand.deep)
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Brand.glow))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("말문 Pro")
                                .scaledFont(size: 16, weight: .semibold)
                                .foregroundColor(.primary)
                            Text("퇴근길 모드 무제한 · 상황별 회화 전체")
                                .scaledFont(size: 12)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Button {
                    Task { await pro.store.restore() }
                } label: {
                    HStack {
                        Label("구매 복원", systemImage: "arrow.clockwise")
                        if pro.store.isRestoring {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(pro.store.isRestoring)
            }
        } footer: {
            if let error = pro.store.lastError {
                Text(error).foregroundColor(.orange)
            } else if !pro.hasPro {
                Text("구독 해지·환불은 iPhone 설정 ▸ Apple 계정 ▸ 구독에서 할 수 있어요.")
            }
        }
    }
}

// MARK: - 선물

/// Pro 칸 바로 아래의 **선물** 줄. Pro 를 다른 사람에게 보내고(보내는 사람은 소모성 선물 상품을 산다),
/// 받은 코드는 여기서 넣는다. 받는 사람은 평생 Pro 를 산 것과 같아진다(`MalmunSpec.monetization`).
///
/// ⚠️ 상품이 App Store 에서 와야 줄이 선다(`isAvailable`). 상품을 만들기 전에 이 빌드가 나가도
///    눌러도 안 되는 줄은 보이지 않는다. 단, 이미 결제했거나 주고받은 선물이 있는 사람에게는 늘 보인다 —
///    상품을 못 불러온 날에도 코드를 다시 보거나 문의까지 갈 길이 있어야 한다.
/// ⚠️ 문구는 LeeoKit 카탈로그에 있다(`LeeoGiftText`) — 24개 언어가 이미 들어 있다.
/// ⚠️ 엔진(`LeeoGiftStore`)은 따로 관찰한다. 상품은 앱이 뜬 뒤에 오는데 `MalmunPro` 는 그 변화를 알리지 않는다.
private struct GiftRows: View {
    @ObservedObject var gift: LeeoGiftStore
    let isPro: Bool
    @State private var showSupport = false

    var body: some View {
        if gift.isAvailable || gift.pendingCount > 0 || !gift.sentGifts.isEmpty || gift.redeemed != nil {
            Section {
                NavigationLink {
                    // 선물이 안 되면 결제 번호·코드를 붙여 문의하게 한다 — 막힌 사람을 놓치지 않게.
                    LeeoGiftView<MalmunSpec>(gift: gift, showsRedeemLink: false,
                                             onContactSupport: { showSupport = true })
                } label: {
                    Label(LeeoGiftText.sendEntry, systemImage: "gift.fill")
                }
                // 이미 Pro 인 사람은 받을 것이 없다 — 받은 적이 있으면 그 기록을 볼 수 있게만 남긴다.
                if !isPro || gift.redeemed != nil {
                    NavigationLink {
                        LeeoGiftRedeemView<MalmunSpec>(gift: gift,
                                                       onContactSupport: { showSupport = true })
                    } label: {
                        Label(LeeoGiftText.redeemEntry, systemImage: "giftcard")
                    }
                }
            }
            .sheet(isPresented: $showSupport) {
                NavigationStack {
                    LeeoFeedbackView<MalmunSpec>(initialType: .bug, extraInfo: gift.supportLines,
                                                 initialCategory: .purchase)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기") { showSupport = false }
                            }
                        }
                }
                .tint(Brand.solidBlue)
            }
        }
    }
}
