import SwiftUI

@main
struct IndonesianSmallTalkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var phraseStore = PhraseStore()
    @StateObject private var userReplyStore = UserReplyStore()
    @StateObject private var userScenarioStore = UserScenarioStore()
    @StateObject private var sharedScenarioStore = SharedScenarioStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(phraseStore)
                .environmentObject(userReplyStore)
                .environmentObject(userScenarioStore)
                .environmentObject(sharedScenarioStore)
                .task {
                    AppDelegate.onShareAccepted = {
                        Task { await sharedScenarioStore.refresh() }
                    }
                    await sharedScenarioStore.refresh()
                }
        }
    }
}
