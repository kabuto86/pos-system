# Progres — Status Semasa

> **Kemas kini fail ini di HUJUNG setiap fasa**, sebelum commit. Inilah
> satu-satunya sumber kebenaran tentang di mana kerja terhenti.
> Baca [PELAN.md](PELAN.md) untuk keputusan reka bentuk.

**Status keseluruhan:** Belum bermula — pelan sahaja siap
**Fasa terakhir siap:** —
**Fasa seterusnya:** Fasa 1

**Struktur:** 13 fasa merentas 5 session.
Skop diluaskan pada 26 Ogos 2026 daripada 9 fasa / 3 session, selepas Sufi
memutuskan sistem melayani **dua jenis perniagaan** (kedai runcit & kedai
makan) dengan peranan waiter, meja, dan gabung/pecah bil.

---

## ⚠ Perlu dijawab sebelum Fasa 1

- [ ] **Satu pemasangan satu vendor, atau banyak vendor dalam satu pemasangan?**
      Lihat PELAN.md bahagian 12. Pelan sekarang menganggap **satu vendor**.
      Kalau berubah, `vendor_id` perlu ada pada **setiap** jadual dari awal —
      menambahnya selepas data wujud bermakna migrasi semua jadual.

---

## Session 1 — Teras (Fasa 1–3)

### Fasa 1 — Skema & teras
- [ ] Cipta pangkalan data `pos_system` (utf8mb4_unicode_ci)
- [ ] Cipta pengguna MySQL `pos_user` (akses `pos_system` sahaja)
- [ ] `database/schema.sql` — 19 jadual
- [ ] `database/seed.sql` — 18 produk, 3 kategori, 3 kaedah bayaran, tetapan,
      1 admin, 1 kaunter, meja contoh
- [ ] `config/database.php` + `.example.php` + kemas kini `.gitignore`
- [ ] `core/Database.php` (PDO utf8mb4), `Response.php`, `Request.php`,
      `Validator.php`, **`BusinessDay.php`**
- [ ] Sahkan: query dari CLI pulangkan 18 produk, emoji tidak rosak
- [ ] Sahkan: `BusinessDay` pulangkan tarikh semalam bila jam 01:00 dan
      cutoff 04:00 — ini punca pepijat nombor take-away kalau silap

### Fasa 2 — Auth, peranan, kaunter & syif
- [ ] `core/Auth.php`, `core/Csrf.php`
- [ ] `jobs/Auth/LoginJob.php`, `LogoutJob.php`
- [ ] **Tiga peranan**: admin, cashier, waiter
- [ ] `jobs/Terminal/…` (jenis cashier/waiter)
- [ ] `jobs/Shift/OpenShiftJob.php`, `CloseShiftJob.php`, `CurrentShiftJob.php`
- [ ] `cashier/login.php` — log masuk + pilih kaunter
- [ ] `cashier/shift.php` — buka syif (wang mula) / tutup syif (kira, beza)
- [ ] Sahkan: cashier tidak boleh masuk `/admin/`; waiter tidak boleh
      panggil endpoint bayaran **walaupun melalui curl**

### Fasa 3 — POS kaunter (jualan penuh)
- [ ] `jobs/Product/ListProductsJob.php` (produk + variasi + stok)
- [ ] `jobs/Cart/CalculateCartJob.php` (port `calcUnitPrice` + `getTotals`)
- [ ] `jobs/Order/OpenOrderJob.php`, `AddOrderItemJob.php`, `CloseOrderJob.php`
- [ ] `jobs/Stock/DeductStockJob.php` (`SELECT ... FOR UPDATE`)
- [ ] `jobs/Transaction/CreateTransactionJob.php` (DB transaction, jana `receipt_no`)
- [ ] `jobs/Transaction/ListTransactionsJob.php`, `GetReceiptJob.php`
- [ ] `api/` untuk semua di atas
- [ ] `cashier/index.php` + `cashier/js/` — pindah dari index.html,
      **buang butang Variasi dari navbar**
- [ ] Sahkan dengan Playwright: jualan sebenar → semak baris dalam `orders`,
      `order_items`, `transactions`, `transaction_items`, `stock_movements`
- [ ] Sahkan: refresh browser → stok kekal berkurang

> **Ingat keputusan 4.1 dalam PELAN.md:** jualan kaunter tetap melalui `orders`
> (dibuka & ditutup serentak, `order_type = counter`). Jangan tulis terus ke
> `transactions` — kalau tidak, Fasa 9 perlu tulis semula fasa ini.

**Hujung Session 1: jualan kaunter berfungsi sebenar dengan DB.**

---

## Session 2 — Kedai Runcit Siap (Fasa 4–6)

