import Foundation

struct SharedPhraseReader {
    private static let appGroupID = "group.com.devkoan.IndonesianSmallTalk"

    static func loadPhrases() -> [MyPhrase] {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return [] }
        let fileURL = groupURL.appendingPathComponent("myphrases.json")
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MyPhrase].self, from: data)) ?? []
    }
}
