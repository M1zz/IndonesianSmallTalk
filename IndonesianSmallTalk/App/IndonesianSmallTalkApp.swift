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
                .task {
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
