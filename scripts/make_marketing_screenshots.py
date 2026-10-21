#!/usr/bin/env python3
"""마케팅 스크린샷 목업 생성: HTML 생성 → 헤드리스 Chrome 렌더링.

슬라이드마다 layout 이 달라 배치가 다양함:
  hero-bleed  : 헤드라인 상단 중앙 + 정면 대형 폰, 하단 블리드
  left-text   : 좌측 정렬 텍스트 + 오른쪽으로 기운 폰
  text-bottom : 폰 상단 + 텍스트 하단
  flat-rotate : 평면 회전(-5°) 폰, 하단 블리드
  dark        : 다크 배경 반전 + 정면 폰
"""
import subprocess, sys, pathlib

# 말문 — 언어마다 원본(raw/<언어>/)에 헤드라인을 얹어 marketing/<언어>/ 로 만든다.
# 원본 캡처: scripts/capture_store_screenshots.sh   실행: python3 scripts/make_marketing_screenshots.py [언어 ...]
ROOT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "screenshots"
WORK = pathlib.Path("/tmp/malmun-marketing")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1284, 2778          # 레이아웃이 이 크기에 맞춰져 있다 → 그린 뒤 제출 규격으로 줄인다
OUT_W, OUT_H = 1242, 2688  # App Store Connect 제출 규격

FILES = ["01-home.png", "02-practice.png", "03-drive.png", "04-script.png", "05-pronunciation.png"]
LAYOUT_OF = ["hero-bleed", "left-text", "dark", "text-bottom", "flat-rotate"]

