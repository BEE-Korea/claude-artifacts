// 잠긴 아티팩트의 비밀번호 후보를 검사한다. 맞는지만 알려주고 내용은 출력하지 않는다.
//   사용: node tools/check-password.mjs private/ict-briefing.html
//   비번은 화면에 안 보이게 입력받는다.
import { readFileSync } from "node:fs";
import { pbkdf2Sync, createDecipheriv } from "node:crypto";
import { createInterface } from "node:readline";

const file = process.argv[2] || "private/ict-briefing.html";
const html = readFileSync(file, "utf8");
const grab = (k, quoted = true) => {
  const re = quoted ? new RegExp(`\\b${k}\\s*=\\s*"([^"]+)"`) : new RegExp(`\\b${k}\\s*=\\s*(\\d+)`);
  const m = html.match(re);
  if (!m) throw new Error(`${k} 를 못 찾음 — 이 파일은 잠긴 형식이 아닐 수 있습니다`);
  return m[1];
};
const SALT = Buffer.from(grab("SALT"), "base64");
const IV   = Buffer.from(grab("IV"), "base64");
const ITER = Number(grab("ITER", false));
const DATA = Buffer.from(grab("DATA"), "base64");

function tryPw(pw) {
  const key = pbkdf2Sync(Buffer.from(pw, "utf8"), SALT, ITER, 32, "sha256");
  const tag = DATA.subarray(DATA.length - 16);
  const ct  = DATA.subarray(0, DATA.length - 16);
  const d = createDecipheriv("aes-256-gcm", key, IV);
  d.setAuthTag(tag);
  try { const out = Buffer.concat([d.update(ct), d.final()]); return out.toString("utf8"); }
  catch { return null; }
}

const rl = createInterface({ input: process.stdin, output: process.stdout, terminal: true });
process.stdout.write(`대상: ${file}  (PBKDF2-SHA256 ${ITER.toLocaleString()}회 → AES-GCM-256)\n`);
rl.question("검사할 비밀번호(입력해도 안 보임): ", (pw) => {
  rl.close();
  process.stdout.write("\n");
  const out = tryPw(pw);
  if (out) {
    console.log("✅ 맞습니다. 이 비밀번호로 열립니다.");
    console.log(`   (복호화된 내용 ${out.length.toLocaleString()}자 — 화면에 출력하지 않습니다)`);
  } else {
    console.log("❌ 틀립니다. 다른 후보로 다시 시도해보세요.");
  }
});
rl._writeToOutput = function (s) { if (rl.stdoutMuted) rl.output.write("*"); else rl.output.write(s); };
rl.stdoutMuted = true;
