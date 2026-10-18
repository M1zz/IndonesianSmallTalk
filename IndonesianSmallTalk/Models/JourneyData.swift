import Foundation

// MARK: - Builder Helpers

private func t(_ label: String, _ tip: String, _ why: String) -> CoachTip {
    CoachTip(label: label, tip: tip, why: why)
}

private func me(
    _ id: String, _ idn: String, _ ko: String, _ rom: String,
    _ pol: Polarity = .neutral, _ coach: CoachTip? = nil,
    _ kids: [ConversationNode] = []
) -> ConversationNode {
    ConversationNode(id: id, speaker: .me, indonesian: idn, korean: ko,
                     romanization: rom, polarity: pol, coachTip: coach, children: kids)
}

private func other(
    _ id: String, _ idn: String, _ ko: String, _ rom: String,
    _ pol: Polarity = .neutral, _ coach: CoachTip? = nil,
    _ kids: [ConversationNode] = []
) -> ConversationNode {
    ConversationNode(id: id, speaker: .other, indonesian: idn, korean: ko,
                     romanization: rom, polarity: pol, coachTip: coach, children: kids)
}

/// 시나리오 UUID를 고정한다. (사용자가 추가한 답변이 앱을 껐다 켜도 붙어 있도록)
private func stopUUID(_ seed: Int) -> UUID {
    UUID(uuidString: String(format: "5C0A0000-0000-4000-8000-%012d", seed)) ?? UUID()
}

/// 타임테이블 한 칸. 장소/상황이 곧 시나리오의 제목과 설명이 된다.
private func stop(
    id: String, seed: Int, time: String, emoji: String,
    place: String, placeKo: String, situation: String,
    transit: String? = nil,
    difficulty: ConversationScenario.Difficulty = .beginner,
    root: ConversationNode
) -> JourneyStop {
    JourneyStop(
        id: id, time: time, emoji: emoji, place: place, placeKo: placeKo,
        situation: situation, transitNote: transit,
        scenario: ConversationScenario(
            id: stopUUID(seed),
            title: place, titleKo: placeKo, description: situation,
            emoji: emoji, root: root, difficulty: difficulty
        )
    )
}

// MARK: - All Courses

struct JourneyData {
    static let allCourses: [JourneyCourse] = [tripDay, firstWorkDay, weekendDay]

    /// 주간 시간표에 들어가는 코스 (요일이 정해진 것)
    static var weeklyCourses: [JourneyCourse] { allCourses.filter { !$0.isAnyDay } }
    /// 요일이 없는 코스 (여행처럼 아무 날이나 벌어지는 것)
    static var anyDayCourses: [JourneyCourse] { allCourses.filter { $0.isAnyDay } }

    /// 월요일부터 시작하는 요일 순서 (Calendar.weekday 값)
    static let weekdayOrder: [Int] = [2, 3, 4, 5, 6, 7, 1]

    static func weekdayLabel(_ weekday: Int) -> String {
        // 화면 언어의 짧은 요일 이름 (일·월… / Sun·Mon…)
        let f = DateFormatter()
        f.locale = Locale(identifier: AppLanguage.native.rawValue)
        return f.shortStandaloneWeekdaySymbols[weekday - 1]
    }

    /// 특정 요일 + 시간대에 벌어지는 장면들
    static func stops(weekday: Int, slot: TimeSlot) -> [(course: JourneyCourse, stop: JourneyStop)] {
        weeklyCourses
            .filter { $0.weekdays.contains(weekday) }
            .flatMap { course in course.stops(in: slot).map { (course, $0) } }
    }
}

