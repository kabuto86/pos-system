---
name: user-manual-auto
description: Jana panduan pengguna (user manual) lengkap untuk aplikasi web secara automatik — terokai sistem sendiri, rakam screenshot setiap langkah menggunakan Playwright MCP, dan hasilkan dokumen berbahasa Melayu dalam format Markdown dan PDF. Guna skill ini setiap kali pengguna menyebut user manual, panduan pengguna, manual pengguna, buku panduan, dokumentasi sistem, tutorial langkah demi langkah, "screenshot setiap langkah", "buatkan dokumentasi untuk app ni", atau apa sahaja permintaan untuk menerangkan cara menggunakan sesuatu aplikasi web kepada pengguna akhir — walaupun mereka tidak menyebut perkataan "manual" secara khusus.
---

# Panduan Pengguna Automatik

Skill ini menghasilkan tiga artifak daripada satu aplikasi web yang sedang berjalan:

| Fail | Kegunaan |
|---|---|
| `docs/images/NN-*.png` | Screenshot sebenar bagi setiap langkah |
| `docs/panduan-pengguna.md` | Manual dalam Markdown (mudah dibaca dalam repo/GitHub) |
| `docs/panduan-pengguna.pdf` | Manual siap cetak A4 (dijana daripada HTML + Bootstrap) |

Prinsip utama: **manual ini ditulis untuk pengguna akhir, bukan untuk pembangun.** Orang
yang membacanya mahu tahu *butang mana perlu ditekan dan apa yang akan berlaku* — bukan
struktur kod atau nama fungsi. Sebab itulah setiap langkah mesti disertakan gambar skrin
sebenar dan contoh konkrit (nama produk sebenar, harga sebenar), bukan penerangan abstrak.

Jalankan aliran kerja ini sampai habis tanpa berhenti bertanya, melainkan sistem tidak
dapat dicapai atau anda menemui sesuatu yang benar-benar mengelirukan.

---

## Langkah 1 — Tentukan sasaran dan sahkan ia hidup

Tentukan URL sistem sebelum apa-apa kerja lain, kerana keseluruhan skill bergantung pada
pelayar yang benar-benar boleh membuka halaman itu.

- Projek dalam `htdocs` (XAMPP): URL biasanya `http://localhost/<nama-folder>/`
- Projek Node/Vite: cari port dalam `package.json` atau `vite.config.js` (contoh `http://localhost:5173`)
- Jika pengguna sudah beri URL, guna URL itu.

