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
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            async let mineTask = service.fetchPrivateScenarios()
            async let theirsTask = service.fetchSharedScenarios()
            let mine = try await mineTask
            let theirs = try await theirsTask
            myScenarios = mine.sorted { $0.createdAt > $1.createdAt }
            friendScenarios = theirs.sorted { $0.createdAt > $1.createdAt }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
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
}
