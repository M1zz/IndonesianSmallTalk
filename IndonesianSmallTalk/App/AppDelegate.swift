import CloudKit
import UIKit

/// SwiftUI scene-based 앱에선 CKShare 수락이 SceneDelegate 로 라우팅됨.
/// 여기선 SceneDelegate 등록 + 비-scene 폴백을 처리.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var onShareAccepted: (() -> Void)?
    static var onRemoteNotification: (() -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 사일런트 푸시 수신 등록 (사용자 권한 불필요)
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("[AppDelegate] APNs 등록 OK")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] APNs 등록 실패: \(error)")
    }

    /// CloudKit 사일런트 푸시 수신 — 변경 감지 → 새로고침 트리거
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if notification?.subscriptionID != nil {
            print("[AppDelegate] CK 사일런트 푸시 수신")
            Task { @MainActor in
                AppDelegate.onRemoteNotification?()
                completionHandler(.newData)
            }
        } else {
            completionHandler(.noData)
        }
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    /// 폴백 — scene-based 가 아닌 환경에서만 호출됨
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        print("[AppDelegate] (fallback) CKShare 수락")
        Task { @MainActor in
            try? await CloudKitService.shared.accept(metadata: cloudKitShareMetadata)
            AppDelegate.onShareAccepted?()
        }
    }
}
