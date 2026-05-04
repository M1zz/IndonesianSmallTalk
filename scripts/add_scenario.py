#!/usr/bin/env python3
"""
add_scenario.py — HTML 페이지나 설명을 Claude API로 분석해
ConversationData.swift에 새 시나리오를 자동으로 추가합니다.

사용법:
  python3 scripts/add_scenario.py --html path/to/page.html --name scenarioRestoran
  python3 scripts/add_scenario.py --describe "Di Pasar - 시장에서 야채 사기" --name scenarioPasar

필요한 패키지:
  pip install anthropic
"""

import argparse
import re
import sys
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("anthropic 패키지가 필요합니다: pip install anthropic")
    sys.exit(1)

PROJECT_ROOT = Path(__file__).parent.parent
SWIFT_FILE = PROJECT_ROOT / "IndonesianSmallTalk" / "ConversationData.swift"

SYSTEM_PROMPT = """You are a Swift code generator for an Indonesian language learning iOS app.

The app teaches Indonesian small talk through conversation trees. Given an HTML page or description of Indonesian conversation scenarios, generate a Swift `ConversationScenario` extension.

## Data model (do NOT import or redefine these — they already exist):

```swift
struct CoachTip {
    let label: String       // technique name (Indonesian)
    let tip: String         // explanation
    let why: String         // pedagogical reason
}

class ConversationNode: Identifiable {
    let id: String
    let speaker: Speaker    // .me or .other
    let indonesian: String
    let korean: String
    let romanization: String  // Korean phonetic (한글 발음, e.g. "슬라맛 시앙")
    let polarity: Polarity    // .positive, .negative, .neutral
    let coachTip: CoachTip?
    let children: [ConversationNode]
}

struct ConversationScenario {
    let title: String       // Bahasa Indonesia topic name
    let titleKo: String     // Korean topic name
    let description: String // short description
    let emoji: String
    let root: ConversationNode
    let difficulty: Difficulty  // .beginner, .intermediate, .advanced
}
```

## Output format:

Generate ONLY the Swift extension code — no markdown fences, no comments outside the code, no imports.

```swift
extension ConversationData {
    static let scenarioXxx = ConversationScenario(
        title: "...",
        titleKo: "...",
        description: "...",
        emoji: "...",
        root: ConversationNode(
            id: "xxx_root",
            speaker: .other,
            indonesian: "...",
            korean: "...",
            romanization: "한글 발음",
            polarity: .neutral,
            coachTip: CoachTip(
                label: "...",
                tip: "...",
                why: "..."
            ),
            children: [
                ConversationNode(
                    id: "xxx_a",
                    ...
                    children: [...]
                ),
                ...
            ]
        ),
        difficulty: .beginner
    )
}
```

## Rules:
- Variable name: the exact name given by the user (e.g. scenarioPasar)
- Node IDs: short prefix + letter/number (e.g. "pas_root", "pas_a", "pas_a1", "pas_b")
- Include 2–3 top-level branches from root (A = positive path, B = another scenario, etc.)
- Each branch should have 2–3 depth levels with meaningful .me and .other turns
- Alternate speaker between .me and .other naturally
- coachTip: include for key nodes, nil for simple response nodes
- romanization: Korean phonetic spelling only (no Latin romanization)
- polarity: .positive for good conversation moves, .negative for less ideal but realistic choices
- Output ONLY valid Swift code, nothing else
"""


def read_html(path: str) -> str:
    content = Path(path).read_text(encoding="utf-8")
    # Strip script/style tags to reduce token count
    content = re.sub(r"<style[^>]*>.*?</style>", "", content, flags=re.DOTALL)
    content = re.sub(r"<script[^>]*>.*?</script>", "", content, flags=re.DOTALL)
    # Strip HTML tags, keep text
    content = re.sub(r"<[^>]+>", " ", content)
    content = re.sub(r"\s+", " ", content).strip()
    return content[:12000]  # Claude context limit safety


def generate_swift(content: str, scenario_name: str) -> str:
    client = anthropic.Anthropic()
    print(f"Claude에게 '{scenario_name}' 시나리오 생성 요청 중...")
    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=8000,
        system=SYSTEM_PROMPT,
        messages=[
            {
                "role": "user",
                "content": (
                    f"Variable name: {scenario_name}\n\n"
                    f"Content to convert:\n{content}"
                ),
            }
        ],
    )
    return message.content[0].text.strip()


def update_all_scenarios(swift_code: str, scenario_name: str) -> None:
    source = SWIFT_FILE.read_text(encoding="utf-8")

    # 이미 추가돼 있으면 스킵
    if scenario_name in source:
        print(f"⚠️  {scenario_name}이 이미 ConversationData.swift에 있어요. 건너뜁니다.")
        return

    # allScenarios 배열에 추가
    pattern = r"(static let allScenarios: \[ConversationScenario\] = \[)(.*?)(\])"
    match = re.search(pattern, source, re.DOTALL)
    if not match:
        print("❌ allScenarios 배열을 찾지 못했어요. 수동으로 추가해주세요.")
        return

    existing_list = match.group(2).rstrip()
    new_list = existing_list + f",\n        {scenario_name}"
    source = source[: match.start(2)] + new_list + "\n    " + source[match.end(2) :]

    # 파일 끝에 extension 추가
    source = source.rstrip() + "\n\n" + swift_code + "\n"
    SWIFT_FILE.write_text(source, encoding="utf-8")
    print(f"✅ {scenario_name}이 ConversationData.swift에 추가됐어요!")


def main():
    parser = argparse.ArgumentParser(
        description="Claude API로 인도네시아어 회화 시나리오를 생성해 앱에 추가"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--html", metavar="FILE", help="변환할 HTML 파일 경로")
    group.add_argument("--describe", metavar="TEXT", help="시나리오 설명 (자유 텍스트)")
    parser.add_argument(
        "--name",
        required=True,
        metavar="VAR_NAME",
        help="Swift 변수명 (예: scenarioPasar)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="생성된 Swift 코드만 출력하고 파일은 수정 안 함",
    )
    args = parser.parse_args()

    if not SWIFT_FILE.exists():
        print(f"❌ {SWIFT_FILE} 파일을 찾지 못했어요.")
        sys.exit(1)

    if args.html:
        if not Path(args.html).exists():
            print(f"❌ HTML 파일을 찾지 못했어요: {args.html}")
            sys.exit(1)
        content = read_html(args.html)
        print(f"HTML 파싱 완료: {len(content)}자")
    else:
        content = args.describe

    swift_code = generate_swift(content, args.name)

    if args.dry_run:
        print("\n── 생성된 Swift 코드 ──\n")
        print(swift_code)
        return

    # 생성된 코드 미리 보기
    print("\n── 생성된 Swift 코드 (앞 400자) ──")
    print(swift_code[:400])
    print("...\n")

    answer = input("이 코드를 ConversationData.swift에 추가할까요? [y/N] ").strip().lower()
    if answer != "y":
        print("취소했어요.")
        return

    update_all_scenarios(swift_code, args.name)


if __name__ == "__main__":
    main()
