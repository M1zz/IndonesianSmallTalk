import CloudKit
import UIKit

/// SwiftUI App 라이프사이클은 scene 기반이라 CKShare 수락 콜백은
/// AppDelegate 가 아니라 이 SceneDelegate 의 windowScene 메서드로 들어온다.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        print("[SceneDelegate] CKShare 수락 들어옴: \(cloudKitShareMetadata.share.recordID)")
        Task { @MainActor in
            do {
                try await CloudKitService.shared.accept(metadata: cloudKitShareMetadata)
                print("[SceneDelegate] accept 성공 — 새로고침 트리거")
                AppDelegate.onShareAccepted?()
            } catch {
                print("[SceneDelegate] accept 실패: \(error)")
            }
        }
    }
}
