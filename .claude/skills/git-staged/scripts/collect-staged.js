#!/usr/bin/env node
/**
 * collect-staged.js — kumpul semua maklumat perubahan staged dalam satu laporan teks.
 *
 * Tujuan: elak agent memanggil git berkali-kali dan tercekik oleh diff besar.
 * Skrip ini yang uruskan pemotongan (truncation), fail binari, dan pengesanan
 * rahsia — supaya agent hanya perlu membaca dan menilai.
 *
 * Guna:
 *   node collect-staged.js [--repo <laluan>] [--max-lines-per-file N]
 *                          [--max-total-lines N] [--files-only]
 *
 * Keluar dengan kod 0 = ada perubahan staged, 3 = tiada staged, 4 = bukan repo Git.
 */

const { execFileSync } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);
function flag(name, fallback) {
  const i = args.indexOf(name);
  return i === -1 ? fallback : args[i + 1];
}
const repo = path.resolve(flag('--repo', process.cwd()));
const MAX_PER_FILE = parseInt(flag('--max-lines-per-file', '400'), 10);
const MAX_TOTAL = parseInt(flag('--max-total-lines', '3000'), 10);
const FILES_ONLY = args.includes('--files-only');

function git(...a) {
  return execFileSync('git', ['-C', repo, ...a], {
    encoding: 'utf8',
    // Senyapkan stderr: setiap kegagalan git sudah ditangkap dan dilaporkan sendiri.
    stdio: ['ignore', 'pipe', 'pipe'],
    maxBuffer: 128 * 1024 * 1024,
  });
}

// --- Sahkan repo ---------------------------------------------------------
try {
  git('rev-parse', '--is-inside-work-tree');
} catch {
  console.log('RALAT: bukan repositori Git -> ' + repo);
  process.exit(4);
}

// 'branch --show-current' berfungsi walaupun belum ada commit pertama,
// berbeza dengan 'rev-parse HEAD' yang terus gagal.
const branch = git('branch', '--show-current').trim() || '(HEAD terpisah)';
let hasCommits = true;
try {
  git('rev-parse', '--verify', 'HEAD');
} catch {
  hasCommits = false;
}
// Sebelum commit pertama tiada HEAD untuk dibandingkan, jadi banding dengan
// 'empty tree' supaya fail yang di-git add tetap kelihatan sebagai perubahan.
const EMPTY_TREE = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
const BASE = hasCommits ? [] : [EMPTY_TREE];

// --- Senarai fail staged -------------------------------------------------
const nameStatus = git('diff', '--staged', ...BASE, '-M', '--name-status')
  .split('\n')
  .filter(Boolean)
  .map((line) => {
    const parts = line.split('\t');
    return { code: parts[0], from: parts[1], to: parts[2] || parts[1] };
  });

if (nameStatus.length === 0) {
  console.log('TIADA PERUBAHAN STAGED');
  console.log('Cawangan: ' + branch);
  const unstaged = git('status', '--porcelain').trim();
  console.log(
    unstaged
      ? '\nFail berubah tetapi BELUM staged:\n' + unstaged
      : '\nDirektori kerja bersih — tiada apa-apa untuk di-commit.'
  );
  process.exit(3);
}

const numstat = git('diff', '--staged', ...BASE, '-M', '--numstat')
  .split('\n')
  .filter(Boolean)
  .map((line) => {
    const [add, del, file] = line.split('\t');
    return { add, del, file };
  });

const STATUS_BM = {
  A: 'Baharu',
  M: 'Diubah',
  D: 'Dipadam',
  R: 'Dinamakan semula',
  C: 'Disalin',
  T: 'Tukar jenis',
};

// --- Laporan -------------------------------------------------------------
const out = [];
out.push('=== PERUBAHAN STAGED ===');
out.push('Repo     : ' + repo);
out.push('Cawangan : ' + branch);
out.push('Commit   : ' + (hasCommits ? 'ada sejarah' : 'BELUM ADA COMMIT (commit pertama)'));
out.push('');

