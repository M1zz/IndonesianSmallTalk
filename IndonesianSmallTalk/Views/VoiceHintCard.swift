import SwiftUI

/// 배우는 언어에 기본 음질 목소리밖에 없을 때, 더 또렷한 목소리를 받는 길을 알려 준다.
/// 앱이 목소리를 대신 받을 수는 없어서 iPhone 설정의 위치를 말해 준다. 받고 나면 SpeechVoice 가 알아서 그 목소리를 쓴다.
enum VoiceHint {
    static var isNeeded: Bool {
        #if DEBUG
        if ScreenshotScene.isActive { return false }
        #endif
        return (SpeechVoice.best(for: AppLanguage.learning)?.quality ?? .default) == .default
    }

    static var title: String { String(localized: "더 또렷한 목소리로 듣기") }

    static var steps: String {
        let language = AppLanguage.learning.localizedName
        return String(localized: "iPhone 설정 ▸ 손쉬운 사용 ▸ 읽기 및 말하기 ▸ 음성 ▸ \(language) 에서 '향상된 음질' 목소리를 받아 주세요. 받으면 말문이 그 목소리로 읽어요.")
    }
}

/// 홈에 한 번 보이는 안내. 닫으면 다시 나오지 않는다(설정 화면에는 계속 남는다).
struct VoiceHintCard: View {
    @AppStorage("voiceHintDismissed") private var dismissed = false

    var body: some View {
        if !dismissed && VoiceHint.isNeeded {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "waveform")
                    .scaledFont(size: 18, weight: .semibold)
                    .foregroundColor(Brand.blue)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(VoiceHint.title)
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(.primary)
                    Text(VoiceHint.steps)
                        .scaledFont(size: 12)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button { dismissed = true } label: {
                    Image(systemName: "xmark")
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(4)
                }
                .accessibilityLabel(Text("닫기"))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
        }
    }
}
