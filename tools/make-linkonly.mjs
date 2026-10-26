// 평문 HTML → 「받은 링크로만 열리는」 자체 완결 HTML (AES-GCM-256, 열쇠는 링크의 #k= 에만)
//   사용: node tools/make-linkonly.mjs <입력.html> <출력.html> "<탭 제목>" [열쇠(base64url) — 없으면 새로 만든다]
//   출력: 열쇠를 표준출력에 한 줄로 낸다 → 링크 = https://…/<출력 경로>#k=<열쇠>
//   왜: 이 저장소는 GitHub 공개라 「비공개(목록에 없음)」 페이지도 저장소에서 누구나 읽는다.
//       열쇠가 주소의 # 뒤에만 있으면 서버·저장소에는 암호문만 남고, 링크를 받은 사람만 연다.
//       비밀번호 잠금(make-locked)과 달리 입력할 것이 없어 폰으로 받은 링크를 누르면 바로 열린다.
//   ⚠️ 포장지 스타일은 body.lk 안에만 — document.write 뒤에도 남는 브라우저가 있어 펼친 페이지의 정렬·폭을 바꿨다(10/26)
//   ⚠️ 그림은 미리 data: 로 넣어 두어야 함께 암호화된다(따로 둔 img/ 파일은 공개로 남는다).
import { readFileSync, writeFileSync } from "node:fs";
import { createCipheriv, randomBytes } from "node:crypto";

const [, , inFile, outFile, titleArg, keyArg] = process.argv;
if (!inFile || !outFile) { console.error("사용: node tools/make-linkonly.mjs <입력> <출력> [제목] [열쇠]"); process.exit(1); }
const title = titleArg || "BEE Korea";
const key = keyArg ? Buffer.from(keyArg, "base64url") : randomBytes(32);
if (key.length !== 32) { console.error("열쇠는 32바이트(base64url 43자)여야 합니다"); process.exit(1); }
const iv = randomBytes(12);
const c = createCipheriv("aes-256-gcm", key, iv);
const data = Buffer.concat([c.update(readFileSync(inFile)), c.final(), c.getAuthTag()]);
const esc = (s) => s.replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]);

writeFileSync(outFile, `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="robots" content="noindex, nofollow"><title>${esc(title)}</title>
<style id="lk-style">
:root{--bg:#F4F6F5;--ink:#16201E;--soft:#4F5B59}
@media(prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#0E1413;--ink:#E8EDEB;--soft:#A7B2AF;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#0E1413;--ink:#E8EDEB;--soft:#A7B2AF;color-scheme:dark}
body.lk{margin:0;min-height:100vh;display:grid;place-items:center;padding:1.5rem max(16px,env(safe-area-inset-right,0px)) 1.5rem max(16px,env(safe-area-inset-left,0px));background:var(--bg);color:var(--ink);font-family:"Noto Sans","Noto Sans KR",system-ui,sans-serif;text-align:center}
.lk p{margin:.4rem 0;color:var(--soft);max-width:26rem}
</style></head><body class="lk"><main id="m"><p>Opening…</p></main>
<script>
var IV="${iv.toString("base64")}",DATA="${data.toString("base64")}";
function b64(s){var b=atob(s),u=new Uint8Array(b.length);for(var i=0;i<b.length;i++)u[i]=b.charCodeAt(i);return u}
function b64u(s){s=s.replace(/-/g,"+").replace(/_/g,"/");while(s.length%4)s+="=";return b64(s)}
function fail(){document.getElementById("m").innerHTML='<p><b>This page opens only from the link you received.</b></p><p>Ukurasa huu unafunguka tu kwa kiungo ulichopokea.</p><p>받은 링크로만 열리는 페이지입니다. 링크 전체(# 뒤까지)를 그대로 여세요.</p>'}
(async function(){try{var m=location.hash.match(/k=([A-Za-z0-9_-]{43})/);if(!m)return fail();
var k=await crypto.subtle.importKey("raw",b64u(m[1]),"AES-GCM",false,["decrypt"]);
var pt=await crypto.subtle.decrypt({name:"AES-GCM",iv:b64(IV)},k,b64(DATA));
var html=new TextDecoder().decode(pt);document.open();document.write(html);document.close();var st=document.getElementById("lk-style");if(st)st.remove();}catch(e){fail()}})();
</script></body></html>`, "utf8");
console.log(key.toString("base64url"));
