import SwiftUI

// MARK: - 요일 이름

extension JourneyData {
    /// 화면 언어의 온전한 요일 이름 (월요일 / Monday …). weekday 는 Calendar 기준 1 = 일요일
    static func weekdayName(_ weekday: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: AppLanguage.native.rawValue)
        return f.standaloneWeekdaySymbols[weekday - 1]
    }
}

// MARK: - Practice Launcher (연습 화면 띄우기 + 완료 기록)

/// 코스 어디서든(홈 배너 / 타임라인 / 주간 시간표) 같은 방식으로 연습을 시작하고,
/// 돌아왔을 때 완료 여부를 기록하기 위한 공용 런처.
@MainActor
final class JourneyLauncher: ObservableObject {
    @Published var showPractice = false
    @Published var showVoicePractice = false
    private(set) var session: PracticeSession?
    private(set) var stopID: String?

    func start(_ stop: JourneyStop, voice: Bool = false) {
        stopID = stop.id
        session = PracticeSession(scenario: stop.scenario)
        if voice { showVoicePractice = true } else { showPractice = true }
    }

    /// 대화를 끝까지 마쳤을 때만 완료로 기록한다.
    func record(into progress: JourneyProgressStore) {
        guard let session, let stopID else { return }
        guard session.isFinished, session.totalChoices > 0 else { return }
        progress.complete(stopID, score: session.score)
    }
}

private struct JourneyPracticeModifier: ViewModifier {
    @ObservedObject var launcher: JourneyLauncher
    let progress: JourneyProgressStore

    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: $launcher.showPractice) {
                if let session = launcher.session {
                    PracticeView(session: session).id(launcher.stopID ?? "")
                }
            }
            .navigationDestination(isPresented: $launcher.showVoicePractice) {
                if let session = launcher.session {
                    VoicePracticeView(session: session).id(launcher.stopID ?? "")
                }
            }
            .onChange(of: launcher.showPractice) { _, shown in
                if !shown { launcher.record(into: progress) }
            }
            .onChange(of: launcher.showVoicePractice) { _, shown in
                if !shown { launcher.record(into: progress) }
            }
    }
}

extension View {
    func journeyPractice(_ launcher: JourneyLauncher, progress: JourneyProgressStore) -> some View {
        modifier(JourneyPracticeModifier(launcher: launcher, progress: progress))
    }
}

// MARK: - Course Card (홈 화면)

struct JourneyCourseCard: View {
    let course: JourneyCourse
    @EnvironmentObject var progress: JourneyProgressStore
    let onTap: () -> Void

