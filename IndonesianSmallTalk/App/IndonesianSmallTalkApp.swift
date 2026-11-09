import LeeoKit
import SwiftUI

@main
struct IndonesianSmallTalkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var phraseStore = PhraseStore()
    @StateObject private var userReplyStore = UserReplyStore()
    @StateObject private var userScenarioStore = UserScenarioStore()
    @StateObject private var sharedScenarioStore = SharedScenarioStore()
    @StateObject private var sharedReplyStore = SharedReplyStore()
    @StateObject private var aiScenarioStore = AIScenarioStore()
    @StateObject private var slangStore = SlangStore()
    @StateObject private var vocabularyStore = VocabularyStore()
    @StateObject private var journeyProgressStore = JourneyProgressStore()

    init() {
        // LeeoKit 계약을 켜는 한 줄 (→ MalmunSpec). 실행 횟수 · 익명 사용 통계 · 크래시 진단 ·
        // 원격 킬스위치(→ MalmunFlags) · DEBUG 프리플라이트. 모두 FeedbackHub(CloudKit)를 쓴다.
        LeeoKit.bootstrap(MalmunSpec.self, flags: MalmunFlag.self)
        #if DEBUG
        ScreenshotScene.applyLearningOverride()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 개발자가 보낸 의견에 답장하면, 앱이 앞으로 올 때 답장을 시트로 보여 준다 (LeeoKit).
                .leeoFeedbackReplyNotice(MalmunSpec.self)
                .environmentObject(phraseStore)
                .environmentObject(userReplyStore)
                .environmentObject(userScenarioStore)
                .environmentObject(sharedScenarioStore)
                .environmentObject(sharedReplyStore)
                .environmentObject(aiScenarioStore)
                .environmentObject(slangStore)
                .environmentObject(vocabularyStore)
                .environmentObject(journeyProgressStore)
                // 아이폰 듀오: 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
                .foldAware()
                .task {
                    // 퇴근길 모드가 화면과 같은 저장소를 읽도록
                    DriveContent.phrases = { [phraseStore] in phraseStore.phrases }
                    DriveContent.words = { [vocabularyStore] in vocabularyStore.words }
                    AppDelegate.onShareAccepted = {
                        Task { await refreshAll() }
                    }
                    AppDelegate.onRemoteNotification = {
                        Task { await refreshAll() }
                    }
                    // 산 칸을 영수증으로 다시 읽는다 (팁 · 선물 엔진도 스토어가 함께 깨운다)
                    Task { await MalmunPro.shared.refresh() }
                    await refreshAll()
                    try? await CloudKitService.shared.ensureSubscriptions()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await refreshAll() }
                        // 다른 기기에서 샀거나 구독이 끝났을 수 있다.
                        Task { await MalmunPro.shared.refresh() }
                    }
                    // 내 표현을 Spotlight 에 다시 싣는다 (→ DriveIntents.swift)
                    if phase != .inactive {
                        Task { await PhraseEntity.reindex() }
                    }
                }
        }
    }

    private func refreshAll() async {
        await sharedScenarioStore.refresh()
        await sharedReplyStore.refresh(forScenarios: sharedScenarioStore.allScenarios)
    }
}
