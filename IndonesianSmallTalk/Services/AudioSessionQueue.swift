import AVFoundation

/// 오디오 세션 바꾸기(setCategory·setActive)는 시간이 걸려 메인 스레드에서 하면 화면이 멈칫한다.
/// 모든 세션 변경을 이 전용 줄에서 차례로 하고, 끝나면 이어서 진행한다.
/// 누가 지금 세션을 맞춰 두었는지(owner)도 기억해서, 이미 맞으면 다시 바꾸지 않는다.
enum AudioSessionQueue {
    enum Owner { case none, speech, drive }

    private static let queue = DispatchQueue(label: "malmun.audio-session", qos: .userInitiated)

    /// 마지막으로 세션을 맞춘 쪽 (메인 액터에서만 읽고 쓴다)
    @MainActor static var owner: Owner = .none

    /// 전용 줄에서 세션을 바꾼다. 실패하면 오류를 던진다.
    static func run(_ change: @escaping (AVAudioSession) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try change(AVAudioSession.sharedInstance())
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}
