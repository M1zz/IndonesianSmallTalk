import CarPlay
import UIKit

/// CarPlay 화면: 무엇을 들을지 고르는 목록 → '지금 재생'.
/// Apple 에서 CarPlay 오디오 권한(com.apple.developer.carplay-audio)을 받아 entitlements 에 넣어야
/// 차 화면에 앱 아이콘이 생긴다. (docs/CARPLAY.md) 권한 전에도 블루투스·CarPlay '지금 재생'으로는 쓸 수 있다.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        Task { @MainActor in
            interfaceController.setRootTemplate(self.rootTemplate(), animated: false, completion: nil)
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    @MainActor
    private func rootTemplate() -> CPListTemplate {
        let lang = AppLanguage.learning
        let resume = CPListItem(
            text: String(localized: "이어 듣기"),
            detailText: String(localized: "\(lang.localizedName) · \(DriveSettings.source.title)"),
            image: UIImage(systemName: "play.circle.fill")
        )
        resume.handler = { [weak self] _, done in
            Task { @MainActor in
                self?.startAndShow(nil)
                done()
            }
        }

        let sources: [CPListItem] = DriveSource.allCases.compactMap { src in
            let count = DriveContent.lessons(for: src, language: lang).count
            guard count > 0 else { return nil }
            let item = CPListItem(
                text: src.title,
                detailText: String(localized: "장면 \(count)개"),
                image: UIImage(systemName: src.icon)
            )
            item.handler = { [weak self] _, done in
                Task { @MainActor in
                    self?.startAndShow(src)
                    done()
                }
            }
            return item
        }

        let template = CPListTemplate(
            title: String(localized: "말문 퇴근길"),
            sections: [
                CPListSection(items: [resume]),
                CPListSection(items: sources, header: String(localized: "무엇을 들을까요?"), sectionIndexTitle: nil)
            ]
        )
        template.tabImage = UIImage(systemName: "car.fill")
        return template
    }

    @MainActor
    private func startAndShow(_ source: DriveSource?) {
        if let source { DriveSession.shared.start(source) } else if DriveSession.shared.isActive { DriveSession.shared.play() } else { DriveSession.shared.start() }
        interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
    }
}
