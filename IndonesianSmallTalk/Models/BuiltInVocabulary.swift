import Foundation

/// 출장 100단어 — 처음 실행 시 VocabularyStore가 시딩하는 기본 데이터셋.
/// 사용자가 삭제/편집해도 되며, "기본값으로 복원" 시 이 목록으로 다시 채움.
///
/// - tier 1: 필수 (인사·긍정부정·부탁·의문사·핵심동사·필수식당장소시간정도)
/// - tier 2: 편의 (식당·교통·시간·숫자 세부)
/// - tier 3: 자연스러움 (호칭 변형·비즈니스·추임새·접속사)
enum BuiltInVocabulary {
    static let seedItems: [VocabWord] = [
        // MARK: - 1-6 인사·호칭
        VocabWord(
            indonesian: "halo / hai", korean: "안녕",
            romanization: "할로 / 하이",
            category: "인사·호칭",
            examples: [
                VocabExample("Halo, apa kabar?", "안녕, 잘 지내요?"),
                VocabExample("Hai, senang bertemu kamu.", "안녕, 만나서 반가워요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "selamat pagi / siang / sore / malam",
            korean: "아침/낮/오후/밤 인사",
            romanization: "슬라맛 빠기 / 시앙 / 소레 / 말람",
            category: "인사·호칭",
            notes: "pagi(아침)/siang(점심)/sore(오후)/malam(저녁) 시간대별 인사",
            examples: [
                VocabExample("Selamat pagi, Pak!", "안녕하세요 (아침), 사장님!"),
                VocabExample("Selamat malam, sampai besok.", "잘 자요, 내일 봬요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "selamat datang", korean: "환영합니다",
            romanization: "슬라맛 다땅",
            category: "인사·호칭",
            notes: "호텔·식당에서 듣는 말",
            examples: [
                VocabExample("Selamat datang di Jakarta.", "자카르타에 오신 걸 환영합니다."),
                VocabExample("Selamat datang di hotel kami.", "저희 호텔에 어서 오세요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "sampai jumpa / sampai besok",
            korean: "다음에 봬요 / 내일 봬요",
            romanization: "삼빠이 줌빠 / 베속",
            category: "인사·호칭",
            examples: [
                VocabExample("Sampai jumpa nanti.", "이따 봐요."),
                VocabExample("Sampai besok pagi!", "내일 아침에 봐요!")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "Bapak / Ibu (Pak / Bu)",
            korean: "선생님 / 사장님",
            romanization: "바빡 / 이부 (빡 / 부)",
            category: "인사·호칭",
            notes: "남자(Pak)/여자(Bu) 격식 호칭",
            examples: [
                VocabExample("Pak, ada waktu sebentar?", "사장님, 잠깐 시간 있으세요?"),
                VocabExample("Terima kasih, Bu.", "감사합니다, 사모님.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "Mas / Mbak", korean: "형/누나뻘 호칭",
            romanization: "마스 / 음박",
            category: "인사·호칭",
            notes: "식당·카페 직원에게 — Mas(남)/Mbak(여)",
            examples: [
                VocabExample("Mas, minta menu dong.", "(점원분), 메뉴 좀 주세요."),
                VocabExample("Mbak, di sini ada Wi-Fi?", "(점원분), 여기 와이파이 있어요?")
            ],
            tier: 3
        ),

        // MARK: - 7-13 긍정·부정·확인
        VocabWord(
            indonesian: "ya / iya", korean: "네",
            romanization: "야 / 이야",
            category: "긍정·부정·확인",
            examples: [
                VocabExample("Ya, saya mengerti.", "네, 이해했어요."),
                VocabExample("Iya, betul.", "네, 맞아요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "tidak / nggak / gak", korean: "아니",
            romanization: "띠닥 / 응각 / 각",
            category: "긍정·부정·확인",
            notes: "동사·형용사 부정. nggak/gak는 구어체.",
            examples: [
                VocabExample("Saya tidak mau pedas.", "저 매운 거 싫어요."),
                VocabExample("Gak apa-apa.", "괜찮아요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "bukan", korean: "아니다",
            romanization: "부깐",
            category: "긍정·부정·확인",
            notes: "명사 부정에만 — '아니에요'",
            examples: [
                VocabExample("Saya bukan orang Jepang.", "저는 일본 사람이 아니에요."),
                VocabExample("Itu bukan punya saya.", "그거 제 거 아니에요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "sudah / udah", korean: "이미, 다 됐다",
            romanization: "수다 / 우다",
            category: "긍정·부정·확인",
            examples: [
                VocabExample("Saya sudah makan.", "저 이미 먹었어요."),
                VocabExample("Udah, terima kasih.", "됐어요, 감사합니다.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "belum", korean: "아직 안",
            romanization: "블룸",
            category: "긍정·부정·확인",
            notes: "부드러운 거절 — 명백한 'tidak'보다 완곡",
            examples: [
                VocabExample("Saya belum makan.", "저 아직 안 먹었어요."),
                VocabExample("Belum siap, Pak.", "아직 준비 안 됐어요, 사장님.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "betul / benar", korean: "맞아요",
            romanization: "브뚤 / 브나르",
            category: "긍정·부정·확인",
            examples: [
                VocabExample("Betul, jam dua sore.", "맞아요, 오후 2시예요."),
                VocabExample("Apakah ini benar?", "이게 맞아요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "salah", korean: "틀렸어요",
            romanization: "살라",
            category: "긍정·부정·확인",
            examples: [
                VocabExample("Maaf, saya salah.", "죄송합니다, 제가 틀렸어요."),
                VocabExample("Kalau salah, tolong koreksi.", "틀리면 고쳐주세요.")
            ],
            tier: 2
        ),

        // MARK: - 14-18 부탁·사과·감사
        VocabWord(
            indonesian: "terima kasih / makasih", korean: "감사합니다",
            romanization: "뜨리마 까씨 / 마까씨",
            category: "부탁·사과·감사",
            notes: "makasih는 구어체 줄임",
            examples: [
                VocabExample("Terima kasih banyak.", "정말 감사합니다."),
                VocabExample("Makasih ya!", "고마워요!")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "sama-sama", korean: "천만에요",
            romanization: "사마사마",
            category: "부탁·사과·감사",
            examples: [
                VocabExample("A: Terima kasih. B: Sama-sama.", "A: 감사합니다. B: 천만에요."),
                VocabExample("Sama-sama, Pak.", "천만에요, 사장님.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "maaf", korean: "미안합니다 / 실례합니다",
            romanization: "마앞",
            category: "부탁·사과·감사",
            examples: [
                VocabExample("Maaf, saya terlambat.", "죄송합니다, 늦었어요."),
                VocabExample("Maaf, mengganggu.", "실례합니다 (방해해서).")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "permisi", korean: "실례합니다 (지나갈 때)",
            romanization: "뻐르미시",
            category: "부탁·사과·감사",
            notes: "지나갈 때·말 걸 때 사용",
            examples: [
                VocabExample("Permisi, saya mau lewat.", "실례합니다, 좀 지나갈게요."),
                VocabExample("Permisi, di mana toilet?", "실례합니다, 화장실 어디예요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "tolong", korean: "부탁합니다",
            romanization: "똘롱",
            category: "부탁·사과·감사",
            notes: "✨ tolong + 동사 = 마법 공식",
            examples: [
                VocabExample("Tolong panggil taksi.", "택시 좀 불러주세요."),
                VocabExample("Tolong bicara pelan-pelan.", "천천히 말씀해 주세요.")
            ],
            tier: 1
        ),

        // MARK: - 19-25 의문사
        VocabWord(
            indonesian: "apa", korean: "무엇",
            romanization: "아빠",
            category: "의문사",
            examples: [
                VocabExample("Ini apa?", "이거 뭐예요?"),
                VocabExample("Apa nama makanan ini?", "이 음식 이름이 뭐예요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "siapa", korean: "누구",
            romanization: "시아빠",
            category: "의문사",
            examples: [
                VocabExample("Siapa nama Anda?", "성함이 어떻게 되세요?"),
                VocabExample("Itu siapa?", "저 사람 누구예요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "di mana", korean: "어디 (위치)",
            romanization: "디 마나",
            category: "의문사",
            examples: [
                VocabExample("Di mana stasiun?", "역이 어디예요?"),
                VocabExample("Di mana saya bisa beli tiket?", "어디서 표를 살 수 있어요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "ke mana", korean: "어디로",
            romanization: "끄 마나",
            category: "의문사",
            examples: [
                VocabExample("Mau ke mana, Pak?", "어디 가세요? (택시기사 멘트)"),
                VocabExample("Saya mau ke bandara.", "저 공항으로 가요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "kapan", korean: "언제",
            romanization: "까빤",
            category: "의문사",
            examples: [
                VocabExample("Kapan rapatnya?", "회의 언제예요?"),
                VocabExample("Kapan kamu pulang?", "언제 돌아가요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "kenapa", korean: "왜",
            romanization: "끄나빠",
            category: "의문사",
            examples: [
                VocabExample("Kenapa macet?", "왜 막히죠?"),
                VocabExample("Kenapa terlambat?", "왜 늦었어요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "berapa", korean: "얼마 / 몇",
            romanization: "브라빠",
            category: "의문사",
            examples: [
                VocabExample("Berapa harganya?", "얼마예요?"),
                VocabExample("Jam berapa sekarang?", "지금 몇 시예요?")
            ],
            tier: 1
        ),

        // MARK: - 26-37 동사·조동사
        VocabWord(
            indonesian: "bisa", korean: "할 수 있다",
            romanization: "비사",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya bisa bicara sedikit.", "저 조금 말할 수 있어요."),
                VocabExample("Bisa pakai kartu?", "카드 되나요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "mau", korean: "원하다 / ~할 거다",
            romanization: "마우",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya mau nasi goreng.", "나시고렝 주세요."),
                VocabExample("Mau ke mana?", "어디 가실 거예요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "ada", korean: "있다",
            romanization: "아다",
            category: "동사·조동사",
            examples: [
                VocabExample("Ada Wi-Fi?", "와이파이 있어요?"),
                VocabExample("Tidak ada masalah.", "문제없어요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "punya", korean: "가지다",
            romanization: "뿐야",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya punya reservasi.", "저 예약 있어요."),
                VocabExample("Anda punya kembalian?", "거스름돈 있으세요?")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "tahu / tau", korean: "알다",
            romanization: "따우",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya tidak tahu.", "저 몰라요."),
                VocabExample("Anda tahu jalannya?", "길 아세요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "boleh", korean: "해도 된다",
            romanization: "볼레",
            category: "동사·조동사",
            examples: [
                VocabExample("Boleh saya foto?", "사진 찍어도 돼요?"),
                VocabExample("Boleh masuk?", "들어가도 돼요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "harus", korean: "해야 한다",
            romanization: "하루스",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya harus pergi sekarang.", "저 지금 가야 해요."),
                VocabExample("Harus bayar dulu.", "먼저 결제하셔야 돼요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "minta", korean: "달라고 하다",
            romanization: "민따",
            category: "동사·조동사",
            notes: "minta + 명사 = ~ 주세요",
            examples: [
                VocabExample("Minta air putih.", "생수 주세요."),
                VocabExample("Minta bonnya, Pak.", "계산서 주세요, 사장님.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "mengerti / ngerti", korean: "이해하다",
            romanization: "믕어르띠 / 응어르띠",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya tidak mengerti.", "이해 못 했어요."),
                VocabExample("Ngerti, Pak.", "알겠습니다, 사장님.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "lihat", korean: "보다",
            romanization: "리핫",
            category: "동사·조동사",
            examples: [
                VocabExample("Boleh saya lihat?", "좀 봐도 돼요?"),
                VocabExample("Lihat ke kanan.", "오른쪽 보세요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "dengar", korean: "듣다",
            romanization: "등아르",
            category: "동사·조동사",
            examples: [
                VocabExample("Saya tidak dengar.", "안 들려요."),
                VocabExample("Tolong dengar baik-baik.", "잘 들어주세요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "bicara / ngomong", korean: "말하다",
            romanization: "비짜라 / 응오몽",
            category: "동사·조동사",
            examples: [
                VocabExample("Tolong bicara pelan-pelan.", "천천히 말씀해 주세요."),
                VocabExample("Saya tidak bisa ngomong banyak.", "저 많이 못 말해요.")
            ],
            tier: 2
        ),

        // MARK: - 38-46 숫자·가격
        VocabWord(
            indonesian: "satu, dua, tiga", korean: "1, 2, 3",
            romanization: "사뚜, 두아, 띠가",
            category: "숫자·가격",
            examples: [
                VocabExample("Untuk dua orang.", "두 사람용이에요."),
                VocabExample("Tiga gelas teh, ya.", "차 세 잔 주세요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "empat, lima", korean: "4, 5",
            romanization: "음빳, 리마",
            category: "숫자·가격",
            examples: [
                VocabExample("Lima ribu rupiah.", "5천 루피아예요."),
                VocabExample("Empat hari di Bali.", "발리에서 4일.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "enam, tujuh, delapan, sembilan, sepuluh",
            korean: "6, 7, 8, 9, 10",
            romanization: "으남, 뚜주, 들라빤, 슴빌란, 스뿔루",
            category: "숫자·가격",
            examples: [
                VocabExample("Sepuluh menit lagi.", "10분 후에요."),
                VocabExample("Tujuh malam, ya.", "저녁 7시요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "ribu", korean: "천 (1,000)",
            romanization: "리부",
            category: "숫자·가격",
            notes: "인니어는 천 단위가 기본 — lima ribu = 5천 루피아",
            examples: [
                VocabExample("Lima puluh ribu rupiah.", "5만 루피아예요."),
                VocabExample("Seratus ribu, mahal sekali.", "10만 루피아, 너무 비싸요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "juta", korean: "백만 (1,000,000)",
            romanization: "주따",
            category: "숫자·가격",
            examples: [
                VocabExample("Satu juta rupiah.", "1백만 루피아."),
                VocabExample("HP ini lima juta.", "이 폰은 5백만이에요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "uang / duit", korean: "돈",
            romanization: "우앙 / 두잇",
            category: "숫자·가격",
            notes: "duit는 구어체",
            examples: [
                VocabExample("Saya tidak punya uang cash.", "저 현금 없어요."),
                VocabExample("Berapa duit semuanya?", "다 합쳐서 얼마예요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "mahal", korean: "비싸다",
            romanization: "마할",
            category: "숫자·가격",
            examples: [
                VocabExample("Terlalu mahal!", "너무 비싸요!"),
                VocabExample("Mahal sekali, ya?", "너무 비싸지 않아요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "murah", korean: "싸다",
            romanization: "무라",
            category: "숫자·가격",
            examples: [
                VocabExample("Yang lebih murah, ada?", "더 싼 거 있어요?"),
                VocabExample("Ini lumayan murah.", "이거 꽤 싸네요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "diskon", korean: "할인",
            romanization: "디스꼰",
            category: "숫자·가격",
            notes: "영어 discount 차용어",
            examples: [
                VocabExample("Ada diskon?", "할인 있어요?"),
                VocabExample("Diskon dua puluh persen.", "20% 할인.")
            ],
            tier: 2
        ),

        // MARK: - 47-57 식당·음식
        VocabWord(
            indonesian: "makan", korean: "먹다",
            romanization: "마깐",
            category: "식당·음식",
            examples: [
                VocabExample("Mau makan apa?", "뭐 드실래요?"),
                VocabExample("Saya sudah makan.", "저 이미 먹었어요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "minum", korean: "마시다",
            romanization: "미눔",
            category: "식당·음식",
            examples: [
                VocabExample("Mau minum apa?", "뭐 드실래요? (음료)"),
                VocabExample("Saya minum kopi.", "저 커피 마실게요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "lapar", korean: "배고프다",
            romanization: "라빠르",
            category: "식당·음식",
            examples: [
                VocabExample("Saya lapar sekali.", "저 너무 배고파요."),
                VocabExample("Sudah lapar?", "배고프세요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "kenyang", korean: "배부르다",
            romanization: "끄냥",
            category: "식당·음식",
            examples: [
                VocabExample("Saya sudah kenyang.", "저 배불러요."),
                VocabExample("Kenyang banget!", "엄청 배부르네!")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "enak", korean: "맛있다 / 좋다",
            romanization: "으낙",
            category: "식당·음식",
            notes: "용도 무한 — 맛·기분·몸 컨디션 등",
            examples: [
                VocabExample("Enak banget!", "엄청 맛있어요!"),
                VocabExample("Tidak enak badan.", "몸이 안 좋아요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "pedas", korean: "맵다",
            romanization: "쁘다스",
            category: "식당·음식",
            notes: "한국인 카드 — 매운 거 좋아한다고 해도 인니 매운맛은 강력함",
            examples: [
                VocabExample("Tolong jangan pedas.", "맵게 하지 말아주세요."),
                VocabExample("Sedikit pedas saja.", "조금만 매워요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "manis / asin / asam / pahit",
            korean: "달다 / 짜다 / 시다 / 쓰다",
            romanization: "마니스 / 아신 / 아삼 / 빠힛",
            category: "식당·음식",
            examples: [
                VocabExample("Terlalu manis untuk saya.", "저한테는 너무 달아요."),
                VocabExample("Asin sekali, kurangi garam.", "너무 짜요, 소금 줄여주세요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "air", korean: "물",
            romanization: "아이르",
            category: "식당·음식",
            notes: "air putih = 생수",
            examples: [
                VocabExample("Minta air putih.", "생수 주세요."),
                VocabExample("Air panas, ada?", "뜨거운 물 있어요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "kopi / teh", korean: "커피 / 차",
            romanization: "꼬삐 / 떼",
            category: "식당·음식",
            examples: [
                VocabExample("Satu kopi susu, ya.", "라떼(연유커피) 하나요."),
                VocabExample("Teh tarik, dua gelas.", "테타릭 두 잔.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "nasi", korean: "밥",
            romanization: "나시",
            category: "식당·음식",
            notes: "nasi goreng(볶음밥), nasi padang(파당식 밥)",
            examples: [
                VocabExample("Nasi goreng satu.", "나시고렝 하나요."),
                VocabExample("Nasi padang, enak banget.", "나시빠당, 엄청 맛있어요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "bayar", korean: "계산하다",
            romanization: "바야르",
            category: "식당·음식",
            notes: "minta bill / mau bayar = 계산할게요",
            examples: [
                VocabExample("Mau bayar.", "계산할게요."),
                VocabExample("Bayar pakai kartu, bisa?", "카드로 결제 돼요?")
            ],
            tier: 1
        ),

        // MARK: - 58-65 교통
        VocabWord(
            indonesian: "pergi", korean: "가다",
            romanization: "뻐르기",
            category: "교통",
            examples: [
                VocabExample("Mau pergi ke mana?", "어디 가세요?"),
                VocabExample("Saya pergi sekarang.", "저 지금 갈게요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "pulang", korean: "돌아가다",
            romanization: "뿔랑",
            category: "교통",
            examples: [
                VocabExample("Saya mau pulang ke hotel.", "호텔로 돌아갈게요."),
                VocabExample("Kapan pulang ke Korea?", "한국에 언제 돌아가세요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "datang", korean: "오다",
            romanization: "다땅",
            category: "교통",
            examples: [
                VocabExample("Taksinya sudah datang.", "택시가 도착했어요."),
                VocabExample("Saya baru datang dari Korea.", "저 한국에서 막 왔어요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "jalan", korean: "길 / 걷다",
            romanization: "잘란",
            category: "교통",
            notes: "jalan kaki = 걸어서",
            examples: [
                VocabExample("Jalan kaki saja.", "걸어서 갈게요."),
                VocabExample("Jalannya macet sekali.", "길이 너무 막혀요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "macet", korean: "차 막힘",
            romanization: "마쩻",
            category: "교통",
            notes: "자카르타 일상 단어",
            examples: [
                VocabExample("Lagi macet parah, Pak.", "지금 엄청 막혀요, 사장님."),
                VocabExample("Jakarta selalu macet.", "자카르타는 항상 막혀요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "taksi / ojek / Grab / Gojek",
            korean: "택시 / 오토바이 택시 / 앱",
            romanization: "딱시 / 오젝 / 그랍 / 고젝",
            category: "교통",
            notes: "Grab/Gojek은 동남아 차량 호출 앱",
            examples: [
                VocabExample("Tolong panggil taksi.", "택시 좀 불러주세요."),
                VocabExample("Pakai Grab saja.", "그랩 부르죠.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "bandara", korean: "공항",
            romanization: "반다라",
            category: "교통",
            examples: [
                VocabExample("Ke bandara, ya.", "공항으로 가주세요."),
                VocabExample("Bandara Soekarno-Hatta.", "수카르노-하타 공항.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "stasiun", korean: "역",
            romanization: "스따시운",
            category: "교통",
            examples: [
                VocabExample("Di mana stasiun MRT?", "MRT 역 어디예요?"),
                VocabExample("Stasiun terdekat di mana?", "가장 가까운 역 어디예요?")
            ],
            tier: 2
        ),

        // MARK: - 66-73 장소·방향
        VocabWord(
            indonesian: "di sini", korean: "여기",
            romanization: "디 시니",
            category: "장소·방향",
            examples: [
                VocabExample("Di sini saja, Pak.", "여기서 내려주세요."),
                VocabExample("Di sini ada lift?", "여기 엘리베이터 있어요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "di sana", korean: "저기",
            romanization: "디 사나",
            category: "장소·방향",
            examples: [
                VocabExample("Toiletnya di sana.", "화장실은 저기예요."),
                VocabExample("Lihat, di sana.", "봐요, 저기.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "dekat", korean: "가깝다",
            romanization: "드깟",
            category: "장소·방향",
            examples: [
                VocabExample("Hotelnya dekat dari sini?", "호텔이 여기서 가까워요?"),
                VocabExample("Restoran dekat sini.", "근처 식당.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "jauh", korean: "멀다",
            romanization: "자우",
            category: "장소·방향",
            notes: "택시 흥정 필수 — '멀어요?' 묻기",
            examples: [
                VocabExample("Jauh tidak?", "멀어요?"),
                VocabExample("Terlalu jauh untuk jalan kaki.", "걸어가기엔 너무 멀어요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "kanan / kiri", korean: "오른쪽 / 왼쪽",
            romanization: "까난 / 끼리",
            category: "장소·방향",
            examples: [
                VocabExample("Belok kanan di depan.", "앞에서 우회전하세요."),
                VocabExample("Pintunya di sebelah kiri.", "문은 왼쪽에 있어요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "lurus", korean: "직진",
            romanization: "루루스",
            category: "장소·방향",
            examples: [
                VocabExample("Lurus saja, ya.", "직진하세요."),
                VocabExample("Jalan lurus terus.", "쭉 직진.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "belok", korean: "돌다 (꺾다)",
            romanization: "블록",
            category: "장소·방향",
            examples: [
                VocabExample("Belok kiri di lampu merah.", "신호등에서 좌회전."),
                VocabExample("Belok kanan, lalu lurus.", "우회전, 그리고 직진.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "lantai", korean: "층",
            romanization: "란따이",
            category: "장소·방향",
            examples: [
                VocabExample("Kamar saya lantai dua.", "제 방은 2층이에요."),
                VocabExample("Lantai berapa?", "몇 층이에요?")
            ],
            tier: 2
        ),

        // MARK: - 74-80 시간
        VocabWord(
            indonesian: "sekarang", korean: "지금",
            romanization: "스까랑",
            category: "시간",
            examples: [
                VocabExample("Sekarang jam berapa?", "지금 몇 시예요?"),
                VocabExample("Saya sibuk sekarang.", "저 지금 바빠요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "nanti", korean: "이따가",
            romanization: "난띠",
            category: "시간",
            notes: "거절 클리셰 — 'nanti aja'(나중에)",
            examples: [
                VocabExample("Nanti aja, ya.", "나중에 봐요."),
                VocabExample("Telpon saya nanti.", "이따가 전화해 주세요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "tadi", korean: "아까",
            romanization: "따디",
            category: "시간",
            examples: [
                VocabExample("Tadi pagi sudah makan.", "아침에 이미 먹었어요."),
                VocabExample("Yang tadi siapa?", "방금 그 사람 누구예요?")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "besok", korean: "내일",
            romanization: "베속",
            category: "시간",
            examples: [
                VocabExample("Besok jam sembilan.", "내일 9시예요."),
                VocabExample("Sampai besok, ya!", "내일 봬요!")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "kemarin", korean: "어제",
            romanization: "끄마린",
            category: "시간",
            examples: [
                VocabExample("Kemarin saya ke pantai.", "어제 해변에 갔어요."),
                VocabExample("Yang kemarin sudah selesai.", "어제 거 다 끝났어요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "hari ini", korean: "오늘",
            romanization: "하리 이니",
            category: "시간",
            examples: [
                VocabExample("Hari ini ada rapat.", "오늘 회의 있어요."),
                VocabExample("Cuaca hari ini panas sekali.", "오늘 날씨 너무 더워요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "jam berapa?", korean: "몇 시?",
            romanization: "잠 브라빠",
            category: "시간",
            notes: "jam 9 pagi = 오전 9시",
            examples: [
                VocabExample("Jam berapa rapatnya?", "회의 몇 시예요?"),
                VocabExample("Sekarang jam tiga sore.", "지금 오후 3시예요.")
            ],
            tier: 2
        ),

        // MARK: - 81-88 호텔·비즈니스
        VocabWord(
            indonesian: "kamar", korean: "방",
            romanization: "까마르",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Kamar nomor tiga ratus dua.", "302호."),
                VocabExample("Mau ganti kamar.", "방 바꾸고 싶어요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "kunci", korean: "열쇠 / 키",
            romanization: "꾼찌",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Kuncinya hilang.", "열쇠 잃어버렸어요."),
                VocabExample("Minta kunci kamar.", "방 카드 키 주세요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "kantor", korean: "사무실",
            romanization: "깐또르",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Kantor saya di Jakarta.", "제 사무실은 자카르타에 있어요."),
                VocabExample("Mau ke kantor sekarang.", "지금 사무실 가요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "rapat / meeting", korean: "회의",
            romanization: "라빳 / 미띵",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Rapat jam dua siang.", "회의 오후 2시."),
                VocabExample("Meeting hari ini jam berapa?", "오늘 미팅 몇 시예요?")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "janji", korean: "약속",
            romanization: "잔지",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Saya ada janji jam empat.", "저 4시에 약속 있어요."),
                VocabExample("Sudah janji kemarin.", "어제 이미 약속했어요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "sibuk", korean: "바쁘다",
            romanization: "시북",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Lagi sibuk, maaf.", "지금 바빠요, 죄송."),
                VocabExample("Hari ini sibuk sekali.", "오늘 너무 바빠요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "selesai", korean: "끝났다 / 다 됐다",
            romanization: "슬르사이",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Sudah selesai.", "다 끝났어요."),
                VocabExample("Kapan selesainya?", "언제 끝나요?")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "mulai", korean: "시작하다",
            romanization: "물라이",
            category: "호텔·비즈니스",
            examples: [
                VocabExample("Rapat mulai jam berapa?", "회의 몇 시에 시작해요?"),
                VocabExample("Mulai sekarang.", "지금 시작.")
            ],
            tier: 3
        ),

        // MARK: - 89-94 정도·상태
        VocabWord(
            indonesian: "sekali / banget", korean: "매우",
            romanization: "스깔리 / 방엇",
            category: "정도·상태",
            notes: "sekali는 격식, banget는 구어체 — 형용사 뒤에 붙음",
            examples: [
                VocabExample("Enak banget!", "엄청 맛있어요!"),
                VocabExample("Mahal sekali.", "너무 비싸요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "sedikit / dikit", korean: "조금",
            romanization: "스디낏 / 디낏",
            category: "정도·상태",
            examples: [
                VocabExample("Saya bicara sedikit.", "저 조금 말할 수 있어요."),
                VocabExample("Pedas dikit aja, ya.", "조금만 매워요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "terlalu", korean: "너무 (과하게)",
            romanization: "뜨를랄루",
            category: "정도·상태",
            examples: [
                VocabExample("Terlalu mahal.", "너무 비싸요."),
                VocabExample("Terlalu pedas untuk saya.", "저한테는 너무 매워요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "panas / dingin", korean: "덥다 / 춥다",
            romanization: "빠나스 / 딩인",
            category: "정도·상태",
            examples: [
                VocabExample("Panas sekali hari ini.", "오늘 너무 더워요."),
                VocabExample("AC-nya terlalu dingin.", "에어컨이 너무 추워요.")
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "capek", korean: "피곤하다",
            romanization: "짜뻭",
            category: "정도·상태",
            examples: [
                VocabExample("Saya capek sekali.", "저 너무 피곤해요."),
                VocabExample("Capek setelah meeting.", "미팅 끝나고 피곤하네요.")
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "sakit", korean: "아프다",
            romanization: "사낏",
            category: "정도·상태",
            examples: [
                VocabExample("Saya sakit perut.", "배가 아파요."),
                VocabExample("Kepala saya sakit.", "머리가 아파요.")
            ],
            tier: 2
        ),

        // MARK: - 95-100 추임새·접속사
        VocabWord(
            indonesian: "dan / atau / tapi",
            korean: "그리고 / 또는 / 그런데",
            romanization: "단 / 아따우 / 따삐",
            category: "추임새·접속사",
            examples: [
                VocabExample("Saya mau kopi dan teh.", "커피랑 차 주세요."),
                VocabExample("Mau kopi atau teh?", "커피요, 아니면 차요?")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "karena / soalnya", korean: "왜냐하면",
            romanization: "까르나 / 소알냐",
            category: "추임새·접속사",
            notes: "karena 격식 / soalnya 구어",
            examples: [
                VocabExample("Saya tidak bisa karena sibuk.", "바빠서 못 해요."),
                VocabExample("Soalnya saya capek.", "저 피곤해서요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "jadi", korean: "그래서",
            romanization: "자디",
            category: "추임새·접속사",
            examples: [
                VocabExample("Jadi, kita ke mana?", "그래서 우리 어디 가요?"),
                VocabExample("Macet, jadi terlambat.", "막혀서 늦었어요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "kalau", korean: "만약 ~라면",
            romanization: "깔라우",
            category: "추임새·접속사",
            examples: [
                VocabExample("Kalau hujan, di hotel saja.", "비 오면 호텔에 있죠."),
                VocabExample("Kalau bisa, jam tiga.", "가능하면 3시요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "juga", korean: "~도 (또한)",
            romanization: "주가",
            category: "추임새·접속사",
            examples: [
                VocabExample("Saya juga.", "저도요."),
                VocabExample("Saya mau yang ini juga.", "저도 이거 주세요.")
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "dong / sih / kok / nih",
            korean: "어조 입자 (의미 약함)",
            romanization: "동 / 시 / 꼭 / 니",
            category: "추임새·접속사",
            notes: "의미는 약하지만 빼면 외국인 말투 — 듣기로 익혀두기",
            examples: [
                VocabExample("Mahal banget dong!", "너무 비싸잖아요!", level: .casual),
                VocabExample("Kok mahal sih?", "왜 비싸지?", level: .casual)
            ],
            tier: 3
        ),

        // MARK: - v2 회화 뼈대 보강 (인칭 · 시제 · 비교 · 담화 표지)

        // 1인칭/2인칭/3인칭 — HTML 회화 뼈대 01 인칭 대명사
        VocabWord(
            indonesian: "saya / aku", korean: "나",
            romanization: "사야 / 아꾸",
            category: "인사·호칭",
            notes: "saya=격식 기본값(출장 안전), aku=친구·또래·연인. 친해진 후 전환",
            examples: [
                VocabExample("Saya senang bertemu Bapak.", "만나서 반갑습니다, 사장님.", level: .formal),
                VocabExample("Aku capek banget hari ini.", "오늘 진짜 피곤해.", level: .casual)
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "Anda / kamu", korean: "당신 / 너",
            romanization: "안다 / 까무",
            category: "인사·호칭",
            notes: "Anda=거리감 있는 격식(광고·문서), kamu=친구. 보통은 Bapak/Ibu로 대체",
            examples: [
                VocabExample("Anda tinggal di mana?", "어디에 사세요?", level: .formal),
                VocabExample("Kamu sudah makan?", "너 밥 먹었어?", level: .casual)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "dia / beliau", korean: "그/그녀 / 그분",
            romanization: "디아 / 블리아우",
            category: "인사·호칭",
            notes: "dia=성별 구분 없음(무난), beliau=존경하는 사람(상사·어른)",
            examples: [
                VocabExample("Dia kolega saya dari Jakarta.", "그분 자카르타에서 온 동료예요.", level: .neutral),
                VocabExample("Beliau direktur kami.", "그분이 저희 디렉터십니다.", level: .formal)
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "kita / kami", korean: "우리 (포함 / 제외)",
            romanization: "끼따 / 까미",
            category: "인사·호칭",
            notes: "한국어에 없는 구분 — kita=듣는 사람 포함, kami=듣는 사람 제외",
            examples: [
                VocabExample("Kita berangkat bersama, Pak.", "우리 같이 출발해요. (상대 포함)", level: .formal),
                VocabExample("Kami sudah pesan kamar dari Korea.", "저희끼리 한국에서 미리 예약했어요. (상대 제외)", level: .neutral)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "mereka", korean: "그들",
            romanization: "므레까",
            category: "인사·호칭",
            examples: [
                VocabExample("Mereka sedang rapat.", "그들 회의 중이에요.", level: .neutral),
                VocabExample("Mereka semua dari kantor pusat.", "다들 본사에서 왔어요.", level: .neutral)
            ],
            tier: 3
        ),

        // 시제 표지어 — HTML 04
        VocabWord(
            indonesian: "sedang / lagi", korean: "~하는 중",
            romanization: "스당 / 라기",
            category: "동사·조동사",
            notes: "sedang=격식, lagi=구어(훨씬 흔함). 동사 앞에 붙임",
            examples: [
                VocabExample("Saya sedang bekerja, Pak.", "저 일하는 중입니다, 사장님.", level: .formal),
                VocabExample("Lagi makan, nanti telpon balik ya.", "지금 먹는 중, 이따 다시 걸어줘.", level: .casual)
            ],
            tier: 1
        ),
        VocabWord(
            indonesian: "akan / bakal", korean: "~할 것이다",
            romanization: "아깐 / 바깔",
            category: "동사·조동사",
            notes: "akan=격식 미래, bakal=구어 미래(예상). mau도 같은 역할",
            examples: [
                VocabExample("Akan berangkat besok pagi.", "내일 아침에 출발합니다.", level: .formal),
                VocabExample("Bakal hujan kayaknya.", "비 올 것 같아.", level: .casual)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "pernah", korean: "~한 적 있다",
            romanization: "쁘르나",
            category: "동사·조동사",
            notes: "경험 — 'belum pernah'(아직 안 해봤어요)도 자주 씀",
            examples: [
                VocabExample("Pernah ke Bali?", "발리 가본 적 있어요?", level: .neutral),
                VocabExample("Belum pernah coba.", "아직 안 해봤어요.", level: .neutral)
            ],
            tier: 2
        ),

        // 비교 표현 — HTML 09
        VocabWord(
            indonesian: "lebih", korean: "더",
            romanization: "르비",
            category: "정도·상태",
            notes: "lebih + 형용사 = 더 ~한",
            examples: [
                VocabExample("Yang lebih murah, ada?", "더 싼 거 있어요?", level: .neutral),
                VocabExample("Lebih baik daripada kemarin.", "어제보다 좋아요.", level: .neutral)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "paling / ter-", korean: "가장 / 제일",
            romanization: "빨링 / 떠르-",
            category: "정도·상태",
            notes: "paling=일상, ter-=접두사 격식 (paling enak = terenak)",
            examples: [
                VocabExample("Paling enak di sini.", "여기가 제일 맛있어요.", level: .neutral),
                VocabExample("Restoran terenak di Jakarta.", "자카르타에서 가장 맛있는 식당.", level: .formal)
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "daripada / sama saja", korean: "~보다 / 똑같다",
            romanization: "다리빠다 / 사마 사자",
            category: "정도·상태",
            notes: "daripada=비교 기준(~보다), sama saja=똑같다",
            examples: [
                VocabExample("Lebih murah daripada yang lain.", "다른 거보다 싸요.", level: .neutral),
                VocabExample("Sama saja, Pak.", "똑같아요, 사장님.", level: .neutral)
            ],
            tier: 3
        ),

        // 캐주얼 전치사 — HTML 10
        VocabWord(
            indonesian: "buat / sama / kayak", korean: "캐주얼 전치사 3종",
            romanization: "부앗 / 사마 / 까약",
            category: "추임새·접속사",
            notes: "buat=untuk(~위해), sama=dengan(~와), kayak=seperti(~처럼). 격식 자리에선 원래 형태 사용",
            examples: [
                VocabExample("Ini buat kamu.", "이거 너 줄게.", level: .casual),
                VocabExample("Sama teman aja.", "친구랑 같이 (갈게).", level: .casual),
                VocabExample("Kayak ini, ya?", "이거처럼 하는 거지?", level: .casual)
            ],
            tier: 3
        ),

        // 담화 표지 — HTML 14
        VocabWord(
            indonesian: "sebenarnya / sebenernya", korean: "사실은",
            romanization: "스브나르냐 / 스브너르냐",
            category: "추임새·접속사",
            notes: "본론·반대 의견 꺼낼 때 — 격식/구어 형태",
            examples: [
                VocabExample("Sebenarnya saya sudah ada janji.", "사실 저 약속이 있어서요.", level: .formal),
                VocabExample("Sebenernya tuh, aku lagi capek.", "사실 나 지금 피곤해.", level: .casual)
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "kayaknya / sepertinya", korean: "~인 것 같다",
            romanization: "까약냐 / 스쁘르띠냐",
            category: "추임새·접속사",
            notes: "추측·완곡 — 직접적 단정 피할 때(인니 문화 코어)",
            examples: [
                VocabExample("Sepertinya akan hujan.", "비가 올 것 같습니다.", level: .formal),
                VocabExample("Kayaknya bakal macet.", "막힐 것 같아.", level: .casual)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "kan / iya kan / beneran", korean: "확인·강조 추임새",
            romanization: "깐 / 이야 깐 / 브너란",
            category: "추임새·접속사",
            notes: "kan=그렇지?, iya kan=맞지?, beneran=진짜로. 캐주얼 회화 양념",
            examples: [
                VocabExample("Mahal banget kan?", "엄청 비싸지 않아?", level: .casual),
                VocabExample("Beneran enak banget!", "진짜 너무 맛있어!", level: .casual),
                VocabExample("Iya kan, lagi macet parah.", "그치, 지금 엄청 막혀.", level: .casual)
            ],
            tier: 3
        ),

        // 캐주얼 조동사 — HTML 07
        VocabWord(
            indonesian: "pengen / kudu", korean: "~하고 싶다 / 해야 한다 (캐주얼)",
            romanization: "쁭언 / 꾸두",
            category: "동사·조동사",
            notes: "pengen=mau의 캐주얼, kudu=harus의 캐주얼. 친구 사이 회식·잡담",
            examples: [
                VocabExample("Pengen tidur banget.", "진짜 자고 싶다.", level: .casual),
                VocabExample("Kudu cepet, udah telat.", "빨리 해야 해, 이미 늦었어.", level: .casual)
            ],
            tier: 3
        ),

        // 시간 보강 — HTML 11
        VocabWord(
            indonesian: "lusa", korean: "모레",
            romanization: "루사",
            category: "시간",
            examples: [
                VocabExample("Lusa saya berangkat.", "모레 저 출발해요.", level: .neutral),
                VocabExample("Rapatnya lusa pagi.", "회의는 모레 아침이에요.", level: .neutral)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "barusan", korean: "방금",
            romanization: "바루산",
            category: "시간",
            examples: [
                VocabExample("Barusan datang.", "방금 도착했어요.", level: .neutral),
                VocabExample("Barusan dia telpon.", "방금 그 사람이 전화했어요.", level: .neutral)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "sebentar / bentar", korean: "잠깐",
            romanization: "스븐따르 / 븐따르",
            category: "시간",
            notes: "sebentar=격식, bentar=구어 축약",
            examples: [
                VocabExample("Tunggu sebentar, Pak.", "잠깐만 기다려주세요, 사장님.", level: .formal),
                VocabExample("Bentar ya.", "잠깐만.", level: .casual)
            ],
            tier: 2
        ),

        // 장소 보강 — HTML 12 ('거기' 빠져있었음)
        VocabWord(
            indonesian: "di situ", korean: "거기",
            romanization: "디 시뚜",
            category: "장소·방향",
            notes: "여기(di sini)와 저기(di sana) 사이 — 한국어 '거기'와 1:1",
            examples: [
                VocabExample("Ada di situ, Pak.", "거기 있어요, 사장님.", level: .neutral),
                VocabExample("Tunggu di situ saja.", "거기서 기다리세요.", level: .neutral)
            ],
            tier: 3
        ),

        // 감정·의견 + 의문사 보강 — HTML 13, 05
        VocabWord(
            indonesian: "suka / tidak suka", korean: "좋아하다 / 싫어하다",
            romanization: "수까 / 띠닥 수까",
            category: "정도·상태",
            notes: "한국인 카드 — 'tidak suka pedas'(매운 거 싫어요)는 식당 필수",
            examples: [
                VocabExample("Saya suka makanan ini.", "이 음식 좋아해요.", level: .neutral),
                VocabExample("Gak suka pedas.", "매운 거 싫어해.", level: .casual)
            ],
            tier: 2
        ),
        VocabWord(
            indonesian: "misalnya", korean: "예를 들어",
            romanization: "미살냐",
            category: "추임새·접속사",
            examples: [
                VocabExample("Misalnya nasi goreng atau sate.", "예를 들어 나시고렝이나 사테요.", level: .neutral),
                VocabExample("Misalnya kalau hujan, gimana?", "예를 들어 비 오면 어떡해요?", level: .neutral)
            ],
            tier: 3
        ),
        VocabWord(
            indonesian: "gimana", korean: "어떻게 (구어)",
            romanization: "기마나",
            category: "의문사",
            notes: "bagaimana의 구어 축약 — 일상에서 압도적으로 자주 쓰임",
            examples: [
                VocabExample("Gimana kabarnya?", "어떻게 지내?", level: .casual),
                VocabExample("Gimana kalau besok aja?", "내일 가는 건 어때?", level: .casual)
            ],
            tier: 2
        ),
    ]
}
