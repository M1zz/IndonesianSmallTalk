import Foundation

/// App Group 컨테이너에서 메인 앱이 저장한 myphrases.json 을 읽는다.
enum SharedPhraseReader {
    static let appGroupID = "group.com.devkoan.IndonesianSmallTalk"

    static func loadPhrases() -> [MyPhrase] {
        guard
            let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("myphrases.json"),
            let data = try? Data(contentsOf: url)
        else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let all = (try? decoder.decode([MyPhrase].self, from: data)) ?? []
        // 키보드에 표시 토글이 켜진 것만
        return all.filter { $0.inKeyboard }
    }
}
