# Prompt untuk Setiap Session

Salin blok yang berkenaan sebagai **mesej pertama** dalam session baharu.
Prompt ini sengaja pendek — konteks sebenar ada dalam PELAN.md dan PROGRES.md,
dan itu yang perlu dibaca dahulu.

---

## Session 1 — Teras + POS Juruwang (Fasa 1–3)

```
Kita migrasikan KedaiPOS dari localStorage ke MySQL + PHP vanila.

Baca dulu, ikut susunan:
1. CLAUDE.md — konvensyen projek
2. docs/migrasi-mysql/PELAN.md — keputusan reka bentuk yang sudah disahkan
3. docs/migrasi-mysql/PROGRES.md — status semasa

Buat Fasa 1, 2 dan 3 sahaja. Jangan mula Fasa 4.

Peraturan:
- Ikut skema 14 jadual dalam PELAN.md. Kalau ada yang tak masuk akal semasa
  kerja, beritahu aku dulu sebelum ubah, dan catat dalam PROGRES.md.
- Guna pengguna MySQL pos_user, bukan root. Jangan sentuh database tuisyen.
- Port calcUnitPrice(), makeLineId(), getTotals() dari JS sedia ada — jangan
  tulis logik harga dari awal.
- Satu job class satu kerja. Fail dalam api/ mesti nipis.
- Uji dengan Playwright: buat jualan sebenar melalui browser, kemudian sahkan
  barisnya betul-betul masuk ke jadual transactions, transaction_items dan
  stock_movements. Refresh browser dan sahkan stok kekal berkurang.
- Commit berasingan setiap fasa. Kemas kini PROGRES.md sebelum commit terakhir.
```

---

## Session 2 — Cetakan + Bahagian Admin (Fasa 4–6)

```
Sambung migrasi KedaiPOS ke MySQL.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-3 sepatutnya sudah bertanda siap

Sebelum tulis kod baharu, sahkan Fasa 1-3 masih berfungsi: buka POS juruwang,
buat satu jualan ujian, pastikan ia masuk DB.

Buat Fasa 4, 5 dan 6 sahaja.

Peraturan:
- Bahagian admin BERASINGAN sepenuhnya di /admin/ dengan sidebar sendiri.
  Butang Variasi di navbar juruwang sudah dibuang dalam Fasa 3 — jangan
  masukkan semula.
- Semak peranan di dalam setiap endpoint, bukan sekadar sorok butang.
- Muat naik gambar: sahkan jenis fail dengan finfo, had 2MB, nama fail jadi
  hash, uploads/.htaccess halang PHP.
- Void dan refund adalah dua perkara berbeza — rujuk jadual perbandingan
  dalam PELAN.md bahagian 3B.
- Uji dengan Playwright. Untuk void/refund, sahkan stok dipulangkan betul.
- Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 3 — Laporan, Tetapan & Dokumentasi (Fasa 7–9)

```
Sambung migrasi KedaiPOS ke MySQL — fasa terakhir.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-6 sepatutnya sudah bertanda siap

Buat Fasa 7, 8 dan 9.

Peraturan:
- Laporan mesti tolak refund dengan betul. Sahkan jumlah dalam laporan sama
  dengan jumlah yang dikira terus dari DB melalui SQL — jangan percaya
  paparan sahaja.
- Kadar cukai kena dibaca dari jadual settings, bukan pemalar dalam kod.
  Uji: tukar kadar dalam tetapan, buat jualan baharu, sahkan kadar baharu
  digunakan dan jualan lama tidak berubah.
- Untuk Fasa 9, guna skill user-manual-auto untuk jana screenshot baharu.
  Panduan sedia ada dalam docs/panduan-pengguna.md merujuk skrin lama yang
  sudah tidak wujud — kena ganti, bukan tampal.
- Hujung session: jalankan /code-review ke atas keseluruhan kerja migrasi.
- Commit berasingan setiap fasa. Tandakan PROGRES.md siap sepenuhnya.
```

---

## Kalau session terputus di tengah fasa

```
Sambung kerja migrasi KedaiPOS yang terhenti.

Baca docs/migrasi-mysql/PROGRES.md dan docs/migrasi-mysql/PELAN.md.
Kemudian jalankan `git log --oneline -10` dan `git status` untuk lihat
di mana kerja sebenarnya terhenti.

Beritahu aku apa yang kau dapati dan apa langkah seterusnya SEBELUM
mula menulis kod.
```
