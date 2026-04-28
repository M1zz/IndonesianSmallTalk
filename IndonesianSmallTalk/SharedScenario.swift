import CloudKit
import Foundation

struct SharedScenario: Identifiable, Equatable {
    static let recordType = "SharedScenario"

    let id: UUID
    var title: String
    var titleKo: String
    var description: String
    var emoji: String
    var difficultyRaw: String
    var openerSpeakerIsOther: Bool
    var openingIndonesian: String
    var openingKorean: String
    var openingRomanization: String
    var createdAt: Date

    /// 내가 만든 (private DB) — true / 친구가 공유 (shared DB) — false
    var ownedByMe: Bool

    /// shared DB 에서 온 경우 zone 정보를 보존(저장 시 필요)
    var zoneID: CKRecordZone.ID?

    /// 다른 사람이 공유해준 시나리오인 경우 소유자 표시명
    var ownerDisplay: String?

    var rootNodeId: String { "shared-\(id.uuidString)-root" }

    static func == (lhs: SharedScenario, rhs: SharedScenario) -> Bool {
        lhs.id == rhs.id && lhs.ownedByMe == rhs.ownedByMe
    }
}

// MARK: - CKRecord <-> SharedScenario

extension SharedScenario {
    init?(record: CKRecord, ownedByMe: Bool) {
        guard
            let title = record["title"] as? String,
            let titleKo = record["titleKo"] as? String,
            let emoji = record["emoji"] as? String,
            let difficultyRaw = record["difficultyRaw"] as? String,
            let openingIndonesian = record["openingIndonesian"] as? String,
            let openingKorean = record["openingKorean"] as? String
        else { return nil }

        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.title = title
        self.titleKo = titleKo
        self.description = (record["desc"] as? String) ?? ""
        self.emoji = emoji
        self.difficultyRaw = difficultyRaw
        self.openerSpeakerIsOther = (record["openerSpeakerIsOther"] as? Int64 ?? 1) != 0
        self.openingIndonesian = openingIndonesian
        self.openingKorean = openingKorean
        self.openingRomanization = (record["openingRomanization"] as? String) ?? ""
        self.createdAt = record.creationDate ?? Date()
        self.ownedByMe = ownedByMe
        self.zoneID = record.recordID.zoneID
        self.ownerDisplay = nil
    }

    func toRecord(inZone zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["title"] = title as CKRecordValue
        record["titleKo"] = titleKo as CKRecordValue
        record["desc"] = description as CKRecordValue
        record["emoji"] = emoji as CKRecordValue
        record["difficultyRaw"] = difficultyRaw as CKRecordValue
        record["openerSpeakerIsOther"] = (openerSpeakerIsOther ? 1 : 0) as CKRecordValue
        record["openingIndonesian"] = openingIndonesian as CKRecordValue
        record["openingKorean"] = openingKorean as CKRecordValue
        record["openingRomanization"] = openingRomanization as CKRecordValue
        return record
    }
}

// MARK: - Conversion to ConversationScenario

extension SharedScenario {
    func toScenario() -> ConversationScenario {
        let root = ConversationNode(
            id: rootNodeId,
            speaker: openerSpeakerIsOther ? .other : .me,
            indonesian: openingIndonesian,
            korean: openingKorean,
            romanization: openingRomanization,
            polarity: .neutral,
            coachTip: nil,
            children: []
        )
        let difficulty = ConversationScenario.Difficulty(rawValue: difficultyRaw) ?? .beginner
        return ConversationScenario(
            id: id,
            title: title,
            titleKo: titleKo,
            description: description,
            emoji: emoji,
            root: root,
            difficulty: difficulty
        )
    }
}
