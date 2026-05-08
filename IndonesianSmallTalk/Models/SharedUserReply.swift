import CloudKit
import Foundation

/// 공유 시나리오에 달리는 사용자 응답. 부모 시나리오 record 의 자식으로 묶여
/// CKShare 와 함께 자동 공유된다 — 둘이 동시에 응답을 추가해도 record 가 다르므로 충돌 없음.
struct SharedUserReply: Identifiable, Equatable {
    static let recordType = "SharedUserReply"

    let id: UUID
    let parentNodeId: String
    let scenarioID: UUID
    var indonesian: String
    var korean: String
    var romanization: String
    var polarity: Polarity
    var speakerRaw: String = "me"
    var createdAt: Date

    var ownedByMe: Bool
    var zoneID: CKRecordZone.ID?

    /// 화면 렌더용 ConversationNode (UserReply.toNode 와 같은 패턴)
    func toNode() -> ConversationNode {
        ConversationNode(
            id: "user-\(id.uuidString)",
            speaker: speakerRaw == "other" ? .other : .me,
            indonesian: indonesian,
            korean: korean,
            romanization: romanization,
            polarity: polarity,
            coachTip: nil,
            children: []
        )
    }
}

extension SharedUserReply {
    init?(record: CKRecord, ownedByMe: Bool) {
        guard
            let parentNodeId = record["parentNodeId"] as? String,
            let scenarioRaw = record["scenarioID"] as? String,
            let scenarioID = UUID(uuidString: scenarioRaw),
            let indonesian = record["indonesian"] as? String,
            let korean = record["korean"] as? String
        else { return nil }

        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.parentNodeId = parentNodeId
        self.scenarioID = scenarioID
        self.indonesian = indonesian
        self.korean = korean
        self.romanization = (record["romanization"] as? String) ?? ""
        self.polarity = Polarity(rawValue: (record["polarity"] as? String) ?? "neutral") ?? .neutral
        self.speakerRaw = (record["speakerRaw"] as? String) ?? "me"
        self.createdAt = record.creationDate ?? Date()
        self.ownedByMe = ownedByMe
        self.zoneID = record.recordID.zoneID
    }

    /// 자식 record 로 저장. parent 레퍼런스로 시나리오 record 와 묶음 → CKShare 자동 포함.
    func toRecord(parentScenarioRecord: CKRecord, inZone zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["parentNodeId"] = parentNodeId as CKRecordValue
        record["scenarioID"] = scenarioID.uuidString as CKRecordValue
        record["indonesian"] = indonesian as CKRecordValue
        record["korean"] = korean as CKRecordValue
        record["romanization"] = romanization as CKRecordValue
        record["polarity"] = polarity.rawValue as CKRecordValue
        record["speakerRaw"] = speakerRaw as CKRecordValue
        // parent 레퍼런스 → 같은 share hierarchy 로 묶임
        record.parent = CKRecord.Reference(record: parentScenarioRecord, action: .none)
        return record
    }
}
