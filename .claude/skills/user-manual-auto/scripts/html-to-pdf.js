#!/usr/bin/env node
/**
 * html-to-pdf.js
 *
 * Render a local HTML file into an A4 PDF using a headless Chromium-based browser that
 * is already installed on the machine. No npm dependencies on purpose: the skill must
 * work on a bare machine without `npm install`, Python, pandoc or wkhtmltopdf.
 *
 * Usage:
 *   node html-to-pdf.js <input.html> <output.pdf>
 *
 * Environment:
 *   BROWSER_BIN   Full path to a Chromium/Edge/Chrome binary, overriding auto-detection.
 */

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

function fail(message) {
  console.error('RALAT: ' + message);
  process.exit(1);
}

/** Candidate browser binaries, most reliable first. */
function browserCandidates() {
  const home = os.homedir();
  const localAppData = process.env.LOCALAPPDATA || path.join(home, 'AppData', 'Local');
  const programFiles = process.env.ProgramFiles || 'C:\\Program Files';
  const programFilesX86 = process.env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)';

  const list = [];

  if (process.env.BROWSER_BIN) list.push(process.env.BROWSER_BIN);

  if (process.platform === 'win32') {
    list.push(
      path.join(programFilesX86, 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
      path.join(programFiles, 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
      path.join(programFiles, 'Google', 'Chrome', 'Application', 'chrome.exe'),
      path.join(programFilesX86, 'Google', 'Chrome', 'Application', 'chrome.exe'),
      path.join(localAppData, 'Google', 'Chrome', 'Application', 'chrome.exe')
    );
  } else if (process.platform === 'darwin') {
    list.push(
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
      '/Applications/Chromium.app/Contents/MacOS/Chromium'
    );
  } else {
    list.push(
      '/usr/bin/google-chrome',
      '/usr/bin/chromium',
      '/usr/bin/chromium-browser',
      '/usr/bin/microsoft-edge'
    );
  }

  // Chromium bundled with Playwright, if the user has ever installed it.
  for (const root of [
    path.join(localAppData, 'ms-playwright'),
    path.join(home, 'Library', 'Caches', 'ms-playwright'),
    path.join(home, '.cache', 'ms-playwright')
  ]) {
    let entries;
    try {
      entries = fs.readdirSync(root);
    } catch (err) {
      continue;
    }
    for (const entry of entries) {
      if (!entry.startsWith('chromium-')) continue;
      list.push(
        path.join(root, entry, 'chrome-win64', 'chrome.exe'),
        path.join(root, entry, 'chrome-linux', 'chrome'),
        path.join(root, entry, 'chrome-mac', 'Chromium.app', 'Contents', 'MacOS', 'Chromium')
      );
    }
  }

  return list;
}

function findBrowser() {
  for (const candidate of browserCandidates()) {
    try {
      if (fs.statSync(candidate).isFile()) return candidate;
    } catch (err) {
      /* not installed at this path */
    }
  }
  return null;
}

function fileUrl(absolutePath) {
  let normalised = absolutePath.replace(/\\/g, '/');
  if (!normalised.startsWith('/')) normalised = '/' + normalised;
  return 'file://' + encodeURI(normalised);
}

function main() {
  const [inputArg, outputArg] = process.argv.slice(2);
  if (!inputArg || !outputArg) {
    fail('Guna: node html-to-pdf.js <input.html> <output.pdf>');
  }

  const input = path.resolve(inputArg);
  const output = path.resolve(outputArg);

  if (!fs.existsSync(input)) fail('Fail HTML tidak dijumpai: ' + input);
  fs.mkdirSync(path.dirname(output), { recursive: true });
  // A stale PDF left behind would make a silent failure look like success.
  if (fs.existsSync(output)) fs.unlinkSync(output);

  const browser = findBrowser();
  if (!browser) {
    fail(
      'Tiada pelayar Chromium dijumpai. Pasang Microsoft Edge atau Google Chrome, ' +
        'atau tetapkan BROWSER_BIN ke laluan pelayar anda.'
    );
  }

  // A throwaway profile keeps this from clashing with a browser the user already has open.
  const profileDir = fs.mkdtempSync(path.join(os.tmpdir(), 'manual-pdf-'));

  const args = [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--no-first-run',
    '--user-data-dir=' + profileDir,
    // Let images, webfonts and layout settle before the page is captured.
    '--run-all-compositor-stages-before-draw',
    '--virtual-time-budget=20000',
    '--no-pdf-header-footer',
    '--print-to-pdf=' + output,
    fileUrl(input)
  ];

  console.log('Pelayar : ' + browser);
  console.log('Sumber  : ' + input);
  console.log('Output  : ' + output);

  const result = spawnSync(browser, args, { encoding: 'utf8', timeout: 180000 });

  try {
    fs.rmSync(profileDir, { recursive: true, force: true });
  } catch (err) {
    /* temp profile cleanup is best-effort */
  }

  if (result.error) fail('Gagal menjalankan pelayar: ' + result.error.message);

  if (!fs.existsSync(output)) {
    const detail = (result.stderr || '').split('\n').slice(-5).join('\n');
    fail('PDF tidak terhasil.\n' + detail);
  }

  const bytes = fs.statSync(output).size;
  if (bytes < 1024) fail('PDF terhasil tetapi kosong (' + bytes + ' bait).');

  console.log('Siap    : ' + (bytes / 1024).toFixed(0) + ' KB');
}

main();
