import SwiftUI

/// 연습 기록: 위에 연속 일수·횟수·문장 수, 아래에 날짜별 목록. 지금 배우는 언어만 보여 준다.
struct PracticeHistoryView: View {
    @ObservedObject private var store = PracticeHistoryStore.shared

    private var language: AppLanguage { AppLanguage.learning }
    private var records: [PracticeRecord] { store.records(for: language) }

    /// 날짜(하루) 단위로 묶기 — 최근 날짜가 위
    private var groups: [(day: Date, items: [PracticeRecord])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: records) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                statsHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if records.isEmpty {
                Section {
                    emptyState
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groups, id: \.day) { group in
                    Section(header: Text(dayTitle(group.day))) {
                        ForEach(group.items) { rec in
                            row(rec)
                        }
                        .onDelete { offsets in
                            for i in offsets { store.delete(id: group.items[i].id) }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text("연습 기록"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var statsHeader: some View {
        let stats = store.stats(for: language)
        return VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(language.flag)
                Text("\(language.localizedName) 연습")
                    .scaledFont(size: 13, weight: .bold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("이번 주 \(stats.thisWeekCount)회")
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundColor(Brand.blue)
            }
            HStack(spacing: 10) {
                statBox(value: stats.currentStreak, label: Text("연속 일수"), icon: "flame.fill", color: Brand.glow)
                statBox(value: stats.totalSessions, label: Text("연습 횟수"), icon: "checkmark.circle.fill", color: Brand.blue)
                statBox(value: stats.linesPracticed, label: Text("연습한 문장"), icon: "text.bubble.fill", color: Brand.deep)
            }
        }
        .padding(.vertical, 8)
    }

    private func statBox(value: Int, label: Text, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .scaledFont(size: 16)
                .foregroundColor(color)
            Text("\(value)")
                .scaledFont(size: 22, weight: .bold, design: .rounded)
                .foregroundColor(.primary)
            label
                .scaledFont(size: 11, weight: .medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Row

    private func row(_ rec: PracticeRecord) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Brand.blue.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: rec.mode.icon)
                    .font(.system(size: 15))
                    .foregroundColor(Brand.blue)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(rec.title.isEmpty ? rec.mode.label : rec.title)
                    .scaledFont(size: 15, weight: .semibold)
                    .singleLine()
                HStack(spacing: 4) {
                    Text(rec.mode.label)
                    if !rec.titleMeaning.isEmpty {
                        Text("·")
                        Text(rec.titleMeaning).singleLine()
                    }
                }
                .scaledFont(size: 12)
                .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                if let score = rec.score {
                    Text("\(score)점")
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(scoreColor(score))
                }
                Text("\(rec.lines)문장 · \(rec.date.formatted(date: .omitted, time: .shortened))")
                    .scaledFont(size: 11)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(Brand.blue.opacity(0.6))
            Text("아직 연습 기록이 없어요")
                .scaledFont(size: 16, weight: .semibold)
            Text("대화나 발음 연습을 마치면 여기에 쌓여요.")
                .scaledFont(size: 13)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helpers

    private func dayTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return String(localized: "오늘") }
        if cal.isDateInYesterday(day) { return String(localized: "어제") }
        return day.formatted(.dateTime.month().day().weekday(.abbreviated))
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
}
