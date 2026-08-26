# Prompt untuk Setiap Session

Salin blok yang berkenaan sebagai **mesej pertama** dalam session baharu.
Prompt ini sengaja pendek — konteks sebenar ada dalam PELAN.md dan PROGRES.md,
dan itu yang perlu dibaca dahulu.

**16 fasa merentas 6 session.**

| Session | Fasa | Hasil |
|---|---|---|
| 1 | 1–3 | Jualan kaunter berfungsi, dua vendor terasing |
| 2 | 4–6 | Kedai runcit siap sepenuhnya |
| 3 | 7–9 | Kedai makan siap sepenuhnya |
| 4 | 10–12 | Operasi & admin kedai penuh |
| 5 | 13–15 | Platform SaaS + audit kebocoran |
| 6 | 16 | Dokumentasi |

---

## Session 1 — Teras Multi-Tenant (Fasa 1–3)

```
Kita bina KedaiPOS sebagai SaaS: satu kod, satu DB, banyak vendor.
Asalnya sistem localStorage — sekarang dipindahkan ke MySQL + PHP vanila.

Baca dulu, ikut susunan:
1. CLAUDE.md — konvensyen projek
2. docs/migrasi-mysql/PELAN.md — beri perhatian penuh pada bahagian 3
   (peraturan multi-tenant). Itu bahagian yang menentukan sistem ini
   selamat atau bocor.
3. docs/migrasi-mysql/PROGRES.md — status semasa

Buat Fasa 1, 2 dan 3 sahaja. Jangan mula Fasa 4.

Peraturan multi-tenant (paling penting):
- vendor_id datang dari SESI, tidak pernah dari $_POST atau $_GET.
  Kalau endpoint terima vendor_id dari browser, vendor A boleh tukar satu
  nombor dan baca data vendor B.
- Setiap pertanyaan menapis vendor_id. Tiada pengecualian.
- Tiada SQL mentah dalam api/. Semua dalam job class.
- Seed WAJIB ada dua vendor: KEDAI01 (retail) dan KEDAI02 (restaurant).
  Dengan satu vendor sahaja, kebocoran mustahil dikesan.
- Setiap UNIQUE jadi unik per vendor (PELAN.md 3.5). Setiap indeks bermula
  dengan vendor_id (PELAN.md 3.6).

Peraturan lain:
- Ikut skema 22 jadual dalam PELAN.md. Kalau ada yang tak masuk akal semasa
  kerja, beritahu aku dulu sebelum ubah, dan catat dalam log keputusan
  di hujung PROGRES.md.
- Semua jualan lalui jadual orders, termasuk jualan kaunter biasa
  (order_type = counter). Ini keputusan 7.1 PELAN.md — jangan tulis terus
  ke transactions, kalau tidak Fasa 9 kena tulis semula fasa ini.
- business_day dikira dari settings.day_cutoff_time, BUKAN CURDATE().
- Guna pengguna MySQL pos_user, bukan root. Jangan sentuh database tuisyen.
- Port calcUnitPrice(), makeLineId(), getTotals() dari JS sedia ada.
- Empat peranan: superadmin, admin, cashier, waiter. Waiter tiada akses
  bayaran, disemak di dalam endpoint, bukan sekadar sorok butang.

Ujian wajib setiap fasa:
- Log masuk KEDAI01, cipta data. Log masuk KEDAI02, sahkan data KEDAI01
  tidak kelihatan.
- Ambil id rekod KEDAI01, cuba capai melalui API sebagai KEDAI02 —
  mesti 404 atau 403, bukan data.

Commit berasingan setiap fasa. Kemas kini PROGRES.md sebelum commit terakhir.
```

---

## Session 2 — Kedai Runcit Siap (Fasa 4–6)

```
Sambung pembinaan KedaiPOS SaaS.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — bahagian 3 (peraturan multi-tenant)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-3 sepatutnya sudah bertanda siap

Sebelum tulis kod baharu, sahkan Fasa 1-3 masih berfungsi: log masuk
KEDAI01, buat satu jualan ujian, pastikan ia masuk DB dengan vendor_id betul.

Buat Fasa 4, 5 dan 6 sahaja.

Peraturan:
- Barcode: pengimbas USB berkelakuan sebagai papan kekunci — ia menaip digit
  dan tekan Enter. Tiada driver, tiada library. Jangan cari penyelesaian
  yang lebih rumit daripada itu. Barcode unik PER VENDOR, bukan global —
  dua kedai memang jual barang sama.
- Fasa 5 (resit termal) menukar pendekatan cetak sepenuhnya, bukan tampal
  CSS. Baca bahagian Fasa 5 dalam PROGRES.md habis dulu — ada tiga sebab
  cara lama gagal dan tiga perangkap driver yang dijangka.
- print/receipt.php terima id dalam URL, jadi ia sasaran kebocoran paling
  jelas dalam sistem. Semak vendor_id sebelum papar apa-apa.
- Buang blok @media print lama dari css/style.css. Jangan tinggal dua
  mekanisme cetak yang bersaing.
- Ada dua keputusan menunggu aku dalam bahagian Fasa 5 (lebar kertas lalai,
  emoji pada resit). Tanya bila sampai situ.
- Muat naik gambar ke uploads/products/{vendor_id}/. Sahkan jenis fail
  dengan finfo, had 2MB, nama fail jadi hash, .htaccess halang PHP.
- Bahagian admin kedai BERASINGAN di /admin/ dengan sidebar sendiri.
  Butang Variasi di navbar juruwang sudah dibuang dalam Fasa 3 — jangan
  masukkan semula.

Ujian kebocoran setiap fasa seperti biasa. Commit berasingan setiap fasa.
Kemas kini PROGRES.md.
```

