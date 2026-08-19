---
name: git-staged
description: Semak dan ringkaskan perubahan Git yang sedang staged sebelum commit — kumpulkan diff, terangkan apa yang berubah dalam Bahasa Melayu, kesan isu (rahsia terdedah, kod debug tertinggal, fail tersalah stage, pelanggaran konvensyen projek), dan cadangkan mesej commit. Guna skill ini setiap kali pengguna menyebut staged, "git add", "sebelum commit", "apa yang saya dah ubah", "review perubahan", "semak diff", "cuba tengok dulu sebelum saya push", "ok ke commit ni", "summary perubahan", atau meminta mesej commit — walaupun mereka tidak menyebut perkataan "staged" atau "review" secara khusus. Guna juga apabila pengguna baru sahaja selesai satu kerja dan bertanya "dah okey?" dalam konteks repo Git.
---

# Semakan Perubahan Staged

Skill ini menghasilkan satu laporan Bahasa Melayu tentang apa yang sedang berada dalam
staging area Git, supaya pengguna boleh commit dengan yakin.

Bezanya dengan sekadar membaca `git diff --staged` sendiri: diff memberitahu **baris mana
berubah**, sedangkan pengguna perlu tahu **apa kesan perubahan itu** dan **adakah ada
sesuatu yang tidak sepatutnya masuk**. Laporan yang berguna menjawab dua soalan itu.

Prinsip yang memandu keseluruhan skill ini: **staging area ialah pintu terakhir sebelum
sesuatu masuk ke sejarah repo secara kekal.** Selepas commit dan push, membetulkan fail
tersalah stage atau rahsia terdedah jauh lebih mahal. Sebab itulah semakan ini berbaloi
walaupun perubahannya nampak kecil.

Jalankan kelima-lima langkah sampai habis tanpa berhenti bertanya, melainkan tiada
apa-apa yang staged.

---

## Langkah 1 — Kumpul perubahan

Jalankan skrip pengumpul dari akar repo:

```bash
node .claude/skills/git-staged/scripts/collect-staged.js
```

Skrip ini menggantikan beberapa panggilan `git` berasingan kerana ia sudah menguruskan
perkara yang mudah terlepas pandang: fail binari (yang diffnya tidak bermakna), diff
terlalu besar (yang boleh menenggelamkan konteks), repo yang belum ada commit pertama,
dan imbasan corak mencurigakan. Keluarannya satu laporan teks siap untuk dibaca.

Bendera berguna:

| Bendera | Bila digunakan |
|---|---|
| `--files-only` | Perubahan sangat besar dan anda mahu tinjau senarai fail dahulu |
| `--max-lines-per-file N` | Had baris diff setiap fail (asal: 400) |
| `--max-total-lines N` | Had jumlah keseluruhan baris diff (asal: 3000) |
| `--repo <laluan>` | Repo bukan di direktori semasa |

Jika laporan menunjukkan sesuatu dipotong dan bahagian itu penting untuk penilaian anda,
baca fail berkenaan secara khusus dengan `git diff --staged -- <laluan-fail>`.

**Jika tiada apa-apa staged** (skrip keluar dengan kod 3): jangan teruskan dan jangan
reka-reka laporan. Beritahu pengguna tiada apa-apa yang staged, tunjukkan fail yang
berubah tetapi belum staged (skrip sudah senaraikannya), dan tanya sama ada mereka mahu
anda `git add` fail tertentu dahulu. Pengguna sering menyangka mereka sudah `git add`
sedangkan belum — memberitahu mereka lebih berguna daripada menyemak diff kosong.

**Jika bukan repo Git** (kod 4): beritahu pengguna, dan jangan jalankan `git init`
sendiri tanpa kebenaran mereka.

## Langkah 2 — Fahami apa yang berubah

Baca diff dan bina gambaran yang **berpusatkan kesan, bukan berpusatkan fail**. Pengguna
sudah nampak senarai fail; nilai yang anda tambah ialah menyatukan fail-fail itu menjadi
cerita yang boleh difahami.

Kumpulkan perubahan mengikut *tujuan*, bukan mengikut folder. Contohnya "borang log masuk
kini menyemak kata laluan di pelayan" mungkin merangkumi satu fail HTML, satu fail JS,
dan satu fail PHP — ketiga-tiganya satu kumpulan, kerana ia satu perubahan.

Untuk setiap kumpulan, tentukan sama ada ia **ciri baharu**, **pembetulan pepijat**,
**penyusunan semula kod**, **dokumentasi**, atau **kerja penyelenggaraan**. Ini
diperlukan untuk mesej commit di Langkah 5.

