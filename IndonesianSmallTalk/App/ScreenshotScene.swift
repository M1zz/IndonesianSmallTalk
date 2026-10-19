#if DEBUG
import SwiftUI

/// 앱스토어 스크린샷 전용 장면 (Debug 빌드에만 있다). 시뮬레이터에서 손으로 누르지 않고
/// 같은 화면을 언어마다 똑같이 찍으려고 실행 인자로 연다.
///   -ScreenshotScene home | practice | drive | script | pronunciation
///   -ScreenshotLearning <AppLanguage.rawValue>   (배울 언어를 못 박는다)
/// 찍는 스크립트: scripts/capture_store_screenshots.sh
enum ScreenshotScene: String {
    case home, practice, drive, script, pronunciation

    static var current: ScreenshotScene? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ScreenshotScene"), i + 1 < args.count else { return nil }
        return ScreenshotScene(rawValue: args[i + 1])
    }

    static var isActive: Bool { current != nil }

    /// 앱이 뜨기 전에 (IndonesianSmallTalkApp.init) 배울 언어를 맞춘다.
    static func applyLearningOverride() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ScreenshotLearning"), i + 1 < args.count,
              let lang = AppLanguage(rawValue: args[i + 1]) else { return }
        LanguagePrefs.defaults.set(lang.rawValue, forKey: LanguagePrefs.learningKey)
        UserDefaults.standard.set(true, forKey: DriveSettings.guideSeenKey)
    }

    /// 그 언어에서 보여 줄 대표 대화 (인도네시아어는 공들인 스몰토크, 나머지는 식당 주문)
    static var showcaseScenario: ConversationScenario? {
        let lang = AppLanguage.learning
        if let talk = ScenarioLibrary.smallTalk(for: lang).first(where: { $0.title == "Kafe" || $0.emoji == "☕" })
            ?? ScenarioLibrary.smallTalk(for: lang).first {
            return talk
        }
        let situations = ScenarioLibrary.situations(for: lang)
        return situations.first { $0.key.hasSuffix("-ordering") } ?? situations.first
    }

    /// 대화를 두 걸음 진행해 둔 연습 세션 (빈 화면 대신 주고받는 모습)
    static func showcaseSession() -> PracticeSession? {
        guard let s = showcaseScenario else { return nil }
        let session = PracticeSession(scenario: s)
        for _ in 0..<2 {
            guard let next = session.availableChoices.first(where: { $0.polarity == .positive })
                    ?? session.availableChoices.first else { break }
            session.choose(next)
        }
        return session
    }
}

/// 장면을 띄우는 껍데기 (ContentView 위에 전체 화면으로)
struct ScreenshotSceneHost: View {
    let scene: ScreenshotScene

    var body: some View {
        NavigationStack {
            switch scene {
            case .practice:
                if let session = ScreenshotScene.showcaseSession() { PracticeView(session: session) }
            case .script:
                if let s = ScreenshotScene.showcaseScenario { ScriptView(scenario: s) }
            case .pronunciation:
                if let s = ScreenshotScene.showcaseScenario { PronunciationPracticeView(scenario: s) }
            case .drive:
                DriveModeView()
                    .onAppear { DriveSession.shared.debugShowcase() }
            case .home:
                EmptyView()
            }
        }
    }
}
#endif