// ─────────────────────────────────────────────────
// MARK: Course 1 — Sehari Jalan-Jalan ke Bandung (반둥 여행 첫날)
// ─────────────────────────────────────────────────
extension JourneyData {
    static let tripDay = JourneyCourse(
        id: "trip-bandung",
        title: "Sehari Jalan-Jalan ke Bandung",
        titleKo: "반둥 여행 첫날",
        description: "공항 입국심사부터 밤 호텔 로비까지, 여행자가 하루 동안 반드시 거치는 6개 장면",
        emoji: "🧳",
        difficulty: .beginner,
        weekdays: [],
        dayLabelKo: "여행 가는 날 · 아무 요일이나",
        stops: [
            // ── 09:00 공항
            stop(
                id: "trip-01", seed: 101, time: "09:00", emoji: "✈️",
                place: "Imigrasi Bandara", placeKo: "공항 입국심사",
                situation: "심사관이 방문 목적을 묻습니다. 첫 마디부터 격식체예요.",
                transit: "🚕 공항택시로 감비르역까지 약 60분",
                root: other(
                    "t1_root",
                    "Selamat pagi. Apa tujuan Anda datang ke Indonesia?",
                    "안녕하세요. 인도네시아에 오신 목적이 무엇인가요?",
                    "슬라맛 빠기. 아빠 뚜주안 안다 다땅 끄 인도네시아?",
                    .neutral,
                    t("Salam Resmi",
                      "Petugas memakai 'Anda'. Jawablah dengan kalimat utuh, bukan satu kata.",
                      "Di meja imigrasi, kalimat utuh menunjukkan rasa hormat dan mempercepat proses."),
                    [
                        me(
                            "t1_a",
                            "Selamat pagi. Saya berlibur satu minggu di Bandung.",
                            "안녕하세요. 반둥에서 일주일 동안 휴가를 보낼 거예요.",
                            "슬라맛 빠기. 사야 브를리부르 사뚜 밍구 디 반둥.",
                            .positive,
                            t("Jawaban Lengkap Sekali Jalan",
                              "Sebutkan tujuan, lama tinggal, dan kota sekaligus dalam satu kalimat.",
                              "Petugas tidak perlu bertanya lagi, jadi antrean Anda selesai lebih cepat."),
                            [
                                other("t1_a1",
                                      "Baik. Selamat berlibur, silakan lewat.",
                                      "좋습니다. 즐거운 여행 되세요, 지나가세요.",
                                      "바익. 슬라맛 브를리부르, 실라깐 레왓.",
                                      .positive),
                                other("t1_a2",
                                      "Baik. Tolong siapkan tiket pulang Anda ya.",
                                      "네. 돌아가는 항공권을 준비해 주세요.",
                                      "바익. 똘롱 시아쁘깐 띠껫 뿔랑 안다 야.",
                                      .neutral)
                            ]
                        ),
                        me(
                            "t1_b",
                            "Jalan-jalan aja.",
                            "그냥 놀러요.",
                            "잘란잘란 아자.",
                            .negative,
                            t("Terlalu Singkat",
                              "'Aja' adalah bahasa santai. Di meja imigrasi, jawaban sependek ini terdengar kurang sopan.",
                              "Bahasa santai di situasi resmi justru mengundang pertanyaan tambahan."),
                            [
                                other("t1_b1",
                                      "Berapa lama tinggal? Menginap di mana?",
                                      "얼마나 머무시죠? 어디에 묵으시나요?",
                                      "브라빠 라마 띵갈? 믕이납 디 마나?",
                                      .negative),
                                other("t1_b2",
                                      "Oh, berlibur ya. Berapa hari, Pak?",
                                      "아, 휴가시군요. 며칠이신가요?",
                                      "오, 브를리부르 야. 브라빠 하리, 빡?",
                                      .neutral)
                            ]
                        )
                    ]
                )
            ),

            // ── 11:00 기차역
            stop(
                id: "trip-02", seed: 102, time: "11:00", emoji: "🚉",
                place: "Loket Stasiun Gambir", placeKo: "감비르역 매표소",
                situation: "반둥행 기차표를 삽니다. 뒤에 줄이 길어요.",
                transit: "🚆 반둥까지 기차로 약 3시간",
                root: me(
                    "t2_root",
                    "Permisi, masih ada tiket ke Bandung siang ini?",
                    "실례합니다, 오늘 낮 반둥행 표 남아 있나요?",
                    "쁘르미시, 마시 아다 띠껫 끄 반둥 시앙 이니?",
                    .neutral,
                    t("Buka dengan 'Permisi'",
                      "'Permisi' adalah kunci pembuka di loket, warung, maupun di jalan. Setelah itu langsung ke inti.",
                      "Satu kata sopan di depan membuat petugas lebih ramah membantu."),
                    [
                        other(
                            "t2_a",
                            "Ada, Kak. Jam satu dan jam tiga. Mau yang mana?",
                            "있어요. 1시랑 3시요. 어느 걸로 하시겠어요?",
                            "아다, 깍. 잠 사뚜 단 잠 띠가. 마우 양 마나?",
                            .positive, nil,
                            [
                                me("t2_a1",
                                   "Yang jam satu ya. Satu tiket, kelas ekonomi.",
                                   "1시 걸로 할게요. 한 장, 이코노미석이요.",
                                   "양 잠 사뚜 야. 사뚜 띠껫, 끌라스 에꼬노미.",
                                   .positive,
                                   t("Putuskan Cepat dan Lengkap",
                                     "Sebutkan jam, jumlah, dan kelas sekaligus.",
                                     "Antrean loket panjang; jawaban lengkap dihargai petugas dan orang di belakang Anda.")),
                                me("t2_a2",
                                   "Hmm... sebentar, saya pikir dulu ya.",
                                   "음… 잠깐만요, 좀 생각해 볼게요.",
                                   "흠… 스븐따르, 사야 삐끼르 둘루 야.",
                                   .negative,
                                   t("Menunda di Depan Antrean",
                                     "Kalau perlu berpikir, mundur dulu: 'Saya lihat-lihat dulu ya, nanti balik.'",
                                     "Menahan antrean membuat suasana tidak nyaman dan petugas terburu-buru."))
                            ]
                        ),
                        other(
                            "t2_b",
                            "Yang siang habis, Kak. Adanya jam lima sore.",
                            "낮 표는 매진이에요. 오후 5시 것만 있어요.",
                            "양 시앙 하비스, 깍. 아다냐 잠 리마 소레.",
                            .negative, nil,
                            [
                                me("t2_b1",
                                   "Oh, kalau begitu jam lima saja. Perjalanannya berapa jam ya?",
                                   "아, 그럼 5시 걸로 할게요. 몇 시간 걸리나요?",
                                   "오, 깔라우 브기뚜 잠 리마 사자. 쁘르잘라난냐 브라빠 잠 야?",
                                   .positive,
                                   t("Terima Lalu Tanya Lanjutan",
                                     "Setelah menerima pilihan yang tersisa, satu pertanyaan kecil membuat percakapan tetap hangat.",
                                     "Pertanyaan lanjutan mengubah kabar buruk menjadi obrolan biasa.")),
                                me("t2_b2",
                                   "Yah, kok bisa habis? Saya buru-buru nih.",
                                   "아니, 왜 벌써 매진이에요? 저 급한데요.",
                                   "야, 꼭 비사 하비스? 사야 부루부루 니.",
                                   .negative,
                                   t("Hindari Menyalahkan Petugas",
                                     "Kecewa itu wajar, tapi jangan ditujukan ke orang di balik loket.",
                                     "Petugas tidak menentukan jumlah kursi; menyalahkan hanya menutup pintu bantuan."))
                            ]
                        )
                    ]
                )
            ),

            // ── 14:30 호텔 체크인
            stop(
                id: "trip-03", seed: 103, time: "14:30", emoji: "🏨",
                place: "Resepsionis Hotel", placeKo: "호텔 체크인",
                situation: "짐을 끌고 프런트에 도착했습니다. 체크인 시간이 애매해요.",
                transit: "🚶 도보 15분, 시내 광장까지",
                root: me(
                    "t3_root",
                    "Selamat siang, saya mau check-in atas nama Kim.",
                    "안녕하세요, 김으로 예약한 체크인하려고요.",
                    "슬라맛 시앙, 사야 마우 첵인 아따스 나마 낌.",
                    .neutral,
                    t("Sebut Nama di Awal",
                      "Salam + tujuan + nama pemesan. Tiga hal ini cukup untuk membuka check-in.",
                      "Resepsionis bisa langsung mencari data tanpa harus bertanya balik."),
                    [
                        other(
                            "t3_a",
                            "Selamat siang, Pak Kim. Kamarnya sudah siap. Boleh pinjam paspornya?",
                            "안녕하세요, 김 선생님. 방은 준비됐어요. 여권 좀 주시겠어요?",
                            "슬라맛 시앙, 빡 낌. 까마르냐 수다 시압. 볼레 삔잠 빠스뽀르냐?",
                            .positive, nil,
                            [
                                me("t3_a1",
                                   "Ini paspornya. Kalau bisa, kamarnya yang menghadap gunung ya.",
                                   "여기 여권이요. 가능하면 산이 보이는 방으로 부탁드려요.",
                                   "이니 빠스뽀르냐. 깔라우 비사, 까마르냐 양 믕하답 구눙 야.",
                                   .positive,
                                   t("Permintaan Kecil yang Ramah",
                                     "Awali dengan 'kalau bisa'. Permintaan jadi terdengar sebagai harapan, bukan tuntutan.",
                                     "Staf lebih sering mengabulkan permintaan yang memberi mereka ruang untuk menolak.")),
                                me("t3_a2",
                                   "Ini. Oh iya, sarapannya mulai jam berapa ya?",
                                   "여기요. 아 참, 조식은 몇 시부터예요?",
                                   "이니. 오 이야, 사라빤냐 물라이 잠 브라빠 야?",
                                   .neutral,
                                   t("Tanya Fasilitas",
                                     "Pertanyaan soal sarapan atau WiFi adalah small talk paling aman di hotel.",
                                     "Anda dapat informasi praktis sekaligus alasan untuk mengobrol."))
                            ]
                        ),
                        other(
                            "t3_b",
                            "Mohon maaf, kamarnya baru siap jam empat, Pak.",
                            "죄송하지만 방은 4시에나 준비됩니다.",
                            "모혼 마아프, 까마르냐 바루 시압 잠 음빳, 빡.",
                            .negative, nil,
                            [
                                me("t3_b1",
                                   "Tidak apa-apa. Boleh titip koper dulu di sini?",
                                   "괜찮아요. 그럼 캐리어만 잠깐 맡겨도 될까요?",
                                   "띠닥 아빠아빠. 볼레 띠띱 꼬뻐르 둘루 디 시니?",
                                   .positive,
                                   t("Ubah Masalah Jadi Permintaan",
                                     "Daripada mengeluh, ajukan satu hal kecil yang bisa staf lakukan sekarang juga.",
                                     "Staf lega karena tetap bisa membantu, dan waktu Anda tidak terbuang.")),
                                me("t3_b2",
                                   "Kok lama sekali? Saya sudah pesan dari bulan lalu.",
                                   "왜 이렇게 오래 걸려요? 지난달에 예약했는데요.",
                                   "꼭 라마 스깔리? 사야 수다 쁘산 다리 불란 랄루.",
                                   .negative,
                                   t("Keluhan Tanpa Jalan Keluar",
                                     "Menyebut masa lalu tidak mengubah keadaan sekarang.",
                                     "Percakapan jadi buntu dan staf berubah defensif."))
                            ]
                        )
                    ]
                )
            ),

            // ── 16:00 관광지
            stop(
                id: "trip-04", seed: 104, time: "16:00", emoji: "📸",
                place: "Alun-Alun Kota", placeKo: "시내 광장 관광",
                situation: "사진을 찍어줄 사람이 필요합니다. 모르는 사람에게 부탁해요.",
                transit: "🛵 그랩으로 식당까지 20분",
                root: me(
                    "t4_root",
                    "Permisi, boleh minta tolong fotokan kami?",
                    "실례합니다, 사진 한 장만 찍어 주실 수 있을까요?",
                    "쁘르미시, 볼레 민따 똘롱 포또깐 까미?",
                    .neutral,
                    t("Minta Tolong dengan 'Boleh'",
                      "'Boleh minta tolong…?' adalah cara paling halus meminta bantuan orang asing.",
                      "Bentuk pertanyaan memberi ruang untuk menolak, jadi tidak terasa membebani."),
                    [
                        other(
                            "t4_a",
                            "Boleh dong! Mau berdiri di depan tugu itu?",
                            "그럼요! 저 탑 앞에 서실래요?",
                            "볼레 동! 마우 브르디리 디 드빤 뚜구 이뚜?",
                            .positive, nil,
                            [
                                me("t4_a1",
                                   "Iya, yang gedungnya kelihatan ya. Makasih banyak, fotonya bagus!",
                                   "네, 건물이 나오게요. 정말 감사해요, 사진 잘 나왔네요!",
                                   "이야, 양 그둥냐 끌리하딴 야. 마까시 바냑, 포또냐 바구스!",
                                   .positive,
                                   t("Terima Kasih yang Konkret",
                                     "Sebutkan apa yang bagus, jangan hanya 'makasih'.",
                                     "Pujian spesifik terasa tulus dan membuat orang senang sudah membantu.")),
                                me("t4_a2",
                                   "Boleh sekalian yang model potret? Nanti saya fotokan balik.",
                                   "세로로도 한 장 부탁드려도 될까요? 저도 찍어 드릴게요.",
                                   "볼레 스깔리안 양 모델 뽀뜨렛? 난띠 사야 포또깐 발릭.",
                                   .positive,
                                   t("Balas Kebaikan",
                                     "Menawarkan bantuan balik mengubah pertemuan sekilas menjadi obrolan.",
                                     "Timbal balik kecil menciptakan rasa setara, bukan rasa berutang."))
                            ]
                        ),
                        other(
                            "t4_b",
                            "Wah, saya buru-buru... tapi boleh deh, satu kali ya.",
                            "아, 제가 좀 급한데… 그래도 한 번은 괜찮아요.",
                            "와, 사야 부루부루… 따삐 볼레 데, 사뚜 깔리 야.",
                            .neutral, nil,
                            [
                                me("t4_b1",
                                   "Satu kali saja cukup, makasih ya! Maaf sudah mengganggu.",
                                   "한 번이면 충분해요, 감사합니다! 방해해서 죄송해요.",
                                   "사뚜 깔리 사자 쭈꿉, 마까시 야! 마아프 수다 믕강구.",
                                   .positive,
                                   t("Hormati Waktu Orang Lain",
                                     "Ketika orang bilang buru-buru, kecilkan permintaan Anda, jangan pertahankan.",
                                     "Menghargai waktu membuat bantuan terasa ringan, bukan terpaksa.")),
                                me("t4_b2",
                                   "Coba beberapa kali ya, biar dapat yang bagus.",
                                   "여러 장 찍어 주세요, 잘 나온 걸로 건지게요.",
                                   "쪼바 브브라빠 깔리 야, 비아르 다빳 양 바구스.",
                                   .negative,
                                   t("Permintaan yang Melebar",
                                     "Menambah permintaan setelah orang bilang buru-buru terasa memaksa.",
                                     "Kebaikan kecil bisa berubah menjadi beban, dan orang menyesal menolong."))
                            ]
                        )
                    ]
                )
            ),

            // ── 19:00 식당
            stop(
                id: "trip-05", seed: 105, time: "19:00", emoji: "🍜",
                place: "Rumah Makan Sunda", placeKo: "순다 식당 저녁",
                situation: "메뉴판을 못 읽겠습니다. 종업원이 먼저 말을 겁니다.",
                transit: "🚕 호텔까지 10분",
                root: other(
                    "t5_root",
                    "Selamat malam, mau pesan apa, Kak?",
                    "안녕하세요, 무엇을 주문하시겠어요?",
                    "슬라맛 말람, 마우 쁘산 아빠, 깍?",
                    .neutral,
                    t("Pelayan Membuka Duluan",
                      "Di rumah makan, pelayan hampir selalu menyapa lebih dulu. Siapkan satu kalimat.",
                      "Jawaban yang sudah siap membuat Anda tidak panik saat ditanya."),
                    [
                        me(
                            "t5_a",
                            "Saya belum tahu menunya. Yang paling enak di sini apa ya?",
                            "메뉴를 잘 몰라서요. 여기서 뭐가 제일 맛있어요?",
                            "사야 블룸 따우 므누냐. 양 빨링 에낙 디 시니 아빠 야?",
                            .positive,
                            t("Tanya Rekomendasi",
                              "Meminta rekomendasi adalah pembuka obrolan terbaik di rumah makan.",
                              "Orang senang ditanya pendapatnya, dan Anda dapat menu terbaiknya."),
                            [
                                other("t5_a1",
                                      "Kalau di sini, ayam bakar sama karedok paling laris, Kak.",
                                      "여기선 아얌 바까르랑 까레독이 제일 잘 나가요.",
                                      "깔라우 디 시니, 아얌 바까르 사마 까레독 빨링 라리스, 깍.",
                                      .positive),
                                other("t5_a2",
                                      "Coba nasi timbel komplit. Pedasnya bisa disesuaikan kok.",
                                      "나시 띰블 꼼쁠릿 드셔 보세요. 맵기도 조절돼요.",
                                      "쪼바 나시 띰블 꼼쁠릿. 쁘다스냐 비사 디스수아이깐 꼭.",
                                      .positive)
                            ]
                        ),
                        me(
                            "t5_b",
                            "Nasi goreng satu, tidak pedas ya.",
                            "나시고렝 하나요, 안 맵게 해 주세요.",
                            "나시 고렝 사뚜, 띠닥 쁘다스 야.",
                            .neutral,
                            t("Pesanan Aman",
                              "Kalau ragu, pesan yang Anda kenal dan sebutkan tingkat pedasnya.",
                              "'Tidak pedas' mencegah kejutan yang bisa merusak makan malam Anda."),
                            [
                                other("t5_b1",
                                      "Baik, nasi goreng satu, tidak pedas. Minumnya apa?",
                                      "네, 나시고렝 하나, 안 맵게요. 음료는요?",
                                      "바익, 나시 고렝 사뚜, 띠닥 쁘다스. 미눔냐 아빠?",
                                      .neutral),
                                other("t5_b2",
                                      "Maaf, nasi gorengnya lagi habis, Kak.",
                                      "죄송해요, 나시고렝은 지금 다 떨어졌어요.",
                                      "마아프, 나시 고렝냐 라기 하비스, 깍.",
                                      .negative)
                            ]
                        )
                    ]
                )
            ),

            // ── 21:30 호텔 로비
            stop(
                id: "trip-06", seed: 106, time: "21:30", emoji: "🛎️",
                place: "Lobi Hotel", placeKo: "호텔 로비",
                situation: "내일 일정을 짜야 합니다. 직원에게 현지 정보를 물어봐요.",
                transit: nil,
                difficulty: .intermediate,
                root: me(
                    "t6_root",
                    "Selamat malam. Besok saya mau ke kawah, enaknya berangkat jam berapa ya?",
                    "안녕하세요. 내일 분화구에 가려는데 몇 시에 출발하는 게 좋을까요?",
                    "슬라맛 말람. 베속 사야 마우 끄 까와, 에낙냐 브랑깟 잠 브라빠 야?",
                    .neutral,
                    t("Tanya Warga Lokal",
                      "Staf hotel tahu jam macet dan cuaca. 'Jam berapa' lebih berguna daripada 'bagus tidak'.",
                      "Pertanyaan spesifik menghasilkan jawaban yang bisa langsung Anda pakai."),
                    [
                        other(
                            "t6_a",
                            "Pagi-pagi, Pak. Jam enam sudah jalan, biar tidak kena macet.",
                            "아침 일찍이요. 6시에는 출발하셔야 안 막혀요.",
                            "빠기빠기, 빡. 잠 으남 수다 잘란, 비아르 띠닥 끄나 마쯧.",
                            .positive, nil,
                            [
                                me("t6_a1",
                                   "Wah, makasih. Kalau sarapannya belum buka, gimana ya?",
                                   "아, 감사해요. 그럼 조식이 아직 안 열었으면 어떡하죠?",
                                   "와, 마까시. 깔라우 사라빤냐 블룸 부까, 기마나 야?",
                                   .positive,
                                   t("Lanjutkan ke Masalah Praktis",
                                     "Setelah saran diterima, tanyakan hal kecil berikutnya agar percakapan mengalir.",
                                     "Rangkaian pertanyaan kecil membangun hubungan dengan staf hotel.")),
                                me("t6_a2",
                                   "Siap, jam enam. Bapak sendiri sudah pernah ke sana?",
                                   "네, 6시요. 혹시 직접 가 보신 적 있으세요?",
                                   "시압, 잠 으남. 바빡 슨디리 수다 쁘르나 끄 사나?",
                                   .positive,
                                   t("Balik Bertanya",
                                     "Menanyakan pengalaman lawan bicara mengubah tanya-jawab menjadi obrolan.",
                                     "Orang jauh lebih terbuka saat diminta bercerita, bukan hanya menjawab."))
                            ]
                        ),
                        other(
                            "t6_b",
                            "Tergantung cuaca, Pak. Besok kabarnya hujan.",
                            "날씨에 달렸어요. 내일 비 온다고 하던데요.",
                            "뜨르간뚱 쭈아짜, 빡. 베속 까바르냐 후잔.",
                            .neutral, nil,
                            [
                                me("t6_b1",
                                   "Kalau hujan, ada tempat lain yang bagus di dekat sini?",
                                   "비가 오면 이 근처에 갈 만한 다른 곳이 있을까요?",
                                   "깔라우 후잔, 아다 뜸빳 라인 양 바구스 디 드깟 시니?",
                                   .positive,
                                   t("Siapkan Rencana Cadangan",
                                     "Ketika jawaban tidak pasti, mintalah alternatif, bukan kepastian.",
                                     "Staf jadi bisa membantu, dan rencana Anda tetap hidup.")),
                                me("t6_b2",
                                   "Yah, padahal sudah jauh-jauh ke sini.",
                                   "아휴, 이렇게 멀리까지 왔는데.",
                                   "야, 빠다할 수다 자우자우 끄 시니.",
                                   .negative,
                                   t("Mengeluh ke Orang yang Salah",
                                     "Cuaca bukan urusan staf. Keluhan menutup percakapan yang tadinya membantu.",
                                     "Kekecewaan lebih berguna kalau diubah menjadi pertanyaan."))
                            ]
                        )
                    ]
                )
            )
        ]
    )
}