Jika sesuatu perubahan tidak jelas tujuannya selepas anda membacanya, jangan reka
penjelasan yang munasabah — nyatakan dalam laporan bahawa tujuannya tidak jelas dan
tanya pengguna. Tekaan yang salah lebih memudaratkan daripada mengaku tidak pasti,
kerana pengguna mungkin mempercayainya.

## Langkah 3 — Baca kod di sekeliling diff

Ini langkah yang paling mudah dilangkau dan paling banyak memberi pulangan.

Diff ialah lubang kunci. Ia menunjukkan baris yang berubah, tetapi menyembunyikan
perkara yang menjadikan perubahan itu betul atau salah: sama ada kod ini bersambung
dengan sistem, sama ada sistem sudah ada cara lain untuk kerja yang sama, dan sama ada
nama yang dipilih bermaksud sesuatu yang lain di tempat lain. **Pepijat yang paling mahal
bukan pepijat dalam baris yang berubah — ia percanggahan antara baris baharu dengan kod
sedia ada yang tidak muncul dalam diff langsung.**

Jadi sebelum menilai apa-apa, buka fail penuh dan selongkar repo. Soalan yang berbaloi
ditanya (senarai ini bukan borang untuk diisi — pilih yang berkaitan dengan diff di
hadapan anda):

- **Siapa memanggil kod baharu ini?** Cari namanya di seluruh repo. Jika tiada sesiapa
  memanggilnya, kerja ini belum bersambung — dan pengguna mungkin tidak sedar.
- **Adakah repo sudah ada pembantu untuk kerja yang sama?** Pemformatan nombor, tarikh,
  mata wang, pelarian HTML — jika perubahan ini membuat sendiri sedangkan seluruh
  codebase memanggil satu fungsi pembantu, hasilnya akan kelihatan berbeza daripada
  bahagian lain sistem.
- **Adakah sudah ada mekanisme untuk masalah yang sama?** Dua mekanisme yang tidak kenal
  satu sama lain akan bertembung, atau salah satunya akan dilupakan.
- **Adakah nama baharu ini sudah bermaksud sesuatu yang lain dalam sistem ini?** Istilah
  yang sama membawa dua maksud akan mengelirukan orang seterusnya yang membaca kod itu.
- **Apa yang berlaku kepada pemanggil sedia ada?** Jika tandatangan fungsi atau bentuk
  data yang disimpan berubah, cari setiap tempat yang bergantung padanya.

Anda tidak perlu menjawab kesemuanya untuk setiap diff — perubahan satu baris dalam
fail dokumentasi tidak memerlukan penyiasatan. Gunakan pertimbangan: makin banyak kod
baharu, makin berbaloi menyelongkar.

Penemuan daripada langkah ini biasanya yang paling bernilai kepada pengguna, kerana ia
perkara yang mereka sendiri tidak nampak semasa menulis kod itu.

## Langkah 4 — Semak isu

Baca `references/senarai-semak.md` sekarang dan gunakannya terhadap diff.

Bahagian "ISYARAT AUTOMATIK" dalam laporan skrip ialah titik permulaan, bukan kesimpulan.
Setiap padanan mesti disahkan sendiri dalam diff sebelum dilaporkan: `console.log` dalam
skrip alat pembangunan memang sepatutnya ada, `password` dalam nama medan borang bukan
rahsia terdedah, dan `style="..."` dalam templat e-mel sering tiada pilihan lain.
Melaporkan padanan mentah tanpa menilai konteks akan menghakis kepercayaan pengguna
terhadap keseluruhan laporan.

Semak juga diff terhadap konvensyen projek. Jika repo mempunyai `CLAUDE.md`,
`CONTRIBUTING.md`, atau fail konfigurasi linter, baca fail itu dan semak terhadap
peraturan yang benar-benar tertulis di dalamnya. Jangan andaikan peraturan daripada
projek lain.

Susun penemuan mengikut keterukan:

| Tahap | Maksud |
|---|---|
| 🔴 **Kritikal** | Jangan commit sebelum dibetulkan — rahsia terdedah, kod pecah, fail tersalah stage |
| 🟡 **Perlu semak** | Mungkin betul, tetapi pengguna patut sahkan dahulu |
| 🔵 **Cadangan** | Boleh diperbaiki, tidak menghalang commit |

Setiap penemuan mesti menunjukkan fail dan baris yang tepat, menerangkan **kesannya**
(apa yang akan rosak, bagi siapa), dan mencadangkan pembetulan konkrit. Penemuan tanpa
lokasi tidak boleh ditindaklanjuti, jadi ia tidak layak dimasukkan.

