import Foundation

/// 한국어 젠지어 ↔ 비슷한 의미·톤의 인도네시아어 슬랭 매핑.
/// 사용자가 수정·추가·삭제 가능. 두 타겟 모두 동일하게 사용.
struct SlangPair: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var korean: String
    var indonesian: String
    var note: String

    init(id: UUID = UUID(), korean: String, indonesian: String, note: String = "") {
        self.id = id
        self.korean = korean
        self.indonesian = indonesian
        self.note = note
    }
}

enum BuiltInSlang {
    /// 처음 실행 시 SlangStore 가 시딩하는 기본 데이터셋.
    /// 사용자가 삭제/편집해도 되며, "기본값으로 복원" 시 이 목록으로 다시 채움.
    static let seedItems: [SlangPair] = [
        SlangPair(korean: "ㅋㅋㅋ",  indonesian: "wkwkwk",       note: "인터넷 웃음"),
        SlangPair(korean: "헐",      indonesian: "Anjir!",        note: "놀람"),
        SlangPair(korean: "대박",    indonesian: "Mantap!",       note: "최고/굉장"),
        SlangPair(korean: "미친",    indonesian: "Gila",          note: "충격/굉장"),
        SlangPair(korean: "진짜?",   indonesian: "Serius?",       note: "정말?"),
        SlangPair(korean: "노잼",    indonesian: "Garing",        note: "재미없음"),
        SlangPair(korean: "인싸",    indonesian: "Anak gaul",     note: "인기/노는 사람"),
        SlangPair(korean: "짱",      indonesian: "Keren banget",  note: "엄청 멋짐"),
        SlangPair(korean: "화이팅",  indonesian: "Semangat!",     note: "응원"),
        SlangPair(korean: "가자",    indonesian: "Yuk",           note: "가자/하자"),
        SlangPair(korean: "알았어",  indonesian: "Sip",           note: "오케이"),
        SlangPair(korean: "어떡해",  indonesian: "Gimana dong",   note: "어쩌지"),
        SlangPair(korean: "별로",    indonesian: "Biasa aja",     note: "그저 그래"),
        SlangPair(korean: "됐어",    indonesian: "Yaudahlah",     note: "됐어/그냥"),
        SlangPair(korean: "고마워",  indonesian: "Makasih",       note: "Terima kasih 줄임"),
        SlangPair(korean: "안 돼",   indonesian: "Nggak bisa",    note: "안 됨"),
        SlangPair(korean: "미안",    indonesian: "Sori",          note: "Sorry 차용"),
        SlangPair(korean: "와",      indonesian: "Wah",           note: "감탄"),
    ]
}

@MainActor
final class SlangStore: ObservableObject {
    @Published private(set) var pairs: [SlangPair] = []

    static let appGroupID = "group.com.devkoan.IndonesianSmallTalk"

    private let fileURL: URL = {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SlangStore.appGroupID
        ) {
            return groupURL.appendingPathComponent("myslangs.json")
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("myslangs.json")
    }()

    init() {
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        load()
        if !exists {
            // 첫 실행 — 시드 채우고 저장
            pairs = BuiltInSlang.seedItems
            save()
        }
    }

    func add(_ pair: SlangPair) {
        pairs.insert(pair, at: 0)
        save()
    }

    func update(_ pair: SlangPair) {
        guard let idx = pairs.firstIndex(where: { $0.id == pair.id }) else { return }
        pairs[idx] = pair
        save()
    }

    func delete(id: UUID) {
        pairs.removeAll { $0.id == id }
        save()
    }

    func resetToDefaults() {
        pairs = BuiltInSlang.seedItems
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        let items = source.sorted().map { pairs[$0] }
        let adjustedDest = destination - source.filter { $0 < destination }.count
        for idx in source.sorted(by: >) {
            pairs.remove(at: idx)
        }
        pairs.insert(contentsOf: items, at: max(0, min(adjustedDest, pairs.count)))
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([SlangPair].self, from: data) {
            pairs = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(pairs) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