# (헤드라인, 서브카피) — 언어마다 따로 쓴 문구. 번역하지 말고 그 나라 말로.
COPY = {
    "ko": [("말문이 트이는<br>외국어 회화", "6개 언어 중 골라 배우세요"),
           ("고르면서 익히는<br>진짜 대화", "대답을 골라 대화를 이어 가요"),
           ("퇴근길 차 안에서<br>귀로 연습", "뜻 듣고, 말해 보고, 정답 듣기"),
           ("대화 전체를<br>메신저처럼", "누르면 그 문장을 들려줘요"),
           ("따라 말하면<br>점수로 알려줘요", "발음 연습과 연습 기록까지")],
    "en": [("Find your voice<br>in 6 languages", "Real small talk, one line at a time"),
           ("Practice real<br>conversations", "Pick a reply and keep the talk going"),
           ("Practice by ear<br>on your commute", "Hear it, say it, check it. Hands-free."),
           ("Read every dialogue<br>like a chat", "Tap any line to hear it"),
           ("Say it,<br>get a score", "Pronunciation drills and practice history")],
    "es": [("Suelta la lengua<br>en 6 idiomas", "Conversaciones reales, frase a frase"),
           ("Practica<br>conversaciones reales", "Elige tu respuesta y sigue la charla"),
           ("Practica de oído<br>en el auto", "Escucha, dilo y compruébalo. Sin manos."),
           ("Lee cada diálogo<br>como un chat", "Toca una frase para escucharla"),
           ("Repite y recibe<br>tu puntuación", "Pronunciación e historial de práctica")],
    "id": [("Lancar ngobrol<br>dalam 6 bahasa", "Percakapan nyata, kalimat demi kalimat"),
           ("Latihan percakapan<br>sungguhan", "Pilih jawaban, lanjutkan obrolan"),
           ("Latihan lewat telinga<br>di mobil", "Dengar, ucapkan, cek. Tanpa tangan."),
           ("Baca dialog<br>seperti chat", "Ketuk kalimat untuk mendengarnya"),
           ("Tirukan,<br>lihat skornya", "Latihan pelafalan dan riwayat latihan")],
    "ja": [("6か国語で、<br>話せる自分に", "リアルな会話を一文ずつ"),
           ("選んで身につく<br>実践会話", "返事を選んで会話を進めよう"),
           ("通勤の車で、<br>耳で練習", "聞いて、言って、答え合わせ。手は使わない"),
           ("会話の流れを<br>チャットのように", "タップでその文を再生"),
           ("まねして話すと<br>点数でわかる", "発音練習と練習記録")],
    "zh-Hans": [("6种语言，<br>开口就说", "真实对话，一句一句练"),
                ("边选边学的<br>真实对话", "选择回答，让对话继续"),
                ("通勤开车，<br>用耳朵练习", "听、说、对答案，全程免手"),
                ("像聊天一样<br>看完整对话", "点一下就能听这句话"),
                ("跟读就能<br>看到分数", "发音练习和练习记录")],
    "pt-BR": [("Fale sem travar<br>em 6 idiomas", "Conversas reais, uma frase de cada vez"),
              ("Pratique conversas<br>de verdade", "Escolha uma resposta e siga o papo"),
              ("Treine de ouvido<br>no trajeto", "Ouça, fale e confira. Sem usar as mãos."),
              ("Leia cada diálogo<br>como num chat", "Toque numa frase para ouvir"),
              ("Repita e receba<br>uma nota", "Prática de pronúncia e histórico")],
    "fr": [("Osez parler<br>6 langues", "Du vrai small talk, phrase après phrase"),
           ("Des conversations<br>pour de vrai", "Choisissez une réponse et poursuivez l’échange"),
           ("Entraînez-vous à l’oreille<br>sur la route", "Écoutez, dites, vérifiez. Mains libres."),
           ("Chaque dialogue<br>comme un chat", "Touchez une phrase pour l’écouter"),
           ("Répétez,<br>obtenez un score", "Prononciation et historique d’entraînement")],
    "de": [("Trau dich zu sprechen<br>in 6 Sprachen", "Echter Smalltalk, Zeile für Zeile"),
           ("Echte Gespräche<br>üben", "Antwort wählen und im Gespräch bleiben"),
           ("Auf dem Heimweg<br>mit den Ohren üben", "Hören, sprechen, prüfen. Freihändig."),
           ("Jeden Dialog lesen<br>wie einen Chat", "Zeile antippen und anhören"),
           ("Sprich es aus,<br>erhalte Punkte", "Ausspracheübung und Übungsverlauf")],
    "ru": [("Заговорите<br>на 6 языках", "Живой разговор — реплика за репликой"),
           ("Реальные диалоги<br>для практики", "Выбирайте ответ и ведите разговор дальше"),
           ("Тренируйтесь на слух<br>в дороге", "Услышал, сказал, проверил. Без рук."),
           ("Читайте диалог<br>как переписку", "Нажмите на реплику, чтобы услышать её"),
           ("Повторите —<br>и узнайте оценку", "Произношение и история практики")],
    "zh-Hant": [("6 種語言，<br>開口就能說", "真實對話，一句一句練"),
                ("邊選邊學的<br>真實對話", "選個回答，讓對話繼續"),
                ("通勤開車，<br>用耳朵練習", "聽、說、對答案，全程不用動手"),
                ("像聊天一樣<br>看完整段對話", "點一下就能聽這一句"),
                ("跟著說，<br>馬上看到分數", "發音練習與練習紀錄")],
    "en-GB": [("Find your voice<br>in 6 languages", "Real small talk, one line at a time"),
              ("Practise real<br>conversations", "Pick a reply and keep the chat going"),
              ("Practise by ear<br>on your commute", "Hear it, say it, check it. Hands-free."),
              ("Read every dialogue<br>like a chat", "Tap any line to hear it"),
              ("Say it,<br>get a score", "Pronunciation drills and practice history")],
}

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#EEF0FB; font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", "Hiragino Sans", "PingFang SC", sans-serif; position:relative; }}
.headline {{ font-size:100px; font-weight:800; color:#1E2978; letter-spacing:-2px; line-height:1.22; }}
.sub {{ font-size:52px; font-weight:500; color:#6B7090; letter-spacing:-0.5px; }}
.phone {{ background:#17171a; border-radius:116px; border:3px solid #3a3a3e; padding:25px;
  box-shadow: 60px 90px 120px rgba(30,41,120,.25), 20px 30px 50px rgba(0,0,0,.16); }}
.phone img {{ width:100%; display:block; border-radius:92px; }}
"""

LAYOUTS = {
    # 1) 정면 대형, 하단 블리드
    "hero-bleed": """
.headline { text-align:center; margin-top:290px; padding:0 70px; }
.sub { text-align:center; margin-top:52px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:1000px; }
""",
    # 2) 좌측 정렬 텍스트 + 오른쪽 기울기, 오른쪽 블리드
    "left-text": """
.headline { text-align:left; margin:300px 0 0 110px; }
.sub { text-align:left; margin:48px 0 0 114px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:300px; top:990px; }
.phone { width:840px; transform:rotateY(16deg) rotateX(2deg); }
""",
    # 3) 폰 상단, 텍스트 하단
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:170px; }
.phone { width:880px; transform:rotateY(-10deg) rotateX(2deg); }
.headline { text-align:center; margin-top:120px; padding:0 70px; }
.sub { text-align:center; margin-top:48px; }
""",
    # 4) 평면 회전, 좌측 치우침 + 하단 블리드
    "flat-rotate": """
.headline { text-align:center; margin-top:270px; padding:0 70px; }
.sub { text-align:center; margin-top:52px; }
.wrap { position:absolute; left:120px; top:1010px; }
.phone { width:1010px; transform:rotate(-6deg); }
""",
    # 5) 다크 배경 반전 + 정면
    "dark": """
body { background:#1E2978; }
.headline { color:#ffffff; text-align:center; margin-top:290px; padding:0 70px; }
.sub { color:#FFB547; text-align:center; margin-top:52px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:930px; border-color:#48484e;
  box-shadow: 0 0 160px rgba(80,140,255,.22), 40px 70px 110px rgba(0,0,0,.55); }
""",
}

# text-bottom 은 폰이 먼저 오는 DOM 순서
BODY_TEXT_FIRST = '<div class="headline">{headline}</div><div class="sub">{sub}</div><div class="wrap"><div class="phone"><img src="{img}"></div></div>'
BODY_PHONE_FIRST = '<div class="wrap"><div class="phone"><img src="{img}"></div></div><div class="headline">{headline}</div><div class="sub">{sub}</div>'

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
{base}{layout}
</style></head><body>{body}</body></html>"""

def main(langs):
    from PIL import Image
    WORK.mkdir(exist_ok=True)
    for lang in langs:
        src = ROOT / "raw" / lang
        out = ROOT / "marketing" / lang
        out.mkdir(parents=True, exist_ok=True)
        for fname, layout, (headline, sub) in zip(FILES, LAYOUT_OF, COPY[lang]):
            body_tpl = BODY_PHONE_FIRST if layout == "text-bottom" else BODY_TEXT_FIRST
            body = body_tpl.format(headline=headline, sub=sub, img=(src / fname).as_uri())
            html_path = WORK / f"{lang}-{fname.replace('.png', '.html')}"
            base = BASE_CSS
            if lang == "zh-Hans":   # 중국어는 일본어 글꼴(히라기노)로 그리지 않게
                base = base.replace('"Hiragino Sans", "PingFang SC"', '"PingFang SC", "Hiragino Sans"')
            html_path.write_text(HTML.format(lang=lang, base=base, layout=LAYOUTS[layout], body=body), encoding="utf-8")
            tmp = WORK / f"{lang}-{fname}"
            subprocess.run([CHROME, "--headless=new", f"--screenshot={tmp}",
                            f"--window-size={W},{H}", "--force-device-scale-factor=1",
                            "--hide-scrollbars", "--disable-gpu", html_path.as_uri()],
                           check=True, capture_output=True)
            Image.open(tmp).convert("RGB").resize((OUT_W, OUT_H), Image.LANCZOS).save(out / fname)
            print(f"rendered {out / fname}")

if __name__ == "__main__":
    main(sys.argv[1:] or list(COPY))
