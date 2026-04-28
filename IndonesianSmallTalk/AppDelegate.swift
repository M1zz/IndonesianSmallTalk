import CloudKit
import UIKit

/// 외부에서 CloudKit 공유 URL 을 탭했을 때 처리. SwiftUI App 라이프사이클에선
/// `userDidAcceptCloudKitShareWith` 가 SceneDelegate 또는 AppDelegate 에서만 호출됨.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var onShareAccepted: (() -> Void)?

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            try? await CloudKitService.shared.accept(metadata: cloudKitShareMetadata)
            AppDelegate.onShareAccepted?()
        }
    }
}
