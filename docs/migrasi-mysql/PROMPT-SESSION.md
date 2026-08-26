# Prompt untuk Setiap Session

Salin blok yang berkenaan sebagai **mesej pertama** dalam session baharu.
Prompt ini sengaja pendek — konteks sebenar ada dalam PELAN.md dan PROGRES.md,
dan itu yang perlu dibaca dahulu.

**13 fasa merentas 5 session.**

| Session | Fasa | Hasil |
|---|---|---|
| 1 | 1–3 | Jualan kaunter berfungsi dengan DB |
| 2 | 4–6 | Kedai runcit siap sepenuhnya |
| 3 | 7–9 | Kedai makan siap sepenuhnya |
| 4 | 10–12 | Operasi & admin penuh |
| 5 | 13 | Dokumentasi |

---

## Session 1 — Teras (Fasa 1–3)

```
Kita migrasikan KedaiPOS dari localStorage ke MySQL + PHP vanila.

Baca dulu, ikut susunan:
1. CLAUDE.md — konvensyen projek
2. docs/migrasi-mysql/PELAN.md — keputusan reka bentuk yang sudah disahkan
3. docs/migrasi-mysql/PROGRES.md — status semasa

Ada satu soalan bertanda "Perlu dijawab sebelum Fasa 1" dalam PROGRES.md.
Tanya aku dulu sebelum tulis schema.sql.

Buat Fasa 1, 2 dan 3 sahaja. Jangan mula Fasa 4.

Peraturan:
- Ikut skema 19 jadual dalam PELAN.md. Kalau ada yang tak masuk akal semasa
  kerja, beritahu aku dulu sebelum ubah, dan catat dalam log keputusan
  di hujung PROGRES.md.
- Semua jualan lalui jadual orders, termasuk jualan kaunter biasa
  (order_type = counter, dibuka dan ditutup serentak). Ini keputusan 4.1
  dalam PELAN.md — jangan tulis terus ke transactions, kalau tidak Fasa 9
  kena tulis semula fasa ini.
- business_day dikira dari settings.day_cutoff_time, BUKAN CURDATE().
- Guna pengguna MySQL pos_user, bukan root. Jangan sentuh database tuisyen.
- Port calcUnitPrice(), makeLineId(), getTotals() dari JS sedia ada — jangan
  tulis logik harga dari awal.
- Tiga peranan: admin, cashier, waiter. Waiter tiada akses bayaran, dan itu
  kena disemak di dalam endpoint, bukan sekadar sorok butang.
- Satu job class satu kerja. Fail dalam api/ mesti nipis.
- Uji dengan Playwright: buat jualan sebenar melalui browser, kemudian sahkan
  barisnya masuk ke orders, order_items, transactions, transaction_items dan
  stock_movements. Refresh browser dan sahkan stok kekal berkurang.
- Commit berasingan setiap fasa. Kemas kini PROGRES.md sebelum commit terakhir.
```

---

## Session 2 — Kedai Runcit Siap (Fasa 4–6)

```
Sambung pembinaan KedaiPOS.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-3 sepatutnya sudah bertanda siap

Sebelum tulis kod baharu, sahkan Fasa 1-3 masih berfungsi: buka POS juruwang,
buat satu jualan ujian, pastikan ia masuk DB.

Buat Fasa 4, 5 dan 6 sahaja.

Peraturan:
- Barcode: pengimbas USB berkelakuan sebagai papan kekunci — ia menaip digit
  dan tekan Enter. Tiada driver, tiada library. Jangan cari penyelesaian
  yang lebih rumit daripada itu.
- Fasa 5 (resit termal) menukar pendekatan cetak sepenuhnya, bukan tampal
  CSS. Baca bahagian Fasa 5 dalam PROGRES.md habis dulu — ada tiga sebab
  cara lama gagal dan tiga perangkap driver yang dijangka.
- Buang blok @media print lama dari css/style.css. Jangan tinggal dua
  mekanisme cetak yang bersaing.
- Ada dua keputusan menunggu aku dalam bahagian Fasa 5 (lebar kertas lalai,
  emoji pada resit). Tanya bila sampai situ.
- Bahagian admin BERASINGAN sepenuhnya di /admin/ dengan sidebar sendiri.
  Butang Variasi di navbar juruwang sudah dibuang dalam Fasa 3 — jangan
  masukkan semula.
- Muat naik gambar: sahkan jenis fail dengan finfo, had 2MB, nama fail jadi
  hash, uploads/.htaccess halang PHP.
- Uji dengan Playwright. Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 3 — Kedai Makan: Pesanan (Fasa 7–9)

```
Sambung pembinaan KedaiPOS — bahagian kedai makan.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — beri perhatian pada bahagian 4 (tiga
   keputusan seni bina) dan bahagian 7 (aliran kerja setiap mod)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-6 sepatutnya sudah bertanda siap