// ─────────────────────────────────────────────────
// MARK: Course 2 — Hari Pertama Masuk Kantor (첫 출근 날)
// ─────────────────────────────────────────────────
extension JourneyData {
    static let firstWorkDay = JourneyCourse(
        id: "work-firstday",
        title: "Hari Pertama Masuk Kantor",
        titleKo: "첫 출근 날",
        description: "출근길 오젝 기사부터 퇴근 인사까지, 자카르타 사무실에서의 하루",
        emoji: "🏢",
        difficulty: .intermediate,
        weekdays: [2, 3, 4, 5, 6],
        dayLabelKo: "평일 · 월–금",
        stops: [
            // ── 07:30 출근길
            stop(
                id: "work-01", seed: 201, time: "07:30", emoji: "🛵",
                place: "Ojek Online", placeKo: "오젝 출근길",
                situation: "오토바이 뒷자리에서 기사님과 나누는 짧은 대화.",
                transit: "🛵 사무실까지 20분",
                root: other(
                    "w1_root",
                    "Pagi, Mas. Ke kantor di Sudirman ya?",
                    "안녕하세요. 수디르만 사무실로 가시죠?",
                    "빠기, 마스. 끄 깐또르 디 수디르만 야?",
                    .neutral,
                    t("Konfirmasi Tujuan",
                      "Driver biasanya menyapa duluan. Pastikan tujuan dengan jelas sebelum berangkat.",
                      "Salah tujuan di pagi hari bisa membuat hari pertama Anda berantakan."),
                    [
                        me(
                            "w1_a",
                            "Iya betul, Pak. Hari ini hari pertama saya kerja di sana.",
                            "네 맞아요. 오늘 거기 첫 출근이에요.",
                            "이야 브뚤, 빡. 하리 이니 하리 쁘르따마 사야 끄르자 디 사나.",
                            .positive,
                            t("Bagikan Konteks Kecil",
                              "Satu kalimat tentang diri Anda mengundang obrolan hangat sepanjang jalan.",
                              "Cerita pribadi singkat membuat orang ikut senang dan mendoakan Anda."),
                            [
                                other("w1_a1",
                                      "Wah, hari pertama! Semoga lancar ya. Saya lewat jalan tikus biar cepat.",
                                      "와, 첫 출근이시구나! 잘 되시길요. 지름길로 빨리 갈게요.",
                                      "와, 하리 쁘르따마! 스모가 란짜르 야. 사야 레왓 잘란 띠꾸스 비아르 쯔빳.",
                                      .positive),
                                other("w1_a2",
                                      "Selamat ya, Mas! Nanti saya turunkan pas di depan lobinya.",
                                      "축하드려요! 로비 바로 앞에 내려 드릴게요.",
                                      "슬라맛 야, 마스! 난띠 사야 뚜룬깐 빠스 디 드빤 로비냐.",
                                      .positive)
                            ]
                        ),
                        me(
                            "w1_b",
                            "Iya, Pak. Kira-kira berapa lama sampai sana?",
                            "네. 거기까지 얼마나 걸릴까요?",
                            "이야, 빡. 끼라끼라 브라빠 라마 삼빠이 사나?",
                            .neutral,
                            t("Tanya Waktu Tempuh",
                              "Pertanyaan praktis tetap sopan dan berguna, apalagi saat Anda terburu-buru.",
                              "Anda bisa menyesuaikan rencana sebelum benar-benar terlambat."),
                            [
                                other("w1_b1",
                                      "Kalau lancar dua puluh menit. Tapi jam segini biasanya macet.",
                                      "안 막히면 20분이요. 근데 이 시간엔 보통 막혀요.",
                                      "깔라우 란짜르 두아 뿔루 므닛. 따삐 잠 스기니 비아사냐 마쯧.",
                                      .neutral),
                                other("w1_b2",
                                      "Wah, kurang tahu, Mas. Tergantung macetnya.",
                                      "글쎄요, 잘 모르겠네요. 막히는 거 봐서요.",
                                      "와, 꾸랑 따우, 마스. 뜨르간뚱 마쯧냐.",
                                      .negative)
                            ]
                        )
                    ]
                )
            ),

            // ── 08:20 로비
            stop(
                id: "work-02", seed: 202, time: "08:20", emoji: "🛗",
                place: "Resepsionis Kantor", placeKo: "사무실 로비",
                situation: "출입 카드가 아직 없습니다. 리셉션에 상황을 설명해요.",
                transit: "🛗 엘리베이터로 12층까지",
                root: me(
                    "w2_root",
                    "Selamat pagi. Saya karyawan baru, hari ini mulai masuk.",
                    "안녕하세요. 신입사원인데 오늘부터 출근합니다.",
                    "슬라맛 빠기. 사야 까르야완 바루, 하리 이니 물라이 마숙.",
                    .neutral,
                    t("Perkenalkan Status Anda",
                      "Di lobi, sebutkan siapa Anda sebelum meminta apa pun.",
                      "Resepsionis bisa langsung mengarahkan tanpa harus menebak-nebak."),
                    [
                        other(
                            "w2_a",
                            "Selamat pagi! Namanya siapa ya? Saya cek dulu kartu aksesnya.",
                            "안녕하세요! 성함이 어떻게 되세요? 출입 카드 확인해 볼게요.",
                            "슬라맛 빠기! 나마냐 시아빠 야? 사야 쩩 둘루 까르뚜 악세스냐.",
                            .positive, nil,
                            [
                                me("w2_a1",
                                   "Kim Minjun, dari tim marketing. Terima kasih ya, Mbak.",
                                   "김민준이고요, 마케팅팀이에요. 감사합니다.",
                                   "낌 민준, 다리 띰 마르께띵. 뜨리마 까시 야, 음박.",
                                   .positive,
                                   t("Nama Plus Tim",
                                     "Menyebut tim membantu orang mengingat Anda besok dan lusa.",
                                     "Perkenalan yang mudah diingat mempercepat pertemanan di kantor baru.")),
                                me("w2_a2",
                                   "Kim Minjun. Tim marketing di lantai berapa ya?",
                                   "김민준이요. 마케팅팀은 몇 층인가요?",
                                   "낌 민준. 띰 마르께띵 디 란따이 브라빠 야?",
                                   .neutral,
                                   t("Sekalian Bertanya Arah",
                                     "Gabungkan jawaban dengan pertanyaan agar tidak perlu bolak-balik.",
                                     "Efisien, dan resepsionis merasa dipercaya sebagai pemandu."))
                            ]
                        ),
                        other(
                            "w2_b",
                            "Kartu aksesnya belum jadi, Pak. Isi buku tamu dulu ya.",
                            "출입 카드가 아직 안 나왔어요. 방문록 먼저 작성해 주세요.",
                            "까르뚜 악세스냐 블룸 자디, 빡. 이시 부꾸 따무 둘루 야.",
                            .neutral, nil,
                            [
                                me("w2_b1",
                                   "Baik, saya isi. Kalau sudah jadi, saya ambil di sini juga?",
                                   "네, 작성할게요. 카드 나오면 여기서 받으면 되나요?",
                                   "바익, 사야 이시. 깔라우 수다 자디, 사야 암빌 디 시니 주가?",
                                   .positive,
                                   t("Ikuti Aturan, Pastikan Langkah Berikutnya",
                                     "Menerima prosedur lalu memastikan langkah selanjutnya menunjukkan Anda mudah diajak kerja sama.",
                                     "Kesan 'gampang diajak kerja' terbentuk justru di hari pertama.")),
                                me("w2_b2",
                                   "Hari pertama kok kartunya belum siap?",
                                   "첫날인데 카드가 아직 준비가 안 됐다고요?",
                                   "하리 쁘르따마 꼭 까르뚜냐 블룸 시압?",
                                   .negative,
                                   t("Jangan Salahkan Petugas Depan",
                                     "Resepsionis tidak membuat kartu akses; keluhan di sini tidak mempercepat apa pun.",
                                     "Kesan pertama di kantor menyebar jauh lebih cepat daripada yang Anda kira."))
                            ]
                        )
                    ]
                )
            ),

            // ── 09:00 팀 소개
            stop(
                id: "work-03", seed: 203, time: "09:00", emoji: "👋",
                place: "Perkenalan Tim", placeKo: "팀 자기소개",
                situation: "팀원들 앞에서 첫인사를 합니다. 15초가 승부예요.",
                transit: "💻 오전 업무 3시간",
                root: me(
                    "w3_root",
                    "Halo semuanya, saya Minjun. Mulai hari ini bergabung di tim ini.",
                    "안녕하세요 여러분, 민준입니다. 오늘부터 이 팀에 합류했어요.",
                    "할로 스무아냐, 사야 민준. 물라이 하리 이니 브르가붕 디 띰 이니.",
                    .neutral,
                    t("Perkenalan 15 Detik",
                      "Nama, peran, dan satu kalimat hangat. Jangan lebih panjang dari itu.",
                      "Perkenalan pendek mudah diingat dan tidak membuat ruangan terasa tegang."),
                    [
                        other(
                            "w3_a",
                            "Halo Minjun! Sudah lama di Indonesia?",
                            "안녕하세요 민준 씨! 인도네시아 오신 지 오래됐어요?",
                            "할로 민준! 수다 라마 디 인도네시아?",
                            .positive, nil,
                            [
                                me("w3_a1",
                                   "Baru tiga bulan. Bahasa saya masih belajar, mohon dibantu ya.",
                                   "이제 3개월이요. 언어는 아직 배우는 중이라 많이 도와주세요.",
                                   "바루 띠가 불란. 바하사 사야 마시 블라자르, 모혼 디반뚜 야.",
                                   .positive,
                                   t("Akui Keterbatasan dengan Ceria",
                                     "Mengaku sedang belajar mengubah rekan kerja menjadi guru, bukan penilai.",
                                     "Orang cenderung membantu mereka yang terbuka soal kekurangannya.")),
                                me("w3_a2",
                                   "Baru tiga bulan. Kalau ada tempat makan enak dekat sini, kasih tahu ya!",
                                   "3개월 됐어요. 근처에 맛집 있으면 알려 주세요!",
                                   "바루 띠가 불란. 깔라우 아다 뜸빳 마깐 에낙 드깟 시니, 까시 따우 야!",
                                   .positive,
                                   t("Buka Pintu Obrolan Lanjutan",
                                     "Pertanyaan tentang makanan hampir selalu menghasilkan jawaban panjang.",
                                     "Anda memberi rekan kerja alasan yang mudah untuk mengajak Anda pergi."))
                            ]
                        ),
                        other(
                            "w3_b",
                            "Halo. Nanti file-file tim saya kirim ya.",
                            "안녕하세요. 팀 자료는 이따 보내 드릴게요.",
                            "할로. 난띠 필파일 띰 사야 끼림 야.",
                            .neutral, nil,
                            [
                                me("w3_b1",
                                   "Terima kasih banyak. Kalau saya bingung, boleh tanya-tanya?",
                                   "정말 감사합니다. 헷갈리면 여쭤봐도 될까요?",
                                   "뜨리마 까시 바냑. 깔라우 사야 빙웅, 볼레 따냐따냐?",
                                   .positive,
                                   t("Minta Izin Bertanya",
                                     "Izin bertanya di awal membuat pertanyaan Anda nanti terasa wajar.",
                                     "Rekan kerja jadi siap membantu, bukan merasa terganggu.")),
                                me("w3_b2",
                                   "Oke, siap.",
                                   "네, 알겠습니다.",
                                   "오께, 시압.",
                                   .negative,
                                   t("Jawaban Terlalu Pendek",
                                     "'Siap' saja membuat percakapan berhenti di kalimat pertama.",
                                     "Di hari pertama, satu kalimat tambahan sangat menentukan."))
                            ]
                        )
                    ]
                )
            ),

            // ── 12:00 점심
            stop(
                id: "work-04", seed: 204, time: "12:00", emoji: "🍛",
                place: "Makan Siang Bareng", placeKo: "팀 점심 초대",
                situation: "동료가 점심을 같이 먹자고 합니다. 첫 초대예요.",
                transit: "☕ 오후 업무",
                root: other(
                    "w4_root",
                    "Minjun, makan siang bareng yuk. Mau makan apa?",
                    "민준 씨, 점심 같이 먹어요. 뭐 먹고 싶어요?",
                    "민준, 마깐 시앙 바렝 유. 마우 마깐 아빠?",
                    .positive,
                    t("Ajakan Pertama",
                      "Ajakan makan siang di hari pertama adalah tanda Anda diterima. Jawab dengan antusias.",
                      "Menolak ajakan pertama sering ditafsirkan sebagai ingin menjaga jarak."),
                    [
                        me(
                            "w4_a",
                            "Mau banget! Saya ikut saja, belum tahu tempat di sini.",
                            "완전 좋죠! 여긴 잘 몰라서 따라갈게요.",
                            "마우 방엣! 사야 이꿋 사자, 블룸 따우 뜸빳 디 시니.",
                            .positive,
                            t("Ikut Dulu, Pilih Nanti",
                              "Di ajakan pertama, menyerahkan pilihan pada tuan rumah adalah cara paling aman dan ramah.",
                              "Tuan rumah senang bisa memperkenalkan tempat favoritnya kepada Anda."),
                            [
                                other("w4_a1",
                                      "Oke, kita ke warung padang langganan. Enak dan cepat.",
                                      "좋아요, 단골 빠당 식당 가요. 맛있고 빨라요.",
                                      "오께, 끼따 끄 와룽 빠당 랑가난. 에낙 단 쯔빳.",
                                      .positive),
                                other("w4_a2",
                                      "Kalau begitu coba soto ayam depan gang. Bisa makan pedas?",
                                      "그럼 골목 앞 소또 아얌 어때요? 매운 거 드세요?",
                                      "깔라우 브기뚜 쪼바 소또 아얌 드빤 강. 비사 마깐 쁘다스?",
                                      .positive)
                            ]
                        ),
                        me(
                            "w4_b",
                            "Boleh. Tapi saya tidak makan daging babi, tidak apa-apa ya?",
                            "좋아요. 그런데 제가 돼지고기를 안 먹는데 괜찮을까요?",
                            "볼레. 따삐 사야 띠닥 마깐 다깅 바비, 띠닥 아빠아빠 야?",
                            .neutral,
                            t("Sampaikan Pantangan Lebih Awal",
                              "Menyebut pantangan makan sejak awal justru memudahkan semua orang.",
                              "Jauh lebih baik disampaikan sekarang daripada saat makanan sudah terhidang."),
                            [
                                other("w4_b1",
                                      "Oh santai, di sini kebanyakan ayam sama ikan kok.",
                                      "아 괜찮아요, 여긴 대부분 닭이랑 생선이에요.",
                                      "오 산따이, 디 시니 끄바냐깐 아얌 사마 이깐 꼭.",
                                      .positive),
                                other("w4_b2",
                                      "Oke, nanti kita cari yang halal saja ya.",
                                      "네, 그럼 할랄 되는 데로 찾아볼게요.",
                                      "오께, 난띠 끼따 짜리 양 할랄 사자 야.",
                                      .neutral)
                            ]
                        )
                    ]
                )
            ),

            // ── 15:00 탕비실
            stop(
                id: "work-05", seed: 205, time: "15:00", emoji: "☕",
                place: "Pantry Kantor", placeKo: "탕비실 커피",
                situation: "커피를 내리던 동료와 마주쳤습니다. 30초짜리 스몰토크.",
                transit: "💻 마감 업무 3시간",
                root: me(
                    "w5_root",
                    "Kopinya harum banget. Bikin sendiri atau beli?",
                    "커피 향 좋네요. 직접 내리신 거예요, 아니면 사 오신 거예요?",
                    "꼬삐냐 하룸 방엣. 비낀 슨디리 아따우 블리?",
                    .neutral,
                    t("Mulai dari Benda di Depan Mata",
                      "Small talk paling mudah dimulai dari apa yang sedang dilakukan lawan bicara.",
                      "Topik yang terlihat bersama tidak pernah terasa dipaksakan."),
                    [
                        other(
                            "w5_a",
                            "Bikin sendiri. Kopi Gayo, mau coba?",
                            "직접 내렸어요. 가요 커피인데 드셔 볼래요?",
                            "비낀 슨디리. 꼬삐 가요, 마우 쪼바?",
                            .positive, nil,
                            [
                                me("w5_a1",
                                   "Boleh! Saya belum pernah coba kopi Aceh. Pahitnya kuat ya?",
                                   "좋죠! 아쩨 커피는 처음이에요. 쓴맛이 강한가요?",
                                   "볼레! 사야 블룸 쁘르나 쪼바 꼬삐 아쩨. 빠힛냐 꾸앗 야?",
                                   .positive,
                                   t("Tunjukkan Rasa Ingin Tahu",
                                     "Bertanya detail tentang hal yang disukai orang lain membuat obrolan berjalan sendiri.",
                                     "Orang senang menjelaskan hobinya kepada pendengar yang tulus.")),
                                me("w5_a2",
                                   "Mau. Besok saya bawa teh dari Korea, kita tukar ya.",
                                   "네. 내일은 제가 한국 차 가져올게요, 바꿔 먹어요.",
                                   "마우. 베속 사야 바와 떼 다리 꼬레아, 끼따 뚜까르 야.",
                                   .positive,
                                   t("Tawarkan Giliran Balik",
                                     "Menjanjikan pertukaran kecil menciptakan alasan untuk bertemu lagi besok.",
                                     "Hubungan kantor tumbuh dari janji-janji kecil yang ditepati."))
                            ]
                        ),
                        other(
                            "w5_b",
                            "Beli di bawah. Kopi di pantry kurang enak soalnya.",
                            "아래층에서 샀어요. 탕비실 커피는 별로라서요.",
                            "블리 디 바와. 꼬삐 디 빤뜨리 꾸랑 에낙 소알냐.",
                            .neutral, nil,
                            [
                                me("w5_b1",
                                   "Oh gitu. Kapan-kapan tunjukkan tempatnya dong.",
                                   "아 그렇군요. 언제 한번 그 가게 알려 주세요.",
                                   "오 기뚜. 까빤까빤 뚠죽깐 뜸빳냐 동.",
                                   .positive,
                                   t("Ubah Informasi Jadi Janji",
                                     "Setiap informasi bisa dijadikan alasan untuk pergi bersama lain kali.",
                                     "Ajakan ringan seperti ini jauh lebih mudah diterima daripada ajakan resmi.")),
                                me("w5_b2",
                                   "Oh, begitu ya.",
                                   "아, 그렇군요.",
                                   "오, 브기뚜 야.",
                                   .negative,
                                   t("Jalan Buntu",
                                     "Tanggapan sependek ini membuat lawan bicara berhenti bercerita.",
                                     "Small talk mati bukan karena topiknya, melainkan karena responsnya."))
                            ]
                        )
                    ]
                )
            ),

            // ── 18:00 퇴근
            stop(
                id: "work-06", seed: 206, time: "18:00", emoji: "🚪",
                place: "Pulang Kantor", placeKo: "퇴근 인사",
                situation: "아직 남아 있는 동료들 앞에서 먼저 나가야 합니다.",
                transit: nil,
                root: me(
                    "w6_root",
                    "Saya duluan ya. Terima kasih untuk hari ini.",
                    "저 먼저 가 볼게요. 오늘 감사했습니다.",
                    "사야 둘루안 야. 뜨리마 까시 운뚝 하리 이니.",
                    .neutral,
                    t("Pamit dengan Terima Kasih",
                      "Di Indonesia, pergi tanpa menyapa yang masih bekerja terasa dingin. Sebutkan terima kasih.",
                      "Kalimat penutup menentukan kesan yang orang bawa pulang tentang Anda."),
                    [
                        other(
                            "w6_a",
                            "Hati-hati di jalan! Besok kita lanjut ya.",
                            "조심히 가세요! 내일 이어서 해요.",
                            "하띠하띠 디 잘란! 베속 끼따 란줏 야.",
                            .positive, nil,
                            [
                                me("w6_a1",
                                   "Siap, sampai besok. Selamat malam!",
                                   "네, 내일 봬요. 좋은 밤 되세요!",
                                   "시압, 삼빠이 베속. 슬라맛 말람!",
                                   .positive,
                                   t("Tutup dengan Janji Besok",
                                     "'Sampai besok' menandakan Anda betah dan pasti kembali.",
                                     "Penutup yang hangat membuat hari kedua terasa jauh lebih mudah.")),
                                me("w6_a2",
                                   "Makasih banyak. Hari pertama jadi tidak canggung karena kalian.",
                                   "정말 감사해요. 여러분 덕분에 첫날이 어색하지 않았어요.",
                                   "마까시 바냑. 하리 쁘르따마 자디 띠닥 짱궁 까르나 깔리안.",
                                   .positive,
                                   t("Sebut Jasa Orang Lain",
                                     "Menyebut siapa yang membantu jauh lebih berkesan daripada terima kasih umum.",
                                     "Orang mengingat mereka yang menghargai bantuan kecil."))
                            ]
                        ),
                        other(
                            "w6_b",
                            "Loh, sudah pulang? Kami masih ada meeting.",
                            "어, 벌써 가세요? 저희는 아직 회의가 있어요.",
                            "로, 수다 뿔랑? 까미 마시 아다 미띵.",
                            .neutral, nil,
                            [
                                me("w6_b1",
                                   "Iya, hari ini saya duluan. Kalau ada yang bisa saya bantu, kabari ya.",
                                   "네, 오늘은 먼저 갈게요. 도울 일 있으면 말씀해 주세요.",
                                   "이야, 하리 이니 사야 둘루안. 깔라우 아다 양 비사 사야 반뚜, 까바리 야.",
                                   .positive,
                                   t("Pamit Tanpa Rasa Bersalah",
                                     "Tidak perlu minta maaf karena pulang tepat waktu. Tawarkan bantuan sebagai gantinya.",
                                     "Menawarkan bantuan menjaga hubungan tanpa mengorbankan batas Anda.")),
                                me("w6_b2",
                                   "Maaf ya, saya pulang duluan...",
                                   "죄송해요, 저 먼저 들어갈게요…",
                                   "마아프 야, 사야 뿔랑 둘루안…",
                                   .negative,
                                   t("Minta Maaf Berlebihan",
                                     "Meminta maaf untuk hal yang wajar membuat Anda terlihat tidak percaya diri.",
                                     "Rekan kerja bisa ikut merasa Anda sedang melakukan kesalahan."))
                            ]
                        )
                    ]
                )
            )
        ]
    )
}

