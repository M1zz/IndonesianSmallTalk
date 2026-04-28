import CloudKit
import Foundation

@MainActor
final class SharedReplyStore: ObservableObject {
    @Published private(set) var replies: [SharedUserReply] = []
    @Published var lastError: String?

    private let service = CloudKitService.shared

    func replies(for parentNodeId: String) -> [SharedUserReply] {
        replies
            .filter { $0.parentNodeId == parentNodeId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func refresh(forScenarios scenarios: [SharedScenario]) async {
        var collected: [SharedUserReply] = []
        for scenario in scenarios {
            do {
                let r = try await service.fetchReplies(for: scenario)
                collected.append(contentsOf: r)
            } catch {
                print("[SharedReplyStore] reply fetch 실패 (\(scenario.title)): \(error)")
            }
        }
        replies = collected
        print("[SharedReplyStore] total replies: \(replies.count)")
    }

    func add(reply: SharedUserReply, parentScenario: SharedScenario) async -> Bool {
        do {
            try await service.saveReply(reply, parentScenario: parentScenario)
            replies.append(reply)
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            print("[SharedReplyStore] reply 저장 실패: \(error)")
            return false
        }
    }

    func delete(id: UUID, parentScenario: SharedScenario) async {
        do {
            try await service.deleteReply(id: id, parentScenario: parentScenario)
            replies.removeAll { $0.id == id }
        } catch {
            print("[SharedReplyStore] reply 삭제 실패: \(error)")
            lastError = error.localizedDescription
        }
    }
}
