import Foundation

struct MyPhrase: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var indonesian: String
    var korean: String
    var context: String
    var polarity: Polarity = .neutral
    var inKeyboard: Bool = true
    var studyCount: Int = 0
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        indonesian: String,
        korean: String,
        context: String = "",
        polarity: Polarity = .neutral,
        inKeyboard: Bool = true,
        studyCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.indonesian = indonesian
        self.korean = korean
        self.context = context
        self.polarity = polarity
        self.inKeyboard = inKeyboard
        self.studyCount = studyCount
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, indonesian, korean, context, polarity, inKeyboard, studyCount, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        indonesian = try c.decode(String.self, forKey: .indonesian)
        korean = try c.decode(String.self, forKey: .korean)
        context = try c.decode(String.self, forKey: .context)
        polarity = (try? c.decode(Polarity.self, forKey: .polarity)) ?? .neutral
        inKeyboard = (try? c.decode(Bool.self, forKey: .inKeyboard)) ?? true
        studyCount = (try? c.decode(Int.self, forKey: .studyCount)) ?? 0
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

@MainActor
final class PhraseStore: ObservableObject {
    @Published private(set) var phrases: [MyPhrase] = []

    static let appGroupID = "group.com.devkoan.IndonesianSmallTalk"

    /// 키보드 익스텐션과 공유하기 위해 App Group 컨테이너에 저장.
    /// 컨테이너 접근이 안 될 때(권한 미설정 등)는 Documents 로 폴백.
    private let fileURL: URL = {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PhraseStore.appGroupID
        ) {
            return groupURL.appendingPathComponent("myphrases.json")
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("myphrases.json")
    }()

    init() {
        migrateFromDocumentsIfNeeded()
        load()
    }

    /// 이전 빌드 사용자: Documents/myphrases.json → App Group 으로 1회 이전
    private func migrateFromDocumentsIfNeeded() {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) else { return }
        let groupFile = groupURL.appendingPathComponent("myphrases.json")
        let fm = FileManager.default
        guard !fm.fileExists(atPath: groupFile.path) else { return }
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let oldFile = docs.appendingPathComponent("myphrases.json")
        guard fm.fileExists(atPath: oldFile.path) else { return }
        try? fm.copyItem(at: oldFile, to: groupFile)
    }

    func add(_ phrase: MyPhrase) {
        phrases.insert(phrase, at: 0)
        save()
    }

    func update(_ phrase: MyPhrase) {
        guard let idx = phrases.firstIndex(where: { $0.id == phrase.id }) else { return }
        phrases[idx] = phrase
        save()
    }

    func toggleInKeyboard(id: UUID) {
        guard let idx = phrases.firstIndex(where: { $0.id == id }) else { return }
        phrases[idx].inKeyboard.toggle()
        save()
    }

    func setAllInKeyboard(_ value: Bool) {
        for i in phrases.indices { phrases[i].inKeyboard = value }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        let movingItems = source.sorted().map { phrases[$0] }
        let adjustedDest = destination - source.filter { $0 < destination }.count
        for idx in source.sorted(by: >) {
            phrases.remove(at: idx)
        }
        phrases.insert(contentsOf: movingItems, at: max(0, min(adjustedDest, phrases.count)))
        save()
    }

    func sortByStudyCount() {
        phrases.sort {
            if $0.studyCount != $1.studyCount { return $0.studyCount > $1.studyCount }
            return $0.createdAt > $1.createdAt
        }
        save()
    }

    func sortByRecent() {
        phrases.sort { $0.createdAt > $1.createdAt }
        save()
    }

    func incrementStudyCount(id: UUID) {
        guard let idx = phrases.firstIndex(where: { $0.id == id }) else { return }
        phrases[idx].studyCount += 1
        save()
    }

    var keyboardCount: Int { phrases.filter { $0.inKeyboard }.count }
    var totalStudyCount: Int { phrases.reduce(0) { $0 + $1.studyCount } }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where index < phrases.count {
            phrases.remove(at: index)
        }
        save()
    }

    func delete(id: UUID) {
        phrases.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([MyPhrase].self, from: data) {
            phrases = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(phrases) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
