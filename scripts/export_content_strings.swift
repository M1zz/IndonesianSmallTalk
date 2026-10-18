// 인도네시아어 기본 콘텐츠의 한국어 원문을 번역용 JSON 으로 뽑는다.
//   cp scripts/export_content_strings.swift /tmp/exp/main.swift && swiftc -o /tmp/export /tmp/exp/main.swift IndonesianSmallTalk/Models/{AppLanguage,ContentLibrary,ConversationTree,ConversationData,Journey,JourneyData,Polarity,Vocabulary,BuiltInVocabulary}.swift
//   /tmp/export > translations.source.json
// 결과 { 키: 한국어 } 를 언어별로 옮겨 IndonesianSmallTalk/Resources/Content/translations.<언어>.json 에 둔다.
// 키 규칙은 ContentKey (ContentLibrary.swift).
import Foundation

var out: [String: String] = [:]
func put(_ key: String, _ ko: String) { if !ko.trimmingCharacters(in: .whitespaces).isEmpty { out[key] = ko } }

func walk(_ n: ConversationNode) {
    put(ContentKey.node(n.id), n.meanings[AppLanguage.korean.rawValue] ?? "")
    n.children.forEach(walk)
}

for s in ConversationData.allScenarios {
    put(ContentKey.scenarioTitle(s.title), s.titleMeanings["ko"] ?? "")
    walk(s.root)
}
for c in JourneyData.allCourses {
    put(ContentKey.course(c.id, "title"), c.titleKo)
    put(ContentKey.course(c.id, "description"), c.description)
    put(ContentKey.course(c.id, "dayLabel"), c.dayLabelKo)
    for st in c.stops {
        put(ContentKey.stop(st.id, "place"), st.placeKo)
        put(ContentKey.stop(st.id, "situation"), st.situation)
        if let t = st.transitNote { put(ContentKey.stop(st.id, "transit"), t) }
        put(ContentKey.scenarioTitle(st.scenario.title), st.placeKo)
        walk(st.scenario.root)
    }
}
for w in BuiltInVocabulary.seedItems {
    put(ContentKey.vocab(w.indonesian, "meaning"), w.korean)
    put(ContentKey.vocab(w.indonesian, "notes"), w.notes)
    for e in w.examples { put(ContentKey.example(e.indonesian), e.korean) }
}
for cat in VocabWord.categories { put(ContentKey.vocabCategory(cat), cat) }

let data = try! JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
print(String(data: data, encoding: .utf8)!)