### Fasa 4 — Barcode & carian
- [ ] `jobs/Product/FindByBarcodeJob.php`, `SearchProductsJob.php`
- [ ] Medan imbas pada skrin juruwang (mod `retail` sahaja)
- [ ] Carian pantas ikut nama / barcode / SKU
- [ ] Sahkan: pengimbas USB menaip seperti papan kekunci — uji dengan
      menaip digit + Enter, tiada driver diperlukan
- [ ] Sahkan: fokus kembali ke medan imbas selepas setiap tindakan
- [ ] Sahkan: produk **bervariasi** buka modal variasi, tidak terus masuk troli
- [ ] Sahkan: barcode tidak dijumpai → toast ralat, fokus kekal

### Fasa 5 — Resit termal

> **Fasa ini tukar pendekatan cetak, bukan tampal CSS.** Baca sebab di bawah
> sebelum mula — mudah tersilap sangka kerja ini kecil.

**Kenapa cara sekarang tidak boleh dikekalkan**

Blok `@media print` dalam `css/style.css` guna helah `visibility: hidden`.
Untuk A4 ia menjadi. Untuk printer termal ia gagal atas tiga sebab:

1. **Tiada `@page size`** — driver andaikan A4, jadi resit 58mm dicetak di
   sudut kertas maya A4. Pada gulungan termal, kertas keluar panjang berjela.
2. **`visibility: hidden` tidak membuang ruang** — elemen tersorok masih
   menduduki tempat. Pada gulungan termal ini bermakna **kertas terbuang
   setiap kali jual**.
3. **Bootstrap masih dimuatkan** — `text-primary` (biru) pada printer termal
   monokrom keluar kelabu cair atau hilang. Baris JUMLAH tidak boleh ambil
   risiko itu.

**Keputusan: halaman cetak berasingan**

`print/receipt.php?id=123` — halaman kosong tanpa Bootstrap, tanpa navbar,
tanpa modal. Hanya resit. Tiga sebab ia lebih baik daripada cetak dari modal:

- Tiada sisa elemen → tiada halaman kosong, tiada kertas terbuang
- Dibaca dari **DB**, bukan dari state JS — resit asal dan cetakan semula
  dijana oleh kod yang sama, jadi mustahil ia berbeza
- Admin guna halaman yang sama untuk cetak semula di Fasa 10

Juruwang tekan Cetak → JS muatkan halaman ini dalam `iframe` tersembunyi →
`iframe.contentWindow.print()`. Skrin POS tidak berkelip, tiada tetingkap
baharu, tiada masalah popup blocker.

**Senarai kerja**

- [ ] `print/receipt.php` — dijana pelayan melalui `GetReceiptJob`
- [ ] `css/receipt-58mm.css` — `@page { size: 58mm auto; margin: 0 }`, 9pt monospace
- [ ] `css/receipt-80mm.css` — sama, 80mm, 10pt
- [ ] `cashier/js/print.js` — cetak melalui iframe tersembunyi
- [ ] Luaskan `GetReceiptJob` — nama kedai, alamat, juruwang, kaunter, footer
      (semua dari `settings`), **jenis pesanan, nombor meja / take-away**
- [ ] Tandaan resit: **SALINAN** / **BATAL** / **PEMULANGAN**
- [ ] **Buang** blok `@media print` lama dari `css/style.css` — jangan tinggal
      dua mekanisme cetak yang bersaing
- [ ] Dokumen langkah tetapan printer Windows

> Fail `.css` berasingan, bukan `style="..."` — peraturan "jangan inline CSS"
> masih dipatuhi. Bootstrap memang tidak menyediakan `@page size`.

**Bentuk resit selepas Fasa 5**

```
        {shop_name}              <- settings
       {shop_address}            <- settings
-----------------------------
No. Resit : K1-20260826-0042     <- BAHARU (dulu Date.now)
Tarikh    : 26/08/2026 14:32
Juruwang  : Ali bin Abu          <- BAHARU (sebab ada syif)
Kaunter   : Kaunter 1            <- BAHARU (sebab kaunter dinamik)
Jenis     : Dine-in - Meja 5     <- BAHARU (mod kedai makan)
-----------------------------
Nasi Lemak x2            18.60
  Rendang daging, Extra pedas
Teh Tarik x1              3.00
  Besar, Ais
-----------------------------
Subjumlah                21.60
Cukai (6%)                1.30   <- kadar dari settings
Caj Perkhidmatan          0.00   <- 0 melainkan dihidupkan
Diskaun                  -0.00
JUMLAH                   22.90
Tunai                    25.00
Baki                      2.10
-----------------------------
      {receipt_footer}           <- settings
```

**Tandaan SALINAN adalah keperluan audit, bukan hiasan.** Tanpa label,
juruwang boleh cetak resit kedua dan serahkan sebagai asal. Transaksi
dibatalkan mesti tercetak **BATAL** dengan jelas.

**Cara pengesahan**

