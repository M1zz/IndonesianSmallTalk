import Foundation

// MARK: - All Scenarios

struct ConversationData {
    static let allScenarios: [ConversationScenario] = [
        scenarioMorning,
        scenarioWeather,
        scenarioCafe,
        scenarioWork
    ]
}

// ─────────────────────────────────────────────────
// MARK: Scenario 1: Sapaan Pagi (아침 인사)
// ─────────────────────────────────────────────────
extension ConversationData {
    static let scenarioMorning = ConversationScenario(
        title: "Sapaan Pagi",
        titleKo: "아침 인사",
        description: "Berlatih percakapan ringan di pagi hari",
        emoji: "🌅",
        root: ConversationNode(
            id: "m_root",
            speaker: .me,
            indonesian: "Selamat pagi! 😊",
            korean: "좋은 아침이에요!",
            romanization: "Sse-la-mat pa-gi",
            polarity: .neutral,
            coachTip: CoachTip(
                label: "Strategi Pembuka",
                tip: "'Selamat pagi' adalah salam yang tidak bisa ditolak. Singkat dan cerah membuat lawan bicara merasa nyaman.",
                why: "Kalimat pertama small talk harus mudah direspons."
            ),
            children: [
                // ── A: Cuaca bagus
                ConversationNode(
                    id: "m_a",
                    speaker: .other,
                    indonesian: "Selamat pagi! Cuacanya bagus ya hari ini? ☀️",
                    korean: "좋은 아침! 오늘 날씨 좋죠?",
                    romanization: "Cua-ca-nya ba-gus ya ha-ri i-ni",
                    polarity: .positive,
                    coachTip: CoachTip(
                        label: "Topik Cuaca",
                        tip: "Cuaca adalah topik small talk paling aman. Semua orang mengalami cuaca yang sama.",
                        why: "Pengalaman bersama menciptakan rasa nyaman dengan cepat."
                    ),
                    children: [
                        ConversationNode(
                            id: "m_a1",
                            speaker: .me,
                            indonesian: "Iya, cuacanya cerah sekali! Bikin semangat 🌿",
                            korean: "맞아요! 정말 맑아서 기분이 좋아요",
                            romanization: "I-ya, cua-ca-nya ce-rah se-ka-li",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Setuju + Tambahkan Perasaan",
                                tip: "Setelah setuju, tambahkan perasaan pribadi agar percakapan lebih hidup.",
                                why: "Ungkapan perasaan menciptakan kedekatan emosional."
                            ),
                            children: [
                                ConversationNode(
                                    id: "m_a1a",
                                    speaker: .other,
                                    indonesian: "Mau jalan-jalan siang nanti? 🚶",
                                    korean: "점심에 산책할래요?",
                                    romanization: "Mau ja-lan-ja-lan si-ang na-nti",
                                    polarity: .positive,
                                    coachTip: CoachTip(
                                        label: "Tawaran Kegiatan",
                                        tip: "Ketika seseorang menawarkan kegiatan bersama, itu tanda mereka tertarik menjalin hubungan.",
                                        why: "Respons positif memperkuat hubungan."
                                    ),
                                    children: [
                                        ConversationNode(
                                            id: "m_a1a1",
                                            speaker: .me,
                                            indonesian: "Boleh! Jam satu siang gimana? 😊",
                                            korean: "좋아요! 1시 어때요?",
                                            romanization: "Bo-leh! Jam sa-tu si-ang gi-ma-na",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Terima + Spesifikkan Waktu",
                                                tip: "Langsung menyebut waktu menunjukkan kesungguhan dan meningkatkan kemungkinan terlaksana.",
                                                why: "'Boleh' saja kurang, perlu tindak lanjut konkret."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_a1a2",
                                            speaker: .me,
                                            indonesian: "Hari ini ada acara. Minggu depan yuk!",
                                            korean: "오늘은 일정이 있어요. 다음 주에 해요!",
                                            romanization: "Ha-ri i-ni a-da a-ca-ra",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Menolak dengan Elegan",
                                                tip: "Tolak = 'Sekarang tidak bisa' + 'Alternatif + Niat masa depan'. Ketiganya penting agar hubungan tetap hangat.",
                                                why: "Penolakan tanpa alternatif terasa dingin dan menutup percakapan."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "m_a1b",
                                    speaker: .other,
                                    indonesian: "Pengen juga, tapi hari ini sibuk banget 😅",
                                    korean: "저도 그러고 싶은데 오늘 너무 바빠요",
                                    romanization: "Pe-ngen ju-ga, ta-pi ha-ri i-ni si-buk",
                                    polarity: .negative,
                                    coachTip: CoachTip(
                                        label: "Menerima Penolakan",
                                        tip: "Saat lawan bicara mengatakan sibuk, responslah dengan empati ringan, bukan kekecewaan.",
                                        why: "Menerima penolakan dengan anggun adalah keterampilan small talk yang penting."
                                    ),
                                    children: [
                                        ConversationNode(
                                            id: "m_a1b1",
                                            speaker: .me,
                                            indonesian: "Jalan 15 menit saja juga sudah beda rasanya! 💪",
                                            korean: "15분만 걸어도 기분이 달라져요!",
                                            romanization: "Ja-lan li-ma be-las me-nit sa-ja",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Ubah Perspektif Positif",
                                                tip: "Menawarkan 'versi kecil' dari sesuatu yang sulit dilakukan memberi harapan tanpa tekanan.",
                                                why: "Saran ringan terasa seperti dukungan, bukan paksaan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_a1b2",
                                            speaker: .me,
                                            indonesian: "Iya, kesibukan sudah jadi keseharian ya... 😔",
                                            korean: "맞아요, 바쁜 게 일상이 됐죠",
                                            romanization: "I-ya, ke-si-bu-kan su-dah ja-di ke-se-ha-ri-an",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Empati Melalui Persamaan",
                                                tip: "'Saya juga merasakan hal yang sama' membuat lawan bicara merasa tidak sendiri.",
                                                why: "Empati tanpa solusi terkadang lebih diperlukan."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "m_a2",
                            speaker: .me,
                            indonesian: "Iya! Jadi semangat mau kerja 💼",
                            korean: "맞아요! 일하고 싶은 기분이 들어요",
                            romanization: "I-ya! Ja-di se-ma-ngat mau ker-ja",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Hubungkan Cuaca dengan Aktivitas",
                                tip: "Menghubungkan cuaca dengan aktivitas sehari-hari membuat percakapan terasa natural dan relevan.",
                                why: "Percakapan yang relevan dengan kehidupan nyata lebih mudah diingat."
                            ),
                            children: [
                                ConversationNode(
                                    id: "m_a2a",
                                    speaker: .other,
                                    indonesian: "Wah, keren! Semangat ya hari ini! 😄",
                                    korean: "대단해요! 오늘 파이팅이에요!",
                                    romanization: "Wah, ke-ren! Se-ma-ngat ya",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "m_a2a1",
                                            speaker: .me,
                                            indonesian: "Makasih! Kamu juga semangat ya! ✨",
                                            korean: "감사해요! 당신도 파이팅!",
                                            romanization: "Ma-ka-sih! Ka-mu ju-ga se-ma-ngat ya",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Kembalikan Semangat",
                                                tip: "Membalas semangat dengan semangat menciptakan energi positif bersama.",
                                                why: "Saling memberi semangat mempererat hubungan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_a2a2",
                                            speaker: .me,
                                            indonesian: "Hehe, semoga saja tahan sampai sore 😅",
                                            korean: "ㅎㅎ 저녁까지 버텼으면 좋겠어요",
                                            romanization: "He-he, se-mo-ga sa-ja ta-han sam-pai so-re",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Humor Ringan",
                                                tip: "Humor kecil tentang diri sendiri terasa autentik dan membuat orang lain mudah terhubung.",
                                                why: "Humor ringan mencairkan suasana dan menciptakan kedekatan."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "m_a2b",
                                    speaker: .other,
                                    indonesian: "Cuaca memang pengaruh banget ya ke mood 🌤️",
                                    korean: "날씨가 정말 기분에 영향을 주죠",
                                    romanization: "Cua-ca me-mang pe-nga-ruh ba-nget ke mood",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "m_a2b1",
                                            speaker: .me,
                                            indonesian: "Banget! Kalau mendung, saya malah mager 😄",
                                            korean: "완전요! 흐린 날엔 집에 있고 싶어요",
                                            romanization: "Ba-nget! Ka-lau men-dung, sa-ya ma-las",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Berbagi Pengalaman Pribadi",
                                                tip: "Menceritakan pengalaman spesifik membuat percakapan lebih berwarna dan mudah diingat.",
                                                why: "Cerita personal lebih menarik dari sekadar setuju."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_a2b2",
                                            speaker: .me,
                                            indonesian: "Makanya cuaca sekarang bikin males juga kadang...",
                                            korean: "그래서 날씨가 안 좋으면 귀찮아지기도 해요",
                                            romanization: "Ma-ka-nya cua-ca se-ka-rang bi-kin ma-les",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Jujur Tentang Perasaan",
                                                tip: "Mengakui perasaan negatif dengan jujur terasa lebih autentik dibandingkan selalu berpura-pura positif.",
                                                why: "Kejujuran emosional menciptakan kepercayaan."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                ),

                // ── B: Ngantuk / Lelah
                ConversationNode(
                    id: "m_b",
                    speaker: .other,
                    indonesian: "Pagi... ngantuk banget, belum ngopi 😴",
                    korean: "아침... 너무 졸려요, 아직 커피도 못 마셨어요",
                    romanization: "Pa-gi... nga-ntuk ba-nget, be-lum ngo-pi",
                    polarity: .negative,
                    coachTip: CoachTip(
                        label: "Respons terhadap Rasa Lelah",
                        tip: "Ketika lawan bicara mengungkapkan kelelahan, empati langsung adalah prioritas utama.",
                        why: "Respons empatik membangun kepercayaan dengan cepat."
                    ),
                    children: [
                        ConversationNode(
                            id: "m_b1",
                            speaker: .me,
                            indonesian: "Sama! Kopi yuk, saya traktir ☕",
                            korean: "저도요! 커피 마셔요, 제가 살게요",
                            romanization: "Sa-ma! Ko-pi yuk, sa-ya trak-tir",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Tawaran Kecil yang Berarti",
                                tip: "Menawarkan traktir kopi adalah cara mengungkapkan empati melalui tindakan, bukan hanya kata-kata.",
                                why: "Tindakan kecil meninggalkan kesan besar."
                            ),
                            children: [
                                ConversationNode(
                                    id: "m_b1a",
                                    speaker: .other,
                                    indonesian: "Serius? Makasih banget! Kamu baik banget 😊",
                                    korean: "진짜요? 감사해요! 정말 친절하세요",
                                    romanization: "Se-ri-us? Ma-ka-sih ba-nget! Ka-mu ba-ik",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "m_b1a1",
                                            speaker: .me,
                                            indonesian: "Sama-sama! Semoga harinya lebih menyenangkan 😊",
                                            korean: "별말씀을요! 오늘 하루도 좋은 하루 되세요",
                                            romanization: "Sa-ma-sa-ma! Se-mo-ga ha-ri-nya le-bih me-nye-na-ngkan",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Tutup dengan Doa Baik",
                                                tip: "Mengakhiri dengan doa atau harapan baik meninggalkan kesan hangat yang bertahan lama.",
                                                why: "Penutup yang baik membuat orang ingin berbicara lagi."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_b1a2",
                                            speaker: .me,
                                            indonesian: "Hehe, sesama yang ngantuk harus saling bantu 😄",
                                            korean: "ㅎㅎ 졸린 사람들끼리 서로 도와야죠",
                                            romanization: "He-he, se-sa-ma yang nga-ntuk ha-rus sa-ling ban-tu",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Humor Solidaritas",
                                                tip: "Humor yang menunjukkan 'kita senasib' menciptakan rasa kebersamaan yang kuat.",
                                                why: "Tertawa bersama melelehkan kekakuan lebih cepat dari kata-kata serius."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "m_b1b",
                                    speaker: .other,
                                    indonesian: "Aduh, jangan repot-repot deh... 😅",
                                    korean: "어머, 신경 쓰지 않아도 돼요...",
                                    romanization: "A-duh, ja-ngan re-pot-re-pot deh",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "m_b1b1",
                                            speaker: .me,
                                            indonesian: "Gak repot sama sekali! Yuk sekalian 😊",
                                            korean: "전혀 번거롭지 않아요! 같이 가요",
                                            romanization: "Gak re-pot sa-ma se-ka-li! Yuk se-ka-li-an",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Perkuat Tawaran",
                                                tip: "Saat tawaran ditolak dengan sopan, perkuat dengan menegaskan bahwa itu bukan beban.",
                                                why: "Ketulusan yang diperkuat membuat tawaran lebih mudah diterima."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_b1b2",
                                            speaker: .me,
                                            indonesian: "Oh oke, lain kali ya kalau mau 😊",
                                            korean: "아, 알겠어요. 다음에 원하시면요",
                                            romanization: "Oh o-ke, la-in ka-li ya ka-lau mau",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Terima Penolakan dengan Lapang",
                                                tip: "Menerima penolakan dengan senyuman dan membuka peluang di masa depan menunjukkan kedewasaan sosial.",
                                                why: "Tidak memaksa adalah bentuk menghormati batasan orang lain."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "m_b2",
                            speaker: .me,
                            indonesian: "Aduh, saya juga! Kantuk banget pagi ini 😩",
                            korean: "어머, 저도요! 오늘 아침 너무 졸려요",
                            romanization: "A-duh, sa-ya ju-ga! Kan-tuk ba-nget",
                            polarity: .negative,
                            coachTip: CoachTip(
                                label: "Empati Langsung",
                                tip: "'Saya juga' adalah respons paling cepat untuk menciptakan rasa kebersamaan.",
                                why: "Persamaan kondisi menghilangkan jarak antar orang."
                            ),
                            children: [
                                ConversationNode(
                                    id: "m_b2a",
                                    speaker: .other,
                                    indonesian: "Haha, kita senasib! Kopi yuk 😄",
                                    korean: "ㅎㅎ 우리 같은 처지네요! 커피 마셔요",
                                    romanization: "Ha-ha, ki-ta se-na-sib! Ko-pi yuk",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "m_b2a1",
                                            speaker: .me,
                                            indonesian: "Yuk! Kopi pagi terbaik itu bareng-bareng ☕",
                                            korean: "좋아요! 같이 마시는 아침 커피가 최고죠",
                                            romanization: "Yuk! Ko-pi pa-gi ter-ba-ik i-tu ba-reng-ba-reng",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Tingkatkan Pengalaman Bersama",
                                                tip: "Menggambarkan pengalaman bersama sebagai 'yang terbaik' membuat momen terasa spesial.",
                                                why: "Kata 'bersama' menciptakan ikatan emosional yang kuat."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_b2a2",
                                            speaker: .me,
                                            indonesian: "Wah, kopi malah bikin deg-degan. Teh aja deh 😅",
                                            korean: "어, 저는 커피 마시면 두근거려요. 차 마실게요",
                                            romanization: "Wah, ko-pi ma-lah bi-kin deg-de-gan. Teh a-ja deh",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Jujur Tentang Preferensi",
                                                tip: "Mengungkapkan preferensi yang berbeda dengan jujur menunjukkan karakter yang autentik.",
                                                why: "Kejujuran tentang preferensi pribadi membuat percakapan lebih personal."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "m_b2b",
                                    speaker: .other,
                                    indonesian: "Kayaknya kita butuh liburan deh... 😔",
                                    korean: "우리 둘 다 휴가가 필요한 것 같아요",
                                    romanization: "Ka-ya-knya ki-ta bu-tuh li-bu-ran deh",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "m_b2b1",
                                            speaker: .me,
                                            indonesian: "Setuju banget! Kapan ya kita liburan? 🏖️",
                                            korean: "완전 동의해요! 언제 우리 여행가요?",
                                            romanization: "Se-tu-ju ba-nget! Ka-pan ya ki-ta li-bu-ran",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Setuju + Ajukan Rencana",
                                                tip: "Mengubah keluhan menjadi rencana positif mengangkat suasana hati keduanya.",
                                                why: "Rencana masa depan memberikan sesuatu yang ditunggu-tunggu."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "m_b2b2",
                                            speaker: .me,
                                            indonesian: "Iya sih... tapi kapan ada waktunya ya 😓",
                                            korean: "그러게요... 근데 언제 시간이 날지",
                                            romanization: "I-ya sih... ta-pi ka-pan a-da wak-tu-nya ya",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Validasi Kesulitan Bersama",
                                                tip: "Mengakui kesulitan yang sama menciptakan rasa solidaritas. Tidak perlu selalu berpikir positif.",
                                                why: "Realisme yang saling diakui lebih bermakna dari optimisme palsu."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        ),
        difficulty: .beginner
    )
}

// ─────────────────────────────────────────────────
// MARK: Scenario 2: Obrolan Cuaca (날씨 이야기)
// ─────────────────────────────────────────────────
extension ConversationData {
    static let scenarioWeather = ConversationScenario(
        title: "Obrolan Cuaca",
        titleKo: "날씨 이야기",
        description: "Percakapan sehari-hari tentang cuaca",
        emoji: "🌦️",
        root: ConversationNode(
            id: "w_root",
            speaker: .me,
            indonesian: "Panas banget ya hari ini! 🥵",
            korean: "오늘 정말 덥네요!",
            romanization: "Pa-nas ba-nget ya ha-ri i-ni",
            polarity: .neutral,
            coachTip: CoachTip(
                label: "Buka dengan Fakta Cuaca",
                tip: "Komentar cuaca yang konkret ('panas banget') lebih efektif dari sekedar 'hai'.",
                why: "Fakta spesifik lebih mudah direspons."
            ),
            children: [
                ConversationNode(
                    id: "w_a",
                    speaker: .other,
                    indonesian: "Iya! Tadi mau keluar, balik lagi masuk 😅",
                    korean: "맞아요! 나가려다가 다시 들어왔어요",
                    romanization: "I-ya! Ta-di mau ke-lu-ar, ba-lik la-gi ma-suk",
                    polarity: .negative,
                    coachTip: CoachTip(
                        label: "Cerita Relatable",
                        tip: "Cerita singkat yang lucu dan relatable langsung menciptakan kedekatan.",
                        why: "Pengalaman yang bisa dibayangkan membuat orang tertawa bersama."
                    ),
                    children: [
                        ConversationNode(
                            id: "w_a1",
                            speaker: .me,
                            indonesian: "Hahaha bener banget! Saya juga nunda keluar 😂",
                            korean: "ㅎㅎㅎ 맞아요! 저도 나가는 걸 미뤘어요",
                            romanization: "Ha-ha-ha be-ner ba-nget! Sa-ya ju-ga nun-da ke-lu-ar",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Tertawa Bersama",
                                tip: "Tertawa bersama tentang pengalaman yang sama adalah cara tercepat membangun koneksi.",
                                why: "Tawa bersama menghilangkan jarak sosial dalam hitungan detik."
                            ),
                            children: [
                                ConversationNode(
                                    id: "w_a1a",
                                    speaker: .other,
                                    indonesian: "Saya mau minum es dulu ah, kamu mau? 🧊",
                                    korean: "저 시원한 음료 마시려고요, 같이 마실래요?",
                                    romanization: "Sa-ya mau mi-num es du-lu ah, ka-mu mau",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_a1a1",
                                            speaker: .me,
                                            indonesian: "Mau banget! Es teh manis dong 🧋",
                                            korean: "너무 마시고 싶어요! 달달한 아이스티 주세요",
                                            romanization: "Mau ba-nget! Es teh ma-nis dong",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Terima dengan Antusias",
                                                tip: "Menerima tawaran dengan antusias dan menyebutkan preferensi spesifik menunjukkan keterlibatan.",
                                                why: "Spesifisitas menunjukkan bahwa kamu benar-benar ingin, bukan sekedar sopan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_a1a2",
                                            speaker: .me,
                                            indonesian: "Makasih, lagi diet gula soalnya 😅",
                                            korean: "감사해요, 요즘 당 조절 중이라서요",
                                            romanization: "Ma-ka-sih, la-gi di-et gu-la so-al-nya",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Tolak dengan Alasan Personal",
                                                tip: "Memberikan alasan personal saat menolak membuat penolakan terasa lebih hangat dan tidak menyinggung.",
                                                why: "Alasan personal membuat penolakan terasa jujur, bukan sekedar tidak mau."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "w_a1b",
                                    speaker: .other,
                                    indonesian: "Untung kantor dingin ya, AC-nya nyaman 😌",
                                    korean: "다행히 사무실은 시원해요, 에어컨이 좋아요",
                                    romanization: "Un-tung kan-tor di-ngin ya, AC-nya nya-man",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_a1b1",
                                            speaker: .me,
                                            indonesian: "Betul! Ini yang bikin betah di kantor 😄",
                                            korean: "맞아요! 이게 사무실에 있고 싶은 이유예요",
                                            romanization: "Be-tul! I-ni yang bi-kin be-tah di kan-tor",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Tambahkan Sudut Pandang Baru",
                                                tip: "Menambahkan sudut pandang baru pada topik yang sama memperkaya percakapan.",
                                                why: "Sudut pandang segar membuat obrolan tidak mentok."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_a1b2",
                                            speaker: .me,
                                            indonesian: "Iya sih, tapi AC-nya kadang terlalu dingin juga 🥶",
                                            korean: "맞긴 한데, 에어컨이 너무 세게 나올 때도 있어요",
                                            romanization: "I-ya sih, ta-pi AC-nya ka-dang ter-la-lu di-ngin",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Setuju tapi Tambahkan Nuansa",
                                                tip: "Setuju sebagian lalu menambahkan nuansa menunjukkan bahwa kamu berpikir kritis, bukan sekedar mengiyakan.",
                                                why: "Percakapan yang jujur lebih menarik daripada yang hanya setuju terus."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "w_a2",
                            speaker: .me,
                            indonesian: "Beneran, panas gini bikin mood langsung drop 😩",
                            korean: "진짜, 이렇게 더우면 기분이 바로 내려가요",
                            romanization: "Be-ne-ran, pa-nas gi-ni bi-kin mood lang-sung drop",
                            polarity: .negative,
                            coachTip: CoachTip(
                                label: "Ungkapkan Dampak Emosional",
                                tip: "Menghubungkan cuaca dengan emosi menciptakan percakapan yang lebih personal dan mudah direspon.",
                                why: "Emosi adalah jembatan terbaik menuju percakapan yang lebih dalam."
                            ),
                            children: [
                                ConversationNode(
                                    id: "w_a2a",
                                    speaker: .other,
                                    indonesian: "Setuju! Tapi anehnya saya malah lapar kalau panas 😂",
                                    korean: "동의해요! 근데 이상하게 더우면 배가 더 고파요",
                                    romanization: "Se-tu-ju! Ta-pi a-neh-nya sa-ya ma-lah la-par",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_a2a1",
                                            speaker: .me,
                                            indonesian: "Haha, sama! Makan siang yuk sekalian? 🍜",
                                            korean: "ㅎㅎ 저도요! 점심 같이 먹을까요?",
                                            romanization: "Ha-ha, sa-ma! Ma-kan si-ang yuk se-ka-li-an",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Gunakan Kesamaan sebagai Jembatan",
                                                tip: "Menemukan kesamaan (sama-sama lapar) lalu mengubahnya menjadi ajakan adalah teknik small talk yang powerful.",
                                                why: "Dari kesamaan ke ajakan adalah alur yang sangat natural."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_a2a2",
                                            speaker: .me,
                                            indonesian: "Haha serius? Saya malah hilang nafsu makan 😅",
                                            korean: "ㅎㅎ 진짜요? 저는 오히려 식욕이 없어져요",
                                            romanization: "Ha-ha se-ri-us? Sa-ya ma-lah hi-lang naf-su ma-kan",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Perbedaan yang Menarik",
                                                tip: "Mengungkapkan perbedaan reaksi dengan humor menunjukkan bahwa percakapan bisa tetap seru meski tidak sepakat.",
                                                why: "Perbedaan pendapat yang disampaikan dengan tawa justru memperkaya obrolan."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "w_a2b",
                                    speaker: .other,
                                    indonesian: "Iya, saya juga. Pengen hujan deras sekalian 🌧️",
                                    korean: "맞아요, 저도요. 차라리 비가 왔으면 좋겠어요",
                                    romanization: "I-ya, sa-ya ju-ga. Pe-ngen hu-jan de-ras se-ka-li-an",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_a2b1",
                                            speaker: .me,
                                            indonesian: "Nah iya! Hujan deras trus minum teh hangat 🍵",
                                            korean: "맞아요! 비 오면서 따뜻한 차 마시는 거요",
                                            romanization: "Nah i-ya! Hu-jan de-ras trus mi-num teh hang-at",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Gambar Skenario yang Menggoda",
                                                tip: "Menggambarkan skenario yang menyenangkan membuat lawan bicara ikut membayangkan dan merasa senang.",
                                                why: "Imajinasi bersama menciptakan kedekatan emosional."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_a2b2",
                                            speaker: .me,
                                            indonesian: "Hmm, tapi kalau hujan macet juga sih 😅",
                                            korean: "음, 근데 비 오면 차도 막히죠",
                                            romanization: "Hmm, ta-pi ka-lau hu-jan ma-cet ju-ga sih",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Realisme yang Lucu",
                                                tip: "Menambahkan konsekuensi realistis dengan cara yang ringan menunjukkan pikiran yang kritis tapi tetap menyenangkan.",
                                                why: "Realisme yang tidak berat terasa seperti humor cerdas."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                ),
                ConversationNode(
                    id: "w_b",
                    speaker: .other,
                    indonesian: "Katanya besok hujan ya? Kamu udah siap? 🌂",
                    korean: "내일 비 온다고 하더라고요. 준비됐어요?",
                    romanization: "Ka-ta-nya be-sok hu-jan ya? Ka-mu u-dah si-ap",
                    polarity: .positive,
                    coachTip: CoachTip(
                        label: "Info + Pertanyaan",
                        tip: "Memberikan informasi lalu langsung bertanya adalah cara efektif membuka percakapan yang menarik respons.",
                        why: "Pertanyaan langsung memudahkan lawan bicara untuk merespons."
                    ),
                    children: [
                        ConversationNode(
                            id: "w_b1",
                            speaker: .me,
                            indonesian: "Oh ya? Bagus dong! Panas terus ini 😅",
                            korean: "그래요? 잘 됐다! 너무 더웠으니까요",
                            romanization: "Oh ya? Ba-gus dong! Pa-nas te-rus i-ni",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Respons Positif terhadap Berita",
                                tip: "Merespons berita dengan sudut pandang positif ('bagus dong') mengangkat energi percakapan.",
                                why: "Optimisme ringan membuat orang senang berbicara dengan kamu."
                            ),
                            children: [
                                ConversationNode(
                                    id: "w_b1a",
                                    speaker: .other,
                                    indonesian: "Iya, udah lama gak hujan! Enak buat tidur 😴",
                                    korean: "맞아요, 비가 오래 안 왔었죠! 자기 좋겠어요",
                                    romanization: "I-ya, u-dah la-ma gak hu-jan! E-nak bu-at ti-dur",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_b1a1",
                                            speaker: .me,
                                            indonesian: "Beneran! Tidur hujan-hujanan terbaik 🌧️😴",
                                            korean: "진짜요! 비 오는 날 자는 게 최고예요",
                                            romanization: "Be-ne-ran! Ti-dur hu-jan-hu-ja-nan ter-ba-ik",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Perkuat dengan Superlative",
                                                tip: "Menggunakan kata 'terbaik' memperkuat persetujuan dan menambah energi positif.",
                                                why: "Superlative menciptakan momen emosional yang lebih berkesan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_b1a2",
                                            speaker: .me,
                                            indonesian: "Enak sih, tapi kalau kerja WFO tetap susah 😅",
                                            korean: "좋긴 한데, 출근해야 하면 힘들죠",
                                            romanization: "E-nak sih, ta-pi ka-lau ker-ja WFO te-tap su-sah",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Nuansa Realistis",
                                                tip: "Menambahkan sisi realistis menunjukkan bahwa kamu berpikir secara menyeluruh.",
                                                why: "Pandangan yang bernuansa lebih menarik daripada hanya setuju atau tidak setuju."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "w_b1b",
                                    speaker: .other,
                                    indonesian: "Payung kamu mana? Jangan sampai basah kuyup 😄",
                                    korean: "우산 어디 있어요? 흠뻑 젖으면 안 되죠",
                                    romanization: "Pa-yung ka-mu ma-na? Ja-ngan sam-pai ba-sah ku-yup",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_b1b1",
                                            speaker: .me,
                                            indonesian: "Udah siap! Payung saya selalu standby 😄",
                                            korean: "준비됐어요! 우산은 항상 대기 중이에요",
                                            romanization: "U-dah si-ap! Pa-yung sa-ya se-la-lu stand-by",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Tunjukkan Kesiapan",
                                                tip: "Menunjukkan bahwa kamu siap dan terorganisir menciptakan kesan yang baik.",
                                                why: "Kesiapan menunjukkan tanggung jawab dan kemandirian."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_b1b2",
                                            speaker: .me,
                                            indonesian: "Aduh, payung saya selalu ketinggalan... 😅",
                                            korean: "어머, 저는 항상 우산을 두고 와요...",
                                            romanization: "A-duh, pa-yung sa-ya se-la-lu ke-ting-ga-lan",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Akui Kelemahan dengan Humor",
                                                tip: "Mengakui kelemahan diri sendiri dengan 'aduh' yang ekspresif terasa lucu dan relatable.",
                                                why: "Kelemahan yang diakui jujur membuat orang merasa lebih dekat dengan kamu."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "w_b2",
                            speaker: .me,
                            indonesian: "Aduh, belum! Payung saya entah di mana... 😅",
                            korean: "어머, 아직요! 우산이 어디 있는지...",
                            romanization: "A-duh, be-lum! Pa-yung sa-ya en-tah di ma-na",
                            polarity: .negative,
                            coachTip: CoachTip(
                                label: "Jujur + Ekspresif",
                                tip: "Kejujuran yang ekspresif ('entah di mana') terasa lebih autentik dari jawaban formal.",
                                why: "Ekspresi diri yang natural membuat percakapan terasa hidup."
                            ),
                            children: [
                                ConversationNode(
                                    id: "w_b2a",
                                    speaker: .other,
                                    indonesian: "Haha, mau minjem payung saya? Saya bawa dua 😄",
                                    korean: "ㅎㅎ 제 우산 빌려드릴까요? 두 개 가져왔어요",
                                    romanization: "Ha-ha, mau min-jem pa-yung sa-ya? Sa-ya ba-wa dua",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_b2a1",
                                            speaker: .me,
                                            indonesian: "Wah serius? Makasih banget kamu baik! 😊",
                                            korean: "진짜요? 정말 감사해요, 친절하시네요!",
                                            romanization: "Wah se-ri-us? Ma-ka-sih ba-nget ka-mu ba-ik",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Terima Kebaikan dengan Tulus",
                                                tip: "Mengekspresikan rasa syukur yang tulus membuat pemberi kebaikan merasa dihargai.",
                                                why: "Ketulusan dalam berterima kasih mempererat hubungan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_b2a2",
                                            speaker: .me,
                                            indonesian: "Makasih, tapi gak mau ngerepotin... 😅",
                                            korean: "감사해요, 근데 폐 끼치기 싫어요...",
                                            romanization: "Ma-ka-sih, ta-pi gak mau nge-re-po-tin",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Menolak dengan Sopan",
                                                tip: "Menolak dengan alasan 'tidak mau merepotkan' menunjukkan perhatian terhadap orang lain meski menolak tawaran.",
                                                why: "Penolakan yang sopan menjaga martabat kedua belah pihak."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "w_b2b",
                                    speaker: .other,
                                    indonesian: "Haha payung saya juga sering ilang! 😂",
                                    korean: "ㅎㅎ 저도 우산 자주 잃어버려요!",
                                    romanization: "Ha-ha pa-yung sa-ya ju-ga se-ring i-lang",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "w_b2b1",
                                            speaker: .me,
                                            indonesian: "Haha kita sama! Mungkin payung punya nyawa 😂",
                                            korean: "ㅎㅎ 우리 같네요! 우산이 살아있나봐요",
                                            romanization: "Ha-ha ki-ta sa-ma! Mung-kin pa-yung pu-nya nya-wa",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Humor Imajinatif",
                                                tip: "Humor imajinatif ('payung punya nyawa') menunjukkan kreativitas dan membuat percakapan menjadi sangat menyenangkan.",
                                                why: "Humor segar dan orisinal meninggalkan kesan yang lama."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "w_b2b2",
                                            speaker: .me,
                                            indonesian: "Haha iya, kita tim pelupa juga ternyata 😅",
                                            korean: "ㅎㅎ 맞아요, 우리 둘 다 건망증 팀이네요",
                                            romanization: "Ha-ha i-ya, ki-ta tim pe-lu-pa ju-ga ter-nya-ta",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Ciptakan Identitas Bersama",
                                                tip: "Menyebut 'kita tim pelupa' menciptakan identitas bersama yang lucu dan mempererat hubungan.",
                                                why: "Identitas bersama, walau kecil, menciptakan rasa kebersamaan."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        ),
        difficulty: .beginner
    )
}

// ─────────────────────────────────────────────────
// MARK: Scenario 3: Di Kafe (카페에서)
// ─────────────────────────────────────────────────
extension ConversationData {
    static let scenarioCafe = ConversationScenario(
        title: "Di Kafe",
        titleKo: "카페에서",
        description: "Percakapan santai di kafe",
        emoji: "☕",
        root: ConversationNode(
            id: "c_root",
            speaker: .me,
            indonesian: "Eh, kamu juga suka kafe ini? ☕",
            korean: "어, 당신도 이 카페 좋아해요?",
            romanization: "Eh, ka-mu ju-ga su-ka ka-fe i-ni",
            polarity: .neutral,
            coachTip: CoachTip(
                label: "Pembuka yang Alami",
                tip: "'Eh' sebagai pembuka terasa spontan dan natural, tidak terkesan terlalu formal.",
                why: "Pembuka yang natural menurunkan kewaspadaan lawan bicara."
            ),
            children: [
                ConversationNode(
                    id: "c_a",
                    speaker: .other,
                    indonesian: "Iya! Kopinya enak banget di sini 😍",
                    korean: "네! 여기 커피가 정말 맛있어요",
                    romanization: "I-ya! Ko-pi-nya e-nak ba-nget di si-ni",
                    polarity: .positive,
                    coachTip: nil,
                    children: [
                        ConversationNode(
                            id: "c_a1",
                            speaker: .me,
                            indonesian: "Bener! Kamu biasanya pesan apa? ☕",
                            korean: "맞아요! 보통 뭐 주문해요?",
                            romanization: "Be-ner! Ka-mu bi-a-sa-nya pe-san a-pa",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Pertanyaan Preferensi",
                                tip: "Menanyakan preferensi minuman membuka topik yang ringan namun personal.",
                                why: "Preferensi personal mudah dijawab dan membuka cerita lebih dalam."
                            ),
                            children: [
                                ConversationNode(
                                    id: "c_a1a",
                                    speaker: .other,
                                    indonesian: "Cappuccino-nya! Busanya tebal banget 🎂",
                                    korean: "카푸치노요! 거품이 엄청 두꺼워요",
                                    romanization: "Cap-puc-ci-no-nya! Bu-sa-nya te-bal ba-nget",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_a1a1",
                                            speaker: .me,
                                            indonesian: "Wah, saya belum coba! Enak ya? 😮",
                                            korean: "와, 저는 아직 안 먹어봤어요! 맛있어요?",
                                            romanization: "Wah, sa-ya be-lum co-ba! E-nak ya",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Tunjukkan Keingintahuan",
                                                tip: "Mengakui belum mencoba dan menunjukkan keingintahuan membuka pintu rekomendasi yang menyenangkan.",
                                                why: "Keingintahuan yang tulus membuat orang senang berbagi."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_a1a2",
                                            speaker: .me,
                                            indonesian: "Saya lebih suka americano, kopi murni 😄",
                                            korean: "저는 아메리카노를 더 좋아해요, 순수한 커피",
                                            romanization: "Sa-ya le-bih su-ka a-me-ri-ca-no, ko-pi mur-ni",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Ungkapkan Preferensi Berbeda",
                                                tip: "Mengungkapkan preferensi yang berbeda dengan percaya diri menciptakan kontras yang menarik untuk dibahas.",
                                                why: "Perbedaan preferensi bisa menjadi awal diskusi yang seru."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "c_a1b",
                                    speaker: .other,
                                    indonesian: "Tergantung mood, kadang es kopi, kadang matcha 🍵",
                                    korean: "기분에 따라 달라요, 가끔 아이스 커피, 가끔 말차",
                                    romanization: "Ter-gan-tung mood, ka-dang es ko-pi, ka-dang mat-cha",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_a1b1",
                                            speaker: .me,
                                            indonesian: "Ooh, kamu mood drinker! Saya juga begitu 😄",
                                            korean: "오, 기분에 따라 마시는군요! 저도 그래요",
                                            romanization: "Ooh, ka-mu mood drin-ker! Sa-ya ju-ga be-gi-tu",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Buat Label Bersama",
                                                tip: "Membuat 'label' yang menyenangkan ('mood drinker') membuat obrolan lebih berkesan dan personal.",
                                                why: "Label yang kreatif menciptakan momen yang mudah diingat."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_a1b2",
                                            speaker: .me,
                                            indonesian: "Wah, saya gak bisa matcha, pahit banget 😅",
                                            korean: "와, 저는 말차 못 마셔요, 너무 써요",
                                            romanization: "Wah, sa-ya gak bi-sa mat-cha, pa-hit ba-nget",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Akui Keterbatasan Selera",
                                                tip: "Mengakui tidak bisa menikmati sesuatu dengan jujur terasa autentik dan mengundang tawa.",
                                                why: "Kejujuran tentang selera membuat orang merasa nyaman berbagi preferensinya juga."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "c_a2",
                            speaker: .me,
                            indonesian: "Iya! Terus suasananya nyaman banget buat kerja 💻",
                            korean: "맞아요! 그리고 분위기가 일하기 너무 좋아요",
                            romanization: "I-ya! Te-rus sua-sa-na-nya nya-man ba-nget bu-at ker-ja",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Tambahkan Alasan Personal",
                                tip: "Menyebutkan alasan spesifik mengapa suka tempat tersebut membuka diskusi yang lebih dalam.",
                                why: "Alasan spesifik mengundang respons yang lebih personal."
                            ),
                            children: [
                                ConversationNode(
                                    id: "c_a2a",
                                    speaker: .other,
                                    indonesian: "Bener! WiFi-nya kenceng juga 😄 Kamu WFC di sini?",
                                    korean: "맞아요! 와이파이도 빠르고요. 여기서 재택해요?",
                                    romanization: "Be-ner! Wi-fi-nya ken-ceng ju-ga. Ka-mu WFC di si-ni",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_a2a1",
                                            speaker: .me,
                                            indonesian: "Kadang-kadang, lebih produktif di sini 😊",
                                            korean: "가끔요, 여기서 더 생산적이에요",
                                            romanization: "Ka-dang-ka-dang, le-bih pro-duk-tif di si-ni",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Berbagi Pola Kerja",
                                                tip: "Berbagi cara kerja yang unik membuka topik yang menarik tentang produktivitas dan gaya hidup.",
                                                why: "Gaya kerja adalah topik yang sangat relevan di era modern."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_a2a2",
                                            speaker: .me,
                                            indonesian: "Gak, takut kecanduan kafe kalau dibiasin 😅",
                                            korean: "아니요, 습관 들면 카페 중독될까봐요",
                                            romanization: "Gak, ta-kut ke-can-du-an ka-fe ka-lau di-bi-a-sin",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Humor Tentang Kelemahan Diri",
                                                tip: "Bercanda tentang 'kecanduan kafe' menunjukkan kesadaran diri yang lucu.",
                                                why: "Self-aware humor sangat disukai karena terasa genuine."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "c_a2b",
                                    speaker: .other,
                                    indonesian: "Tapi saya susah konsentrasi kalau ramai gini 😅",
                                    korean: "근데 저는 이렇게 시끄러우면 집중이 안 돼요",
                                    romanization: "Ta-pi sa-ya su-sah kon-sen-tra-si ka-lau ra-mai gi-ni",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_a2b1",
                                            speaker: .me,
                                            indonesian: "Oh, saya malah fokus kalau ada background noise! 🎧",
                                            korean: "어, 저는 오히려 배경 소음이 있을 때 집중 돼요!",
                                            romanization: "Oh, sa-ya ma-lah fo-kus ka-lau a-da back-ground noi-se",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Perbedaan yang Menarik",
                                                tip: "Mengungkapkan perbedaan cara kerja yang menarik mengundang diskusi tentang kepribadian.",
                                                why: "Perbedaan yang autentik lebih menarik dari persetujuan kosong."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_a2b2",
                                            speaker: .me,
                                            indonesian: "Iya, tergantung mood juga sih, kadang ganggu juga 😅",
                                            korean: "맞아요, 기분에 따라 달라요, 가끔 방해될 때도 있어요",
                                            romanization: "I-ya, ter-gan-tung mood ju-ga sih, ka-dang gang-gu ju-ga",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Setuju Sebagian",
                                                tip: "Setuju sebagian menunjukkan kamu memahami kedua sisi. Lebih jujur dari sekedar mengiyakan.",
                                                why: "Persetujuan yang bernuansa lebih bermakna."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                ),
                ConversationNode(
                    id: "c_b",
                    speaker: .other,
                    indonesian: "Belum pernah ke sini, rekomendasinya apa? 😊",
                    korean: "처음 와봤는데, 뭐가 맛있어요?",
                    romanization: "Be-lum per-nah ke si-ni, re-ko-men-da-si-nya a-pa",
                    polarity: .positive,
                    coachTip: CoachTip(
                        label: "Rekomendasi = Peluang Emas",
                        tip: "Dimintai rekomendasi berarti lawan bicara mempercayai pendapat kamu. Berikan rekomendasi dengan antusias.",
                        why: "Dipercaya memberi rekomendasi adalah awal dari hubungan yang baik."
                    ),
                    children: [
                        ConversationNode(
                            id: "c_b1",
                            speaker: .me,
                            indonesian: "Coba cold brew-nya! Favoritnya banyak orang 🥤",
                            korean: "콜드브루 마셔봐요! 많은 사람들이 좋아해요",
                            romanization: "Co-ba cold brew-nya! Fa-vo-rit-nya ba-nyak o-rang",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Rekomendasi dengan Bukti Sosial",
                                tip: "Menambahkan 'favoritnya banyak orang' membuat rekomendasi terasa lebih dapat dipercaya.",
                                why: "Bukti sosial meningkatkan keyakinan orang terhadap rekomendasi."
                            ),
                            children: [
                                ConversationNode(
                                    id: "c_b1a",
                                    speaker: .other,
                                    indonesian: "Wah boleh dicoba! Makasih rekomendasinya 😊",
                                    korean: "오 해봐야겠어요! 추천 감사해요",
                                    romanization: "Wah bo-leh di-co-ba! Ma-ka-sih re-ko-men-da-si-nya",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_b1a1",
                                            speaker: .me,
                                            indonesian: "Sama-sama! Nanti kasih tahu rasanya gimana ya 😊",
                                            korean: "별말씀을요! 나중에 맛이 어땠는지 알려줘요",
                                            romanization: "Sa-ma-sa-ma! Na-nti ka-sih ta-hu ra-sa-nya gi-ma-na ya",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Buat Janji Percakapan Berikutnya",
                                                tip: "'Nanti kasih tahu' membuat alasan alami untuk percakapan di masa depan.",
                                                why: "Janji kecil adalah investasi untuk hubungan yang berkelanjutan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_b1a2",
                                            speaker: .me,
                                            indonesian: "Semoga cocok ya! Selera orang beda-beda sih 😅",
                                            korean: "맞길 바라요! 사람마다 입맛이 다르니까요",
                                            romanization: "Se-mo-ga co-cok ya! Se-le-ra o-rang be-da-be-da sih",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Tambahkan Disclaimer yang Rendah Hati",
                                                tip: "Menambahkan 'selera orang beda-beda' setelah rekomendasi menunjukkan kerendahan hati yang baik.",
                                                why: "Disclaimer rendah hati membuat rekomendasi terasa tidak memaksa."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "c_b1b",
                                    speaker: .other,
                                    indonesian: "Saya gak terlalu suka kopi yang pahit... ada lain? 😅",
                                    korean: "저는 쓴 커피를 별로 안 좋아하는데... 다른 건요?",
                                    romanization: "Sa-ya gak ter-la-lu su-ka ko-pi yang pa-hit",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_b1b1",
                                            speaker: .me,
                                            indonesian: "Oh! Kalau gitu coba caramel latte-nya 🍮 Manis!",
                                            korean: "오! 그럼 카라멜 라떼 마셔봐요. 달달해요!",
                                            romanization: "Oh! Ka-lau gi-tu co-ba ca-ra-mel lat-te-nya. Ma-nis!",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Adaptasi Rekomendasi",
                                                tip: "Menyesuaikan rekomendasi berdasarkan preferensi lawan bicara menunjukkan kamu benar-benar mendengarkan.",
                                                why: "Rekomendasi yang dipersonalisasi jauh lebih berharga."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_b1b2",
                                            speaker: .me,
                                            indonesian: "Hmm, kafe ini memang strong semua kopinya 😅",
                                            korean: "음, 이 카페 커피가 다 진하긴 해요",
                                            romanization: "Hmm, ka-fe i-ni me-mang strong se-mua ko-pi-nya",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Jujur Tentang Keterbatasan",
                                                tip: "Mengakui jika rekomendasimu mungkin tidak cocok untuk semua orang menunjukkan kejujuran.",
                                                why: "Kejujuran yang tidak dipaksakan lebih dipercaya dari antusiasme berlebihan."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "c_b2",
                            speaker: .me,
                            indonesian: "Saya juga baru coba tempat ini! Hehe 😅",
                            korean: "저도 여기 처음 와봤어요! ㅎㅎ",
                            romanization: "Sa-ya ju-ga ba-ru co-ba tem-pat i-ni! He-he",
                            polarity: .negative,
                            coachTip: CoachTip(
                                label: "Mengaku Tidak Tahu dengan Humor",
                                tip: "Mengaku tidak tahu dengan tawa ('hehe') jauh lebih menyenangkan daripada berpura-pura tahu.",
                                why: "Kejujuran yang lucu menciptakan kedekatan seketika."
                            ),
                            children: [
                                ConversationNode(
                                    id: "c_b2a",
                                    speaker: .other,
                                    indonesian: "Haha kita sama-sama newbie! Eksplor bareng yuk 😄",
                                    korean: "ㅎㅎ 우리 둘 다 처음이네요! 같이 탐색해봐요",
                                    romanization: "Ha-ha ki-ta sa-ma-sa-ma new-bie! Eks-plor ba-reng yuk",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_b2a1",
                                            speaker: .me,
                                            indonesian: "Yuk! Petualangan kafe dimulai haha 😄",
                                            korean: "좋아요! 카페 모험 시작이다 ㅎㅎ",
                                            romanization: "Yuk! Pe-tua-la-ngan ka-fe di-mu-lai ha-ha",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Gamifikasi Momen",
                                                tip: "Menyebut sesuatu yang biasa sebagai 'petualangan' membuat momen biasa terasa spesial dan menyenangkan.",
                                                why: "Framing positif mengubah situasi netral menjadi kenangan indah."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_b2a2",
                                            speaker: .me,
                                            indonesian: "Hehe oke! Asal jangan pesan yang aneh-aneh dulu 😅",
                                            korean: "ㅎㅎ 좋아요! 처음에는 너무 특이한 건 시키지 말고요",
                                            romanization: "He-he o-ke! A-sal ja-ngan pe-san yang a-neh-a-neh du-lu",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Humor Kehati-hatian",
                                                tip: "Menambahkan syarat lucu ('jangan yang aneh-aneh') membuat percakapan tetap ringan dan menyenangkan.",
                                                why: "Syarat yang disampaikan dengan tawa terasa seperti lelucon, bukan aturan."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "c_b2b",
                                    speaker: .other,
                                    indonesian: "Oh, jauh-jauh ke sini ternyata sama-sama gak tau 😂",
                                    korean: "어, 여기까지 왔는데 둘 다 모르네요 ㅎㅎ",
                                    romanization: "Oh, jauh-jauh ke si-ni ter-nya-ta sa-ma-sa-ma gak tau",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "c_b2b1",
                                            speaker: .me,
                                            indonesian: "Haha setidaknya kopinya enak! Itu yang penting 😄",
                                            korean: "ㅎㅎ 그래도 커피는 맛있으니까요! 그게 중요한 거죠",
                                            romanization: "Ha-ha se-ti-dak-nya ko-pi-nya e-nak! I-tu yang pen-ting",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Temukan Silver Lining",
                                                tip: "Menemukan hal positif di tengah situasi yang tidak ideal menunjukkan optimisme yang menyenangkan.",
                                                why: "Silver lining mengubah momen canggung menjadi kenangan yang lucu."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "c_b2b2",
                                            speaker: .me,
                                            indonesian: "Haha iya, review online kadang menyesatkan juga 😅",
                                            korean: "ㅎㅎ 맞아요, 온라인 리뷰가 가끔 과장되기도 하죠",
                                            romanization: "Ha-ha i-ya, re-view on-line ka-dang me-nye-sat-kan ju-ga",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Kritik Ringan yang Relatable",
                                                tip: "Kritik ringan terhadap hal yang banyak orang rasakan ('review online menyesatkan') menciptakan koneksi lewat pengalaman bersama.",
                                                why: "Shared frustration yang disampaikan dengan ringan mempererat hubungan."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        ),
        difficulty: .intermediate
    )
}

// ─────────────────────────────────────────────────
// MARK: Scenario 4: Di Tempat Kerja (직장에서)
// ─────────────────────────────────────────────────
extension ConversationData {
    static let scenarioWork = ConversationScenario(
        title: "Di Tempat Kerja",
        titleKo: "직장에서",
        description: "Obrolan ringan di lingkungan kerja",
        emoji: "💼",
        root: ConversationNode(
            id: "k_root",
            speaker: .me,
            indonesian: "Selamat pagi! Udah ada kerjaan banyak hari ini? 😊",
            korean: "좋은 아침이에요! 오늘 일이 많아요?",
            romanization: "Se-la-mat pa-gi! U-dah a-da ker-ja-an ba-nyak ha-ri i-ni",
            polarity: .neutral,
            coachTip: CoachTip(
                label: "Pembuka Kontekstual",
                tip: "Menanyakan tentang pekerjaan di lingkungan kerja adalah pembuka yang sangat relevan dan alami.",
                why: "Konteks yang relevan membuat pertanyaan terasa natural, bukan nosy."
            ),
            children: [
                ConversationNode(
                    id: "k_a",
                    speaker: .other,
                    indonesian: "Lumayan! Ada meeting pagi ini. Kamu? 📋",
                    korean: "꽤 있어요! 오늘 아침 회의 있어요. 당신은요?",
                    romanization: "Lu-ma-yan! A-da mee-ting pa-gi i-ni. Ka-mu",
                    polarity: .positive,
                    coachTip: nil,
                    children: [
                        ConversationNode(
                            id: "k_a1",
                            speaker: .me,
                            indonesian: "Juga ada! Semoga meetingnya produktif ya 🙏",
                            korean: "저도요! 회의가 생산적이길 바라요",
                            romanization: "Ju-ga a-da! Se-mo-ga mee-ting-nya pro-duk-tif ya",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Berbagi Pengalaman + Doa Baik",
                                tip: "Mendoakan keberhasilan orang lain menciptakan kesan yang sangat positif dan tidak memerlukan usaha besar.",
                                why: "Doa kecil yang tulus meninggalkan kesan yang lama."
                            ),
                            children: [
                                ConversationNode(
                                    id: "k_a1a",
                                    speaker: .other,
                                    indonesian: "Makasih! Kamu juga ya. Lagi project apa sekarang? 😊",
                                    korean: "감사해요! 당신도요. 지금 어떤 프로젝트 하고 있어요?",
                                    romanization: "Ma-ka-sih! Ka-mu ju-ga ya. La-gi pro-ject a-pa se-ka-rang",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_a1a1",
                                            speaker: .me,
                                            indonesian: "Lagi handle launching produk baru, seru banget! 🚀",
                                            korean: "신제품 런칭 맡고 있는데, 정말 재밌어요!",
                                            romanization: "La-gi han-dle laun-ching pro-duk ba-ru, se-ru ba-nget",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Berbagi Kegembiraan Kerja",
                                                tip: "Menggambarkan pekerjaan dengan antusias ('seru banget') menunjukkan passion yang menular.",
                                                why: "Antusiasme terhadap pekerjaan membuat orang tertarik untuk mendengar lebih."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_a1a2",
                                            speaker: .me,
                                            indonesian: "Lagi banyak deadline, agak overwhelming sih 😅",
                                            korean: "마감이 많아서 좀 벅차긴 해요",
                                            romanization: "La-gi ba-nyak dead-line, a-gak o-ver-whel-ming sih",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Jujur Tentang Beban Kerja",
                                                tip: "Mengakui beban kerja dengan jujur menunjukkan autentisitas. Orang lebih mudah terhubung dengan yang jujur.",
                                                why: "Kejujuran mengundang empati dan dukungan dari rekan kerja."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "k_a1b",
                                    speaker: .other,
                                    indonesian: "Semoga meetingnya cepat selesai haha 😄",
                                    korean: "회의가 빨리 끝나길 바라요 ㅎㅎ",
                                    romanization: "Se-mo-ga mee-ting-nya ce-pat se-le-sai ha-ha",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_a1b1",
                                            speaker: .me,
                                            indonesian: "Haha iya! Meeting panjang bisa makan energi 😄",
                                            korean: "ㅎㅎ 맞아요! 긴 회의는 에너지를 다 쓰죠",
                                            romanization: "Ha-ha i-ya! Mee-ting pan-jang bi-sa ma-kan e-ner-gi",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Validasi dengan Humor",
                                                tip: "Memvalidasi harapan orang lain dengan humor ringan menciptakan solidaritas di tempat kerja.",
                                                why: "Humor kerja yang relatable membangun team spirit yang baik."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_a1b2",
                                            speaker: .me,
                                            indonesian: "Sepertinya meeting ini agak panjang... 😔",
                                            korean: "이 회의는 좀 길 것 같아요...",
                                            romanization: "Se-per-ti-nya mee-ting i-ni a-gak pan-jang",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Ekspresikan Kekhawatiran Ringan",
                                                tip: "Berbagi kekhawatiran kecil tentang pertemuan menciptakan rasa senasib yang lucu.",
                                                why: "Keluhan ringan yang dibagi bersama mencairkan suasana kerja yang kaku."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "k_a2",
                            speaker: .me,
                            indonesian: "Wah, semangat ya meetingnya! Saya belum ada 😅",
                            korean: "와, 회의 파이팅이에요! 저는 아직 없어요",
                            romanization: "Wah, se-ma-ngat ya mee-ting-nya! Sa-ya be-lum a-da",
                            polarity: .negative,
                            coachTip: CoachTip(
                                label: "Semangat + Kontras Diri",
                                tip: "Memberikan semangat pada orang lain sambil berbagi kondisi diri sendiri menciptakan percakapan yang seimbang.",
                                why: "Kontras yang jujur membuat percakapan terasa lebih natural."
                            ),
                            children: [
                                ConversationNode(
                                    id: "k_a2a",
                                    speaker: .other,
                                    indonesian: "Enak banget! Kamu kerja santai hari ini dong 😄",
                                    korean: "좋겠다! 오늘 여유롭게 일하겠네요",
                                    romanization: "E-nak ba-nget! Ka-mu ker-ja san-tai ha-ri i-ni dong",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_a2a1",
                                            speaker: .me,
                                            indonesian: "Haha semoga! Tapi deadline tetap ada 😅",
                                            korean: "ㅎㅎ 그러길 바라요! 그래도 마감은 있어요",
                                            romanization: "Ha-ha se-mo-ga! Ta-pi dead-line te-tap a-da",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Optimis tapi Realistis",
                                                tip: "Merespons dengan optimisme tapi tetap menambahkan realita membuat kamu terkesan matang dan jujur.",
                                                why: "Keseimbangan optimisme dan realisme sangat menarik."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_a2a2",
                                            speaker: .me,
                                            indonesian: "Iya, tapi rasanya malah susah fokus kalau santai 😅",
                                            korean: "맞아요, 근데 여유로우면 오히려 집중이 안 되더라고요",
                                            romanization: "I-ya, ta-pi ra-sa-nya ma-lah su-sah fo-kus ka-lau san-tai",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Paradoks yang Relatable",
                                                tip: "Mengungkapkan paradoks yang banyak orang rasakan ('santai tapi susah fokus') langsung menciptakan koneksi.",
                                                why: "Paradoks yang relatable mengundang 'saya juga!' dari lawan bicara."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "k_a2b",
                                    speaker: .other,
                                    indonesian: "Aduh, iri deh. Meeting saya dari pagi 😓",
                                    korean: "아, 부럽다. 저는 아침부터 회의예요",
                                    romanization: "A-duh, i-ri deh. Mee-ting sa-ya da-ri pa-gi",
                                    polarity: .negative,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_a2b1",
                                            speaker: .me,
                                            indonesian: "Wah, semangat ya! Nanti traktir kopi deh 😊",
                                            korean: "와, 파이팅이에요! 나중에 커피 살게요",
                                            romanization: "Wah, se-ma-ngat ya! Na-nti trak-tir ko-pi deh",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Empati Melalui Tindakan",
                                                tip: "Menawarkan traktir kopi sebagai bentuk empati adalah cara yang konkret dan hangat.",
                                                why: "Tindakan nyata mengungkapkan kepedulian lebih dari sekadar kata."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_a2b2",
                                            speaker: .me,
                                            indonesian: "Waduh kasihan... meeting dari pagi itu berat 😔",
                                            korean: "어머 안됐다... 아침부터 회의는 힘들죠",
                                            romanization: "Wa-duh ka-si-han... mee-ting da-ri pa-gi i-tu be-rat",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Validasi Rasa Lelah",
                                                tip: "Mengakui bahwa sesuatu itu berat menunjukkan empati yang dalam terhadap kondisi orang lain.",
                                                why: "Validasi emosional membuat orang merasa dipahami, bukan dihakimi."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                ),
                ConversationNode(
                    id: "k_b",
                    speaker: .other,
                    indonesian: "Eh, kamu udah makan siang? Mau bareng gak? 🍱",
                    korean: "어, 점심 먹었어요? 같이 먹을래요?",
                    romanization: "Eh, ka-mu u-dah ma-kan si-ang? Mau ba-reng gak",
                    polarity: .positive,
                    coachTip: CoachTip(
                        label: "Ajakan Makan Siang",
                        tip: "Ajakan makan siang adalah cara paling natural mempererat hubungan di tempat kerja. Jangan lewatkan!",
                        why: "Makan bersama adalah ritual sosial terkuat di kantor."
                    ),
                    children: [
                        ConversationNode(
                            id: "k_b1",
                            speaker: .me,
                            indonesian: "Belum! Mau kemana? Saya ikut! 😊",
                            korean: "아직요! 어디 가요? 저 따라갈게요!",
                            romanization: "Be-lum! Mau ke-ma-na? Sa-ya i-kut!",
                            polarity: .positive,
                            coachTip: CoachTip(
                                label: "Terima dengan Antusias",
                                tip: "Menerima ajakan dengan antusias membuat orang yang mengajak merasa senang dan percaya dirinya.",
                                why: "Antusiasme yang tulus adalah hadiah terbaik untuk orang yang berani mengajak."
                            ),
                            children: [
                                ConversationNode(
                                    id: "k_b1a",
                                    speaker: .other,
                                    indonesian: "Ada warung nasi padang deket sini, enak! 🍛",
                                    korean: "근처에 나시 빠당 식당 있는데, 맛있어요!",
                                    romanization: "A-da wa-rung na-si pa-dang de-ket si-ni, e-nak",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_b1a1",
                                            speaker: .me,
                                            indonesian: "Asik! Nasi padang favorit saya juga 😋",
                                            korean: "좋아요! 저도 나시 빠당 제일 좋아해요",
                                            romanization: "A-sik! Na-si pa-dang fa-vo-rit sa-ya ju-ga",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Temukan Kesukaan yang Sama",
                                                tip: "Menemukan makanan favorit yang sama adalah momen bonding yang kuat dan menyenangkan.",
                                                why: "Kesamaan selera makanan menciptakan koneksi yang sangat personal."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_b1a2",
                                            speaker: .me,
                                            indonesian: "Wah, saya jarang makan pedas... tapi boleh dicoba! 😅",
                                            korean: "와, 저는 매운 거를 잘 못 먹는데... 그래도 한번 가봐요!",
                                            romanization: "Wah, sa-ya ja-rang ma-kan pe-das... ta-pi bo-leh di-co-ba",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Coba Sesuatu yang Baru",
                                                tip: "Bersedia mencoba sesuatu di luar zona nyaman menunjukkan fleksibilitas dan keberanian sosial.",
                                                why: "Mau mencoba adalah sikap yang sangat menarik dan menghargai pilihan orang lain."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "k_b1b",
                                    speaker: .other,
                                    indonesian: "Belum tau juga sih, mau cari-cari dulu? 😄",
                                    korean: "저도 아직 모르겠어요, 같이 찾아볼까요?",
                                    romanization: "Be-lum tau ju-ga sih, mau ca-ri-ca-ri du-lu",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_b1b1",
                                            speaker: .me,
                                            indonesian: "Yuk! Petualangan makan siang dimulai 😄🍴",
                                            korean: "좋아요! 점심 모험 시작이다 ㅎㅎ",
                                            romanization: "Yuk! Pe-tua-la-ngan ma-kan si-ang di-mu-lai",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Beri Framing yang Menyenangkan",
                                                tip: "Menyebut mencari makan sebagai 'petualangan' mengubah aktivitas biasa menjadi sesuatu yang ditunggu.",
                                                why: "Framing positif membuat momen biasa terasa lebih berkesan."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_b1b2",
                                            speaker: .me,
                                            indonesian: "Hmm, waktunya singkat, ada yang deket? 😅",
                                            korean: "음, 시간이 짧은데, 근처에 뭐 있어요?",
                                            romanization: "Hmm, wak-tu-nya sing-kat, a-da yang de-ket",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Praktis tapi Tetap Hangat",
                                                tip: "Mengingatkan kendala waktu dengan cara yang ringan menunjukkan kamu mempertimbangkan kebutuhan bersama.",
                                                why: "Kepraktisan yang disampaikan dengan sopan menunjukkan kesadaran situasi."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        ),
                        ConversationNode(
                            id: "k_b2",
                            speaker: .me,
                            indonesian: "Makasih, tapi tadi udah beli makan bawa sendiri 😅",
                            korean: "감사해요, 근데 아까 도시락 사왔어요",
                            romanization: "Ma-ka-sih, ta-pi ta-di u-dah be-li ma-kan ba-wa sen-di-ri",
                            polarity: .negative,
                            coachTip: CoachTip(
                                label: "Tolak dengan Hangat dan Penjelasan",
                                tip: "Memberikan penjelasan singkat saat menolak membuat penolakan terasa hangat dan tidak mengecewakan.",
                                why: "Penjelasan membuat penolakan terasa personal, bukan dingin."
                            ),
                            children: [
                                ConversationNode(
                                    id: "k_b2a",
                                    speaker: .other,
                                    indonesian: "Oh, rajin banget! Masak sendiri? 😮",
                                    korean: "오, 부지런하네요! 직접 만들었어요?",
                                    romanization: "Oh, ra-jin ba-nget! Ma-sak sen-di-ri",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_b2a1",
                                            speaker: .me,
                                            indonesian: "Iya! Lagi diet jadi masak sendiri lebih sehat 😊",
                                            korean: "네! 다이어트 중이라 직접 만드는 게 더 건강해요",
                                            romanization: "I-ya! La-gi di-et ja-di ma-sak sen-di-ri le-bih se-hat",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Berbagi Tujuan Sehat",
                                                tip: "Menyebutkan tujuan sehat secara positif mengundang dukungan dan rasa hormat.",
                                                why: "Tujuan sehat yang dibagikan sering kali menginspirasi orang lain."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_b2a2",
                                            speaker: .me,
                                            indonesian: "Haha enggak, beli di warung deket rumah 😅",
                                            korean: "ㅎㅎ 아니요, 집 근처 식당에서 샀어요",
                                            romanization: "Ha-ha eng-gak, be-li di wa-rung de-ket ru-mah",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Koreksi Asumsi dengan Humor",
                                                tip: "Mengoreksi asumsi yang terlalu tinggi dengan tawa menunjukkan kerendahan hati yang autentik.",
                                                why: "Tidak berpura-pura lebih dari yang sebenarnya adalah tanda kepercayaan diri yang sehat."
                                            ),
                                            children: []
                                        )
                                    ]
                                ),
                                ConversationNode(
                                    id: "k_b2b",
                                    speaker: .other,
                                    indonesian: "Oh sayang deh, besok bareng ya kalau bisa! 😊",
                                    korean: "아쉽다, 내일은 같이 가요!",
                                    romanization: "Oh sa-yang deh, be-sok ba-reng ya ka-lau bi-sa",
                                    polarity: .positive,
                                    coachTip: nil,
                                    children: [
                                        ConversationNode(
                                            id: "k_b2b1",
                                            speaker: .me,
                                            indonesian: "Iya! Besok saya gak bawa bekal, jadi boleh! 😊",
                                            korean: "네! 내일은 도시락 안 싸와요, 같이 가요!",
                                            romanization: "I-ya! Be-sok sa-ya gak ba-wa be-kal, ja-di bo-leh",
                                            polarity: .positive,
                                            coachTip: CoachTip(
                                                label: "Konfirmasi Rencana Masa Depan",
                                                tip: "Mengkonfirmasi rencana besok dengan spesifik menunjukkan komitmen dan membuat orang senang.",
                                                why: "Konfirmasi konkret jauh lebih bermakna dari 'iya kapan-kapan'."
                                            ),
                                            children: []
                                        ),
                                        ConversationNode(
                                            id: "k_b2b2",
                                            speaker: .me,
                                            indonesian: "Boleh! Tapi tergantung deadline juga sih 😅",
                                            korean: "좋아요! 근데 마감이 없을 때만요 ㅎㅎ",
                                            romanization: "Bo-leh! Ta-pi ter-gan-tung dead-line ju-ga sih",
                                            polarity: .negative,
                                            coachTip: CoachTip(
                                                label: "Setuju Bersyarat",
                                                tip: "Menerima ajakan dengan syarat yang realistis menunjukkan kejujuran. Lebih baik dari janji kosong.",
                                                why: "Janji realistis lebih dihargai daripada konfirmasi berlebihan yang tidak ditepati."
                                            ),
                                            children: []
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        ),
        difficulty: .advanced
    )
}
