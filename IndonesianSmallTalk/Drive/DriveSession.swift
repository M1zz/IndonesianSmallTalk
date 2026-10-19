import AVFoundation
import LeeoKit
import MediaPlayer
import UIKit

/// 퇴근길 모드 재생기. 화면을 보지 않아도 되도록 소리로만 진행한다.
///
/// 한 줄을 읽는 순서
/// - 상대 말(listen): 배우는 언어 → 뜻
/// - 내 말(speak): 뜻 → 딩 소리 → (말해 볼 시간) → 천천히 정답 → (따라 할 시간) → 보통 속도로 한 번 더
///
/// 블루투스·CarPlay 로 차에 연결하면 소리가 차 스피커로 나오고, 차량 버튼·'지금 재생'·잠금 화면에서 재생/일시정지/다음(다음 줄)/이전(이 줄 다시)이 된다.
/// 말과 말 사이 쉬는 동안에도 앱이 멈추지 않도록 무음을 계속 흘려 둔다.
///
/// 목소리 조작(설정에서 켜고 마이크·음성 인식을 허락했을 때): 말해 볼 차례에만 폰 마이크로 듣는다.
/// 내가 말한 문장이 맞으면 "좋아요" 라고 해 주고, "다음 / 다시 / 천천히 / 빠르게 / 다음 장면 / 그만" 을 알아듣는다.
/// 소리는 차 스피커(블루투스 A2DP)로 그대로 나가고 마이크는 폰 것을 쓴다 — 블루투스 마이크를 쓰면 통화 음질로 떨어진다.
@MainActor
final class DriveSession: NSObject, ObservableObject {
    static let shared = DriveSession()

    enum Phase: Equatable {
        case idle
        case intro          // 장면 제목
        case listening      // 상대 말 / 뜻 듣기
        case yourTurn       // 말해 볼 차례
        case answer         // 정답 듣기
        case finished
    }

    @Published private(set) var isActive = false
    @Published private(set) var isPlaying = false
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var source: DriveSource = .mix
    @Published private(set) var lesson: DriveLesson?
    @Published private(set) var line: DriveLine?
    @Published private(set) var linesDone = 0
    @Published private(set) var startedAt: Date?
    /// 지금 마이크로 듣고 있는지 (목소리 조작이 켜진 채로 재생 중)
    @Published private(set) var voiceActive = false
    /// 방금 말해 본 문장과 그 결과
    @Published private(set) var heardText = ""
    @Published private(set) var lastResult: AttemptResult?
    @Published private(set) var correctCount = 0

    enum AttemptResult { case good, close, missed }

    private var lessons: [DriveLesson] = []
    private var lessonIndex = 0
    private var lineIndex = 0
    private var runner: Task<Void, Never>?
    private var language: AppLanguage = .learning

    private let synthesizer = AVSpeechSynthesizer()
    private var speechContinuation: CheckedContinuation<Void, Never>?

    // 무음·딩 소리
    private let engine = AVAudioEngine()
    private let silencePlayer = AVAudioPlayerNode()
    private let cuePlayer = AVAudioPlayerNode()
    private var engineReady = false
    private var micTapInstalled = false

    private let voice = DriveVoiceListener()
    /// 무료 한도에 이미 센 장면
    private var countedLessonID: String?
    private var pendingAck: String?

    private override init() {
        super.init()
        synthesizer.delegate = self
        voice.onCommand = { [weak self] cmd in self?.handle(cmd) }
        observeSession()
        setupRemoteCommands()
    }

    // MARK: - Control

    /// 소스를 골라 시작한다. 같은 소스는 지난번 듣던 장면부터 이어 간다.
    func start(_ source: DriveSource? = nil) {
        let src = source ?? DriveSettings.source
        language = .learning
        self.source = src
        UserDefaults.standard.set(src.rawValue, forKey: DriveSettings.sourceKey)
        lessons = DriveContent.lessons(for: src, language: language)
        // 고른 소스가 비어 있으면(예: 내 표현이 없음) 섞어서로
        if lessons.isEmpty, src != .mix {
            self.source = .mix
            lessons = DriveContent.lessons(for: .mix, language: language)
        }
        guard !lessons.isEmpty else {
            isActive = false
            phase = .idle
            return
        }
        let saved = UserDefaults.standard.integer(forKey: DriveSettings.cursorKey(self.source, language))
        lessonIndex = saved < lessons.count ? saved : 0
        lineIndex = 0
        linesDone = 0
        correctCount = 0
        lastResult = nil
        heardText = ""
        startedAt = Date()
        isActive = true
        play()
    }

