import SwiftUI

/// 입력 폼에서 사용자 직접 입력을 격려하는 작은 배너.
/// 다양한 변형을 두고 폼별로 골라 쓰기.
struct EncouragementBanner: View {
    enum Tone {
        case phrase     // 표현 추가/수정
        case scenario   // 시나리오 추가/수정
        case reply      // 응답 추가
    }

    let tone: Tone

    private var icon: String {
        switch tone {
        case .phrase: return "✍️"
        case .scenario: return "🌱"
        case .reply: return "💭"
        }
    }

    private var title: String {
        switch tone {
        case .phrase: return "직접 적는 이 시간이 학습이에요"
        case .scenario: return "첫 마디 한 줄로 트리가 시작돼요"
        case .reply: return "어떤 답이 나올 수 있을까 떠올려보세요"
        }
    }

    private var body_text: String {
        switch tone {
        case .phrase:
            return "한 글자씩 입력하면서 뇌가 그 표현을 '내 것'으로 만들어요. 천천히 적으셔도 괜찮습니다."
        case .scenario:
            return "직접 입력한 만큼 본인 머리에 남아요. 짧아도, 어색해도 일단 적고 시작하세요."
        case .reply:
            return "정답은 없어요. 가능한 답변을 떠올려 적는 그 과정 자체가 그 상황 학습이에요."
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.50, blue: 0.0))
                Text(body_text)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.8)
                )
        )
    }
}