- [ ] `page.emulateMedia({ media: 'print' })` → ukur lebar sebenar `body`.
      Mesti 58mm (~219px pada 96dpi), bukan lebih
- [ ] Tiada limpahan mendatar — teks tidak terpotong di tepi
- [ ] **Kes terburuk dari data sebenar**: `Nasi Lemak` +
      `Rendang daging, Extra pedas, Telur mata, Sambal extra` — 48 aksara
      pada lebar 32 aksara. Mesti membalut, bukan terpotong
- [ ] Cetak ke PDF → 1 halaman, tiada halaman kosong di hujung
- [ ] Ulang untuk 58mm dan 80mm

**Sufi kena sahkan sekali dengan printer sebenar.** Kod boleh dipastikan
betul, tetapi hanya kertas sebenar membuktikan driver berkelakuan seperti
dijangka.

**Tiga perangkap yang dijangka**

1. **Saiz kertas dalam Printer Properties Windows.** `@page { size: 58mm auto }`
   hanyalah cadangan; sesetengah driver abaikan. Mungkin perlu set 58mm sekali
   dalam Windows. Ini **langkah pemasangan, bukan pepijat kod**.
2. **Margin dialog cetak Chrome.** Lalai "Default" tambah ~10mm. Perlu tukar
   ke "None". Untuk mesin kaunter sebenar, lancarkan Chrome dengan
   `--kiosk-printing` — dialog hilang, resit terus keluar.
3. **Emoji pada resit termal.** Selalunya keluar sebagai kotak hitam pada
   driver murah. Cadangan: **buang emoji dari resit bercetak, kekalkan pada
   skrin**. Skrin dan kertas ada keperluan berbeza.

**Dua keputusan diperlukan dari Sufi**

- [ ] **Lebar lalai — 58mm atau 80mm?** Kedua-dua akan dibina; cuma perlu tahu
      yang mana jadi lalai dalam `settings`
- [ ] **Emoji pada resit bercetak — buang atau kekal?** Cadangan: buang

### Fasa 6 — Admin: katalog
- [ ] Rangka `admin/` — login, sidebar, semak peranan pada setiap halaman
- [ ] `admin/index.php` — dashboard (jualan hari ini, transaksi, top produk,
      stok rendah)
- [ ] `admin/products.php` — CRUD + gambar + **barcode/SKU**
- [ ] `admin/categories.php`
- [ ] `admin/variations.php` — pindah editor dari js/admin.js jadi halaman penuh
- [ ] `assets/img/product-default.png` + `uploads/.htaccess`
- [ ] Sahkan: muat naik gambar, gambar muncul di skrin juruwang, jatuh balik
      ke emoji berfungsi
- [ ] Sahkan: barcode berganda ditolak

**Hujung Session 2: kedai runcit boleh guna sistem ini sepenuhnya.**

---

## Session 3 — Kedai Makan: Pesanan (Fasa 7–9)

### Fasa 7 — Meja, jenis pesanan & pesanan terbuka
- [ ] `jobs/Table/ListTablesJob.php`, `SaveTableJob.php`, `TableStatusJob.php`
- [ ] `jobs/Order/OpenOrderJob.php` (luaskan), `AddOrderItemJob.php`,
      `UpdateOrderItemJob.php`, `CancelOrderItemJob.php`, `GetOpenOrdersJob.php`
- [ ] Penjana nombor take-away — unik setiap `business_day`, reset harian
- [ ] Skrin kaunter: pilih Dine-in (meja) / Take away (nombor auto)
- [ ] Papar meja: kosong / berisi, dengan jumlah semasa
- [ ] Stok ditolak **semasa pesanan dibuat**, bukan semasa bayaran
- [ ] Batal item pesanan → stok dipulangkan
- [ ] Sahkan: pesanan bertambah sepanjang "makan" — tambah item 3 kali,
      jumlah betul
- [ ] Sahkan: nombor take-away pada jam 01:00 masih ikut hari semalam

### Fasa 8 — Aplikasi waiter
- [ ] `waiter/login.php`, `waiter/index.php` — **mobile-first**
- [ ] Paparan meja: kosong / berisi
- [ ] Buka meja → tambah pesanan → hantar
- [ ] Take away → sistem beri nombor
- [ ] Tambah pesanan pada meja sedia ada
- [ ] Nota bebas setiap item ("kurang pedas")
- [ ] **Tiada UI bayaran langsung**
- [ ] Sahkan dengan curl: waiter panggil endpoint bayaran → **ditolak 403**
- [ ] Sahkan pada saiz skrin telefon (Playwright viewport 390x844)

### Fasa 9 — Bayaran kedai makan: gabung & pecah bil
- [ ] Kaunter: pilih meja atau taip nombor take-away → panggil pesanan
- [ ] `jobs/Transaction/MergeBillJob.php` — banyak pesanan → satu bayaran
      (`transaction_orders`)
