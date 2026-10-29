import AppIntents
import SwiftUI

/// 퇴근길 모드 화면. 출발 전에 고르고 누르면, 그다음은 소리와 운전대 버튼으로 진행된다.
struct DriveModeView: View {
    @ObservedObject private var session = DriveSession.shared
    @ObservedObject private var pro = MalmunPro.shared
    @AppStorage(DriveSettings.sourceKey) private var sourceRaw = DriveSource.mix.rawValue
    @AppStorage(DriveSettings.rateKey) private var rate = 0.9
    @AppStorage(DriveSettings.gapKey) private var gap = 1.0
    @AppStorage(DriveSettings.repeatKey) private var repeatTwice = true
    @AppStorage(DriveSettings.voiceKey) private var voiceOn = true
    @AppStorage(DriveSettings.guideSeenKey) private var guideSeen = false
    @State private var showGuide = false
    @State private var voiceDenied = false
    /// 소스별 장면 수 (화면이 뜰 때 한 번 센다 — 그릴 때마다 세면 무겁다)
    @State private var counts: [DriveSource: Int] = [:]

    private var source: DriveSource { DriveSource(rawValue: sourceRaw) ?? .mix }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                nowPlayingCard
                controls
                if let left = pro.driveScenesLeft {
                    freeLimitRow(left: left)
                }
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
        .onAppear {
            // 처음 열면 차에서 쓰는 법(자동 시작·목소리 조작)을 한 번 보여 준다.
            if !guideSeen {
                guideSeen = true
                showGuide = true
            }
            counts = Dictionary(uniqueKeysWithValues: DriveSource.allCases.map { ($0, DriveContent.lessons(for: $0).count) })
        }
    }

    // MARK: Now playing

    private var nowPlayingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(AppLanguage.learning.flag)
                Text(session.lesson?.title ?? String(localized: "출발 전에 눌러 두세요"))
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(.white.opacity(0.85))
                    .singleLine()
                Spacer()
                if session.isActive {
                    Text("\(session.lessonPosition.index)/\(session.lessonPosition.count)")
                        .scaledFont(size: 12, weight: .semibold).monospacedDigit()
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            phaseBadge

            VStack(alignment: .leading, spacing: 8) {
                Text(primaryText)
                    .scaledFont(size: 26, weight: .bold, design: .rounded)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: primaryText)
                if !secondaryText.isEmpty {
                    Text(secondaryText)
                        .scaledFont(size: 16)
                        .foregroundColor(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .accessibilityElement(children: .combine)

            if session.phase == .yourTurn, session.voiceActive {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative)
                    Text(session.heardText.isEmpty ? String(localized: "듣고 있어요…") : session.heardText)
                        .lineLimit(2)
                }
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(Brand.glow)
            } else if let result = session.lastResult {
                resultBadge(result)
            }

            if session.isActive {
                HStack(spacing: 12) {
                    Label {
                        Text("오늘 \(session.linesDone)문장")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    if session.voiceActive {
                        Label {
                            Text("맞힌 문장 \(session.correctCount)")
                        } icon: {
                            Image(systemName: "star.fill")
                        }
                        Label {
                            Text("목소리 조작 켜짐")
                        } icon: {
                            Image(systemName: "mic.fill")
                        }
                    }
                }
                .scaledFont(size: 12, weight: .medium)
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
        case .yourTurn: return ""
        case .listening where line.role == .speak: return ""
        default: return line.meaning
        }
    }

    @ViewBuilder
    private func resultBadge(_ result: DriveSession.AttemptResult) -> some View {
        let (label, icon, color): (LocalizedStringKey, String, Color) = {
            switch result {
            case .good: return ("좋아요!", "hand.thumbsup.fill", .green)
            case .close: return ("거의 맞았어요", "checkmark.circle", Brand.glow)
            case .missed: return ("정답을 듣고 따라 해 보세요", "ear", .white.opacity(0.8))
            }
        }()
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label)
            if !session.heardText.isEmpty, result != .good {
                Text("· \(session.heardText)").lineLimit(1).opacity(0.7)
            }
        }
        .scaledFont(size: 13, weight: .semibold)
        .foregroundColor(color)
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
        .scaledFont(size: 12, weight: .bold)
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
                if session.isActive { session.toggle() } else { Task { await startWithPermission() } }
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

    /// 무료 사용자: 오늘 남은 장면 수 + Pro 안내
    private func freeLimitRow(left: Int) -> some View {
        Button { pro.showPaywall(.commute) } label: {
            HStack(spacing: 10) {
                Image(systemName: left == 0 ? "lock.fill" : "gift.fill")
                    .foregroundColor(Brand.glow)
                VStack(alignment: .leading, spacing: 2) {
                    (left == 0 ? Text("오늘 무료 장면을 다 들었어요") : Text("오늘 무료 장면 \(left)개 남음"))
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(.primary)
                    Text("말문 Pro는 하루 제한 없이 들을 수 있어요")
                        .scaledFont(size: 12)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Pro")
                    .scaledFont(size: 12, weight: .heavy)
                    .foregroundColor(Brand.deep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Brand.glow))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }

    /// 목소리 조작이 켜져 있으면 처음 한 번 마이크·음성 인식 허락을 받고 시작한다.
    private func startWithPermission() async {
        if voiceOn, DriveVoiceListener.needsPermission {
            let ok = await DriveVoiceListener.requestPermission()
            if !ok { voiceDenied = true }
        }
        session.start(source)
    }

    private func controlButton(icon: String, label: LocalizedStringKey, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                Text(label).scaledFont(size: 11, weight: .medium)
            }
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Setup

    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("무엇을 들을까요?").accessibilityAddTraits(.isHeader)
                .scaledFont(size: 13, weight: .bold)
                .foregroundColor(.secondary)
            VStack(spacing: 0) {
                ForEach(DriveSource.allCases) { src in
                    let count = counts[src] ?? 0
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
                                .scaledFont(size: 12)
                                .foregroundColor(.secondary)
                            if source == src {
                                Image(systemName: "checkmark").foregroundColor(Brand.blue)
                            }
                        }
                        .scaledFont(size: 15)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(source == src ? .isSelected : [])
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
            Text("듣기 설정").accessibilityAddTraits(.isHeader)
                .scaledFont(size: 13, weight: .bold)
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
                        .accessibilityLabel(Text("말 빠르기"))
                        .accessibilityValue(rate < 0.8 ? Text("천천히") : rate > 1.0 ? Text("빠르게") : Text("보통"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("말해 볼 시간")
                        Spacer()
                        (gap < 0.9 ? Text("짧게") : gap > 1.3 ? Text("넉넉히") : Text("보통"))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $gap, in: 0.6...2.0, step: 0.1)
                        .accessibilityLabel(Text("말해 볼 시간"))
                        .accessibilityValue(gap < 0.9 ? Text("짧게") : gap > 1.3 ? Text("넉넉히") : Text("보통"))
                }
                Toggle("정답을 한 번 더 듣기", isOn: $repeatTwice)
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("목소리로 조작", isOn: $voiceOn)
                        .onChange(of: voiceOn) { _, on in
                            guard on, DriveVoiceListener.needsPermission else { return }
                            Task { voiceDenied = !(await DriveVoiceListener.requestPermission()) }
                        }
                    Text("말해 볼 차례에만 폰 마이크로 들어요. 맞게 말하면 알려 주고, \"다음\" \"다시\" \"천천히\" \"그만\" 을 알아들어요. 들은 말은 기기 밖으로 보내지 않아요.")
                        .scaledFont(size: 12)
                        .foregroundColor(.secondary)
                    if voiceOn, voiceDenied || (!DriveVoiceListener.isAuthorized && !DriveVoiceListener.needsPermission) {
                        Button("마이크·음성 인식 허락하러 가기") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .scaledFont(size: 12, weight: .semibold)
                    }
                }
            }
            .scaledFont(size: 15)
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
                    Text("차에서 쓰는 법")
                        .scaledFont(size: 15, weight: .semibold)
                        .foregroundColor(.primary)
                    Text("연결하면 저절로 시작 · 목소리 조작 · Siri")
                        .scaledFont(size: 12)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Guide

/// 차에서 쓰는 법. 퇴근길 모드를 처음 열 때 한 번 저절로 뜬다.
struct DriveGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var commandExamples: [(DriveCommand, LocalizedStringKey)] {
        [(.next, "다음 문장"), (.again, "같은 문장 한 번 더"), (.slower, "말을 느리게"),
         (.faster, "말을 빠르게"), (.nextScene, "다음 장면으로"), (.stop, "멈추기")]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("손대지 않고, 목소리로").accessibilityAddTraits(.isHeader)
                        .scaledFont(size: 24, weight: .bold)
                    Text("한 번만 설정해 두면 차에 타서 폰을 연결하는 것만으로 시작되고, 그다음은 말로 조작해요.")
                        .scaledFont(size: 14)
                        .foregroundColor(.secondary)

                    step(1, icon: "cable.connector", title: "폰을 차에 연결",
                         detail: "블루투스나 CarPlay로 연결하면 소리가 차 스피커로 나와요. 차 화면의 '지금 재생'에 지금 문장이 보여요.")

                    step(2, icon: "bolt.car.fill", title: "연결하면 저절로 시작 (한 번만 설정)",
                         detail: "단축어 앱 ▸ 자동화 ▸ + ▸ 'CarPlay' (또는 '블루투스' ▸ 내 차) ▸ '연결될 때' ▸ '즉시 실행' ▸ 동작에서 '말문 · 퇴근길 연습 시작' 을 고르세요.") {
                        Button {
                            if let url = URL(string: "shortcuts://") { openURL(url) }
                        } label: {
                            Label("단축어 앱 열기", systemImage: "arrow.up.forward.app")
                                .scaledFont(size: 14, weight: .semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.solidBlue)
                    }

                    step(3, icon: "waveform", title: "말해 볼 차례에 말로 조작",
                         detail: "딩 소리가 나면 문장을 말해 보세요. 맞으면 \"좋아요\" 라고 알려 줘요. 그때 이렇게 말해도 돼요.") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(commandExamples, id: \.0) { cmd, meaning in
                                HStack(spacing: 8) {
                                    Text("\"\(cmd.words(AppLanguage.native).first ?? "")\"")
                                        .scaledFont(size: 14, weight: .bold)
                                    Text(meaning)
                                        .scaledFont(size: 13)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    step(4, icon: "mic.circle.fill", title: "언제든 Siri 로",
                         detail: "멈춰 있거나 다른 소리가 날 때는 Siri 에게 말하세요. \"말문 계속\" \"말문 다음\" \"말문 다시\" \"말문 연습 멈춰\"") {
                        SiriTipView(intent: StartDriveIntent())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("운전 중에는 화면을 만지지 마세요. 운전대의 다음·이전·재생 버튼도 쓸 수 있어요.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Label("내비게이션 안내가 나오면 잠깐 멈췄다가 이어서 들려줘요.", systemImage: "location.fill")
                            .foregroundColor(.secondary)
                    }
                    .scaledFont(size: 13)
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("차에서 쓰는 법")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
        }
    }

    private func step<Extra: View>(_ n: Int, icon: String, title: LocalizedStringKey, detail: LocalizedStringKey,
                                   @ViewBuilder extra: () -> Extra = { EmptyView() }) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(Brand.solidBlue).frame(width: 32, height: 32)
                Text("\(n)").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundColor(Brand.blue)
                    Text(title).scaledFont(size: 16, weight: .bold)
                }
                Text(detail)
                    .scaledFont(size: 13)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                extra()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
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
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(.primary)
                    Text(session.isPlaying ? (session.lesson?.title ?? "") : String(localized: "차에 연결하고 귀로만 연습해요"))
                        .scaledFont(size: 12)
                        .foregroundColor(.secondary)
                        .singleLine()
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .scaledFont(size: 12, weight: .medium)
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