---

## Session 3 — Kedai Makan: Pesanan (Fasa 7–9)

```
Sambung pembinaan KedaiPOS SaaS — bahagian kedai makan.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — bahagian 3 (multi-tenant), 7 (tiga
   keputusan seni bina) dan 8 (aliran kerja setiap mod)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-6 sepatutnya sudah bertanda siap

Uji sebagai vendor KEDAI02 (restaurant).

Buat Fasa 7, 8 dan 9.

Peraturan:
- orders dan transactions adalah DUA benda berbeza. orders = apa yang
  dipesan (boleh berubah). transactions = apa yang dibayar (kekal).
  Gabung bil: banyak order -> satu transaction. Pecah bil: satu order ->
  banyak transaction.
- Stok ditolak SEMASA PESANAN DIBUAT, bukan semasa bayaran. Kalau tunggu
  bayaran, dua meja boleh pesan ikan terakhir yang sama. Batal pesanan
  mesti pulangkan stok.
- Nombor take-away unik per vendor + business_day, reset harian.
  business_day dikira dari day_cutoff_time — uji pada jam 01:00, ia mesti
  ikut hari semalam. Dua vendor boleh ada take-away 001 pada hari sama.
- Pecah bil mesti kemas kini order_items.paid_qty dalam DB transaction yang
  sama. Kalau tidak, item sama boleh dibayar dua kali. Ini kena diuji
  secara khusus.
- Mustahil gabung pesanan merentas vendor — uji ini.
- Waiter TIADA akses bayaran. Uji dengan curl, bukan sekadar tengok UI —
  panggil endpoint bayaran guna sesi waiter dan pastikan ditolak 403.
- Aplikasi waiter mobile-first. Uji pada viewport 390x844.

Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 4 — Operasi & Admin Kedai (Fasa 10–12)

```
Sambung pembinaan KedaiPOS SaaS.

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
- Laporan paling mudah bocor sebab ia mengagregat. Sahkan jumlah KEDAI01
  tidak termasuk sebarang jualan KEDAI02.
- Kadar cukai, caj perkhidmatan dan caj bungkus dibaca dari settings vendor,
  bukan pemalar dalam kod. Uji: tukar kadar KEDAI01, sahkan KEDAI02 tidak
  terjejas dan jualan lama tidak berubah.
- business_type TIADA dalam tetapan kedai — ia milik superadmin (Fasa 13).

Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 5 — Platform SaaS (Fasa 13–15)

```
Sambung pembinaan KedaiPOS SaaS — lapisan platform.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — bahagian 3, 5 (peranan) dan 9 (had pelan)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-12 sepatutnya sudah bertanda siap

Buat Fasa 13, 14 dan 15.

Peraturan:
- superadmin ada vendor_id NULL. Ia menguruskan vendor, TIDAK masuk POS
  mana-mana vendor. Uji kedua-dua arah: superadmin tak boleh masuk POS,
  admin vendor tak boleh capai /superadmin/.
- Had pelan dikuatkuasa dalam job simpan, bukan hanya butang disable di UI.
  Uji dengan panggil API terus melebihi had.
- ProvisionVendorJob mesti hasilkan vendor yang terus boleh berjualan —
  tetapan lalai, kaedah bayaran, kategori, akaun admin, kaunter pertama.
  Tiada langkah manual dalam DB selepas itu.
- Fasa 15 ialah audit kebocoran menyeluruh. Ia bukan formaliti — senaraikan
  setiap pertanyaan SQL dalam jobs/ dan sahkan setiap satu menapis
  vendor_id. `grep -rn "vendor_id" api/` mesti kosong. Jalankan juga
  /security-review. Catat hasilnya dalam PROGRES.md.

Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 6 — Dokumentasi (Fasa 16)

```
Fasa terakhir KedaiPOS SaaS — dokumentasi.

Baca dulu:
1. CLAUDE.md
2. docs/migrasi-mysql/PROGRES.md — Fasa 1-15 sepatutnya sudah siap

Buat Fasa 16.

Peraturan:
- Empat panduan berasingan sebab empat peranan berbeza: juruwang, waiter,
  admin kedai, superadmin. Jangan campur jadi satu dokumen.
- Guna skill user-manual-auto untuk jana screenshot baharu.
- Panduan sedia ada dalam docs/panduan-pengguna.md merujuk skrin lama yang
  sudah tidak wujud — kena ganti, bukan tampal.
- docs/variasi/ juga perlu dikemas kini: editor variasi kini halaman penuh
  dalam admin, bukan modal.
- README pemasangan mesti termasuk cara provision vendor pertama.
- Hujung session: jalankan /code-review ke atas keseluruhan projek.
- Tandakan PROGRES.md siap sepenuhnya.
```

---

## Kalau session terputus di tengah fasa

```
Sambung kerja KedaiPOS SaaS yang terhenti.

Baca docs/migrasi-mysql/PROGRES.md dan docs/migrasi-mysql/PELAN.md.
Kemudian jalankan `git log --oneline -10` dan `git status` untuk lihat
di mana kerja sebenarnya terhenti.

Beritahu aku apa yang kau dapati dan apa langkah seterusnya SEBELUM
mula menulis kod.
```
