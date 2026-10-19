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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(phraseStore)
                .environmentObject(userReplyStore)
                .environmentObject(userScenarioStore)
                .environmentObject(sharedScenarioStore)
                .environmentObject(sharedReplyStore)
                .environmentObject(aiScenarioStore)
                .environmentObject(slangStore)
                .environmentObject(vocabularyStore)
                .environmentObject(journeyProgressStore)
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
                    await refreshAll()
                    try? await CloudKitService.shared.ensureSubscriptions()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await refreshAll() }
                    }
                }
        }
    }

    private func refreshAll() async {
        await sharedScenarioStore.refresh()
        await sharedReplyStore.refresh(forScenarios: sharedScenarioStore.allScenarios)
    }
}
