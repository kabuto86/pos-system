# Progres — Status Semasa

> **Kemas kini fail ini di HUJUNG setiap fasa**, sebelum commit. Inilah
> satu-satunya sumber kebenaran tentang di mana kerja terhenti.
> Baca [PELAN.md](PELAN.md) untuk keputusan reka bentuk.

**Status keseluruhan:** Belum bermula — pelan sahaja siap
**Fasa terakhir siap:** —
**Fasa seterusnya:** Fasa 1

**Struktur:** 16 fasa merentas 6 session.

Sejarah skop:
9 fasa/3 session → 13 fasa/5 session (dua jenis perniagaan, waiter, meja)
→ **16 fasa/6 session** (SaaS multi-tenant, 26 Ogos 2026).

---

## ⚠ Ujian yang dijalankan pada SETIAP fasa

Bukan sekali di hujung. Setiap fasa, tanpa kecuali:

- [ ] Log masuk sebagai vendor **KEDAI01**, cipta data
- [ ] Log masuk sebagai vendor **KEDAI02**, sahkan data KEDAI01 **tidak kelihatan**
- [ ] Ambil id rekod milik KEDAI01, cuba capai melalui API sebagai KEDAI02 →
      mesti **404 atau 403**, bukan data

Sebabnya dalam PELAN.md 3.4: dengan hanya satu vendor, kebocoran mustahil
dikesan. Setiap `WHERE vendor_id` yang tertinggal mesti terserlah pada fasa
ia ditulis, bukan enam session kemudian.

---

## Session 1 — Teras Multi-Tenant (Fasa 1–3)

### Fasa 1 — Skema & teras
- [ ] Cipta pangkalan data `pos_saas` (utf8mb4_unicode_ci)
- [ ] Cipta pengguna MySQL `pos_user` (akses `pos_saas` sahaja)
- [ ] `database/schema.sql` — 22 jadual, `vendor_id` pada setiap jadual
      perniagaan, setiap UNIQUE jadi unik per vendor (PELAN.md 3.5),
      setiap indeks bermula dengan `vendor_id` (PELAN.md 3.6)
- [ ] `database/seed.sql` — **DUA vendor**: KEDAI01 (retail), KEDAI02
      (restaurant), setiap satu dengan 18 produk, kategori, kaedah bayaran,
      tetapan, admin, kaunter; KEDAI02 dapat meja contoh
- [ ] Satu akaun `superadmin` (vendor_id NULL)
- [ ] `config/database.php` + `.example.php` + kemas kini `.gitignore`
- [ ] `core/Database.php` (PDO utf8mb4), `Response.php`, `Request.php`,
      `Validator.php`, `BusinessDay.php`, **`VendorScope.php`**
- [ ] Sahkan: query CLI pulangkan 18 produk **setiap vendor**, emoji tidak rosak
- [ ] Sahkan: `BusinessDay` pulangkan tarikh semalam bila jam 01:00 dan
      cutoff 04:00 — punca pepijat nombor take-away kalau silap

### Fasa 2 — Auth, vendor, peranan, kaunter & syif
- [ ] `core/Auth.php` — sesi menyimpan `vendor_id`, `user_id`, `role`
- [ ] `core/Csrf.php`
- [ ] `jobs/Auth/LoginJob.php` — **Kod Kedai + nama pengguna + kata laluan**
- [ ] `jobs/Auth/CheckSubscriptionJob.php` — vendor suspended/cancelled ditolak
- [ ] **Empat peranan**: superadmin, admin, cashier, waiter
- [ ] `jobs/Terminal/…` (jenis cashier/waiter), `jobs/Shift/…`
- [ ] `cashier/login.php`, `cashier/shift.php`
- [ ] Sahkan: nama pengguna `ali` boleh wujud dalam KEDAI01 **dan** KEDAI02
      tanpa bertembung
- [ ] Sahkan: log masuk KEDAI01 dengan kata laluan KEDAI02 → gagal
- [ ] Sahkan: vendor `suspended` → hanya admin masuk, dan hanya untuk lihat
      mesej langganan
- [ ] Sahkan dengan curl: waiter panggil endpoint bayaran → **403**

