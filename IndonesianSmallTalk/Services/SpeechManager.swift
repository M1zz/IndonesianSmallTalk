import AVFoundation
import Speech

@MainActor
class SpeechManager: ObservableObject {
    // MARK: - TTS
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - STT
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var recognizedText = ""
    @Published var permissionGranted = false

    private var ttsDelegate: TTSDelegate?

    // 정적 감지
    private var silenceTimer: Timer?
    private var hasSpeechBegun = false
    private var onSilenceDetected: (() -> Void)?
    private let silenceThreshold: Float = -40.0  // dB 기준
    private let silenceTimeout: TimeInterval = 2.0  // 말한 뒤 2초 정적이면 자동 종료

    init() {
        ttsDelegate = TTSDelegate { [weak self] in
            self?.isSpeaking = false
        }
        synthesizer.delegate = ttsDelegate
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - Permissions

    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }

        let audioStatus: Bool
        if #available(iOS 17.0, *) {
            audioStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            audioStatus = await withCheckedContinuation { cont in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        }

        permissionGranted = speechStatus == .authorized && audioStatus
    }

    // MARK: - TTS

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        synthesizer.stopSpeaking(at: .immediate)

        // TTS 전에 오디오 세션을 스피커 출력으로 재설정
        configureAudioSession()

        isSpeaking = true

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.05
        utterance.postUtteranceDelay = 0.3

        ttsDelegate?.onFinish = { [weak self] in
            self?.isSpeaking = false
            completion?()
        }

        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - STT (정적 감지 포함)

    /// onSilence: 말한 뒤 정적이 감지되면 자동 호출됨
    func startListening(onSilence: (() -> Void)? = nil) throws {
        stopListening()
        recognizedText = ""
        hasSpeechBegun = false
        self.onSilenceDetected = onSilence

        configureAudioSession()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.recognizedText = result.bestTranscription.formattedString
                    // 텍스트가 인식되면 말이 시작된 것
                    if !self.recognizedText.isEmpty {
                        self.hasSpeechBegun = true
                    }
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            self?.detectSilence(buffer: buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        onSilenceDetected = nil
        hasSpeechBegun = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    // MARK: - 정적 감지

    private nonisolated func detectSilence(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // RMS 계산
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(max(rms, 1e-9))

        let isSilent = db < -40.0

        Task { @MainActor in
            self.handleSilenceState(isSilent: isSilent)
        }
    }

    private func handleSilenceState(isSilent: Bool) {
        if isSilent && hasSpeechBegun {
            // 말한 뒤 조용해짐 → 타이머 시작 (아직 없으면)
            if silenceTimer == nil {
                silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        guard let self, self.isListening else { return }
                        let callback = self.onSilenceDetected
                        self.stopListening()
                        callback?()
                    }
                }
            }
        } else if !isSilent {
            // 소리가 들리면 타이머 리셋
            silenceTimer?.invalidate()
            silenceTimer = nil
        }
    }

    // MARK: - Matching

    func bestMatch(from choices: [ConversationNode]) -> ConversationNode? {
        guard !recognizedText.isEmpty else { return nil }
        let spoken = Self.normalizeForMatch(recognizedText)
        guard !spoken.isEmpty else { return nil }

        var bestScore = 0.0
        var bestNode: ConversationNode?

        for choice in choices {
            let target = Self.normalizeForMatch(choice.indonesian)
            let score = similarity(spoken, target)
            if score > bestScore {
                bestScore = score
                bestNode = choice
            }
        }

        // 최소 유사도 20% 이상이어야 매칭
        return bestScore >= 0.2 ? bestNode : nil
    }

    /// 비교용 정규화: 소문자화 + 문자/숫자/공백만 남김(구두점·이모지 제거) + 공백 압축
    static func normalizeForMatch(_ s: String) -> String {
        let lowered = s.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
                return Character(scalar)
            }
            return " "
        }
        return String(scalars)
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    private func similarity(_ a: String, _ b: String) -> Double {
        Self.similarityScore(spoken: a, target: b, alreadyNormalized: true)
    }

    /// 발화와 타겟 문장의 유사도(0.0~1.0). 이미 정규화된 문자열이 아니면 자동 정규화.
    static func similarityScore(spoken: String, target: String, alreadyNormalized: Bool = false) -> Double {
        let a = alreadyNormalized ? spoken : normalizeForMatch(spoken)
        let b = alreadyNormalized ? target : normalizeForMatch(target)

        let aWords = Set(a.split(separator: " ").map { String($0) })
        let bWords = Set(b.split(separator: " ").map { String($0) })

        guard !bWords.isEmpty else { return 0 }

        let intersection = aWords.intersection(bWords).count
        let wordScore = Double(intersection) / Double(bWords.count)

        let maxLen = max(a.count, b.count)
        guard maxLen > 0 else { return 0 }
        let dist = levenshtein(a, b)
        let charScore = 1.0 - Double(dist) / Double(maxLen)

        return wordScore * 0.6 + charScore * 0.4
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        Self.levenshtein(a, b)
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let aArr = Array(a)
        let bArr = Array(b)
        var dp = Array(0...bArr.count)

        for i in 1...aArr.count {
            var prev = dp[0]
            dp[0] = i
            for j in 1...bArr.count {
                let temp = dp[j]
                if aArr[i-1] == bArr[j-1] {
                    dp[j] = prev
                } else {
                    dp[j] = min(prev, dp[j], dp[j-1]) + 1
                }
                prev = temp
            }
        }
        return dp[bArr.count]
    }
}

// MARK: - TTS Delegate

private class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onFinish?()
        }
    }
}
