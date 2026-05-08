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

    // MARK: - Save (fetch-or-create + .changedKeys 로 필드 단위 LWW)

    func savePrivate(_ scenario: SharedScenario) async throws {
        try await ensureZone()
        let recordID = CKRecord.ID(recordName: scenario.id.uuidString, zoneID: zoneID)
        let record = (try? await privateDB.record(for: recordID))
            ?? CKRecord(recordType: SharedScenario.recordType, recordID: recordID)
        scenario.applyTo(record: record)
        try await modifyChanged([record], in: privateDB)
    }

    /// 친구가 공유한 (shared DB 에 들어온) 시나리오 업데이트. zone 은 record 의 zone 을 그대로 사용.
    func saveShared(_ scenario: SharedScenario) async throws {
        guard let originalZone = scenario.zoneID else { return }
        let recordID = CKRecord.ID(recordName: scenario.id.uuidString, zoneID: originalZone)
        let record = (try? await sharedDB.record(for: recordID))
            ?? CKRecord(recordType: SharedScenario.recordType, recordID: recordID)
        scenario.applyTo(record: record)
        try await modifyChanged([record], in: sharedDB)
    }

    private func modifyChanged(_ records: [CKRecord], in db: CKDatabase) async throws {
        let (results, _) = try await db.modifyRecords(saving: records, deleting: [], savePolicy: .changedKeys)
        for (_, result) in results {
            if case .failure(let err) = result { throw err }
        }
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

        // 이미 share 가 있으면 재사용 (URL 포함된 서버 레코드 그대로 반환)
        if let existingRef = record.share,
           let existing = try? await privateDB.record(for: existingRef.recordID) as? CKShare {
            return (existing, container)
        }

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "스몰토크 공유: \(record["title"] as? String ?? "")" as CKRecordValue
        share.publicPermission = .none

        let (results, _) = try await privateDB.modifyRecords(saving: [record, share], deleting: [])

        // 저장 후 서버가 채운 URL이 포함된 share 를 results 에서 꺼냄
        var savedShare = share
        for (savedID, result) in results {
            switch result {
            case .failure(let err):
                throw err
            case .success(let savedRecord):
                if savedID == share.recordID, let updated = savedRecord as? CKShare {
                    savedShare = updated
                }
            }
        }

        return (savedShare, container)
    }

    // MARK: - Stop Sharing

    /// CKShare 삭제(친구 접근 차단) + CloudKit 레코드 삭제. 로컬 UserScenario는 건드리지 않음.
    func stopSharing(for scenarioID: UUID) async throws {
        try await ensureZone()
        let recordID = CKRecord.ID(recordName: scenarioID.uuidString, zoneID: zoneID)

        // share 레코드 먼저 삭제
        if let record = try? await privateDB.record(for: recordID),
           let shareRef = record.share {
            _ = try? await privateDB.deleteRecord(withID: shareRef.recordID)
        }

        // 시나리오 레코드 삭제
        _ = try await privateDB.deleteRecord(withID: recordID)
    }

    // MARK: - Shared Replies

    func saveReply(_ reply: SharedUserReply, parentScenario: SharedScenario) async throws {
        let zone = parentScenario.ownedByMe ? zoneID : (parentScenario.zoneID ?? zoneID)
        let db = parentScenario.ownedByMe ? privateDB : sharedDB
        let scenarioRecordID = CKRecord.ID(recordName: parentScenario.id.uuidString, zoneID: zone)
        let scenarioRecord = try await db.record(for: scenarioRecordID)
        let record = reply.toRecord(parentScenarioRecord: scenarioRecord, inZone: zone)
        try await modifyChanged([record], in: db)
    }

    func deleteReply(id: UUID, parentScenario: SharedScenario) async throws {
        let zone = parentScenario.ownedByMe ? zoneID : (parentScenario.zoneID ?? zoneID)
        let db = parentScenario.ownedByMe ? privateDB : sharedDB
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zone)
        _ = try await db.deleteRecord(withID: recordID)
    }

    func fetchReplies(for scenario: SharedScenario) async throws -> [SharedUserReply] {
        let zone = scenario.ownedByMe ? zoneID : (scenario.zoneID ?? zoneID)
        let db = scenario.ownedByMe ? privateDB : sharedDB
        let predicate = NSPredicate(format: "scenarioID == %@", scenario.id.uuidString)
        let query = CKQuery(recordType: SharedUserReply.recordType, predicate: predicate)
        var results: [SharedUserReply] = []
        var cursor: CKQueryOperation.Cursor? = nil
        repeat {
            let part: ([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)
            if let cursor {
                let r = try await db.records(continuingMatchFrom: cursor)
                part = (r.matchResults, r.queryCursor)
            } else {
                let r = try await db.records(matching: query, inZoneWith: zone)
                part = (r.matchResults, r.queryCursor)
            }
            for (_, recordResult) in part.0 {
                if let rec = try? recordResult.get(),
                   let reply = SharedUserReply(record: rec, ownedByMe: scenario.ownedByMe) {
                    results.append(reply)
                }
            }
            cursor = part.1
        } while cursor != nil
        return results
    }

    // MARK: - Subscriptions (사일런트 푸시로 변경 알림)

    private static let privateSubID = "private-db-changes"
    private static let sharedSubID = "shared-db-changes"

    func ensureSubscriptions() async throws {
        async let priv = ensureSub(id: Self.privateSubID, in: privateDB)
        async let shr = ensureSub(id: Self.sharedSubID, in: sharedDB)
        _ = try await (priv, shr)
    }

    private func ensureSub(id: String, in db: CKDatabase) async throws {
        // 이미 있으면 통과
        if (try? await db.subscription(for: id)) != nil { return }
        let sub = CKDatabaseSubscription(subscriptionID: id)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true   // 사일런트 푸시 (UI 없음)
        sub.notificationInfo = info
        do {
            _ = try await db.save(sub)
            print("[CloudKitService] subscription saved: \(id)")
        } catch let error as CKError where error.code == .serverRejectedRequest {
            print("[CloudKitService] subscription \(id) 이미 있음")
        }
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
