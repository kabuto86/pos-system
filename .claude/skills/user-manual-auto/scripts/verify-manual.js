#!/usr/bin/env node
/**
 * verify-manual.js
 *
 * Check a generated user manual before reporting it as finished. Broken image links are
 * the most common failure of an automated manual and the hardest to spot by skimming, so
 * this runs the checks that a human would otherwise have to do by hand.
 *
 * Usage:
 *   node verify-manual.js <panduan.md> [panduan.html] [panduan.pdf]
 *
 * When only the Markdown path is given, the HTML and PDF siblings are guessed from it.
 * Exits 1 when anything is missing so the caller cannot miss the failure.
 */

'use strict';

const fs = require('fs');
const path = require('path');

const problems = [];
const notes = [];

function readIfExists(file) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch (err) {
    return null;
  }
}

/** Image references from Markdown `![alt](src)` and HTML `<img src="...">`. */
function extractImageRefs(content, isHtml) {
  const pattern = isHtml ? /<img[^>]+src=["']([^"']+)["']/g : /!\[([^\]]*)\]\(([^)\s]+)\)/g;
  const refs = [];
  let match;
  while ((match = pattern.exec(content)) !== null) {
    refs.push(isHtml ? { alt: null, src: match[1] } : { alt: match[1], src: match[2] });
  }
  return refs;
}

function checkDocument(file, isHtml, usedImages) {
  const content = readIfExists(file);
  if (content === null) {
    problems.push('Fail tidak dijumpai: ' + file);
    return;
  }

  const baseDir = path.dirname(file);
  const refs = extractImageRefs(content, isHtml);

  if (refs.length === 0) {
    problems.push(path.basename(file) + ': tiada gambar langsung — setiap langkah sepatutnya ada screenshot.');
  }

  for (const ref of refs) {
    if (/^(https?:)?\/\//.test(ref.src) || ref.src.startsWith('data:')) continue;
    const resolved = path.resolve(baseDir, decodeURI(ref.src));
    if (!fs.existsSync(resolved)) {
      problems.push(path.basename(file) + ': gambar hilang → ' + ref.src);
    } else {
      usedImages.add(path.resolve(resolved));
      if (fs.statSync(resolved).size < 2048) {
        problems.push(path.basename(file) + ': gambar mencurigakan kecil → ' + ref.src);
      }
    }
    if (ref.alt !== null && ref.alt.trim() === '') {
      problems.push(path.basename(file) + ': kapsyen kosong pada ' + ref.src);
    }
  }

  notes.push(path.basename(file) + ': ' + refs.length + ' rujukan gambar');

  if (!isHtml) {
    const steps = (content.match(/^##\s+Langkah\s/gm) || []).length;
    if (steps === 0) {
      problems.push(path.basename(file) + ': tiada tajuk "## Langkah N" dijumpai.');
    } else {
      notes.push(path.basename(file) + ': ' + steps + ' langkah');
    }
    for (const tajuk of ['## Kandungan', '## Masalah Lazim']) {
      if (!content.includes(tajuk)) {
        problems.push(path.basename(file) + ': bahagian "' + tajuk.replace('## ', '') + '" tiada.');
      }
    }
  }
}

function main() {
  const [mdArg, htmlArg, pdfArg] = process.argv.slice(2);
  if (!mdArg) {
    console.error('Guna: node verify-manual.js <panduan.md> [panduan.html] [panduan.pdf]');
    process.exit(1);
  }

  const mdFile = path.resolve(mdArg);
  const stem = mdFile.replace(/\.md$/i, '');
  const htmlFile = path.resolve(htmlArg || stem + '.html');
  const pdfFile = path.resolve(pdfArg || stem + '.pdf');

  const usedImages = new Set();

  checkDocument(mdFile, false, usedImages);
  if (fs.existsSync(htmlFile)) {
    checkDocument(htmlFile, true, usedImages);
  } else {
    problems.push('Versi HTML tidak dijumpai: ' + htmlFile);
  }

  // Orphan screenshots usually mean a step was recorded but never written up.
  const imageDir = path.join(path.dirname(mdFile), 'images');
  if (fs.existsSync(imageDir)) {
    for (const name of fs.readdirSync(imageDir)) {
      if (!/\.(png|jpe?g|webp)$/i.test(name)) continue;
      if (!usedImages.has(path.resolve(imageDir, name))) {
        problems.push('Gambar yatim (tidak dirujuk mana-mana dokumen): images/' + name);
      }
    }
  }

  if (!fs.existsSync(pdfFile)) {
    problems.push('PDF tidak dijumpai: ' + pdfFile);
  } else {
    const kb = fs.statSync(pdfFile).size / 1024;
    if (kb < 20) {
      problems.push('PDF terlalu kecil (' + kb.toFixed(0) + ' KB) — kemungkinan gambar tidak dimuatkan.');
    } else {
      notes.push('PDF: ' + kb.toFixed(0) + ' KB');
    }
  }

  for (const note of notes) console.log('  ' + note);

  if (problems.length > 0) {
    console.log('');
    console.log('Masalah dijumpai (' + problems.length + '):');
    for (const problem of problems) console.log('  - ' + problem);
    process.exit(1);
  }

  console.log('');
  console.log('Semua pemeriksaan lulus.');
}

main();