Jika anda tidak menemui apa-apa isu sebenar, **katakan begitu dengan jelas**. Menokok
laporan dengan pemerhatian lemah semata-mata untuk mengisi ruang akan melatih pengguna
supaya melangkau bahagian ini — dan mereka akan turut terlepas isu sebenar pada masa
hadapan.

## Langkah 5 — Tulis laporan

Guna templat ini:

<pre>
# Semakan Perubahan Staged

**Cawangan:** &lt;nama&gt;  ·  **Fail:** &lt;N&gt;  ·  **Baris:** +&lt;tambah&gt; / -&lt;buang&gt;

## Ringkasan
&lt;Satu hingga tiga ayat: apa yang perubahan ini capai secara keseluruhan.
Tulis untuk seseorang yang belum melihat kodnya.&gt;

## Apa yang berubah

### &lt;Nama kumpulan — ikut tujuan, bukan nama folder&gt;
- &lt;perubahan konkrit&gt; — `laluan/fail.js`
- &lt;perubahan konkrit&gt; — `laluan/lain.html`

### &lt;Kumpulan seterusnya&gt;
...

## Isu perlu diberi perhatian

### 🔴 Kritikal
- **`fail.js:42`** — &lt;masalah&gt;. &lt;Kesan jika dibiarkan.&gt;
  Cadangan: &lt;pembetulan konkrit&gt;

### 🟡 Perlu semak
- ...

### 🔵 Cadangan
- ...

&lt;Jika tiada isu langsung, ganti keseluruhan bahagian ini dengan:
"Tiada isu ditemui. Perubahan ini selamat untuk di-commit."&gt;

## Konvensyen projek
&lt;Semakan terhadap peraturan dalam CLAUDE.md/CONTRIBUTING.md. Nyatakan peraturan mana
dipatuhi dan mana dilanggar. Jika repo tiada fail konvensyen, tulis:
"Repo ini tiada fail konvensyen — bahagian ini dilangkau."&gt;

## Cadangan mesej commit
&lt;blok kod mengandungi mesej commit siap salin&gt;
</pre>

Nada laporan: terus dan ringkas, seperti rakan sekerja yang membaca kod anda sebelum
anda tekan commit. Elakkan pujian kosong ("Bagus sekali!") dan elakkan juga nada
menghukum. Nyatakan sahaja apa yang anda nampak.

### Format mesej commit

Guna *conventional commits* dengan ringkasan Bahasa Melayu. Jenis yang lazim:
`feat` (ciri baharu), `fix` (pembetulan pepijat), `docs` (dokumentasi),
`refactor` (susun semula tanpa ubah kelakuan), `style` (format), `test` (ujian),
`chore` (penyelenggaraan).

Struktur: `<jenis>(<skop>): <ringkasan huruf kecil, tanpa noktah>`, diikuti baris kosong
dan badan mesej. Badan menerangkan **sebab**, kerana diff sudah menerangkan **apa**. Jika
sebabnya sudah jelas sepenuhnya daripada ringkasan, tinggalkan badan kosong.

**Contoh 1**
Diff: fungsi `kiraBaki()` ditambah dalam `js/app.js`, modal bayaran dalam `index.html`

```
feat(bayaran): tambah pengiraan wang baki dalam modal bayaran

Juruwang sebelum ini mengira baki secara manual dan tersilap semasa waktu sibuk.
```

**Contoh 2**
Diff: satu baris `parseFloat` ditukar kepada `Math.round(x * 100) / 100`

```
fix(troli): bundarkan jumlah harga kepada dua tempat perpuluhan

Ralat titik apung menyebabkan jumlah troli terpapar sebagai 12.300000000000001.
```

**Contoh 3**
Diff: semata-mata fail README dan komen dikemas kini

```
docs: kemas kini arahan pemasangan
```

Jika perubahan yang staged sebenarnya mengandungi dua kerja berasingan, cadangkan **dua**
mesej commit dan terangkan fail mana untuk yang mana. Commit yang fokus lebih mudah
di-`revert` apabila salah satunya bermasalah nanti.

---

## Selepas laporan

Berhenti selepas laporan dan biarkan pengguna membuat keputusan. **Jangan jalankan
`git commit` sendiri melainkan pengguna memintanya** — mereka mungkin mahu membetulkan
sesuatu, memecahkan commit, atau meng-`unstage` fail dahulu. Commit yang dibuat tanpa
diminta menghilangkan tujuan semakan ini.

Jika terdapat penemuan 🔴 Kritikal, tawarkan untuk membetulkannya. Jika pengguna
bersetuju untuk commit selepas itu, guna mesej yang anda cadangkan (atau versi yang
mereka ubah).
