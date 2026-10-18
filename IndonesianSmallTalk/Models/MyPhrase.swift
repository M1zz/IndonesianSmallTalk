import Foundation
import SwiftUI

struct MyPhrase: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var indonesian: String      // 배우는 언어 문장 (이름은 예전 저장 파일과 맞추려고 그대로 둔다)
    var korean: String          // 뜻 (쓴 사람의 화면 언어)
    var context: String
    var polarity: Polarity = .neutral
    var inKeyboard: Bool = true
    var studyCount: Int = 0
    var createdAt: Date = Date()
    /// 이 표현의 언어 (AppLanguage.rawValue). 예전 저장분은 인도네시아어.
    var language: String = AppLanguage.indonesian.rawValue

    var text: String { indonesian }
    var meaning: String { korean }

    init(
        id: UUID = UUID(),
        indonesian: String,
        korean: String,
        context: String = "",
        polarity: Polarity = .neutral,
        inKeyboard: Bool = true,
        studyCount: Int = 0,
        createdAt: Date = Date(),
        language: AppLanguage = AppLanguage.learning
    ) {
        self.id = id
        self.indonesian = indonesian
        self.korean = korean
        self.context = context
        self.polarity = polarity
        self.inKeyboard = inKeyboard
        self.studyCount = studyCount
        self.createdAt = createdAt
        self.language = language.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case id, indonesian, korean, context, polarity, inKeyboard, studyCount, createdAt, language
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
        language = (try? c.decode(String.self, forKey: .language)) ?? AppLanguage.indonesian.rawValue
    }
}

@MainActor
final class PhraseStore: ObservableObject {
    /// 모든 언어의 표현 (파일에 저장되는 전부)
    @Published private(set) var allPhrases: [MyPhrase] = []

    /// 지금 배우는 언어의 표현만
    var phrases: [MyPhrase] { allPhrases.filter { $0.language == AppLanguage.learning.rawValue } }

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
        allPhrases.insert(phrase, at: 0)
        save()
    }

    func update(_ phrase: MyPhrase) {
        guard let idx = allPhrases.firstIndex(where: { $0.id == phrase.id }) else { return }
        allPhrases[idx] = phrase
        save()
    }

    func toggleInKeyboard(id: UUID) {
        guard let idx = allPhrases.firstIndex(where: { $0.id == id }) else { return }
        allPhrases[idx].inKeyboard.toggle()
        save()
    }

    func setAllInKeyboard(_ value: Bool) {
        let lang = AppLanguage.learning.rawValue
        for i in allPhrases.indices where allPhrases[i].language == lang { allPhrases[i].inKeyboard = value }
        save()
    }

    /// 지금 언어 목록(phrases) 기준의 위치로 옮긴다. 다른 언어 표현은 뒤에 그대로 둔다.
    func move(from source: IndexSet, to destination: Int) {
        var current = phrases
        current.move(fromOffsets: source, toOffset: destination)
        replaceCurrent(with: current)
    }

    func sortByStudyCount() {
        replaceCurrent(with: phrases.sorted {
            if $0.studyCount != $1.studyCount { return $0.studyCount > $1.studyCount }
            return $0.createdAt > $1.createdAt
        })
    }

    func sortByRecent() {
        replaceCurrent(with: phrases.sorted { $0.createdAt > $1.createdAt })
    }

    func incrementStudyCount(id: UUID) {
        guard let idx = allPhrases.firstIndex(where: { $0.id == id }) else { return }
        allPhrases[idx].studyCount += 1
        save()
    }

    var keyboardCount: Int { phrases.filter { $0.inKeyboard }.count }
    var totalStudyCount: Int { phrases.reduce(0) { $0 + $1.studyCount } }

    /// 지금 언어 목록(phrases) 기준의 위치
    func delete(at offsets: IndexSet) {
        let current = phrases
        let ids = Set(offsets.compactMap { $0 < current.count ? current[$0].id : nil })
        allPhrases.removeAll { ids.contains($0.id) }
        save()
    }

    func delete(id: UUID) {
        allPhrases.removeAll { $0.id == id }
        save()
    }

    private func replaceCurrent(with current: [MyPhrase]) {
        let lang = AppLanguage.learning.rawValue
        allPhrases = current + allPhrases.filter { $0.language != lang }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([MyPhrase].self, from: data) {
            allPhrases = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(allPhrases) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
