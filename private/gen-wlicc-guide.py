#!/usr/bin/env python3
"""
WLICC 학사 운영 가이드 아티팩트 생성기 (2026-07-24)

원본(단일 소스) = ministry-manager-v2/docs/CATALOG-COHORT-GUIDE.md
→ 그 마크다운을 정적 HTML 셸에 '그대로' 주입. 브라우저에서 marked로 렌더.
문서 수정 후 이 스크립트 재실행 + git push → Vercel 자동 배포(자동 갱신).

사용: python3 private/gen-wlicc-guide.py  (claude-artifacts 루트에서)
"""
import os, html

SRC = "/home/beekorea/ministry-manager-v2/docs/CATALOG-COHORT-GUIDE.md"
OUT = os.path.join(os.path.dirname(__file__), "wlicc-guide.html")

md = open(SRC, encoding="utf-8").read()
# </script> 만 안전 처리 (그 외 원문 그대로 — marked가 파싱)
md_safe = md.replace("</script>", "<\\/script>")

TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>WLICC 학사 운영 가이드 — BEE Korea</title>
<style>
  :root{
    --paper:#f7f3ea; --card:#fffdf8; --ink:#21304d; --ink-soft:#46506a;
    --line:#e4dcc9; --accent:#5b7a2f; --accent-soft:#eef3e2;
    --warn-bg:#fdf0e7; --warn-line:#e8c9a8; --code-bg:#f1ede1; --link:#5b7a2f;
    --shadow:0 1px 3px rgba(60,50,20,.08);
  }
  @media (prefers-color-scheme: dark){
    :root{--paper:#12161f;--card:#1a2029;--ink:#eae3d3;--ink-soft:#c3bdae;--line:#2c3442;
      --accent:#8ba25e;--accent-soft:#232c1a;--warn-bg:#2c231a;--warn-line:#584427;
      --code-bg:#161b23;--link:#a9bd85;--shadow:none;}
  }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{background:var(--paper);color:var(--ink);
    font-family:'Apple SD Gothic Neo','Noto Sans KR','Malgun Gothic',system-ui,sans-serif;line-height:1.68;}
  .wrap{max-width:880px;margin:0 auto;padding:40px 18px 90px;}
  a{color:var(--link);text-underline-offset:3px;}
  h1{font-size:1.6rem;line-height:1.3;margin:28px 0 6px;text-wrap:balance;}
  h2{font-size:1.2rem;margin:36px 0 12px;padding-top:12px;border-top:1px solid var(--line);
    scroll-margin-top:64px;text-wrap:balance;}
  h3{font-size:1.02rem;margin:22px 0 8px;color:var(--ink);}
  h4{font-size:.95rem;margin:16px 0 6px;color:var(--ink-soft);}
  p,li{font-size:.95rem;color:var(--ink);margin:8px 0;}
  ul,ol{padding-left:1.3em;}
  strong{color:var(--ink);}
  hr{border:none;border-top:1px solid var(--line);margin:28px 0;}
  blockquote{background:var(--warn-bg);border-left:4px solid var(--warn-line);
    border-radius:0 8px 8px 0;padding:12px 16px;margin:16px 0;color:var(--ink-soft);font-size:.92rem;}
  blockquote p{margin:4px 0;color:inherit;}
  code{background:var(--code-bg);padding:2px 6px;border-radius:5px;font-size:.86em;
    font-family:'SF Mono',ui-monospace,'D2Coding',Menlo,monospace;}
  pre{background:var(--code-bg);border:1px solid var(--line);border-radius:10px;
    padding:14px 16px;margin:16px 0;overflow-x:auto;}
  pre code{background:none;padding:0;font-size:.82rem;line-height:1.5;white-space:pre;}
  .tablewrap{overflow-x:auto;margin:16px 0;}
  table{border-collapse:collapse;width:100%;font-size:.9rem;}
  th,td{border:1px solid var(--line);padding:8px 11px;text-align:left;vertical-align:top;}
  th{background:var(--accent-soft);font-weight:700;}
  tbody tr:nth-child(even){background:rgba(0,0,0,.02);}
  @media (prefers-color-scheme: dark){tbody tr:nth-child(even){background:rgba(255,255,255,.03);}}
</style>
</head>
<body>
  <div class="wrap"><div id="content">렌더링 중…</div></div>

  <script type="text/markdown" id="md-src">
__MARKDOWN__
  </script>
  <script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>
  <script>
    (function(){
      var src = document.getElementById('md-src').textContent;
      marked.setOptions({ gfm:true, breaks:false });
      document.getElementById('content').innerHTML = marked.parse(src);
      // 넓은 표는 가로 스크롤 래퍼로 (본문 가로 스크롤 방지)
      document.querySelectorAll('#content table').forEach(function(t){
        if(t.parentElement.classList.contains('tablewrap')) return;
        var w=document.createElement('div'); w.className='tablewrap';
        t.parentNode.insertBefore(w,t); w.appendChild(t);
      });
      // 공유 목차(nav.js)는 h2 렌더 후 로드해야 TOC가 잡힘
      var s=document.createElement('script'); s.src='/nav.js'; document.body.appendChild(s);
    })();
  </script>
</body>
</html>
"""

open(OUT, "w", encoding="utf-8").write(TEMPLATE.replace("__MARKDOWN__", md_safe))
print("생성:", OUT, "|", len(md), "chars from", SRC)
