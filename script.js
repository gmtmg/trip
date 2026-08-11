/* TRIP Tacos
   - ヘッダーの背景切り替え
   - PHOTOセクション：スクロール量に応じて料理写真を左右に捌けさせ、
     奥の店内写真と店舗情報を出す
   スクロール量は CSS カスタムプロパティ --p / --pi として渡し、
   実際の変形は CSS 側で行う。 */
(function () {
  'use strict';

  var reduceMQ = window.matchMedia('(prefers-reduced-motion: reduce)');

  var topbar = document.getElementById('topbar');
  var track  = document.querySelector('.sweep__track');
  var stage  = document.querySelector('.sweep__stage');

  /* 右端の縦メニュー：いま見ているセクションに印を付ける */
  var navLinks = Array.prototype.slice.call(
    document.querySelectorAll('.rail__list a'));
  var navTargets = navLinks.map(function (a) {
    return document.querySelector(a.getAttribute('href'));
  });

  function docTop(el) {
    return el.getBoundingClientRect().top + window.scrollY;
  }

  function spy() {
    if (!navLinks.length) return;
    var line = window.scrollY + window.innerHeight * 0.45;
    var active = -1;
    for (var i = 0; i < navTargets.length; i++) {
      if (navTargets[i] && docTop(navTargets[i]) <= line) active = i;
    }
    for (var j = 0; j < navLinks.length; j++) {
      var on = (j === active);
      navLinks[j].classList.toggle('is-current', on);
      if (on) navLinks[j].setAttribute('aria-current', 'true');
      else navLinks[j].removeAttribute('aria-current');
    }
  }

  var span = 0;          // 進捗1.0に達するまでのスクロール距離
  var ticking = false;

  function clamp(v) { return v < 0 ? 0 : v > 1 ? 1 : v; }

  /* 0→1をなめらかに。写真が動き出す瞬間と止まる瞬間の当たりを柔らかくする */
  function smoothstep(t) { return t * t * (3 - 2 * t); }

  function measure() {
    if (!track || !stage) return;
    span = track.offsetHeight - stage.offsetHeight;
  }

  function update() {
    ticking = false;

    if (topbar) {
      topbar.classList.toggle('is-stuck', window.scrollY > 40);
    }

    spy();

    if (!track || !stage || span <= 0 || reduceMQ.matches) return;

    var top = track.getBoundingClientRect().top;
    var raw = clamp(-top / span);

    /* 情報パネルは写真がある程度捌けてから出す */
    var info = clamp((raw - 0.42) / 0.32);

    stage.style.setProperty('--p', smoothstep(raw).toFixed(4));
    stage.style.setProperty('--pi', smoothstep(info).toFixed(4));
  }

  function onScroll() {
    if (!ticking) {
      ticking = true;
      window.requestAnimationFrame(update);
    }
  }

  function init() {
    measure();
    update();
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', function () { measure(); onScroll(); });
  window.addEventListener('orientationchange', function () {
    window.setTimeout(init, 200);
  });

  /* 画像の読み込みでレイアウト高さが変わることがあるため測り直す */
  window.addEventListener('load', init);

  if (reduceMQ.addEventListener) {
    reduceMQ.addEventListener('change', init);
  }

  init();
})();
