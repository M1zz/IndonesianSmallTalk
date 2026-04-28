import CloudKit
import SwiftUI
import UIKit

struct CloudKitShareSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowReadOnly, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDone: () -> Void
        init(onDone: @escaping () -> Void) { self.onDone = onDone }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("CKShare 저장 실패: \(error)")
            onDone()
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            csc.share?[CKShare.SystemFieldKey.title] as? String ?? "스몰토크 공유"
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDone()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDone()
        }
    }
}
