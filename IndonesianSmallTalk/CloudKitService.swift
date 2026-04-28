import CloudKit
import Foundation

/// CloudKit 동작을 한 곳에서 관리. Private DB 의 커스텀 zone 에 공유용 시나리오 레코드를 저장하고,
/// CKShare 로 친구를 초대하면 친구의 Shared DB 에 동일 레코드가 노출된다.
@MainActor
final class CloudKitService {
    static let shared = CloudKitService()

    let container: CKContainer
    let privateDB: CKDatabase
    let sharedDB: CKDatabase

    static let zoneName = "SharedScenarios"
    static let containerID = "iCloud.com.devkoan.IndonesianSmallTalk"

    private let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    private var zoneEnsured = false

    init() {
        container = CKContainer(identifier: Self.containerID)
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
    }

    // MARK: - Account

    func accountStatus() async -> CKAccountStatus {
        (try? await container.accountStatus()) ?? .couldNotDetermine
    }

    // MARK: - Zone

    private func ensureZone() async throws {
        guard !zoneEnsured else { return }
        let zone = CKRecordZone(zoneID: zoneID)
        do {
            _ = try await privateDB.save(zone)
        } catch let error as CKError where error.code == .serverRejectedRequest || error.code == .zoneBusy {
            // 이미 존재하는 zone — 무시
        }
        zoneEnsured = true
    }

    // MARK: - Save

    func savePrivate(_ scenario: SharedScenario) async throws {
        try await ensureZone()
        let record = scenario.toRecord(inZone: zoneID)
        _ = try await privateDB.save(record)
    }

    /// 친구가 공유한 (shared DB 에 들어온) 시나리오 업데이트. zone 은 record 의 zone 을 그대로 사용.
    func saveShared(_ scenario: SharedScenario) async throws {
        guard let originalZone = scenario.zoneID else { return }
        let record = scenario.toRecord(inZone: originalZone)
        _ = try await sharedDB.save(record)
    }

    // MARK: - Fetch

    func fetchPrivateScenarios() async throws -> [SharedScenario] {
        try await ensureZone()
        let query = CKQuery(recordType: SharedScenario.recordType, predicate: NSPredicate(value: true))
        return try await fetchAll(query: query, in: privateDB, zoneID: zoneID, ownedByMe: true)
    }

    func fetchSharedScenarios() async throws -> [SharedScenario] {
        // Shared DB 는 친구가 공유해준 zone 들을 가지고 있음 — 모든 zone 순회
        let zones = try await sharedDB.allRecordZones()
        var collected: [SharedScenario] = []
        for zone in zones {
            let query = CKQuery(recordType: SharedScenario.recordType, predicate: NSPredicate(value: true))
            do {
                let part = try await fetchAll(query: query, in: sharedDB, zoneID: zone.zoneID, ownedByMe: false)
                collected.append(contentsOf: part)
            } catch {
                continue
            }
        }
        return collected
    }

    private func fetchAll(query: CKQuery, in db: CKDatabase, zoneID: CKRecordZone.ID, ownedByMe: Bool) async throws -> [SharedScenario] {
        var results: [SharedScenario] = []
        var cursor: CKQueryOperation.Cursor? = nil
        repeat {
            let (matchResults, nextCursor): ([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)
            if let cursor {
                let r = try await db.records(continuingMatchFrom: cursor)
                matchResults = r.matchResults
                nextCursor = r.queryCursor
            } else {
                let r = try await db.records(matching: query, inZoneWith: zoneID)
                matchResults = r.matchResults
                nextCursor = r.queryCursor
            }
            for (_, recordResult) in matchResults {
                if let record = try? recordResult.get(),
                   let scenario = SharedScenario(record: record, ownedByMe: ownedByMe) {
                    results.append(scenario)
                }
            }
            cursor = nextCursor
        } while cursor != nil
        return results
    }

    // MARK: - Delete

    func deletePrivate(id: UUID) async throws {
        try await ensureZone()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        _ = try await privateDB.deleteRecord(withID: recordID)
    }

    // MARK: - Share

    /// 시나리오에 대한 CKShare 를 생성하고 저장. UICloudSharingController 에 그대로 전달 가능.
    func createShare(for scenarioID: UUID) async throws -> (CKShare, CKContainer) {
        try await ensureZone()
        let recordID = CKRecord.ID(recordName: scenarioID.uuidString, zoneID: zoneID)
        let record = try await privateDB.record(for: recordID)

        // 이미 share 가 있으면 재사용
        if let existingRef = record.share,
           let existing = try? await privateDB.record(for: existingRef.recordID) as? CKShare {
            return (existing, container)
        }

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "스몰토크 공유: \(record["title"] as? String ?? "")" as CKRecordValue
        share.publicPermission = .none

        let (results, _) = try await privateDB.modifyRecords(saving: [record, share], deleting: [])
        for (_, result) in results {
            if case .failure(let err) = result { throw err }
        }
        return (share, container)
    }

    // MARK: - Accept

    func accept(metadata: CKShare.Metadata) async throws {
        let op = CKAcceptSharesOperation(shareMetadatas: [metadata])
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.acceptSharesResultBlock = { result in
                switch result {
                case .success: cont.resume()
                case .failure(let err): cont.resume(throwing: err)
                }
            }
            container.add(op)
        }
    }
}