// ─────────────────────────────────────────────────
// MARK: Course 3 — Akhir Pekan di Kampung (동네에서 보내는 주말)
// ─────────────────────────────────────────────────
extension JourneyData {
    static let weekendDay = JourneyCourse(
        id: "weekend-kampung",
        title: "Akhir Pekan di Kampung",
        titleKo: "동네에서 보내는 주말",
        description: "이웃 인사부터 야시장까지, 현지에 사는 사람의 하루",
        emoji: "🏘️",
        difficulty: .beginner,
        weekdays: [7, 1],
        dayLabelKo: "주말 · 토–일",
        stops: [
            // ── 08:00 이웃
            stop(
                id: "week-01", seed: 301, time: "08:00", emoji: "🌤️",
                place: "Tetangga Depan Rumah", placeKo: "집 앞 이웃",
                situation: "대문을 나서자마자 이웃이 '어디 가?'라고 묻습니다.",
                transit: "🚶 시장까지 도보 10분",
                root: other(
                    "k1_root",
                    "Pagi! Mau ke mana pagi-pagi begini?",
                    "안녕! 이 아침부터 어디 가요?",
                    "빠기! 마우 끄 마나 빠기빠기 브기니?",
                    .neutral,
                    t("Arti 'Mau ke Mana?'",
                      "Ini bukan interogasi, melainkan sapaan khas Indonesia. Jawab santai, tidak perlu detail.",
                      "Salah paham di sini membuat banyak orang asing terlihat tertutup tanpa sadar."),
                    [
                        me(
                            "k1_a",
                            "Pagi, Bu! Mau ke pasar sebentar. Ibu sendiri?",
                            "안녕하세요! 시장에 잠깐 다녀오려고요. 어머니는요?",
                            "빠기, 부! 마우 끄 빠사르 스븐따르. 이부 슨디리?",
                            .positive,
                            t("Jawab Ringkas Lalu Balik Bertanya",
                              "'Mau ke pasar' sudah cukup. Setelah itu kembalikan pertanyaannya.",
                              "Pola tanya-balik adalah irama dasar small talk di Indonesia."),
                            [
                                other("k1_a1",
                                      "Saya mau nyapu halaman dulu. Kalau ke pasar, sayurnya masih segar jam segini.",
                                      "난 마당 좀 쓸려고요. 이 시간엔 채소가 아직 싱싱해요.",
                                      "사야 마우 냐뿌 할라만 둘루. 깔라우 끄 빠사르, 사유르냐 마시 스가르 잠 스기니.",
                                      .positive),
                                other("k1_a2",
                                      "Wah, kebetulan! Titip cabai satu ons ya, nanti saya ganti.",
                                      "잘됐다! 고추 100g만 사다 줘요, 돈은 나중에 줄게요.",
                                      "와, 끄브뚤란! 띠띱 짜바이 사뚜 온스 야, 난띠 사야 간띠.",
                                      .positive)
                            ]
                        ),
                        me(
                            "k1_b",
                            "Pagi. Ada urusan sedikit.",
                            "안녕하세요. 볼일이 좀 있어서요.",
                            "빠기. 아다 우루산 스디낏.",
                            .negative,
                            t("Terlalu Menutup",
                              "Jawaban kabur membuat tetangga merasa Anda tidak ingin diajak bicara.",
                              "Di lingkungan tempat tinggal, kesan tertutup bertahan sangat lama."),
                            [
                                other("k1_b1",
                                      "Oh, ya sudah. Hati-hati ya.",
                                      "아, 그래요. 조심해서 다녀와요.",
                                      "오, 야 수다. 하띠하띠 야.",
                                      .neutral),
                                other("k1_b2",
                                      "Oh... iya, silakan.",
                                      "아… 네, 다녀오세요.",
                                      "오… 이야, 실라깐.",
                                      .negative)
                            ]
                        )
                    ]
                )
            ),

            // ── 09:30 시장
            stop(
                id: "week-02", seed: 302, time: "09:30", emoji: "🥬",
                place: "Pasar Tradisional", placeKo: "재래시장 흥정",
                situation: "망고 값을 깎아야 합니다. 흥정도 대화예요.",
                transit: "🚶 이발소까지 5분",
                root: me(
                    "k2_root",
                    "Bu, mangganya berapa sekilo?",
                    "아주머니, 망고 1kg에 얼마예요?",
                    "부, 망가냐 브라빠 스낄로?",
                    .neutral,
                    t("Panggil 'Bu' atau 'Pak' Dulu",
                      "Menyapa penjual dengan panggilan hormat sebelum bertanya harga adalah aturan tak tertulis di pasar.",
                      "Panggilan hormat sering langsung menurunkan harga pembuka."),
                    [
                        other(
                            "k2_a",
                            "Tiga puluh ribu sekilo, Kak. Manis-manis ini.",
                            "1kg에 3만 루피아예요. 다 달아요.",
                            "띠가 뿔루 리부 스낄로, 깍. 마니스마니스 이니.",
                            .positive, nil,
                            [
                                me("k2_a1",
                                   "Kalau ambil dua kilo, boleh dua puluh lima ribu?",
                                   "2kg 사면 2만 5천에 해 주실 수 있어요?",
                                   "깔라우 암빌 두아 낄로, 볼레 두아 뿔루 리마 리부?",
                                   .positive,
                                   t("Tawar dengan Alasan",
                                     "Menawar sambil menambah jumlah beli terdengar wajar, bukan pelit.",
                                     "Penjual untung dari jumlah, jadi tawaran Anda masuk akal baginya.")),
                                me("k2_a2",
                                   "Boleh coba satu? Kalau manis saya ambil dua kilo.",
                                   "하나 맛봐도 될까요? 달면 2kg 살게요.",
                                   "볼레 쪼바 사뚜? 깔라우 마니스 사야 암빌 두아 낄로.",
                                   .positive,
                                   t("Minta Cicip Dulu",
                                     "Meminta mencicipi adalah kebiasaan normal di pasar, bukan hal memalukan.",
                                     "Momen mencicipi membuat penjual mengingat Anda sebagai pelanggan."))
                            ]
                        ),
                        other(
                            "k2_b",
                            "Lagi mahal, Kak. Hujan terus soalnya.",
                            "요즘 비싸요. 비가 계속 와서요.",
                            "라기 마할, 깍. 후잔 뜨루스 소알냐.",
                            .neutral, nil,
                            [
                                me("k2_b1",
                                   "Iya ya, musim hujan semuanya naik. Yang lagi murah apa, Bu?",
                                   "그러게요, 우기엔 다 오르네요. 지금 싼 건 뭐예요?",
                                   "이야 야, 무심 후잔 스무아냐 나익. 양 라기 무라 아빠, 부?",
                                   .positive,
                                   t("Ikut Merasakan Keadaan",
                                     "Menyetujui keluhan penjual sebelum menawar membuat Anda terasa satu pihak dengannya.",
                                     "Rasa senasib jauh lebih efektif daripada tawar-menawar yang keras.")),
                                me("k2_b2",
                                   "Mahal amat. Di sebelah lebih murah.",
                                   "너무 비싸요. 옆집이 더 싸던데.",
                                   "마할 아맛. 디 스블라 르비 무라.",
                                   .negative,
                                   t("Jangan Bandingkan di Depan Penjual",
                                     "Menyebut lapak sebelah terdengar seperti menantang, bukan menawar.",
                                     "Penjual jadi enggan memberi harga terbaiknya untuk Anda."))
                            ]
                        )
                    ]
                )
            ),

            // ── 11:30 이발소
            stop(
                id: "week-03", seed: 303, time: "11:30", emoji: "💈",
                place: "Barbershop", placeKo: "동네 이발소",
                situation: "머리를 자릅니다. 말이 안 통하면 되돌릴 수 없어요.",
                transit: "🚶 와룽까지 3분",
                difficulty: .intermediate,
                root: me(
                    "k3_root",
                    "Mas, potong rambut ya. Rapikan saja, jangan terlalu pendek.",
                    "머리 좀 잘라 주세요. 다듬기만 하고 너무 짧게는 말고요.",
                    "마스, 뽀똥 람붓 야. 라삐깐 사자, 장안 뜨를랄루 뻰덱.",
                    .neutral,
                    t("Sebutkan Batasan, Bukan Nama Model",
                      "'Jangan terlalu pendek' lebih aman daripada nama gaya yang bisa berbeda artinya.",
                      "Batasan yang jelas mencegah kekecewaan yang tidak bisa diperbaiki hari itu juga."),
                    [
                        other(
                            "k3_a",
                            "Siap. Sampingnya dinaikkan sedikit boleh?",
                            "네. 옆머리는 조금 올려도 될까요?",
                            "시압. 삼삥냐 디나이깐 스디낏 볼레?",
                            .positive, nil,
                            [
                                me("k3_a1",
                                   "Boleh, tapi jangan pakai mesin ya. Pakai gunting saja.",
                                   "네, 근데 바리캉은 쓰지 마세요. 가위로만요.",
                                   "볼레, 따삐 장안 빠까이 므신 야. 빠까이 군띵 사자.",
                                   .positive,
                                   t("Setuju Plus Satu Syarat",
                                     "Menerima saran ahli sambil menahan satu hal penting adalah jalan tengah terbaik.",
                                     "Anda tetap dapat hasil yang diinginkan tanpa terdengar rewel.")),
                                me("k3_a2",
                                   "Terserah Mas saja, yang penting rapi.",
                                   "알아서 해 주세요, 단정하기만 하면 돼요.",
                                   "뜨르스라 마스 사자, 양 쁜띵 라삐.",
                                   .negative,
                                   t("Menyerahkan Sepenuhnya",
                                     "'Terserah' memang santai, tapi hasilnya bisa jauh dari bayangan Anda.",
                                     "Untuk layanan yang tidak bisa diulang, sebutkan minimal satu batasan."))
                            ]
                        ),
                        other(
                            "k3_b",
                            "Antre dua orang dulu ya, sekitar dua puluh menit.",
                            "앞에 두 분 계세요, 20분쯤 걸려요.",
                            "안뜨레 두아 오랑 둘루 야, 스끼따르 두아 뿔루 므닛.",
                            .neutral, nil,
                            [
                                me("k3_b1",
                                   "Oke, saya tunggu. Biasanya ramai jam segini ya?",
                                   "네, 기다릴게요. 이 시간엔 원래 붐비나요?",
                                   "오께, 사야 뚱구. 비아사냐 라마이 잠 스기니 야?",
                                   .positive,
                                   t("Isi Waktu Tunggu dengan Obrolan",
                                     "Menunggu adalah kesempatan small talk terbaik, bukan waktu yang terbuang.",
                                     "Obrolan santai membuat Anda jadi pelanggan yang diingat, bukan sekadar antrean.")),
                                me("k3_b2",
                                   "Wah, lama. Saya balik lagi nanti deh.",
                                   "오래 걸리네요. 나중에 다시 올게요.",
                                   "와, 라마. 사야 발릭 라기 난띠 데.",
                                   .negative,
                                   t("Pergi Tanpa Menyebut Waktu",
                                     "Boleh saja pergi, tapi sebutkan kapan Anda kembali.",
                                     "Tanpa waktu, tukang cukur tidak bisa menyimpan giliran untuk Anda."))
                            ]
                        )
                    ]
                )
            ),

            // ── 13:00 와룽
            stop(
                id: "week-04", seed: 304, time: "13:00", emoji: "🍢",
                place: "Warung Makan", placeKo: "동네 와룽 점심",
                situation: "반찬 이름을 모릅니다. 물어보는 것도 대화의 시작이에요.",
                transit: "🛵 카페까지 10분",
                root: other(
                    "k4_root",
                    "Makan di sini atau bungkus, Kak?",
                    "여기서 드세요, 아니면 포장이세요?",
                    "마깐 디 시니 아따우 붕꾸스, 깍?",
                    .neutral,
                    t("Dua Pilihan Standar",
                      "Di warung, pertanyaan pertama hampir selalu ini. Siapkan jawabannya sebelum masuk.",
                      "Jawaban cepat membuat antrean warung tetap mengalir dan Anda tidak gugup."),
                    [
                        me(
                            "k4_a",
                            "Makan di sini. Sayur yang itu apa ya, Bu?",
                            "여기서 먹을게요. 저 나물은 뭐예요?",
                            "마깐 디 시니. 사유르 양 이뚜 아빠 야, 부?",
                            .positive,
                            t("Tanya Nama Makanan",
                              "Menanyakan nama masakan adalah cara termudah memulai obrolan di warung.",
                              "Pemilik warung bangga menjelaskan masakan buatannya sendiri."),
                            [
                                other("k4_a1",
                                      "Itu sayur asem. Cocok sama ikan asin, mau coba?",
                                      "그건 사유르 아슴이에요. 자반 생선이랑 잘 어울려요, 드셔 볼래요?",
                                      "이뚜 사유르 아슴. 쪼쪽 사마 이깐 아신, 마우 쪼바?",
                                      .positive),
                                other("k4_a2",
                                      "Oh itu tumis kangkung. Baru matang tadi, masih hangat.",
                                      "아 그건 깡꿍 볶음이에요. 방금 해서 아직 따뜻해요.",
                                      "오 이뚜 뚜미스 깡꿍. 바루 마땅 따디, 마시 항앗.",
                                      .positive)
                            ]
                        ),
                        me(
                            "k4_b",
                            "Bungkus saja ya, nasi ayam satu.",
                            "포장해 주세요, 나시 아얌 하나요.",
                            "붕꾸스 사자 야, 나시 아얌 사뚜.",
                            .neutral,
                            t("Pesanan Praktis Tetap Ramah",
                              "Kalau memang buru-buru, pesan singkat itu wajar. Tambahkan 'ya' di akhir.",
                              "Satu partikel kecil mengubah perintah menjadi permintaan."),
                            [
                                other("k4_b1",
                                      "Baik, nasi ayam satu. Pedasnya berapa?",
                                      "네, 나시 아얌 하나요. 맵기는 어느 정도로요?",
                                      "바익, 나시 아얌 사뚜. 쁘다스냐 브라빠?",
                                      .neutral),
                                other("k4_b2",
                                      "Siap, tunggu lima menit ya, Kak.",
                                      "알겠습니다, 5분만 기다려 주세요.",
                                      "시압, 뚱구 리마 므닛 야, 깍.",
                                      .neutral)
                            ]
                        )
                    ]
                )
            ),

            // ── 15:30 카페
            stop(
                id: "week-05", seed: 305, time: "15:30", emoji: "☕",
                place: "Kafe", placeKo: "카페에서 친구 만나기",
                situation: "약속에 늦었습니다. 첫 마디로 분위기가 정해져요.",
                transit: "🌇 야시장까지 저녁 산책",
                difficulty: .intermediate,
                root: me(
                    "k5_root",
                    "Maaf ya, aku telat. Tadi macet parah.",
                    "미안, 늦었어. 아까 엄청 막혔어.",
                    "마아프 야, 아꾸 뜰랏. 따디 마쯧 빠라.",
                    .neutral,
                    t("Minta Maaf plus Alasan Singkat",
                      "Cukup satu kalimat alasan. Penjelasan panjang justru membuat suasana makin berat.",
                      "Teman ingin segera mulai mengobrol, bukan mendengar laporan lalu lintas."),
                    [
                        other(
                            "k5_a",
                            "Santai, aku juga baru sampai. Sudah pesan?",
                            "괜찮아, 나도 방금 왔어. 주문했어?",
                            "산따이, 아꾸 주가 바루 삼빠이. 수다 쁘산?",
                            .positive, nil,
                            [
                                me("k5_a1",
                                   "Belum. Kamu mau apa? Kali ini aku yang traktir.",
                                   "아직. 뭐 마실래? 오늘은 내가 살게.",
                                   "블룸. 까무 마우 아빠? 깔리 이니 아꾸 양 뜨락띠르.",
                                   .positive,
                                   t("Tawarkan Traktir Ringan",
                                     "Menawarkan membayar setelah membuat teman menunggu adalah gestur kecil yang manis.",
                                     "Gestur kecil menutup rasa bersalah tanpa perlu drama.")),
                                me("k5_a2",
                                   "Belum. Di sini yang enak apa? Kamu kan sering ke sini.",
                                   "아직. 여기 뭐가 맛있어? 너 자주 오잖아.",
                                   "블룸. 디 시니 양 에낙 아빠? 까무 깐 스링 끄 시니.",
                                   .positive,
                                   t("Serahkan Keahlian ke Teman",
                                     "Mengakui teman lebih tahu adalah pujian yang tidak terdengar seperti pujian.",
                                     "Orang senang menjadi ahli di hadapan temannya sendiri."))
                            ]
                        ),
                        other(
                            "k5_b",
                            "Aku sudah nunggu setengah jam, lho.",
                            "나 30분이나 기다렸어.",
                            "아꾸 수다 눙구 스뜽아 잠, 로.",
                            .negative, nil,
                            [
                                me("k5_b1",
                                   "Iya, maaf banget. Lain kali aku berangkat lebih awal.",
                                   "응, 진짜 미안해. 다음엔 더 일찍 나올게.",
                                   "이야, 마아프 방엣. 라인 깔리 아꾸 브랑깟 르비 아왈.",
                                   .positive,
                                   t("Akui Tanpa Membela Diri",
                                     "Ketika teman kesal, akui dulu. Alasan tambahan hanya memperpanjang kekesalan.",
                                     "Pengakuan singkat memulihkan suasana jauh lebih cepat daripada pembelaan.")),
                                me("k5_b2",
                                   "Kan aku sudah bilang macet. Bukan salahku.",
                                   "막혔다고 말했잖아. 내 잘못 아니야.",
                                   "깐 아꾸 수다 빌랑 마쯧. 부깐 살라꾸.",
                                   .negative,
                                   t("Membela Diri Terlalu Cepat",
                                     "Membalas kekesalan dengan pembelaan mengubah masalah kecil jadi pertengkaran.",
                                     "Yang dibutuhkan teman adalah pengakuan, bukan bukti."))
                            ]
                        )
                    ]
                )
            ),

            // ── 19:00 야시장
            stop(
                id: "week-06", seed: 306, time: "19:00", emoji: "🎪",
                place: "Pasar Malam", placeKo: "야시장 구경",
                situation: "노점 앞에서 처음 보는 사람과 자연스럽게 말을 섞습니다.",
                transit: nil,
                root: me(
                    "k6_root",
                    "Rame banget ya malam ini. Ada acara apa?",
                    "오늘 밤 진짜 붐비네요. 무슨 행사 있어요?",
                    "라메 방엣 야 말람 이니. 아다 아짜라 아빠?",
                    .neutral,
                    t("Komentari Suasana Bersama",
                      "Menyebut apa yang kalian berdua rasakan saat itu juga adalah pembuka paling alami.",
                      "Pengalaman bersama langsung menciptakan pijakan yang sama untuk mengobrol."),
                    [
                        other(
                            "k6_a",
                            "Iya, ada pasar malam sampai minggu depan. Sudah coba martabaknya?",
                            "네, 다음 주까지 야시장이에요. 마르따박 드셔 보셨어요?",
                            "이야, 아다 빠사르 말람 삼빠이 밍구 드빤. 수다 쪼바 마르따박냐?",
                            .positive, nil,
                            [
                                me("k6_a1",
                                   "Belum! Yang mana yang paling enak menurut Mas?",
                                   "아직요! 어느 게 제일 맛있어요?",
                                   "블룸! 양 마나 양 빨링 에낙 므누룻 마스?",
                                   .positive,
                                   t("Minta Rekomendasi Personal",
                                     "'Menurut kamu' membuat jawaban terasa seperti rahasia yang dibagikan khusus.",
                                     "Rekomendasi pribadi hampir selalu memicu cerita lanjutan.")),
                                me("k6_a2",
                                   "Sudah, yang cokelat keju. Antrenya panjang tapi worth it!",
                                   "먹어 봤어요, 초코 치즈요. 줄은 길었지만 그럴 만했어요!",
                                   "수다, 양 쪼끌랏 께주. 안뜨레냐 빤장 따삐 월띳!",
                                   .positive,
                                   t("Bagikan Pengalaman plus Penilaian",
                                     "Jangan berhenti di 'sudah'. Tambahkan penilaian agar ada yang bisa ditanggapi.",
                                     "Penilaian memberi lawan bicara bahan untuk setuju atau membantah, dan keduanya bagus."))
                            ]
                        ),
                        other(
                            "k6_b",
                            "Setiap malam Minggu memang begini, Kak.",
                            "토요일 밤은 원래 이래요.",
                            "스띠압 말람 밍구 메망 브기니, 깍.",
                            .neutral, nil,
                            [
                                me("k6_b1",
                                   "Pantas. Kalau mau tidak terlalu penuh, sebaiknya datang jam berapa?",
                                   "그렇군요. 덜 붐빌 때 오려면 몇 시쯤이 좋을까요?",
                                   "빤따스. 깔라우 마우 띠닥 뜨를랄루 쁘누, 스바익냐 다땅 잠 브라빠?",
                                   .positive,
                                   t("Gali Informasi Lokal",
                                     "Ubah jawaban singkat menjadi pertanyaan praktis agar percakapan berlanjut.",
                                     "Warga lokal senang membagikan 'kunci' yang hanya mereka tahu.")),
                                me("k6_b2",
                                   "Oh, gitu ya.",
                                   "아, 그렇군요.",
                                   "오, 기뚜 야.",
                                   .negative,
                                   t("Tanggapan Kosong",
                                     "Percakapan berhenti bukan karena lawan bicara diam, tapi karena Anda tidak melanjutkan.",
                                     "Satu pertanyaan kecil selalu bisa menyelamatkan obrolan yang mulai mati."))
                            ]
                        )
                    ]
                )
            )
        ]
    )
}