    func play() {
        guard isActive else { start(); return }
        guard !isPlaying else { return }
        isPlaying = true
        // 세션을 맞추는 건 메인 스레드 밖에서. 다 맞춘 뒤 재생을 시작한다 (그 사이 멈추면 시작하지 않음).
        Task {
            await activateAudio()
            guard isActive, isPlaying else { return }
            runFromCurrentLine()
        }
    }

    func pause() {
        guard isPlaying else { return }
        isPlaying = false
        runner?.cancel()
        runner = nil
        voice.close()
        stopSpeech()
        updateNowPlaying()
    }

    func toggle() { isPlaying ? pause() : play() }

    /// 다음 줄로 (장면 끝이면 다음 장면)
    func next() {
        guard isActive else { return }
        advanceLine()
        restartIfPlaying()
    }

    /// 지금 줄을 처음부터 한 번 더 (멈춰 있을 때는 앞 줄로)
    func previous() {
        guard isActive else { return }
        if !isPlaying { lineIndex = max(0, lineIndex - 1) }
        restartIfPlaying()
    }

    /// 다음 장면으로 건너뛰기
    func nextLesson() {
        guard isActive else { return }
        finishLesson(completed: false)
        restartIfPlaying()
    }

    func stop() {
        pause()
        isActive = false
        phase = .idle
        lesson = nil
        line = nil
        voiceActive = false
        stopEngine()
        Task {
            try? await AudioSessionQueue.run { try $0.setActive(false, options: .notifyOthersOnDeactivation) }
            AudioSessionQueue.owner = .none
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    var lessonPosition: (index: Int, count: Int) { (lessonIndex + 1, lessons.count) }
    var linePosition: (index: Int, count: Int) { (lineIndex + 1, lesson?.lines.count ?? 0) }

    // MARK: - Runner

    private func restartIfPlaying() {
        runner?.cancel()
        runner = nil
        voice.close()
        stopSpeech()
        if isPlaying { runFromCurrentLine() } else { refreshCurrent(); updateNowPlaying() }
    }

    private func runFromCurrentLine() {
        runner?.cancel()
        runner = Task { [weak self] in
            await self?.loop()
        }
    }

    private func loop() async {
        while !Task.isCancelled, isPlaying {
            guard lessonIndex < lessons.count else { lessonIndex = 0; continue }
            let current = lessons[lessonIndex]
            lesson = current
            // 무료 한도는 장면을 '시작할 때' 센다 (끝나기 직전에 건너뛰어도 한 장면). 같은 장면을 다시 들으면 세지 않는다.
            if lineIndex == 0, countedLessonID != current.id, !MalmunPro.shared.canStartDriveScene() {
                // 오늘 무료 장면을 다 들었다 — 알려 주고 멈춘다. (화면이 떠 있으면 페이월이 뜬다)
                phase = .finished
                line = nil
                updateNowPlaying()
                await say(String(localized: "오늘 무료 장면 \(MalmunPro.freeDriveScenesPerDay)개를 다 들었어요. 말문 Pro로 계속 들을 수 있어요."),
                          in: AppLanguage.native, rate: 1.0)
                MalmunPro.shared.showPaywall(.commute)
                pause()
                return
            }
            if countedLessonID != current.id {
                countedLessonID = current.id
                MalmunPro.shared.countDriveScene()
            }
            if lineIndex == 0 {
                phase = .intro
                line = nil
                updateNowPlaying()
                await say(String(localized: "다음 장면, \(current.title)"), in: AppLanguage.native, rate: 1.0)
                await rest(0.6)
            }
            while lineIndex < current.lines.count {
                if Task.isCancelled || !isPlaying { return }
                await perform(current.lines[lineIndex])
                if Task.isCancelled || !isPlaying { return }
                linesDone += 1
                lineIndex += 1
            }
            finishLesson(completed: true)
            await rest(1.0)
        }
    }

    private func perform(_ l: DriveLine) async {
        line = l
        heardText = ""
        lastResult = nil
        // 속도는 말할 때마다 읽는다 ("천천히" 라고 하면 바로 바뀌도록)
        switch l.role {
        case .listen:
            phase = .listening
            updateNowPlaying()
            await say(l.text, in: language, rate: DriveSettings.rate)
            await rest(0.5)
            await say(l.meaning, in: AppLanguage.native, rate: 1.0)
            await rest(0.9)
        case .speak:
            phase = .listening
            updateNowPlaying()
            await say(l.meaning, in: AppLanguage.native, rate: 1.0)
            phase = .yourTurn
            updateNowPlaying()
            playCue()
            let heard = await listenWindow(seconds: thinkTime(for: l.text) * DriveSettings.gap, target: l.text)
            guard !Task.isCancelled, isPlaying else { return }
            await react(to: heard, target: l.text)
            phase = .answer
            updateNowPlaying()
            await say(l.text, in: language, rate: DriveSettings.rate * 0.8)
            // 따라 해 볼 시간 (명령도 듣는다)
            _ = await listenWindow(seconds: thinkTime(for: l.text) * 0.8 * DriveSettings.gap, target: l.text)
            guard !Task.isCancelled, isPlaying else { return }
            if DriveSettings.repeatTwice {
                await say(l.text, in: language, rate: DriveSettings.rate)
                await rest(0.8)
            }
        }
    }

    /// 말해 볼 틈. 목소리 조작이 꺼져 있으면 그냥 기다린다.
    /// 말을 시작하면 끝날 때까지 조금 더 기다려 주고, 말이 멈추면 바로 다음으로 넘어간다.
    private func listenWindow(seconds: Double, target: String) async -> String {
        guard voiceActive else { await rest(seconds); return "" }
        await rest(0.35)   // 딩 소리가 마이크에 들어가지 않게
        guard !Task.isCancelled, isPlaying else { return "" }
        voice.open(learning: language, native: AppLanguage.native)
        let start = Date()
        var deadline = start.addingTimeInterval(seconds)
        let hardLimit = start.addingTimeInterval(seconds + 4)
        while !Task.isCancelled, isPlaying, pendingAck == nil, Date() < deadline {
            if let last = voice.lastHeardAt {
                if Date().timeIntervalSince(last) > 1.1 { break }        // 말이 끝남
                deadline = min(hardLimit, max(deadline, last.addingTimeInterval(1.5)))
            }
            await rest(0.15)
        }
        let heard = voice.close()
        heardText = heard
        if let ack = pendingAck {
            pendingAck = nil
            await say(ack, in: AppLanguage.native, rate: 1.05)
        }
        return heard
    }

    /// 말해 본 문장을 정답과 견줘 짧게 반응한다.
    private func react(to heard: String, target: String) async {
        guard voiceActive, !heard.isEmpty else { lastResult = voiceActive ? .missed : nil; return }
        let score = SpeechManager.similarityScore(spoken: heard, target: target)
        if score >= 0.75 {
            lastResult = .good
            correctCount += 1
            await say(String(localized: "좋아요!"), in: AppLanguage.native, rate: 1.05)
        } else if score >= 0.4 {
            lastResult = .close
            await say(String(localized: "거의 맞았어요"), in: AppLanguage.native, rate: 1.05)
        } else {
            lastResult = .missed
        }
    }

    /// 말로 한 명령
    private func handle(_ cmd: DriveCommand) {
        guard isActive else { return }
        switch cmd {
        case .next: next()
        case .again: previous()
        case .nextScene: nextLesson()
        case .stop: pause()
        case .slower:
            UserDefaults.standard.set(max(0.6, DriveSettings.rate - 0.1), forKey: DriveSettings.rateKey)
            pendingAck = String(localized: "천천히 할게요")
        case .faster:
            UserDefaults.standard.set(min(1.2, DriveSettings.rate + 0.1), forKey: DriveSettings.rateKey)
            pendingAck = String(localized: "빠르게 할게요")
        }
    }

    /// 문장 길이에 맞춰 말해 볼 시간 (2.5 ~ 8초)
    private func thinkTime(for text: String) -> Double {
        let units = AppLanguage.learning.writesWithoutSpaces ? Double(text.count) * 0.35 : Double(text.count) * 0.09
        return min(8, max(2.5, 1.5 + units))
    }

    private func advanceLine() {
        guard let current = lessons[safe: lessonIndex] else { return }
        if lineIndex + 1 < current.lines.count {
            lineIndex += 1
        } else {
            finishLesson(completed: true)
        }
    }

    private func finishLesson(completed: Bool) {
        if completed, let current = lessons[safe: lessonIndex] {
            PracticeHistoryStore.shared.record(
                language: language, scenarioKey: current.id, title: current.title,
                mode: .drive, lines: current.lines.count
            )
        }
        lessonIndex = (lessonIndex + 1) % max(lessons.count, 1)
        lineIndex = 0
        UserDefaults.standard.set(lessonIndex, forKey: DriveSettings.cursorKey(source, language))
        refreshCurrent()
    }

    private func refreshCurrent() {
        lesson = lessons[safe: lessonIndex]
        line = lesson?.lines[safe: lineIndex]
    }

    private func rest(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
    }

    // MARK: - Speech

    private func say(_ text: String, in lang: AppLanguage, rate: Double) async {
        guard !Task.isCancelled, isPlaying, !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = SpeechVoice.best(for: lang)
        utterance.rate = Float(Double(AVSpeechUtteranceDefaultSpeechRate) * rate)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            speechContinuation?.resume()
            speechContinuation = cont
            synthesizer.speak(utterance)
        }
    }

    private func stopSpeech() {
        synthesizer.stopSpeaking(at: .immediate)
        speechContinuation?.resume()
        speechContinuation = nil
    }

    fileprivate func speechEnded() {
        speechContinuation?.resume()
        speechContinuation = nil
    }

    // MARK: - Audio

    private func activateAudio() async {
        let wantsMic = DriveSettings.voice && DriveVoiceListener.isAuthorized
            && LeeoRemoteFlags.isEnabled(MalmunFlag.driveVoice)
        do {
            try await AudioSessionQueue.run { session in
                if wantsMic {
                    // 소리는 차(A2DP)·스피커로, 듣기는 폰 마이크로. 블루투스 통화 모드(HFP)는 쓰지 않는다.
                    let options: AVAudioSession.CategoryOptions = [.allowBluetoothA2DP, .defaultToSpeaker, .allowAirPlay]
                    do {
                        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: options)
                    } catch {
                        try session.setCategory(.playAndRecord, mode: .default, options: options)
                    }
                    try session.setActive(true)
                    if let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                        try? session.setPreferredInput(builtIn)
                    }
                } else {
                    // spokenAudio: 내비 안내가 나오면 시스템이 잠깐 멈췄다가 이어 준다.
                    try session.setCategory(.playback, mode: .spokenAudio, options: [])
                    try session.setActive(true)
                }
            }
            AudioSessionQueue.owner = .drive
        } catch {
            print("[Drive] 오디오 세션 실패: \(error)")
        }
        startEngine(withMic: wantsMic)
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func stopEngine() {
        engine.stop()
        if micTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            micTapInstalled = false
        }
    }

    private func startEngine(withMic: Bool) {
        // 마이크 사용 여부가 바뀌었으면 엔진을 다시 꾸린다.
        if engine.isRunning, withMic != micTapInstalled { stopEngine() }
        if withMic, !micTapInstalled {
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            if format.sampleRate > 0 {
                let listener = voice
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                    listener.append(buffer)
                }
                micTapInstalled = true
            }
        }
        if !engineReady {
            engine.attach(silencePlayer)
            engine.attach(cuePlayer)
            let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
            engine.connect(silencePlayer, to: engine.mainMixerNode, format: format)
            engine.connect(cuePlayer, to: engine.mainMixerNode, format: format)
            engineReady = true
        }
        guard !engine.isRunning else { voiceActive = micTapInstalled; return }
        do {
            try engine.start()
            voiceActive = micTapInstalled
            let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
            if let silence = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44_100) {
                silence.frameLength = 44_100   // 0 으로 채워진 1초
                silencePlayer.scheduleBuffer(silence, at: nil, options: .loops)
                silencePlayer.play()
            }
            cuePlayer.play()
        } catch {
            print("[Drive] 엔진 시작 실패: \(error)")
            // 화면 없이(Siri) 시작해 마이크를 못 열면 목소리 조작 없이라도 소리는 낸다.
            if micTapInstalled {
                stopEngine()
                voiceActive = false
                Task {
                    try? await AudioSessionQueue.run { try $0.setCategory(.playback, mode: .spokenAudio, options: []) }
                    startEngine(withMic: false)
                }
            }
        }
    }

    /// 말해 볼 차례를 알리는 짧은 딩 (두 음)
    private func playCue() {
        guard engine.isRunning else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let frames = AVAudioFrameCount(44_100 * 0.28)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buf.floatChannelData?[0] else { return }
        buf.frameLength = frames
        let half = Int(frames) / 2
        for i in 0..<Int(frames) {
            let freq: Float = i < half ? 784 : 1046   // 솔 → 도
            let t = Float(i) / 44_100
            let local = Float(i % half) / Float(half)
            let envelope = sin(Float.pi * local) * 0.22
            data[i] = sin(2 * Float.pi * freq * t) * envelope
        }
        cuePlayer.scheduleBuffer(buf, at: nil, options: [])
    }

    private func observeSession() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let info = note.userInfo
            Task { @MainActor in self?.handleInterruption(info) }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let info = note.userInfo
            Task { @MainActor in self?.handleRouteChange(info) }
        }
    }

    private func handleInterruption(_ info: [AnyHashable: Any]?) {
        guard let raw = info?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            if isPlaying { pause(); resumeAfterInterruption = true }
        case .ended:
            let opts = (info?[AVAudioSessionInterruptionOptionKey] as? UInt).map(AVAudioSession.InterruptionOptions.init) ?? []
            if resumeAfterInterruption, opts.contains(.shouldResume) { play() }
            resumeAfterInterruption = false
        @unknown default:
            break
        }
    }
    private var resumeAfterInterruption = false

    /// 차에서 내려 블루투스가 끊기면 멈춘다.
    private func handleRouteChange(_ info: [AnyHashable: Any]?) {
        guard let raw = info?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
        pause()
    }

    // MARK: - Now Playing / Remote

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.play() }; return .success }
        c.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.pause() }; return .success }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.toggle() }; return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.next() }; return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.previous() }; return .success }
        c.skipForwardCommand.isEnabled = false
        c.skipBackwardCommand.isEnabled = false
        c.changePlaybackPositionCommand.isEnabled = false
    }

    private static let artwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "BrandMark") else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }()

    /// 차 화면·잠금 화면에 보이는 글: 제목 = 지금 문장, 부제 = 뜻(말해 볼 차례엔 가림)
    private func updateNowPlaying() {
        var info: [String: Any] = [:]
        let lessonTitle = lesson?.title ?? String(localized: "퇴근길 모드")
        switch phase {
        case .intro, .idle, .finished:
            info[MPMediaItemPropertyTitle] = lessonTitle
            info[MPMediaItemPropertyArtist] = String(localized: "말문 퇴근길 모드")
        case .yourTurn:
            info[MPMediaItemPropertyTitle] = line?.meaning ?? ""
            info[MPMediaItemPropertyArtist] = String(localized: "🗣 말해 보세요")
        case .listening, .answer:
            if line?.role == .speak && phase == .listening {
                info[MPMediaItemPropertyTitle] = line?.meaning ?? ""
                info[MPMediaItemPropertyArtist] = String(localized: "어떻게 말할까요?")
            } else {
                info[MPMediaItemPropertyTitle] = line?.text ?? ""
                info[MPMediaItemPropertyArtist] = line?.meaning ?? ""
            }
        }
        info[MPMediaItemPropertyAlbumTitle] = "\(lessonTitle) · \(lessonPosition.index)/\(lessonPosition.count)"
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        if let art = Self.artwork { info[MPMediaItemPropertyArtwork] = art }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
}

// MARK: - Speech delegate

extension DriveSession: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speechEnded() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speechEnded() }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
