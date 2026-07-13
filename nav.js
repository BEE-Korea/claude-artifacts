/* claude-artifacts shared nav: top-left hamburger with auto TOC + back-to-hub.
   Builds the table of contents from the page's own h2 / .grouptitle headings. */
(function () {
  if (window.__caNav) return; window.__caNav = 1;

  function build() {
    var items = [].slice.call(document.querySelectorAll('h2, .grouptitle'));
    items.forEach(function (el, i) { if (!el.id) el.id = 'ca-sec-' + i; });

    var css =
      '@media (prefers-reduced-motion: no-preference){html{scroll-behavior:smooth}}' +
      'h2,.grouptitle{scroll-margin-top:64px}' +
      '.ca-navbtn{position:fixed;top:12px;left:12px;z-index:1000;width:42px;height:42px;border-radius:11px;' +
      'border:1px solid var(--line,#e2dac9);background:var(--card,#fffdf8);color:var(--accent,#b0802a);' +
      'font-size:19px;line-height:1;cursor:pointer;box-shadow:0 2px 10px rgba(0,0,0,.16);display:flex;align-items:center;justify-content:center}' +
      '.ca-navbtn:hover{filter:brightness(1.05)}' +
      '.ca-navbtn:focus-visible{outline:2px solid var(--accent,#b0802a);outline-offset:2px}' +
      '.ca-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.38);z-index:1001;opacity:0;pointer-events:none;transition:opacity .18s}' +
      '.ca-backdrop.open{opacity:1;pointer-events:auto}' +
      '.ca-panel{position:fixed;top:0;left:0;height:100%;width:82%;max-width:318px;z-index:1002;background:var(--paper,#f7f3ea);' +
      'border-right:1px solid var(--line,#e2dac9);box-shadow:4px 0 26px rgba(0,0,0,.2);transform:translateX(-105%);' +
      'transition:transform .2s ease;overflow-y:auto;padding:14px 0 34px;' +
      'font-family:system-ui,-apple-system,"Segoe UI","Apple SD Gothic Neo","Malgun Gothic",sans-serif}' +
      '.ca-panel.open{transform:translateX(0)}' +
      '.ca-head{display:flex;align-items:center;justify-content:space-between;padding:6px 16px 12px;' +
      'border-bottom:1px solid var(--line,#e2dac9);font-family:Georgia,serif;font-size:15px;color:var(--muted,#77715f)}' +
      '.ca-close{background:none;border:none;font-size:18px;color:var(--muted,#77715f);cursor:pointer;padding:4px 8px}' +
      '.ca-home{display:block;margin:12px 12px 4px;padding:11px 14px;border-radius:10px;background:var(--accent-soft,#e9dcbd);' +
      'color:var(--ink,#21304d);text-decoration:none;font-weight:700;font-size:14.5px}' +
      '.ca-home:hover{filter:brightness(1.04)}' +
      '.ca-panel ul{list-style:none;margin:6px 0 0;padding:0}' +
      '.ca-panel li a{display:block;padding:10px 16px;color:var(--ink,#21304d);text-decoration:none;font-size:14.5px;' +
      'border-left:3px solid transparent}' +
      '.ca-panel li a:hover{background:var(--card,#fffdf8);border-left-color:var(--accent,#b0802a)}';
    var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

    var btn = document.createElement('button');
    btn.className = 'ca-navbtn'; btn.type = 'button'; btn.textContent = '☰';
    btn.setAttribute('aria-label', '목차 열기 · Contents'); btn.setAttribute('aria-expanded', 'false');

    var backdrop = document.createElement('div'); backdrop.className = 'ca-backdrop';
    var panel = document.createElement('nav'); panel.className = 'ca-panel'; panel.setAttribute('aria-label', '목차');

    var head = document.createElement('div'); head.className = 'ca-head';
    var hspan = document.createElement('span'); hspan.textContent = '목차 · Contents';
    var closeBtn = document.createElement('button'); closeBtn.className = 'ca-close'; closeBtn.textContent = '✕';
    closeBtn.setAttribute('aria-label', '닫기');
    head.appendChild(hspan); head.appendChild(closeBtn); panel.appendChild(head);

    var home = document.createElement('a'); home.className = 'ca-home'; home.href = '/';
    home.textContent = '🏠 목록으로 · Back to list'; panel.appendChild(home);

    if (items.length) {
      var ul = document.createElement('ul');
      items.forEach(function (el) {
        var li = document.createElement('li'); var a = document.createElement('a');
        a.href = '#' + el.id; a.textContent = (el.textContent || '').replace(/\s+/g, ' ').trim();
        li.appendChild(a); ul.appendChild(li);
      });
      panel.appendChild(ul);
    }

    document.body.appendChild(btn);
    document.body.appendChild(backdrop);
    document.body.appendChild(panel);

    function open() { panel.classList.add('open'); backdrop.classList.add('open'); btn.setAttribute('aria-expanded', 'true'); }
    function close() { panel.classList.remove('open'); backdrop.classList.remove('open'); btn.setAttribute('aria-expanded', 'false'); }
    btn.addEventListener('click', open);
    backdrop.addEventListener('click', close);
    closeBtn.addEventListener('click', close);
    panel.addEventListener('click', function (e) {
      var a = e.target.closest ? e.target.closest('a') : null;
      if (a && a.getAttribute('href').charAt(0) === '#') close();
    });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });
  }

  if (document.body) build();
  else document.addEventListener('DOMContentLoaded', build);
})();
