import AppIntents

// MARK: - Siri · 단축어

/// "말문 퇴근길 연습 시작" — 앱을 열지 않고 바로 소리로 시작한다.
/// 단축어 앱 ▸ 자동화 ▸ 'CarPlay에 연결될 때' 에 이 동작을 걸면 차에 타자마자 시작된다.
struct StartDriveIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "퇴근길 연습 시작"
    static var description = IntentDescription("배우는 언어로 퇴근길 듣기 연습을 이어서 시작해요.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let session = DriveSession.shared
        if session.isActive { session.play() } else { session.start() }
        return .result()
    }
}

struct PauseDriveIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "퇴근길 연습 멈추기"

    @MainActor
    func perform() async throws -> some IntentResult {
        DriveSession.shared.pause()
        return .result()
    }
}

struct MalmunShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartDriveIntent(),
            phrases: [
                "\(.applicationName) 퇴근길 연습 시작",
                "\(.applicationName)으로 퇴근길 연습",
                "\(.applicationName) 연습 시작"
            ],
            shortTitle: "퇴근길 연습",
            systemImageName: "car.fill"
        )
        AppShortcut(
            intent: PauseDriveIntent(),
            phrases: ["\(.applicationName) 연습 멈춰"],
            shortTitle: "연습 멈추기",
            systemImageName: "pause.fill"
        )
    }
}