    private var doneCount: Int { progress.doneCount(in: course) }
    private var ratio: Double { progress.progress(in: course) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 54, height: 54)
                        Text(course.emoji).font(.system(size: 28))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(course.titleKo)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(course.dayLabelKo)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Label(course.timeRange, systemImage: "clock")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("·").foregroundColor(.secondary)
                            Text("\(course.stopCount)개 장면")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                Text(course.description)
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // ── 타임테이블 미리보기 (배운 칸은 초록)
                HStack(spacing: 0) {
                    ForEach(Array(course.stops.enumerated()), id: \.element.id) { idx, stop in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(progress.isDone(stop.id)
                                          ? Color.green.opacity(0.18)
                                          : Color(.tertiarySystemFill))
                                    .frame(width: 28, height: 28)
                                if progress.isDone(stop.id) {
                                    Circle()
                                        .strokeBorder(Color.green.opacity(0.45), lineWidth: 1.5)
                                        .frame(width: 28, height: 28)
                                }
                                Text(stop.emoji).font(.system(size: 13))
                            }
                            Text(stop.time)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(progress.isDone(stop.id) ? .green : .secondary)
                        }
                        if idx < course.stops.count - 1 {
                            Rectangle()
                                .fill(Color(.quaternaryLabel))
                                .frame(height: 1)
                                .padding(.bottom, 12)
                        }
                    }
                }

                // ── 진행률
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.quaternarySystemFill))
                            Capsule()
                                .fill(doneCount == course.stopCount ? Color.green : Color.accentColor)
                                .frame(width: max(0, geo.size.width * ratio))
                        }
                    }
                    .frame(height: 5)

                    Text("\(doneCount)/\(course.stopCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(doneCount == course.stopCount ? .green : .secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Journey Detail (타임테이블)

struct JourneyDetailView: View {
    let course: JourneyCourse
    @EnvironmentObject var progress: JourneyProgressStore

    @StateObject private var launcher = JourneyLauncher()
    @State private var order: StopOrder = .time

    enum StopOrder: String, CaseIterable, Identifiable {
        case time = "시간 순"
        case todo = "안 배운 것"
        var id: String { rawValue }

        var label: String {
            switch self {
            case .time: return String(localized: "시간 순")
            case .todo: return String(localized: "안 배운 것")
            }
        }
    }

    private var doneCount: Int { progress.doneCount(in: course) }

    private var displayedStops: [JourneyStop] {
        switch order {
        case .time:
            return course.stops
        case .todo:
            return course.stops.filter { !progress.isDone($0.id) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                orderPicker
                timeline
                whyCard
            }
            .padding(.bottom, 90)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(course.titleKo)
        .navigationBarTitleDisplayMode(.inline)
        .journeyPractice(launcher, progress: progress)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(course.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 3) {
                    Text(course.titleKo)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(course.dayLabelKo)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
            }

            Text(course.description)
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                chip(icon: "clock", text: course.timeRange)
                chip(icon: "list.bullet", text: String(localized: "\(course.stopCount)개 장면"))
                chip(icon: "checkmark.circle", text: String(localized: "\(doneCount)개 배움"))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.42, blue: 0.85),
                         Color(red: 0.42, green: 0.28, blue: 0.78)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(text).font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.2)))
    }

    // MARK: 보기 방식

    private var orderPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("보기", selection: $order) {
                ForEach(StopOrder.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Text(orderHint)
                .font(.system(size: 10.5))
                .foregroundColor(Color(.tertiaryLabel))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var orderHint: String {
        switch order {
        case .time: return String(localized: "하루가 흘러가는 순서예요. 어디서 시작해도 됩니다.")
        case .todo:
            let left = course.stops.count - doneCount
            return left == 0 ? String(localized: "이 코스는 다 배웠어요. 다른 코스도 골라 보세요.")
                             : String(localized: "아직 안 배운 \(left)개만 보여주고 있어요.")
        }
    }

    // MARK: Timeline

    private var timeline: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.day.timeline.left")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                (order == .time ? Text("하루 타임테이블") : Text("골라서 연습하기"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 12)

            if displayedStops.isEmpty {
                emptyTodo
            }

            ForEach(Array(displayedStops.enumerated()), id: \.element.id) { idx, stop in
                stopRow(stop, isLast: idx == displayedStops.count - 1)
                if order == .time, let transit = stop.transitNote {
                    transitRow(transit)
                }
            }

        }
    }

    private var emptyTodo: some View {
        VStack(spacing: 8) {
            Text("🎉").font(.system(size: 34))
            Text("이 코스의 \(course.stopCount)개 장면을 모두 배웠어요")
                .font(.system(size: 14, weight: .bold))
            Text("다른 코스에서 아직 안 배운 장면을 골라 보세요.")
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }




    private func stopRow(_ stop: JourneyStop, isLast: Bool) -> some View {
        let done = progress.isDone(stop.id)
        return HStack(alignment: .top, spacing: 10) {
            Text(stop.time)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(done ? .green : .primary)
                .frame(width: 42, alignment: .trailing)
                .padding(.top, 14)

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(done ? Color.green.opacity(0.18) : Color(.secondarySystemGroupedBackground))
                        .frame(width: 34, height: 34)
                    Circle()
                        .strokeBorder(done ? Color.green.opacity(0.5) : Color(.quaternaryLabel), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text(stop.emoji).font(.system(size: 15))
                    }
                }
                .padding(.top, 8)

                if !isLast {
                    Rectangle()
                        .fill(Color(.quaternaryLabel))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 34)

            stopCard(stop, done: done)
                .padding(.trailing, 18)
                .padding(.bottom, 10)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func stopCard(_ stop: JourneyStop, done: Bool) -> some View {
        HStack(spacing: 0) {
            Button {
                launcher.start(stop)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(stop.placeKo)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        if let score = progress.score(for: stop.id) {
                            Text("\(score)점")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(4)
                        }
                        Spacer(minLength: 0)
                    }
                    Text(stop.place)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(stop.situation)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(.tertiaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().frame(height: 44)

            Button {
                launcher.start(stop, voice: true)
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.blue)
                    .frame(width: 46)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("음성으로 연습"))
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(done ? Color.green.opacity(0.35) : Color.clear, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        )
    }

    private func transitRow(_ note: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Spacer().frame(width: 42)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(.quaternaryLabel))
                    .frame(width: 1.5, height: 26)
            }
            .frame(width: 34)

            Text(note)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(.tertiarySystemFill)))
            Spacer(minLength: 0)
        }
        .padding(.bottom, 10)
    }

    // MARK: 왜 순서대로 안 해도 되는가

    private var whyCard: some View {
        JourneyWhyCard()
            .padding(.horizontal, 18)
            .padding(.top, 18)
    }
}

// MARK: - 설득 카드 (순서 없이 배워도 되는 이유)

struct JourneyWhyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "shuffle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text("앞에서부터 안 해도 됩니다")
                    .font(.system(size: 13, weight: .bold))
            }

            reason("실제 하루도 순서대로 오지 않아요.",
                   "오늘은 식당만 가고, 내일은 이발소만 갑니다. 공항 장면을 몰라도 저녁 식당에서 아무 문제 없어요.")
            reason("장면 하나하나가 독립된 대화예요.",
                   "앞 장면에서 배운 표현을 알아야 풀리는 구조가 아닙니다. 어디를 열어도 첫 마디부터 시작해요.")
            reason("끌리는 장면부터 하면 오래 남아요.",
                   "곧 가 볼 곳, 궁금한 상황부터 고르세요. 관심 있는 대화일수록 잘 안 잊힙니다.")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func reason(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(verbatim: "· ") + Text(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            Text(body)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)
        }
    }
}
