import CloudKit
import Combine
import Foundation

@MainActor
final class SharedScenarioStore: ObservableObject {
    @Published private(set) var myScenarios: [SharedScenario] = []
    @Published private(set) var friendScenarios: [SharedScenario] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var iCloudAvailable = true

    private let service = CloudKitService.shared

    var allScenarios: [SharedScenario] { myScenarios + friendScenarios }

    func refresh() async {
        let status = await service.accountStatus()
        iCloudAvailable = (status == .available)
        guard iCloudAvailable else {
            lastError = "iCloud 로그인이 필요합니다"
            print("[SharedScenarioStore] iCloud 미로그인 (status=\(status.rawValue))")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // 두 fetch 를 별도로 try — 하나가 실패해도 다른 쪽은 보여줌
        do {
            myScenarios = try await service.fetchPrivateScenarios()
                .sorted { $0.createdAt > $1.createdAt }
            print("[SharedScenarioStore] private fetch OK: \(myScenarios.count)")
        } catch {
            print("[SharedScenarioStore] private fetch 실패: \(error)")
            lastError = "내 시나리오 불러오기 실패: \(error.localizedDescription)"
        }

        do {
            friendScenarios = try await service.fetchSharedScenarios()
                .sorted { $0.createdAt > $1.createdAt }
            print("[SharedScenarioStore] shared fetch OK: \(friendScenarios.count)")
        } catch {
            print("[SharedScenarioStore] shared fetch 실패: \(error)")
            lastError = "친구 시나리오 불러오기 실패: \(error.localizedDescription)"
        }

        if myScenarios.isEmpty && friendScenarios.isEmpty && lastError == nil {
            print("[SharedScenarioStore] 양쪽 모두 비어있음 (에러는 아님)")
        }
    }

    func add(_ scenario: SharedScenario) async -> Bool {
        do {
            try await service.savePrivate(scenario)
            myScenarios.insert(scenario, at: 0)
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func delete(id: UUID) async {
        do {
            try await service.deletePrivate(id: id)
            myScenarios.removeAll { $0.id == id }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stopSharing(id: UUID) async -> Bool {
        do {
            try await service.stopSharing(for: id)
            myScenarios.removeAll { $0.id == id }
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    var myScenarioIDs: Set<UUID> { Set(myScenarios.map { $0.id }) }
}