Sahkan ia hidup dahulu:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost/<nama-folder>/
```

Jika bukan `200`, beritahu pengguna pelayan perlu dihidupkan (contoh: mulakan Apache dalam
XAMPP Control Panel, atau `npm run dev`) dan berhenti di situ. Meneruskan tanpa pelayan
hanya menghasilkan screenshot halaman ralat.

Folder output lalai ialah `docs/` di akar projek. Cipta `docs/images/` jika belum ada.

---

## Langkah 2 — Baca kod sumber sebelum membuka pelayar

Baca fail antara muka utama (`index.html`, `js/*.js`, atau komponen setara) **sebelum**
mula mengklik. Ini bukan langkah pilihan — ia menjimatkan banyak masa kerana:

- Anda dapat label sebenar dalam bahasa asal sistem (contoh "Bayar", "Ada pilihan",
  "Troli masih kosong"). Manual mesti guna perkataan yang pengguna nampak di skrin,
  bukan terjemahan anda sendiri.
- Anda nampak ciri tersembunyi yang tidak jelas dari skrin — modal, pengesahan,
  keadaan kosong, produk habis stok, pengiraan cukai/diskaun.
- Anda tahu data ujian yang wujud, jadi contoh dalam manual boleh guna nilai sebenar.

Daripada bacaan itu, bina senarai langkah yang mengikut **satu aliran kerja lengkap dari
mula sampai selesai** (contoh: buka sistem → pilih produk → bayar → resit → sejarah).
Susunan naratif begini jauh lebih berguna daripada senarai ciri yang berselerak, kerana
pengguna baharu belajar dengan mengikut satu urutan sebenar.

Rekod senarai ini dalam TodoWrite supaya progres kelihatan, kemudian teruskan.

---

## Langkah 3 — Rakam screenshot dengan Playwright MCP

Baca `references/screenshot-playbook.md` untuk teknik penuh (menu terbuka, modal, keadaan
hover, elemen tertentu, data ujian). Ringkasan mekanik yang mesti dipatuhi:

**Tetapkan saiz tetingkap sekali sahaja pada permulaan:**

```
browser_resize → width: 1440, height: 900
```

Semua screenshot mesti sama saiz. Jika saiz berubah di tengah jalan, gambar dalam PDF
akan bertukar-tukar skala dan manual nampak tidak kemas.

**Simpan terus ke folder projek.** Parameter `filename` pada `browser_take_screenshot`
menerima laluan relatif dari akar projek, jadi guna terus:

```
browser_take_screenshot → filename: "docs/images/01-halaman-utama.png", scale: "css"
```

Fail akan terus jatuh dalam `docs/images/`. Tidak perlu salin dari folder sementara.

**Kitaran untuk setiap langkah:**

1. `browser_snapshot` — dapatkan rujukan elemen semasa (jangan teka selector)
2. Lakukan tindakan (`browser_click`, `browser_type`, `browser_select_option`)
3. `browser_take_screenshot` dengan nama fail berformat `NN-nama-langkah.png`

**Penamaan fail** guna nombor dua digit mengikut urutan langkah dan nama Bahasa Inggeris
ringkas atau slug Melayu tanpa tanda baca — contoh `01-halaman-utama.png`,
`05-modal-variasi.png`, `11-modal-bayaran.png`. Nombor berjujukan penting supaya susunan
fail dalam folder sepadan dengan susunan dalam manual.

**Guna screenshot viewport (lalai), bukan `fullPage`,** melainkan halaman itu benar-benar
panjang dan isinya penting semua. Gambar `fullPage` yang tinggi dan kurus akan mengecil
teruk apabila dimuatkan ke halaman A4 sehingga teks tidak dapat dibaca.

Selepas semua rakaman selesai, tutup pelayar dengan `browser_close` dan buang folder
`.playwright-mcp/` yang terhasil di akar projek — ia fail sementara, bukan sebahagian
daripada hasil kerja.

---

## Langkah 4 — Tulis manual dalam Markdown

Tulis ke `docs/panduan-pengguna.md`. Baca `references/penulisan-bm.md` untuk gaya bahasa,
istilah teknikal Melayu, dan ayat contoh sebelum mula menulis.

Guna struktur ini — ia terbukti mudah diikuti dan menghasilkan PDF yang kemas:

```markdown
# Panduan Pengguna — <Nama Sistem>

**<Subtajuk: apa yang manual ini ajar>**

Versi 1.0 · Kemas kini <tarikh hari ini dalam Bahasa Melayu>

---

## Kandungan
<senarai bernombor dengan pautan ke setiap tajuk>

---

## 1. Pengenalan
<apa itu sistem ini, untuk siapa, apa yang manual ini liputi>

**Keperluan:**
- <pelayar, URL, akaun jika ada>

---

## 2. Mengenali Antara Muka
<jadual: Bahagian | Lokasi | Fungsi>
![Antara muka utama](images/01-halaman-utama.png)
<senarai maklumat penting pada skrin, contoh maksud label dan warna>

---

## Langkah 1 — <Kata kerja + objek>
<satu atau dua perenggan arahan>
<contoh konkrit dengan data sebenar>
![Kapsyen bermakna](images/NN-nama.png)
> **Nota:** <perkara yang pengguna mudah tersilap di langkah ini>

---
<ulang untuk setiap langkah>

## Petua Pantas
<senarai pintasan dan tabiat kerja yang mempercepatkan tugas>

## Masalah Lazim
<jadual: Masalah | Sebab | Penyelesaian>
```

Perkara yang membezakan manual berguna daripada manual kosong:

- **Setiap langkah ada gambar.** Jika satu langkah tiada screenshot, sama ada langkah itu
  tidak perlu wujud, atau anda terlepas merakamnya — betulkan salah satu.
- **Kapsyen menerangkan apa yang berlaku**, bukan mengulang tajuk. Tulis
  `![Roti Canai ditambah ke troli]`, bukan `![Screenshot 4]`.
- **Nota dan petua diletakkan tepat di tempat pengguna akan tersilap.** Contoh: "Butang
  **Bayar** dilumpuhkan selagi troli kosong" diletak di langkah troli kosong, bukan di
  bahagian Masalah Lazim sahaja.
- **Nama butang ditebalkan** (`**Bayar**`) supaya mata pembaca terus jumpa di skrin.
- **Jadual untuk perkara berkelompok** — maksud simbol, kategori, kadar cukai. Perenggan
  panjang yang menyenaraikan enam perkara lebih sukar diimbas berbanding jadual enam baris.

---

## Langkah 5 — Bina versi HTML untuk PDF

PDF dijana daripada HTML, bukan terus daripada Markdown, kerana hanya dengan HTML kita
dapat kawal pemisahan halaman, muka depan, dan saiz gambar dalam ruang A4.

1. Salin `assets/print.css` ke `docs/print.css`.
2. Bina `docs/panduan-pengguna.html` mengikut rangka `assets/manual-template.html` —
   kandungannya sama dengan Markdown tadi, tetapi dibungkus dengan kelas Bootstrap.

Peraturan yang mesti dipatuhi:

- **Jangan guna CSS inline.** Semua gaya datang daripada Bootstrap atau `print.css`.
  Jika satu gaya tidak dapat dicapai dengan kelas Bootstrap, tambah peraturan bernama
  dalam `print.css`.
- Pautkan Bootstrap tempatan jika projek sudah ada (contoh `../vendor/bootstrap/bootstrap.min.css`).
  Jika tiada, muat turun sekali ke `vendor/bootstrap/` supaya PDF boleh dijana walaupun
  tanpa internet.
- Setiap seksyen langkah dibalut `<section class="page-break">` supaya bermula pada
  halaman baharu — ini yang menjadikan PDF senang dirujuk semasa dicetak.
- Setiap gambar dibalut `<figure class="doc-figure">` dengan `<figcaption>`, kerana
  `print.css` menghalang figure daripada terpotong antara halaman.
- Laluan gambar dalam HTML adalah `images/NN-nama.png` — sama seperti dalam Markdown.

---

## Langkah 6 — Jana PDF

```bash
node .claude/skills/user-manual-auto/scripts/html-to-pdf.js docs/panduan-pengguna.html docs/panduan-pengguna.pdf
```

Skrip ini mencari pelayar Chromium yang sedia ada dalam sistem (Edge, Chrome, atau
Chromium milik Playwright) dan mencetak halaman ke PDF. Ia tidak memerlukan `npm install`,
Python, `pandoc` atau `wkhtmltopdf` — sengaja begitu supaya skill ini berfungsi pada mesin
kosong.

Jika skrip melaporkan tiada pelayar dijumpai, beritahu pengguna dan tawarkan untuk
menetapkan pembolehubah persekitaran `BROWSER_BIN` ke laluan pelayar mereka.

---

## Langkah 7 — Sahkan hasil sebelum melapor

Jangan lapor siap sebelum pemeriksaan ini lulus — manual dengan gambar rosak lebih buruk
daripada tiada manual, kerana pengguna hilang kepercayaan pada keseluruhan dokumen.

```bash
node .claude/skills/user-manual-auto/scripts/verify-manual.js docs/panduan-pengguna.md
```

Skrip ini menyemak setiap pautan gambar dalam Markdown benar-benar wujud, melaporkan
gambar yatim (ada dalam folder tetapi tidak dirujuk), dan mengesahkan PDF terhasil dengan
saiz munasabah.

Kemudian laporkan kepada pengguna dalam Bahasa Melayu: bilangan langkah, bilangan
screenshot, lokasi ketiga-tiga fail, dan apa-apa bahagian sistem yang sengaja tidak
diliputi (contoh panel admin yang memerlukan log masuk).

---

## Fail rujukan

- `references/screenshot-playbook.md` — teknik merakam modal, dropdown, keadaan hover,
  elemen tunggal, dan cara menyediakan data ujian yang kelihatan kemas dalam gambar
- `references/penulisan-bm.md` — gaya bahasa, istilah teknikal Melayu, dan contoh ayat
  arahan yang baik berbanding lemah
- `assets/manual-template.html` — rangka HTML lengkap dengan muka depan dan seksyen langkah
- `assets/print.css` — gaya cetakan A4
- `scripts/html-to-pdf.js` — penjana PDF
- `scripts/verify-manual.js` — penyemak kesempurnaan manual
