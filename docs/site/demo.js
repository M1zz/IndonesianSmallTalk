// 말문 웹 체험: 앱의 인도네시아어 스몰토크 '아침 인사'(ConversationData.scenarioMorning)를 그대로 고르며 이어 간다.
// 규칙은 앱과 같다 — 고를 때마다 긍정이면 10점, 아니면 5점 (PracticeSession.choose).
// 문장과 긍정·부정은 앱 데이터에서 가져왔고, 갈래 몇 개만 남겼다. 뜻은 그 언어 글(data-text)의 meanings 에서 온다.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);

  // id: [말하는 사람, 인도네시아어, 긍정(+1)·부정(-1)·보통(0), 다음 갈래]
  const N = {
    m_root: ["me", "Selamat pagi! 😊", 0, ["m_a", "m_b"]],
    m_a: ["other", "Selamat pagi! Cuacanya bagus ya hari ini? ☀️", 1, ["m_a1", "m_a2"]],
    m_b: ["other", "Pagi... ngantuk banget, belum ngopi 😴", -1, ["m_b1", "m_b2"]],
    m_a1: ["me", "Iya, cuacanya cerah sekali! Bikin semangat 🌿", 1, ["m_a1a", "m_a1b"]],
    m_a2: ["me", "Iya! Jadi semangat mau kerja 💼", 1, ["m_a2a"]],
    m_b1: ["me", "Sama! Kopi yuk, saya traktir ☕", 1, ["m_b1a"]],
    m_b2: ["me", "Aduh, saya juga! Kantuk banget pagi ini 😩", -1, ["m_b2a"]],
    m_a1a: ["other", "Mau jalan-jalan siang nanti? 🚶", 1, ["m_a1a1", "m_a1a2"]],
    m_a1b: ["other", "Pengen juga, tapi hari ini sibuk banget 😅", -1, ["m_a1b1", "m_a1b2"]],
    m_a2a: ["other", "Wah, keren! Semangat ya hari ini! 😄", 1, ["m_a2a1", "m_a2a2"]],
    m_b1a: ["other", "Serius? Makasih banget! Kamu baik banget 😊", 1, ["m_b1a1", "m_b1a2"]],
    m_b2a: ["other", "Haha, kita senasib! Kopi yuk 😄", 1, ["m_b2a1", "m_b2a2"]],
    m_a1a1: ["me", "Boleh! Jam satu siang gimana? 😊", 1, []],
    m_a1a2: ["me", "Hari ini ada acara. Minggu depan yuk!", -1, []],
    m_a1b1: ["me", "Jalan 15 menit saja juga sudah beda rasanya! 💪", 1, []],
    m_a1b2: ["me", "Iya, kesibukan sudah jadi keseharian ya... 😔", -1, []],
    m_a2a1: ["me", "Makasih! Kamu juga semangat ya! ✨", 1, []],
    m_a2a2: ["me", "Hehe, semoga saja tahan sampai sore 😅", -1, []],
    m_b1a1: ["me", "Sama-sama! Semoga harinya lebih menyenangkan 😊", 1, []],
    m_b1a2: ["me", "Hehe, sesama yang ngantuk harus saling bantu 😄", 1, []],
    m_b2a1: ["me", "Yuk! Kopi pagi terbaik itu bareng-bareng ☕", 1, []],
    m_b2a2: ["me", "Wah, kopi malah bikin deg-degan. Teh aja deh 😅", -1, []],
  };

  root.innerHTML = `
    <div class="mm-chat" aria-live="polite"></div>
    <div class="mm-side">
      <div class="mm-score" aria-live="polite"><span aria-hidden="true">★</span> <b>0</b></div>
      <p class="mm-ask"></p>
      <div class="mm-choices"></div>
      <button type="button" class="mm-restart">${T.restart}</button>
      <p class="muted small mm-note">${T.note}</p>
    </div>`;
  const $ = s => root.querySelector(s);
  const chat = $(".mm-chat"), ask = $(".mm-ask"), choices = $(".mm-choices"), scoreEl = $(".mm-score b");
  let path, score;

  // 앱처럼 소리 내어 읽는다. 브라우저에 인도네시아어 목소리가 없으면 읽기 단추를 세우지 않는다.
  const synth = window.speechSynthesis;
  let voice = null;
  const findVoice = () => {
    voice = synth && synth.getVoices().find(v => /^id[-_]/i.test(v.lang)) || null;
    root.classList.toggle("can-speak", !!voice);
  };
  if (synth) { findVoice(); synth.addEventListener?.("voiceschanged", findVoice); }
  function speak(text) {
    if (!voice) return;
    synth.cancel();
    const u = new SpeechSynthesisUtterance(text.replace(/\p{Extended_Pictographic}|️/gu, "").trim());
    u.voice = voice; u.lang = voice.lang; u.rate = 0.9;
    synth.speak(u);
  }

  const esc = s => s.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const badge = p => p > 0 ? `<span class="mm-badge pos">😊 ${T.pos}</span>`
    : p < 0 ? `<span class="mm-badge neg">😟 ${T.neg}</span>` : "";

  function bubble(id, fresh) {
    const [who, text] = N[id];
    return `<div class="mm-row ${who}${fresh ? " fresh" : ""}">
      <span class="mm-who">${who === "me" ? T.me : T.other}</span>
      <div class="mm-bubble"><span lang="id">${esc(text)}</span>
        <small>${esc(T.meanings[id])}</small>
        <button type="button" class="mm-say" data-say="${id}" aria-label="${T.listen}">🔊</button>
      </div></div>`;
  }

  function render(fresh) {
    chat.innerHTML = path.map((id, i) => bubble(id, fresh && i === path.length - 1)).join("");
    chat.scrollTop = chat.scrollHeight;
    scoreEl.textContent = score;
    const next = N[path[path.length - 1]][3];
    if (!next.length) {
      ask.textContent = T.done.replace("{score}", score);
      choices.innerHTML = "";
      return;
    }
    ask.textContent = N[next[0]][0] === "me" ? T.askMe : T.askOther;
    choices.innerHTML = next.map(id => `<button type="button" class="mm-choice" data-pick="${id}">
        <span lang="id">${esc(N[id][1])}</span><small>${esc(T.meanings[id])}</small>${badge(N[id][2])}</button>`).join("");
  }

  function reset() { path = ["m_root"]; score = 0; render(false); }

  root.addEventListener("click", e => {
    const pick = e.target.closest("[data-pick]"), say = e.target.closest("[data-say]");
    if (pick) {
      const id = pick.dataset.pick;
      path.push(id);
      score += N[id][2] > 0 ? 10 : 5;
      render(true);
      speak(N[id][1]);
      choices.querySelector("button")?.focus({ preventScroll: true });
    } else if (say) speak(N[say.dataset.say][1]);
    else if (e.target.closest(".mm-restart")) { synth?.cancel(); reset(); }
  });

  reset();
})();