### Fasa 3 — POS kaunter (jualan penuh)
- [ ] `jobs/Product/ListProductsJob.php` (produk + variasi + stok)
- [ ] `jobs/Cart/CalculateCartJob.php` (port `calcUnitPrice` + `getTotals`)
- [ ] `jobs/Order/OpenOrderJob.php`, `AddOrderItemJob.php`, `CloseOrderJob.php`
- [ ] `jobs/Stock/DeductStockJob.php` (`SELECT ... FOR UPDATE`)
- [ ] `jobs/Transaction/CreateTransactionJob.php` (DB transaction,
      jana `receipt_no` unik **per vendor**)
- [ ] `jobs/Transaction/ListTransactionsJob.php`, `GetReceiptJob.php`
- [ ] `api/` untuk semua di atas — **tiada SQL dalam api/**
- [ ] `cashier/index.php` + `cashier/js/` — pindah dari index.html,
      **buang butang Variasi dari navbar**
- [ ] Sahkan: jualan di KEDAI01 dan KEDAI02 kedua-duanya bermula `0001` —
      nombor resit unik per vendor, bukan global
- [ ] Sahkan: baris masuk ke `orders`, `order_items`, `transactions`,
      `transaction_items`, `stock_movements` dengan `vendor_id` betul
- [ ] Sahkan: refresh browser → stok kekal berkurang

> **Ingat keputusan 7.1 PELAN.md:** jualan kaunter tetap melalui `orders`
> (`order_type = counter`, dibuka & ditutup serentak). Jangan tulis terus
> ke `transactions` — kalau tidak Fasa 9 perlu tulis semula fasa ini.

**Hujung Session 1: jualan kaunter berfungsi, dua vendor terasing.**

---

## Session 2 — Kedai Runcit Siap (Fasa 4–6)

### Fasa 4 — Barcode & carian
- [ ] `jobs/Product/FindByBarcodeJob.php`, `SearchProductsJob.php`
- [ ] Medan imbas pada skrin juruwang (mod `retail` sahaja)
- [ ] Carian pantas ikut nama / barcode / SKU
- [ ] Sahkan: pengimbas USB menaip seperti papan kekunci — uji dengan menaip
      digit + Enter, tiada driver diperlukan
- [ ] Sahkan: fokus kembali ke medan imbas selepas setiap tindakan
- [ ] Sahkan: produk **bervariasi** buka modal variasi, tidak terus masuk troli
- [ ] Sahkan: barcode tidak dijumpai → toast ralat, fokus kekal
- [ ] Sahkan: **barcode sama boleh wujud dalam dua vendor** dan setiap vendor
      hanya jumpa produknya sendiri

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
- [ ] **Semak `vendor_id` sebelum papar resit** — halaman ini menerima id
      dalam URL, jadi ia sasaran kebocoran paling jelas dalam sistem
- [ ] `css/receipt-58mm.css` — `@page { size: 58mm auto; margin: 0 }`, 9pt monospace
- [ ] `css/receipt-80mm.css` — sama, 80mm, 10pt
- [ ] `cashier/js/print.js` — cetak melalui iframe tersembunyi
- [ ] Luaskan `GetReceiptJob` — nama kedai, alamat, juruwang, kaunter, footer
      (dari `settings` vendor), **jenis pesanan, nombor meja / take-away**
- [ ] Tandaan resit: **SALINAN** / **BATAL** / **PEMULANGAN**
- [ ] **Buang** blok `@media print` lama dari `css/style.css`
- [ ] Dokumen langkah tetapan printer Windows

> Fail `.css` berasingan, bukan `style="..."` — peraturan "jangan inline CSS"
> masih dipatuhi. Bootstrap memang tidak menyediakan `@page size`.

**Bentuk resit selepas Fasa 5**

```
        {shop_name}              <- settings vendor
       {shop_address}            <- settings vendor
-----------------------------
No. Resit : K1-20260826-0042
Tarikh    : 26/08/2026 14:32
Juruwang  : Ali bin Abu
Kaunter   : Kaunter 1
Jenis     : Dine-in - Meja 5     <- mod kedai makan
-----------------------------
Nasi Lemak x2            18.60
  Rendang daging, Extra pedas
Teh Tarik x1              3.00
  Besar, Ais
-----------------------------
Subjumlah                21.60
Cukai (6%)                1.30
Caj Perkhidmatan          0.00   <- 0 melainkan dihidupkan
Diskaun                  -0.00
JUMLAH                   22.90
Tunai                    25.00
Baki                      2.10
-----------------------------
      {receipt_footer}
```

**Tandaan SALINAN adalah keperluan audit, bukan hiasan.** Tanpa label,
juruwang boleh cetak resit kedua dan serahkan sebagai asal.

**Cara pengesahan**

- [ ] `page.emulateMedia({ media: 'print' })` → ukur lebar sebenar `body`.
      Mesti 58mm (~219px pada 96dpi), bukan lebih
- [ ] Tiada limpahan mendatar — teks tidak terpotong di tepi
- [ ] **Kes terburuk dari data sebenar**: `Nasi Lemak` +
      `Rendang daging, Extra pedas, Telur mata, Sambal extra` — 48 aksara
      pada lebar 32 aksara. Mesti membalut, bukan terpotong
- [ ] Cetak ke PDF → 1 halaman, tiada halaman kosong di hujung
- [ ] Ulang untuk 58mm dan 80mm
- [ ] **KEDAI02 cuba buka resit KEDAI01 melalui URL → ditolak**

**Sufi kena sahkan sekali dengan printer sebenar.** Kod boleh dipastikan
betul, tetapi hanya kertas sebenar membuktikan driver berkelakuan seperti
dijangka.

**Tiga perangkap yang dijangka**

1. **Saiz kertas dalam Printer Properties Windows.** `@page { size: 58mm auto }`
   hanyalah cadangan; sesetengah driver abaikan. Mungkin perlu set 58mm sekali
   dalam Windows. Ini **langkah pemasangan, bukan pepijat kod**.
2. **Margin dialog cetak Chrome.** Lalai "Default" tambah ~10mm. Perlu tukar
   ke "None". Untuk mesin kaunter sebenar, `--kiosk-printing` menghilangkan
   dialog terus.
3. **Emoji pada resit termal.** Selalunya keluar sebagai kotak hitam pada
   driver murah. Cadangan: **buang emoji dari resit bercetak, kekalkan pada
   skrin**.

**Dua keputusan diperlukan dari Sufi**

- [ ] **Lebar lalai — 58mm atau 80mm?**
- [ ] **Emoji pada resit bercetak — buang atau kekal?** Cadangan: buang

### Fasa 6 — Admin kedai: katalog
- [ ] Rangka `admin/` — login, sidebar, semak peranan **dan vendor** pada
      setiap halaman
- [ ] `admin/index.php` — dashboard (jualan hari ini, transaksi, top produk,
      stok rendah) — **vendor semasa sahaja**
- [ ] `admin/products.php` — CRUD + gambar + barcode/SKU
- [ ] `admin/categories.php`
- [ ] `admin/variations.php` — pindah editor dari js/admin.js jadi halaman penuh
- [ ] `assets/img/product-default.png` + `uploads/.htaccess`
- [ ] Muat naik ke `uploads/products/{vendor_id}/`
- [ ] Sahkan: gambar muncul di skrin juruwang, jatuh balik ke emoji berfungsi
- [ ] Sahkan: admin KEDAI01 tidak nampak produk KEDAI02 walaupun taip id terus

**Hujung Session 2: kedai runcit boleh guna sistem ini sepenuhnya.**

---

## Session 3 — Kedai Makan: Pesanan (Fasa 7–9)

Uji sebagai vendor **KEDAI02** (restaurant).

### Fasa 7 — Meja, jenis pesanan & pesanan terbuka
- [ ] `jobs/Table/ListTablesJob.php`, `SaveTableJob.php`, `TableStatusJob.php`
- [ ] `jobs/Order/…` luaskan: `AddOrderItemJob`, `UpdateOrderItemJob`,
      `CancelOrderItemJob`, `GetOpenOrdersJob`, `FindByTakeawayNoJob`
- [ ] Penjana nombor take-away — unik per **vendor + business_day**, reset harian
- [ ] Skrin kaunter: pilih Dine-in (meja) / Take away (nombor auto)
- [ ] Papar meja: kosong / berisi, dengan jumlah semasa
- [ ] Stok ditolak **semasa pesanan dibuat**, bukan semasa bayaran
- [ ] Batal item pesanan → stok dipulangkan
- [ ] Sahkan: tambah item 3 kali sepanjang "makan", jumlah betul
- [ ] Sahkan: nombor take-away pada jam 01:00 masih ikut hari semalam
- [ ] Sahkan: dua vendor boleh ada take-away `001` pada hari sama

### Fasa 8 — Aplikasi waiter
- [ ] `waiter/login.php`, `waiter/index.php` — **mobile-first**
- [ ] Paparan meja: kosong / berisi
- [ ] Buka meja → tambah pesanan → hantar
- [ ] Take away → sistem beri nombor
- [ ] Tambah pesanan pada meja sedia ada
- [ ] Nota bebas setiap item ("kurang pedas")
- [ ] **Tiada UI bayaran langsung**
- [ ] Sahkan dengan curl: waiter panggil endpoint bayaran → **403**
- [ ] Sahkan: waiter KEDAI02 tidak nampak meja vendor lain
- [ ] Sahkan pada viewport telefon (390x844)

### Fasa 9 — Bayaran kedai makan: gabung & pecah bil
- [ ] Kaunter: pilih meja atau taip nombor take-away → panggil pesanan
- [ ] `jobs/Transaction/MergeBillJob.php` — banyak pesanan → satu bayaran
      (`transaction_orders`)
- [ ] `jobs/Transaction/SplitBillJob.php` — pecah **ikut item**
      (kemas kini `order_items.paid_qty`)
- [ ] Pecah rata (bahagi N) — mod ringkas tanpa perincian item
- [ ] Pesanan jadi `paid` hanya bila **setiap** baris `paid_qty = qty`
- [ ] Meja kembali `free` selepas pesanan ditutup
- [ ] Sahkan: gabung meja 5 + meja 6 → satu resit, kedua-dua meja kosong
- [ ] Sahkan: pecah bil 3 orang → 3 resit, jumlah gabungan = jumlah pesanan
- [ ] Sahkan: bayar separa, kemudian bayar baki → pesanan tutup betul
- [ ] Sahkan: **item sama tidak boleh dibayar dua kali**
- [ ] Sahkan: **mustahil gabung pesanan merentas vendor**

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
- [ ] Sahkan: admin KEDAI01 tidak boleh void transaksi KEDAI02

### Fasa 11 — Laporan
- [ ] `admin/reports.php` — harian, bulanan, ikut kaedah bayaran, ikut juruwang
- [ ] **Laporan ikut jenis pesanan** (dine-in vs take away vs kaunter)
- [ ] Laporan tutup syif (Z-report)
- [ ] Eksport CSV
- [ ] Sahkan: jumlah laporan = jumlah dikira terus dari DB melalui SQL
- [ ] Sahkan: refund ditolak, transaksi void dikecualikan
- [ ] Sahkan: **jumlah KEDAI01 tidak termasuk sebarang jualan KEDAI02** —
      bandingkan dengan `SUM` bertapis vendor

### Fasa 12 — Tetapan kedai
- [ ] `admin/users.php` — admin/cashier/waiter (dalam vendor sahaja)
- [ ] `admin/terminals.php` — kaunter & peranti waiter
- [ ] `admin/tables.php` — susun atur meja, kawasan, kapasiti
- [ ] `admin/payment-methods.php`
- [ ] `admin/settings.php` — nama kedai, kadar cukai, caj perkhidmatan,
      caj bungkus, `day_cutoff_time`, footer, lebar kertas
- [ ] `admin/logs.php` — log aktiviti vendor
- [ ] Sahkan: tukar kadar cukai KEDAI01 → jualan KEDAI02 tidak terjejas
- [ ] Sahkan: jualan lama tidak berubah bila kadar ditukar

> `business_type` **tiada** dalam tetapan kedai — ia milik superadmin
> (Fasa 13), kerana ia menentukan ciri yang dilanggan.

---

## Session 5 — Platform SaaS (Fasa 13–15)

### Fasa 13 — Panel superadmin
- [ ] `superadmin/` — login berasingan, layout berasingan
- [ ] `superadmin/vendors.php` — senarai, cari, lihat penggunaan
- [ ] `superadmin/plans.php` — pelan, harga, had
- [ ] `superadmin/subscriptions.php` — status, tempoh, tandakan bayar
- [ ] `jobs/Vendor/…`, `jobs/Plan/…`
- [ ] Dashboard platform: jumlah vendor, aktif vs suspended, jualan agregat
- [ ] Sahkan: superadmin (vendor_id NULL) **tidak boleh** masuk POS vendor
- [ ] Sahkan: admin vendor **tidak boleh** capai `/superadmin/` langsung

### Fasa 14 — Onboarding, had pelan & penggantungan
- [ ] `jobs/Vendor/ProvisionVendorJob.php` — cipta vendor baharu lengkap:
      tetapan lalai, kaedah bayaran, kategori, akaun admin, kaunter pertama
- [ ] `core/PlanLimit.php` — kuatkuasa `max_terminals`, `max_users`,
      `max_products` **dalam job simpan**, bukan hanya di UI
- [ ] Penggantungan: vendor `suspended` → hanya admin masuk, hanya untuk
      melihat mesej langganan
- [ ] Sahkan: vendor baharu boleh terus berjualan selepas provision, tanpa
      sebarang langkah manual dalam DB
- [ ] Sahkan: had pelan ditolak melalui API terus, bukan hanya butang disable

### Fasa 15 — Audit kebocoran antara vendor

> Fasa khusus. Semua ciri sudah wujud, jadi sekarang boleh diaudit menyeluruh.
> Ujian per-fasa sebelum ini menangkap yang jelas; fasa ini mencari yang halus.

- [ ] Senaraikan **setiap** pertanyaan SQL dalam `jobs/` dan sahkan setiap
      satu menapis `vendor_id`
- [ ] Cari `$_GET`/`$_POST` yang membawa id rekod — setiap satu mesti disemak
      pemilikannya, bukan sekadar wujud
- [ ] Uji setiap endpoint API sebagai KEDAI02 menggunakan id milik KEDAI01
- [ ] Uji laluan fail: `uploads/products/{vendor_lain}/…`
- [ ] Uji cetak resit, eksport CSV, laporan — semua menerima parameter
- [ ] Sahkan tiada `vendor_id` diterima dari input di mana-mana
      (`grep -rn "vendor_id" api/` mesti kosong)
- [ ] Jalankan `/security-review`
- [ ] Catat hasil audit dalam fail ini

---

## Session 6 — Dokumentasi (Fasa 16)

### Fasa 16 — Dokumentasi
- [ ] Panduan juruwang (kemas kini `docs/panduan-pengguna.md`)
- [ ] **Panduan waiter** (baharu)
- [ ] **Panduan admin kedai** (baharu)
- [ ] **Panduan superadmin** (baharu)
- [ ] Kemas kini `docs/variasi/` — editor kini halaman penuh dalam admin
- [ ] Screenshot baharu melalui skill `user-manual-auto`
- [ ] README pemasangan: import schema, cipta pos_user, provision vendor pertama
- [ ] Jalankan `/code-review` ke atas keseluruhan projek

---

## Perkara tertangguh (bukan sebahagian 16 fasa)

- **Bayaran langganan dalam talian** — superadmin tandakan status secara
  manual buat masa ini. Gerbang pembayaran belum dibincangkan
- **Subdomain per vendor** (`kedai01.pos.com`) — perlu DNS dan vhost;
  boleh ditambah kemudian tanpa ubah skema
- **Eksport data vendor** bila vendor berhenti melanggan
- **ESC/POS mentah + buka laci wang** — tunggu jenama printer termal
- **Paparan dapur (kitchen display)** — `order_items.status` sudah disediakan
- **Tempahan meja** — `dining_tables.status` ada nilai `reserved`
- Pelanggan / program kesetiaan · Cukai berbilang kadar

## Log keputusan yang berubah di tengah jalan

| Tarikh | Apa yang berubah | Sebab |
|---|---|---|
| 26 Ogos 2026 | 9 fasa/3 session → 13 fasa/5 session | Dua jenis perniagaan, waiter, meja, gabung/pecah bil |
| 26 Ogos 2026 | Semua jualan lalui `orders`, termasuk kedai runcit | Elak tulis `CreateTransactionJob` dua kali dan tulis semula Fasa 3 |
| 26 Ogos 2026 | **SaaS multi-tenant** — 13 fasa/5 session → 16 fasa/6 session | Sufi putuskan satu kod satu DB untuk semua vendor |
| 26 Ogos 2026 | `settings.business_type` → `vendors.business_type` | Jenis perniagaan ialah ciri yang dilanggan, bukan pilihan bebas vendor |
| 26 Ogos 2026 | Pangkalan data `pos_system` → `pos_saas` | Nama mencerminkan sifat sebenar sistem |
