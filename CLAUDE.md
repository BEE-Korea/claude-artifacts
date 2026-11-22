# claude-artifacts

BEE Korea 자료 모음 정적 사이트. Claude로 만든 HTML 아티팩트를 한곳에서 보고 공유합니다.

- **허브**: `index.html` — 전체 목록
- **자료**: 주제별 폴더(예: `thm/`)에 독립 실행형 HTML
- **배포**: GitHub `main` push → Vercel 자동 배포
- **접근**: 기본 공개. 민감 자료는 클라이언트 암호화 페이지(비밀번호) 또는 향후 Google 로그인.

## 새 자료 추가
1. `<주제>/이름.html` 추가 (독립 실행형 HTML)
2. `index.html`에 카드 한 개 추가
3. commit & push → 1분 내 반영

## 보관 (`archive/`) — 2026-11-23 관리자 「지워도 될 것은 지우고, 보관할 것은 보관 폴더로」
- 끝난 행사·지난 발표·기록은 **같은 경로 그대로** `archive/<옛 경로>` 로 옮긴다(`git mv`) · 허브 목록(`artifacts.json`)은 `path` 를 바꾸고 `status: "archived"`(숨김)
- ⛔ 옮기면 주소가 바뀐다 → **`vercel.json` 의 `redirects` 에 옛 주소 → 새 주소를 함께 넣는다**(`.html` 있는 꼴·없는 꼴 둘 다). 왓츠앱·카톡·인쇄 QR 로 나간 링크가 끊기지 않게
- 쓸모가 끝나고 밖으로 나간 링크가 없는 시안은 지운다(git 기록에 남음). 그 시안만 쓰던 그림도 같이
- ⛔ 옮기지 않는 것: `help/final-test*.html`(홈 CLAUDE.md #22 본보기 주소) · `bmtc/2026/c/*`(학생 개인 링크)
- ⚠️ 이 저장소는 GitHub **공개** — 개인 자료(기도편지 등)는 넣지 않는다(기도편지 = `~/bee-letters`, 비공개)
