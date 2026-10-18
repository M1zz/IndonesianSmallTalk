import AVFoundation
import Speech

// MARK: - Voice command

/// 퇴근길 모드에서 말로 하는 명령. 말해 볼 차례(조용한 틈)에만 듣는다.
enum DriveCommand: CaseIterable {
    case nextScene, next, again, slower, faster, stop

    /// 화면 언어별로 알아듣는 말 (앞쪽이 대표). 긴 말(다음 장면)을 짧은 말(다음)보다 먼저 맞춘다.
    func words(_ lang: AppLanguage) -> [String] {
        switch (self, lang) {
        case (.nextScene, .korean): return ["다음 장면", "건너뛰어"]
        case (.next, .korean): return ["다음", "넘겨", "패스"]
        case (.again, .korean): return ["다시", "한 번 더", "한번 더", "뭐라고"]
        case (.slower, .korean): return ["천천히", "느리게"]
        case (.faster, .korean): return ["빠르게", "빨리"]
        case (.stop, .korean): return ["그만", "멈춰", "정지", "스톱"]

        case (.nextScene, .english): return ["next scene", "skip scene"]
        case (.next, .english): return ["next", "skip"]
        case (.again, .english): return ["again", "repeat", "one more", "what"]
        case (.slower, .english): return ["slower", "slow down"]
        case (.faster, .english): return ["faster", "speed up"]
        case (.stop, .english): return ["stop", "pause"]

        case (.nextScene, .japanese): return ["次の場面", "次のシーン"]
        case (.next, .japanese): return ["次", "つぎ", "スキップ"]
        case (.again, .japanese): return ["もう一回", "もう一度", "もういっかい", "もう1回"]
        case (.slower, .japanese): return ["ゆっくり"]
        case (.faster, .japanese): return ["速く", "早く", "はやく"]
        case (.stop, .japanese): return ["止めて", "とめて", "ストップ", "やめて"]

        case (.nextScene, .chinese): return ["下一个场景", "跳过场景"]
        case (.next, .chinese): return ["下一个", "下一句", "跳过"]
        case (.again, .chinese): return ["再来", "重复", "再说一遍", "再一次"]
        case (.slower, .chinese): return ["慢一点", "慢点"]
        case (.faster, .chinese): return ["快一点", "快点"]
        case (.stop, .chinese): return ["暂停", "停止", "停"]

        case (.nextScene, .spanish): return ["siguiente escena"]
        case (.next, .spanish): return ["siguiente", "pasa"]
        case (.again, .spanish): return ["otra vez", "repite", "de nuevo"]
        case (.slower, .spanish): return ["más despacio", "despacio"]
        case (.faster, .spanish): return ["más rápido", "rápido"]
        case (.stop, .spanish): return ["para", "detente", "pausa", "alto"]

        case (.nextScene, .indonesian): return ["adegan berikutnya"]
        case (.next, .indonesian): return ["lanjut", "berikutnya", "skip"]
        case (.again, .indonesian): return ["ulang", "sekali lagi", "lagi"]
        case (.slower, .indonesian): return ["lebih pelan", "pelan"]
        case (.faster, .indonesian): return ["lebih cepat", "cepat"]
        case (.stop, .indonesian): return ["berhenti", "stop", "jeda"]
        }
    }

    /// 짧은 말 하나가 명령인지 본다. 문장 연습을 명령으로 잘못 알아듣지 않도록 짧을 때만.
    static func match(_ heard: String, in lang: AppLanguage) -> DriveCommand? {
        let text = heard.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !text.isEmpty else { return nil }
        let short = lang.writesWithoutSpaces || lang == .korean ? text.count <= 8 : text.split(separator: " ").count <= 3
        guard short else { return nil }
        for cmd in allCases {
            for w in cmd.words(lang) where text == w || text.hasPrefix(w + " ") || text.hasSuffix(" " + w)
                || ((lang.writesWithoutSpaces || lang == .korean) && text.contains(w)) {
                return cmd
            }
        }
        return nil
    }
}