- [ ] `jobs/Transaction/SplitBillJob.php` — pecah **ikut item**
      (kemas kini `order_items.paid_qty`)
- [ ] Pecah rata (bahagi N) — mod ringkas tanpa perincian item
- [ ] Pesanan jadi `paid` hanya bila **setiap** baris `paid_qty = qty`
- [ ] Meja kembali `free` selepas pesanan ditutup
- [ ] Sahkan: gabung meja 5 + meja 6 → satu resit, kedua-dua meja jadi kosong
- [ ] Sahkan: pecah bil 3 orang → 3 resit, jumlah gabungan = jumlah pesanan
- [ ] Sahkan: bayar separa, kemudian bayar baki → pesanan tutup betul
- [ ] Sahkan: **item sama tidak boleh dibayar dua kali**

**Hujung Session 3: kedai makan boleh guna sistem ini sepenuhnya.**

---

## Session 4 — Operasi & Admin Penuh (Fasa 10–12)

### Fasa 10 — Stok, transaksi, void & refund
- [ ] `admin/stock.php` — baki, terima stok, pelarasan, log pergerakan
- [ ] `admin/transactions.php` — tapis tarikh/juruwang/kaunter/kaedah/jenis pesanan
- [ ] `jobs/Transaction/VoidTransactionJob.php` — pulang stok penuh
- [ ] `jobs/Transaction/RefundTransactionJob.php` — refund separa, transaksi negatif
- [ ] Cetak semula resit dari admin
- [ ] Sahkan: void pulangkan stok betul; refund separa hanya pulangkan item dipilih

### Fasa 11 — Laporan
- [ ] `admin/reports.php` — harian, bulanan, ikut kaedah bayaran, ikut juruwang
- [ ] **Laporan ikut jenis pesanan** (dine-in vs take away vs kaunter)
- [ ] Laporan tutup syif (Z-report)
- [ ] Eksport CSV
- [ ] Sahkan: jumlah laporan = jumlah dikira terus dari DB melalui SQL
- [ ] Sahkan: refund ditolak dengan betul, transaksi void dikecualikan

### Fasa 12 — Pentadbiran
- [ ] `admin/users.php` — admin/cashier/waiter, reset kata laluan
- [ ] `admin/terminals.php` — vendor tambah kaunter & peranti waiter
- [ ] `admin/tables.php` — susun atur meja, kawasan, kapasiti
- [ ] `admin/payment-methods.php`
- [ ] `admin/settings.php` — **business_type**, nama kedai, kadar cukai,
      caj perkhidmatan, caj bungkus, `day_cutoff_time`, footer, lebar kertas
- [ ] `admin/logs.php` — log aktiviti
- [ ] Sahkan: tukar `business_type` ke `retail` → meja & waiter hilang
      sepenuhnya dari UI
- [ ] Sahkan: tukar kadar cukai → jualan baharu guna kadar baharu,
      jualan lama tidak berubah

---

## Session 5 — Dokumentasi (Fasa 13)

### Fasa 13 — Dokumentasi
- [ ] Panduan juruwang (kemas kini `docs/panduan-pengguna.md`)
- [ ] **Panduan waiter** (baharu)
- [ ] **Panduan admin** (baharu)
- [ ] Kemas kini `docs/variasi/` — editor kini halaman penuh
- [ ] Screenshot baharu melalui skill `user-manual-auto`
- [ ] README pemasangan: import schema, cipta pos_user, pilih business_type
- [ ] Jalankan `/code-review` ke atas keseluruhan kerja

---

## Perkara tertangguh (bukan sebahagian 13 fasa)

- **ESC/POS mentah + buka laci wang** — tunggu Sufi tahu jenama printer termal
- **Paparan dapur (kitchen display)** — `order_items.status` sudah disediakan,
  tetapi skrin dapur belum dirancang
- **Tempahan meja (reservation)** — `dining_tables.status` ada nilai
  `reserved`, tetapi aliran tempahan belum dirancang
- **Multi-tenant** — lihat PELAN.md bahagian 12
- Pelanggan / program kesetiaan
- Cukai berbilang kadar

## Log keputusan yang berubah di tengah jalan

> Kalau keputusan dalam PELAN.md terpaksa diubah semasa kerja, catat di sini
> dengan sebabnya supaya session seterusnya tidak keliru.

| Tarikh | Apa yang berubah | Sebab |
|---|---|---|
| 26 Ogos 2026 | Skop diluaskan: 9 fasa/3 session → 13 fasa/5 session | Sufi tambah dua jenis perniagaan, peranan waiter, meja, gabung/pecah bil |
| 26 Ogos 2026 | Semua jualan lalui `orders`, termasuk kedai runcit | Elak menulis `CreateTransactionJob` dua kali dan menulis semula Fasa 3 |
