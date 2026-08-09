// 평문 HTML → 비밀번호로 잠긴 자체 완결 HTML (PBKDF2-SHA256 200k → AES-GCM-256)
//   사용: node tools/make-locked.mjs <입력.html> <출력.html> "<탭 제목>"
//   비번은 인자로 받지 않는다(쉘 기록에 남지 않게) — 표준입력으로 받는다.
import { readFileSync, writeFileSync } from "node:fs";
import { pbkdf2Sync, createCipheriv, randomBytes } from "node:crypto";
import { createInterface } from "node:readline";

const [, , inFile, outFile, titleArg] = process.argv;
if (!inFile || !outFile) { console.error("사용: node tools/make-locked.mjs <입력> <출력> [제목]"); process.exit(1); }
const title = titleArg || "잠긴 문서";
const plain = readFileSync(inFile, "utf8");
const ITER = 200000;

function build(pw) {
  const salt = randomBytes(16), iv = randomBytes(12);
  const key = pbkdf2Sync(Buffer.from(pw, "utf8"), salt, ITER, 32, "sha256");
  const c = createCipheriv("aes-256-gcm", key, iv);
  const data = Buffer.concat([c.update(Buffer.from(plain, "utf8")), c.final(), c.getAuthTag()]);
  return `<!doctype html><html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>🔒 ${title}</title><meta name="robots" content="noindex, nofollow">
<style>
:root{--bg:#F6F8FA;--card:#FFF;--ink:#141A21;--soft:#4C5764;--rule:#E0E5EC;--accent:#0E6B6B;--bad:#9C3A34}
@media(prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#0E1217;--card:#151B22;--ink:#E5E9EF;--soft:#A7B1BE;--rule:#242D38;--accent:#46B9B0;--bad:#D8827A}}
:root[data-theme="dark"]{--bg:#0E1217;--card:#151B22;--ink:#E5E9EF;--soft:#A7B1BE;--rule:#242D38;--accent:#46B9B0;--bad:#D8827A}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;display:grid;place-items:center;padding:1.5rem;background:var(--bg);color:var(--ink);
font-family:"Pretendard","Apple SD Gothic Neo","Noto Sans KR",system-ui,sans-serif}
.card{background:var(--card);border:1px solid var(--rule);border-radius:8px;padding:2rem;max-width:24rem;width:100%;
display:flex;flex-direction:column;gap:1rem;box-shadow:0 1px 2px rgba(0,0,0,.05),0 12px 32px -16px rgba(0,0,0,.25)}
h1{margin:0;font-size:1.15rem;font-weight:700;letter-spacing:-.01em;line-height:1.4}
p{margin:0;font-size:.88rem;color:var(--soft);line-height:1.65}
form{display:flex;flex-direction:column;gap:.7rem}
input{font:inherit;font-size:1rem;padding:.62rem .8rem;border:1px solid var(--rule);border-radius:5px;
background:var(--bg);color:var(--ink)}
input:focus{outline:2px solid var(--accent);outline-offset:1px;border-color:var(--accent)}
button{font:inherit;font-weight:600;font-size:.95rem;padding:.62rem;border:0;border-radius:5px;
background:var(--accent);color:var(--card);cursor:pointer}
button:hover{filter:brightness(1.08)}
button:focus-visible{outline:2px solid var(--ink);outline-offset:2px}
.err{font-size:.85rem;color:var(--bad);min-height:1.2em}
</style></head><body>
<div class="card">
  <h1>🔒 ${title}</h1>
  <p>내부 문서입니다. 비밀번호를 입력하면 열립니다.</p>
  <form id="f"><input id="pw" type="password" placeholder="비밀번호" autocomplete="current-password" autofocus>
  <button type="submit">열기</button></form>
  <div class="err" id="e" role="status"></div>
</div>
<script>
var SALT="${salt.toString("base64")}",IV="${iv.toString("base64")}",ITER=${ITER},DATA="${data.toString("base64")}";
function b64(s){var bin=atob(s),u=new Uint8Array(bin.length);for(var i=0;i<bin.length;i++)u[i]=bin.charCodeAt(i);return u;}
var KEYNAME="ca_pw_"+location.pathname;
async function tryUnlock(pw){
  var km=await crypto.subtle.importKey("raw",new TextEncoder().encode(pw),"PBKDF2",false,["deriveKey"]);
  var key=await crypto.subtle.deriveKey({name:"PBKDF2",salt:b64(SALT),iterations:ITER,hash:"SHA-256"},km,{name:"AES-GCM",length:256},false,["decrypt"]);
  var buf=await crypto.subtle.decrypt({name:"AES-GCM",iv:b64(IV)},key,b64(DATA));
  return new TextDecoder().decode(buf);
}
function render(html){document.open();document.write(html);document.close();}
document.getElementById("f").addEventListener("submit",async function(ev){
  ev.preventDefault();
  var pw=document.getElementById("pw").value,e=document.getElementById("e");
  e.textContent="";
  try{var html=await tryUnlock(pw);try{sessionStorage.setItem(KEYNAME,pw);}catch(_){}render(html);}
  catch(err){e.textContent="비밀번호가 올바르지 않습니다 · Wrong password";}
});
(async function(){try{var s=sessionStorage.getItem(KEYNAME);if(s){var html=await tryUnlock(s);render(html);}}catch(_){}})();
</script></body></html>`;
}

const rl = createInterface({ input: process.stdin, output: process.stdout, terminal: true });
rl.question("비밀번호(입력해도 안 보임): ", (pw) => {
  rl.close(); process.stdout.write("\n");
  if (!pw) { console.error("비밀번호가 비었습니다."); process.exit(1); }
  writeFileSync(outFile, build(pw), "utf8");
  console.log(`✅ 생성: ${outFile}`);
});
rl._writeToOutput = function (s) { if (rl.stdoutMuted) rl.output.write("*"); else rl.output.write(s); };
rl.stdoutMuted = true;