// MARK: - Listener

/// 퇴근길 모드의 귀. 오디오 엔진의 마이크 버퍼를 받아, 듣는 창이 열려 있을 때만 알아듣는다.
/// - 배우는 언어 인식기: 내가 말해 본 문장 (맞았는지 보기)
/// - 화면 언어 인식기: "다음", "다시" 같은 명령
/// 기기 안에서 알아들을 수 있으면 기기 안에서만 처리한다(네트워크로 보내지 않음).
@MainActor
final class DriveVoiceListener {
    private(set) var attemptText = ""
    private(set) var lastHeardAt: Date?
    var onCommand: ((DriveCommand) -> Void)?

    private var attemptRecognizer: SFSpeechRecognizer?
    private var commandRecognizer: SFSpeechRecognizer?
    private var attemptRequest: SFSpeechAudioBufferRecognitionRequest?
    private var commandRequest: SFSpeechAudioBufferRecognitionRequest?
    private var attemptTask: SFSpeechRecognitionTask?
    private var commandTask: SFSpeechRecognitionTask?
    private var commandFired = false

    static var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
            && AVAudioApplication.shared.recordPermission == .granted
    }

    static var needsPermission: Bool {
        SFSpeechRecognizer.authorizationStatus() == .notDetermined
            || AVAudioApplication.shared.recordPermission == .undetermined
    }

    /// 처음 켤 때 한 번 묻는다 (화면이 떠 있을 때만 부른다)
    static func requestPermission() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        let mic = await AVAudioApplication.requestRecordPermission()
        return speech == .authorized && mic
    }

    /// 듣기 시작. attempt 를 주면 그 언어로 내 문장도 듣는다.
    func open(learning: AppLanguage?, native: AppLanguage) {
        close()
        attemptText = ""
        lastHeardAt = nil
        commandFired = false

        commandRecognizer = SFSpeechRecognizer(locale: Locale(identifier: native.speechCode))
        commandRequest = makeRequest(for: commandRecognizer)
        if let commandRecognizer, let commandRequest {
            commandTask = commandRecognizer.recognitionTask(with: commandRequest) { [weak self] result, _ in
                guard let text = result?.bestTranscription.formattedString else { return }
                Task { @MainActor in self?.heardCommand(text, native: native) }
            }
        }

        guard let learning else { return }
        attemptRecognizer = SFSpeechRecognizer(locale: Locale(identifier: learning.speechCode))
        attemptRequest = makeRequest(for: attemptRecognizer)
        if let attemptRecognizer, let attemptRequest {
            attemptTask = attemptRecognizer.recognitionTask(with: attemptRequest) { [weak self] result, _ in
                guard let text = result?.bestTranscription.formattedString else { return }
                Task { @MainActor in
                    guard let self, text != self.attemptText else { return }
                    self.attemptText = text
                    self.lastHeardAt = Date()
                }
            }
        }
    }

    /// 듣기를 닫고 내가 말한 문장을 돌려준다.
    @discardableResult
    func close() -> String {
        attemptRequest?.endAudio()
        commandRequest?.endAudio()
        attemptTask?.cancel()
        commandTask?.cancel()
        attemptRequest = nil
        commandRequest = nil
        attemptTask = nil
        commandTask = nil
        return attemptText
    }

    /// 오디오 엔진 탭에서 (오디오 스레드) 부른다.
    nonisolated func append(_ buffer: AVAudioPCMBuffer) {
        Task { @MainActor in
            self.attemptRequest?.append(buffer)
            self.commandRequest?.append(buffer)
        }
    }

    private func makeRequest(for recognizer: SFSpeechRecognizer?) -> SFSpeechAudioBufferRecognitionRequest? {
        guard let recognizer, recognizer.isAvailable else { return nil }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        request.taskHint = .dictation
        return request
    }

    private func heardCommand(_ text: String, native: AppLanguage) {
        guard !commandFired, let cmd = DriveCommand.match(text, in: native) else { return }
        commandFired = true
        onCommand?(cmd)
    }
}