out.push('--- SENARAI FAIL (' + nameStatus.length + ' fail) ---');
let totalAdd = 0;
let totalDel = 0;
const binaries = [];
for (const f of nameStatus) {
  const st = numstat.find((n) => n.file === f.to || n.file.includes(f.to)) || {};
  const isBin = st.add === '-';
  if (isBin) binaries.push(f.to);
  else {
    totalAdd += parseInt(st.add || '0', 10);
    totalDel += parseInt(st.del || '0', 10);
  }
  const label = STATUS_BM[f.code[0]] || f.code;
  const churn = isBin ? 'binari' : '+' + (st.add || 0) + ' -' + (st.del || 0);
  const rename = f.code[0] === 'R' ? '  (asal: ' + f.from + ')' : '';
  out.push('  [' + label.padEnd(16) + '] ' + f.to + '  (' + churn + ')' + rename);
}
out.push('');
out.push('Jumlah teks: +' + totalAdd + ' / -' + totalDel + ' baris');
if (binaries.length) out.push('Fail binari: ' + binaries.length + ' (diff tidak dipaparkan)');
out.push('');

// --- Isyarat automatik ---------------------------------------------------
// Ini hanya PETUNJUK untuk disiasat, bukan keputusan muktamad.
const fullDiff = FILES_ONLY ? '' : git('diff', '--staged', ...BASE, '-M', '--unified=3');
const added = fullDiff
  .split('\n')
  .filter((l) => l.startsWith('+') && !l.startsWith('+++'));

const SIGNALS = [
  [/(?:password|passwd|katalaluan|secret|api[_-]?key|apikey|token|auth)\s*[:=]\s*['"][^'"]{6,}/i, 'Kemungkinan rahsia ditulis terus dalam kod'],
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----/, 'Kunci peribadi (private key) dalam diff'],
  [/\b(?:AKIA|ASIA)[0-9A-Z]{16}\b/, 'Kunci akses AWS'],
  [/\b(?:gh[pousr]_[A-Za-z0-9]{20,})\b/, 'Token GitHub'],
  [/\b(?:console\.log|var_dump|print_r|dd\(|dump\()/, 'Kod nyahpepijat (debug) tertinggal'],
  [/\b(?:TODO|FIXME|XXX|HACK)\b/, 'Penanda TODO/FIXME belum selesai'],
  [/style\s*=\s*["']/i, 'Inline CSS (langgar konvensyen projek jika Bootstrap sahaja dibenarkan)'],
  [/<<<<<<<|>>>>>>>|^\+=======$/m, 'Penanda konflik merge belum dibersihkan'],
  [/\.only\(|fdescribe\(|fit\(/, 'Ujian difokuskan (.only) — ujian lain akan dilangkau'],
];

const hits = [];
for (const [re, label] of SIGNALS) {
  const matched = added.filter((l) => re.test(l));
  if (matched.length) {
    hits.push({ label, count: matched.length, sample: matched.slice(0, 3) });
  }
}

out.push('--- ISYARAT AUTOMATIK (petunjuk, sahkan sendiri dalam diff) ---');
if (FILES_ONLY) {
  out.push('  Dilangkau kerana mod --files-only (diff tidak dibaca).');
} else if (hits.length === 0) {
  out.push('  Tiada corak mencurigakan dikesan.');
} else {
  for (const h of hits) {
    out.push('  * ' + h.label + ' — ' + h.count + ' baris');
    for (const s of h.sample) out.push('      ' + s.trim().slice(0, 160));
  }
}
out.push('');

if (FILES_ONLY) {
  console.log(out.join('\n'));
  process.exit(0);
}

// --- Diff, dipotong per fail supaya konteks tidak meletup ----------------
out.push('--- DIFF ---');
const chunks = fullDiff.split(/^diff --git /m).filter(Boolean);
let used = 0;
for (const chunk of chunks) {
  const lines = ('diff --git ' + chunk).split('\n');
  const header = lines[0];
  if (used >= MAX_TOTAL) {
    out.push('');
    out.push('[DIPOTONG] Had ' + MAX_TOTAL + ' baris dicapai. Baki fail tidak dipaparkan.');
    out.push('Untuk melihat satu fail tertentu: git diff --staged -- <laluan-fail>');
    break;
  }
  const budget = Math.min(MAX_PER_FILE, MAX_TOTAL - used);
  if (lines.length > budget) {
    out.push(lines.slice(0, budget).join('\n'));
    out.push(
      '[DIPOTONG: ' + (lines.length - budget) + ' baris lagi dalam fail ini. ' +
      'Guna `git diff --staged -- ' + header.split(' b/')[1] + '` untuk penuh]'
    );
    used += budget;
  } else {
    out.push(lines.join('\n'));
    used += lines.length;
  }
}

console.log(out.join('\n'));
