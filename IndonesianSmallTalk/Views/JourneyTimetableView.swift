import SwiftUI

// MARK: - 주간 시간표 (배운 것 / 안 배운 것 한눈에)

struct JourneyTimetableView: View {
    @EnvironmentObject var progress: JourneyProgressStore

    @StateObject private var launcher = JourneyLauncher()
    @State private var now = Date()
    @State private var selectedCell: TimetableCell?
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var todayWeekday: Int { Calendar.current.component(.weekday, from: now) }
    private var nowSlot: TimeSlot { TimeSlot.now(now) }

    private var doneTotal: Int { progress.doneCount(in: JourneyData.allCourses) }
    private var total: Int { progress.totalCount(in: JourneyData.allCourses) }

    /// 시트로 띄울 셀 (요일 × 시간대)
    struct TimetableCell: Identifiable {
        let id: String
        let titleKo: String
        let items: [(course: JourneyCourse, stop: JourneyStop)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                summary
                grid
                anyDayStrip
                JourneyWhyCard()
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
            }
            .padding(.bottom, 90)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("주간 시간표")
        .navigationBarTitleDisplayMode(.inline)
        .journeyPractice(launcher, progress: progress)
        .onReceive(ticker) { now = $0 }
        .sheet(item: $selectedCell) { cell in
            cellSheet(cell)
                .presentationDetents([.height(280), .medium])
        }
    }

    // MARK: 요약

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(doneTotal)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.green)
                Text("/ \(total)개 장면을 배웠어요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.quaternarySystemFill))
                    Capsule()
                        .fill(Color.green)
                        .frame(width: total == 0 ? 0 : geo.size.width * Double(doneTotal) / Double(total))
                }
            }
            .frame(height: 6)

            Text("초록 = 배운 장면, 회색 = 아직. \(JourneyData.weekdayName(todayWeekday)) \(nowSlot.labelKo) 칸이 지금이에요.")
                .font(.system(size: 11))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: 그리드

    private var grid: some View {
        VStack(spacing: 0) {
            sectionHeader("calendar", "요일 × 시간대")

            VStack(spacing: 4) {
                // 요일 헤더
                HStack(spacing: 4) {
                    Text("")
                        .frame(width: 34)
                    ForEach(JourneyData.weekdayOrder, id: \.self) { wd in
                        Text(JourneyData.weekdayLabel(wd))
                            .font(.system(size: 11, weight: wd == todayWeekday ? .heavy : .medium))
                            .foregroundColor(wd == todayWeekday ? .accentColor : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(TimeSlot.allCases) { slot in
                    HStack(spacing: 4) {
                        VStack(spacing: 0) {
                            Text(slot.labelKo)
                                .font(.system(size: 10, weight: slot == nowSlot ? .heavy : .semibold))
                                .foregroundColor(slot == nowSlot ? .accentColor : .primary)
                            Text(slot.rangeLabel)
                                .font(.system(size: 7.5))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 34)

                        ForEach(JourneyData.weekdayOrder, id: \.self) { wd in
                            cellView(weekday: wd, slot: slot)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 18)
        }
    }

    private func cellView(weekday: Int, slot: TimeSlot) -> some View {
        let items = JourneyData.stops(weekday: weekday, slot: slot)
        let doneAll = !items.isEmpty && items.allSatisfy { progress.isDone($0.stop.id) }
        let isNow = weekday == todayWeekday && slot == nowSlot

        return Button {
            guard !items.isEmpty else { return }
            selectedCell = TimetableCell(
                id: "\(weekday)-\(slot.rawValue)",
                titleKo: String(localized: "\(JourneyData.weekdayName(weekday)) \(slot.labelKo) (\(slot.rangeLabel))"),
                items: items
            )
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(items.isEmpty
                          ? Color(.systemGroupedBackground)
                          : (doneAll ? Color.green.opacity(0.20) : Color(.tertiarySystemFill)))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isNow ? Color.red : (doneAll ? Color.green.opacity(0.45) : Color.clear),
                                  lineWidth: 1.5)

                if items.isEmpty {
                    // 지금 시간대인데 정규 일정이 없는 칸 — 아래 '요일이 없는 코스'로 유도
                    (isNow ? Text("지금") : Text(verbatim: "–"))
                        .font(.system(size: isNow ? 9 : 10, weight: isNow ? .heavy : .regular))
                        .foregroundColor(isNow ? .red : Color(.quaternaryLabel))
                } else {
                    VStack(spacing: 2) {
                        HStack(spacing: 1) {
                            ForEach(items.prefix(2), id: \.stop.id) { item in
                                Text(item.stop.emoji)
                                    .font(.system(size: items.count > 1 ? 11 : 14))
                                    .opacity(progress.isDone(item.stop.id) ? 1 : 0.55)
                            }
                        }
                        HStack(spacing: 2) {
                            ForEach(items.prefix(3), id: \.stop.id) { item in
                                Circle()
                                    .fill(progress.isDone(item.stop.id) ? Color.green : Color(.quaternaryLabel))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(items.isEmpty)
        .accessibilityLabel(Text(verbatim: "\(JourneyData.weekdayName(weekday)) \(slot.labelKo)"))
    }

    // MARK: 요일이 없는 코스

    private var anyDayStrip: some View {
        VStack(spacing: 0) {
            sectionHeader("airplane", "요일이 없는 코스")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(JourneyData.anyDayCourses) { course in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(course.emoji).font(.system(size: 16))
                            Text(course.titleKo)
                                .font(.system(size: 13, weight: .bold))
                            Text(course.dayLabelKo)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(progress.doneCount(in: course))/\(course.stopCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 6) {
                            ForEach(course.stops) { stop in
                                Button {
                                    launcher.start(stop)
                                } label: {
                                    VStack(spacing: 3) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(progress.isDone(stop.id)
                                                      ? Color.green.opacity(0.18)
                                                      : Color(.tertiarySystemFill))
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .strokeBorder(stop.slot == nowSlot ? Color.red : Color.clear, lineWidth: 1.5)
                                            Text(stop.emoji)
                                                .font(.system(size: 15))
                                                .opacity(progress.isDone(stop.id) ? 1 : 0.45)
                                        }
                                        .frame(height: 42)
                                        Text(stop.time)
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundColor(progress.isDone(stop.id) ? .green : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(verbatim: "\(stop.time) \(stop.placeKo)"))
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 18)
        }
    }

    private func sectionHeader(_ icon: String, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: 셀 시트

    private func cellSheet(_ cell: TimetableCell) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(cell.items, id: \.stop.id) { item in
                        HStack(spacing: 12) {
                            Text(item.stop.emoji).font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.stop.placeKo)
                                    .font(.system(size: 14, weight: .bold))
                                Text("\(item.course.emoji) \(item.course.titleKo) · \(item.stop.time)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(item.stop.situation)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            VStack(spacing: 6) {
                                if progress.isDone(item.stop.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                }
                                Button {
                                    let stop = item.stop
                                    selectedCell = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        launcher.start(stop)
                                    }
                                } label: {
                                    (progress.isDone(item.stop.id) ? Text("다시") : Text("연습"))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.accentColor))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(cell.titleKo)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
