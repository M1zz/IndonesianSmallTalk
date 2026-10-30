//
//  MalmunRoadmap.swift
//
//  **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.1.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(기술 용어 금지). 번역은 Resources/Localizable.xcstrings 에 6개 언어로 채운다.
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 여기 적지 않는다.
//     - 배포 준비 때 이번 버전에 들어간 `.building` 을 `.shipped("버전")` 으로 옮긴다.
//

import SwiftUI
import LeeoKit

extension MalmunSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 1.0.3 에 나간 것
        .init(id: "lang.six", status: .shipped("1.0.3"),
              title: String(localized: "6개 언어 배우기"),
              detail: String(localized: "인도네시아어·영어·일본어·중국어·스페인어·한국어 중에서 골라 배워요. 앱 화면도 6개 언어로 볼 수 있어요.")),
        .init(id: "drive.mode", status: .shipped("1.0.3"),
              title: String(localized: "퇴근길 모드"),
              detail: String(localized: "차에 연결하고 화면 없이 귀로 연습해요. 말로 \"다음\" \"다시\" 하면 알아들어요.")),
        .init(id: "situations", status: .shipped("1.0.3"),
              title: String(localized: "상황별 회화"),
              detail: String(localized: "공항·숙소·식당·교통 같은 상황 대화를 언어마다 53개씩 연습해요.")),
        .init(id: "tools.pronunciation", status: .shipped("1.0.3"),
              title: String(localized: "발음 연습과 대본 보기"),
              detail: String(localized: "따라 말하면 점수를 알려 주고, 대화 전체를 메신저처럼 읽고 들을 수 있어요.")),

        // MARK: 만들고 있어요
        .init(id: "gift", status: .building,
              title: String(localized: "말문 Pro 선물하기"),
              detail: String(localized: "함께 공부하는 친구나 가족에게 말문 Pro 를 선물할 수 있어요.")),

        // MARK: 다음에 만들어요
        .init(id: "course.morelangs", status: .planned,
              title: String(localized: "다른 언어의 하루 코스"),
              detail: String(localized: "영어·일본어 등 다른 언어에도 하루를 따라가는 코스가 생겨요.")),
        .init(id: "vocab.morelangs", status: .planned,
              title: String(localized: "다른 언어의 기본 단어장"),
              detail: String(localized: "인도네시아어처럼 다른 언어에도 처음부터 꼭 필요한 단어가 들어 있어요.")),
        .init(id: "drive.review", status: .planned,
              title: String(localized: "틀린 문장 모아 듣기"),
              detail: String(localized: "퇴근길에 잘 안 된 문장만 모아서 다음 날 다시 들려줘요.")),
        .init(id: "course.badge", status: .planned,
              title: String(localized: "코스 완주 배지"),
              detail: String(localized: "하루 코스를 끝까지 마치면 기념 배지와 결과를 보여 줘요.")),
        .init(id: "course.reset", status: .planned,
              title: String(localized: "코스 처음부터 다시"),
              detail: String(localized: "다 배운 코스를 지우고 처음부터 다시 연습할 수 있어요.")),
    ]}
}

// MARK: - 화면

/// 설정 ▸ 앞으로 만들 기능. "이런 기능이 있으면 좋겠어요" 는 기능 제안으로 시작하는 피드백 창을 연다.
struct RoadmapScreen: View {
    @State private var showFeedback = false

    var body: some View {
        LeeoRoadmapView<MalmunSpec>(onSuggest: { showFeedback = true })
            .sheet(isPresented: $showFeedback) {
                NavigationStack {
                    LeeoFeedbackView<MalmunSpec>(initialType: .feature)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기", systemImage: "xmark") { showFeedback = false }
                            }
                        }
                }
                .tint(Brand.solidBlue)
            }
    }
}