Tukar settings.business_type kepada restaurant sebelum mula menguji.

Buat Fasa 7, 8 dan 9.

Peraturan:
- orders dan transactions adalah DUA benda berbeza. orders = apa yang
  dipesan (boleh berubah). transactions = apa yang dibayar (kekal).
  Gabung bil: banyak order → satu transaction. Pecah bil: satu order →
  banyak transaction.
- Stok ditolak SEMASA PESANAN DIBUAT, bukan semasa bayaran. Kalau tunggu
  bayaran, dua meja boleh pesan ikan terakhir yang sama. Batal pesanan
  mesti pulangkan stok.
- Nombor take-away unik setiap business_day dan reset harian. business_day
  dikira dari day_cutoff_time — uji pada jam 01:00, ia mesti ikut hari
  semalam.
- Pecah bil mesti kemas kini order_items.paid_qty dalam DB transaction yang
  sama. Kalau tidak, item sama boleh dibayar dua kali. Ini kena diuji
  secara khusus.
- Waiter TIADA akses bayaran. Uji dengan curl, bukan sekadar tengok UI —
  panggil endpoint bayaran guna sesi waiter dan pastikan ia ditolak 403.
- Aplikasi waiter mobile-first. Uji pada viewport 390x844.
- Uji dengan Playwright. Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 4 — Operasi & Admin Penuh (Fasa 10–12)

```
Sambung pembinaan KedaiPOS.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-9 sepatutnya sudah bertanda siap

Buat Fasa 10, 11 dan 12.

Peraturan:
- Void dan refund adalah dua perkara berbeza. Void = silap juruwang, tanda
  status void, stok pulang penuh. Refund = pelanggan pulang barang kemudian,
  jadi rekod baharu bernilai negatif berpaut pada resit asal.
- Laporan mesti tolak refund dan kecualikan transaksi void. Sahkan jumlah
  dalam laporan sama dengan jumlah dikira terus dari DB melalui SQL —
  jangan percaya paparan sahaja.
- Kadar cukai, caj perkhidmatan dan caj bungkus dibaca dari jadual settings,
  bukan pemalar dalam kod. Uji: tukar kadar, buat jualan baharu, sahkan
  kadar baharu digunakan dan jualan lama tidak berubah.
- Uji tukar business_type ke retail: meja, waiter dan jenis pesanan mesti
  hilang sepenuhnya dari UI, bukan sekadar tersorok.
- Uji dengan Playwright. Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 5 — Dokumentasi (Fasa 13)

```
Fasa terakhir KedaiPOS — dokumentasi.

Baca dulu:
1. CLAUDE.md
2. docs/migrasi-mysql/PROGRES.md — Fasa 1-12 sepatutnya sudah siap

Buat Fasa 13.

Peraturan:
- Tiga panduan berasingan sebab tiga peranan berbeza: juruwang, waiter,
  admin. Jangan campur jadi satu dokumen.
- Guna skill user-manual-auto untuk jana screenshot baharu.
- Panduan sedia ada dalam docs/panduan-pengguna.md merujuk skrin lama yang
  sudah tidak wujud — kena ganti, bukan tampal.
- docs/variasi/ juga perlu dikemas kini: editor variasi kini halaman penuh
  dalam admin, bukan modal.
- Hujung session: jalankan /code-review ke atas keseluruhan projek.
- Tandakan PROGRES.md siap sepenuhnya.
```

---

## Kalau session terputus di tengah fasa

```
Sambung kerja KedaiPOS yang terhenti.

Baca docs/migrasi-mysql/PROGRES.md dan docs/migrasi-mysql/PELAN.md.
Kemudian jalankan `git log --oneline -10` dan `git status` untuk lihat
di mana kerja sebenarnya terhenti.

Beritahu aku apa yang kau dapati dan apa langkah seterusnya SEBELUM
mula menulis kod.
```
