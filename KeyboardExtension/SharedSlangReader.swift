import Foundation

/// App Group 의 myslangs.json 을 읽어 SlangPair 배열로 반환.
/// 파일이 아직 없으면 (메인 앱을 한 번도 안 연 경우) 시드를 폴백으로 사용.
enum SharedSlangReader {
    static let appGroupID = "group.com.devkoan.IndonesianSmallTalk"

    static func loadAll() -> [SlangPair] {
        guard
            let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("myslangs.json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([SlangPair].self, from: data)
        else {
            return BuiltInSlang.seedItems
        }
        return decoded
    }
}
