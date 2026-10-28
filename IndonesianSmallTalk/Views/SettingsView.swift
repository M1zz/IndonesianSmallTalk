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
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("퇴근길 모드 무제한 · 상황별 회화 전체")
                                .font(.system(size: 12))
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
