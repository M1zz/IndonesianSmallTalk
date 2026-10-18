import SwiftUI

/// 퇴근길 모드 화면. 출발 전에 고르고 누르면, 그다음은 소리와 운전대 버튼으로 진행된다.
struct DriveModeView: View {
    @ObservedObject private var session = DriveSession.shared
    @AppStorage(DriveSettings.sourceKey) private var sourceRaw = DriveSource.mix.rawValue
    @AppStorage(DriveSettings.rateKey) private var rate = 0.9
    @AppStorage(DriveSettings.gapKey) private var gap = 1.0
    @AppStorage(DriveSettings.repeatKey) private var repeatTwice = true
    @State private var showGuide = false

    private var source: DriveSource { DriveSource(rawValue: sourceRaw) ?? .mix }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                nowPlayingCard
                controls
                if !session.isActive || !session.isPlaying {
                    sourcePicker
                    settingsCard
                }
                guideCard
                Color.clear.frame(height: 80)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("퇴근길 모드")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showGuide) { DriveGuideSheet() }
    }

    // MARK: Now playing

    private var nowPlayingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(AppLanguage.learning.flag)
                Text(session.lesson?.title ?? String(localized: "출발 전에 눌러 두세요"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                Spacer()
                if session.isActive {
                    Text("\(session.lessonPosition.index)/\(session.lessonPosition.count)")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            phaseBadge

            VStack(alignment: .leading, spacing: 8) {
                Text(primaryText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: primaryText)
                if !secondaryText.isEmpty {
                    Text(secondaryText)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .accessibilityElement(children: .combine)

            if session.isActive {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("오늘 \(session.linesDone)문장")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Brand.glow)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Brand.deep, Color.black.opacity(0.92)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private var primaryText: String {
        guard let line = session.line else {
            return session.isActive ? (session.lesson?.title ?? "") : String(localized: "뜻을 듣고, 먼저 말해 보고, 정답을 들어요")
        }
        switch session.phase {
        case .yourTurn: return line.meaning
        case .listening where line.role == .speak: return line.meaning
        default: return line.text
        }
    }

    private var secondaryText: String {
        guard let line = session.line else { return "" }
        switch session.phase {
        case .yourTurn, .listening where line.role == .speak: return ""
        default: return line.meaning
        }
    }

    @ViewBuilder
    private var phaseBadge: some View {
        let (label, icon, color): (LocalizedStringKey, String, Color) = {
            switch session.phase {
            case .yourTurn: return ("말해 보세요", "mic.fill", Brand.glow)
            case .answer: return ("정답", "checkmark.bubble.fill", .green)
            case .listening: return session.line?.role == .speak ? ("어떻게 말할까요?", "questionmark.bubble.fill", .white) : ("상대방", "person.wave.2.fill", .white)
            case .intro: return ("다음 장면", "sparkles", .white)
            case .idle, .finished: return ("준비", "car.fill", .white)
            }
        }()
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.16)))
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 18) {
            controlButton(icon: "gobackward", label: "한 번 더", size: 64) { session.previous() }
                .disabled(!session.isActive)
            Button {
                if session.isActive { session.toggle() } else { session.start(source) }
            } label: {
                Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(Brand.gradient))
                    .shadow(color: Brand.blue.opacity(0.4), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(session.isPlaying ? Text("일시정지") : Text("재생"))
            controlButton(icon: "forward.end.fill", label: "다음 문장", size: 64) { session.next() }
                .disabled(!session.isActive)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomTrailing) {
            if session.isActive {
                Button { session.stop() } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("끝내기"))
            }
        }
    }

    private func controlButton(icon: String, label: LocalizedStringKey, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Setup

    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("무엇을 들을까요?")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            VStack(spacing: 0) {
                ForEach(DriveSource.allCases) { src in
                    let count = DriveContent.lessons(for: src).count
                    Button {
                        sourceRaw = src.rawValue
                        if session.isActive { session.start(src) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: src.icon)
                                .frame(width: 26)
                                .foregroundColor(Brand.blue)
                            Text(src.title).foregroundColor(.primary)
                            Spacer()
                            Text(count == 0 ? String(localized: "아직 없음") : String(localized: "장면 \(count)개"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            if source == src {
                                Image(systemName: "checkmark").foregroundColor(Brand.blue)
                            }
                        }
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(count == 0)
                    .opacity(count == 0 ? 0.45 : 1)
                    if src != DriveSource.allCases.last { Divider().padding(.leading, 52) }
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("듣기 설정")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("말 빠르기")
                        Spacer()
                        (rate < 0.8 ? Text("천천히") : rate > 1.0 ? Text("빠르게") : Text("보통"))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $rate, in: 0.6...1.2, step: 0.05)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("말해 볼 시간")
                        Spacer()
                        (gap < 0.9 ? Text("짧게") : gap > 1.3 ? Text("넉넉히") : Text("보통"))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $gap, in: 0.6...2.0, step: 0.1)
                }
                Toggle("정답을 한 번 더 듣기", isOn: $repeatTwice)
            }
            .font(.system(size: 15))
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private var guideCard: some View {
        Button { showGuide = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Brand.glow)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Brand.glow.opacity(0.15)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("차에 타면 저절로 시작하게")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("CarPlay·블루투스 연결 · Siri · 단축어 자동화")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Guide

struct DriveGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    guideRow(icon: "cable.connector", title: "폰을 차에 연결",
                             detail: "CarPlay나 블루투스로 연결하고, 출발 전에 퇴근길 모드에서 재생을 눌러 두세요. 차 화면의 '지금 재생'에 지금 문장이 보여요.")
                    guideRow(icon: "steeringwheel", title: "운전대 버튼으로",
                             detail: "다음 곡 버튼은 다음 문장, 이전 곡 버튼은 같은 문장 한 번 더, 재생 버튼은 잠깐 멈춤이에요.")
                } header: { Text("기본") }

                Section {
                    guideRow(icon: "mic.circle.fill", title: "Siri에게 말하기",
                             detail: "\"말문 퇴근길 연습 시작\" 이라고 말하면 앱을 열지 않고 바로 시작해요. \"말문 연습 멈춰\" 로 멈춰요.")
                    guideRow(icon: "bolt.car.fill", title: "타자마자 자동으로",
                             detail: "단축어 앱 ▸ 자동화 ▸ + ▸ 'CarPlay' (또는 '블루투스'에서 내 차) ▸ '연결될 때' ▸ 즉시 실행 ▸ 동작에서 '말문 · 퇴근길 연습 시작' 을 고르세요.")
                } header: { Text("손 안 대고") }

                Section {
                    Label("운전 중에는 화면을 만지지 마세요. 모든 조작은 소리와 운전대 버튼으로 할 수 있어요.", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Label("내비게이션 안내가 나오면 잠깐 멈췄다가 이어서 들려줘요.", systemImage: "location.fill")
                        .font(.system(size: 13))
                }
            }
            .navigationTitle("차에서 쓰는 법")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
        }
    }

    private func guideRow(icon: String, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Brand.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(detail).font(.system(size: 13)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Home entry

/// 홈 맨 위에 두는 퇴근길 모드 바로가기
struct DriveEntryCard: View {
    @ObservedObject private var session = DriveSession.shared

    var body: some View {
        NavigationLink {
            DriveModeView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: session.isPlaying ? "waveform" : "car.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .symbolEffect(.variableColor.iterative, isActive: session.isPlaying)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.glow))
                VStack(alignment: .leading, spacing: 3) {
                    (session.isPlaying ? Text("퇴근길 모드 듣는 중") : Text("퇴근길 모드"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(session.isPlaying ? (session.lesson?.title ?? "") : String(localized: "차에 연결하고 귀로만 연습해요"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}
