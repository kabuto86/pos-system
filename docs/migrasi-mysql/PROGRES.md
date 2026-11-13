# Progres — Status Semasa

> **Kemas kini fail ini di HUJUNG setiap fasa**, sebelum commit. Inilah
> satu-satunya sumber kebenaran tentang di mana kerja terhenti.
> Baca [PELAN.md](PELAN.md) untuk keputusan reka bentuk.

**Status keseluruhan:** Pelan siap · **persekitaran sudah disemak dan lulus**
**Fasa terakhir siap:** —
**Fasa seterusnya:** Fasa 1

### Semakan kesediaan — 26 Ogos 2026 (mesin pejabat)

| Perkara | Hasil |
|---|---|
| Apache (port 80) | ✅ berjalan · `index.html` → HTTP 200 |
| MySQL/MariaDB (port 3306) | ✅ berjalan · 10.4.32 |
| PHP melalui Apache | ✅ 8.2.12 |
| Sambungan `pdo_mysql`, `gd`, `fileinfo`, `mbstring`, `session` | ✅ semua ada |
| `upload_max_filesize` / `post_max_size` | 40M (had pelan kita 2MB — memadai) |
| PDO + prepared statement (`EMULATE_PREPARES` dimatikan) | ✅ |
| Emoji utf8mb4 hantar-balik melalui PDO | ✅ `F09F8D9B` (selepas pembetulan 15.1) |
| `UNIQUE(vendor_id, name)` — nama sama merentas vendor | ✅ dibenarkan |
| `SELECT … FOR UPDATE` (InnoDB) | ✅ |
| Pengguna MySQL berhad tidak boleh capai DB lain | ✅ `tuisyen` ditolak 1044 |
| Playwright memuatkan aplikasi melalui Apache | ✅ 18 produk dipapar, emoji betul |

**Satu masalah dijumpai dan sudah didokumen:** `mysql.exe` di Windows lalai
kepada `cp850`, merosakkan emoji semasa import `seed.sql` **tanpa sebarang
amaran**. Resepi pembetulan dalam PELAN.md 15.1 — baca sebelum Fasa 1.

**Struktur:** 23 fasa merentas 8 session (Session 1 dipecah 1A + 1B; Fasa 9B–9C; Session 3B baharu untuk 9D–9E).

Sejarah skop:
9 fasa/3 session → 13 fasa/5 session (dua jenis perniagaan, waiter, meja)
→ 16 fasa/6 session (SaaS multi-tenant)
→ 17 fasa/6 session (modul promosi & diskaun)
→ 18 fasa/6 session (dwibahasa & modul terjemahan)
→ 19 fasa/7 session (kedai berbilang, PIN, bil; Session 1 dipecah, 27 Ogos 2026)
→ 20 fasa/7 session (modul per pelan + pesanan QR pelanggan, Fasa 9B, 13 Nov 2026).
→ 21 fasa/7 session (modul dapur, Fasa 9C, 13 Nov 2026)
→ **23 fasa/8 session** (bayaran online + kedai online ambil sendiri, Session 3B, 13 Nov 2026).

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

## Mockup UI — sebelum kod backend

> **Peraturan Sufi (13 Nov 2026):** UI mockup dibina dan dipersetujui
> **sebelum** kod backend/API mana-mana bahagian ditulis. UI lama
> (`index.html` satu halaman + modal admin) dipecah ikut peranan.

HTML statik dalam `mockup/`, Bootstrap sahaja, data palsu. Buka di
`http://localhost/claude-learn1/mockup/`.

**Pusingan 1 — rangka + satu skrin setiap peranan**

- [x] `mockup/index.html` — indeks semua mockup
- [x] `mockup/cashier/index.html` — skrin POS kaunter + modal bayaran
      (navbar papar kedai, kaunter, syif, juruwang)
- [x] `mockup/waiter/index.html` — paparan meja, mobile-first (390px),
      **tiada UI bayaran**
- [x] `mockup/admin/index.html` — layout sidebar + pemilih kedai, dashboard
- [x] `mockup/superadmin/index.html` — layout sidebar gelap, senarai vendor
- [x] Reka semula premium (13 Nov 2026) — Sufi tolak versi pertama sebagai
      "oldschool". Tema **Pandan & Kunyit** dalam `css/theme.css`: menukar
      pemboleh ubah Bootstrap + kelas `kp-*`, fon Bricolage Grotesque
      (tajuk & nombor) + Figtree (teks). Tiada inline CSS
- [x] Semakan Sufi #2 (13 Nov 2026): emoji antara muka → Font Awesome 6;
      fon & ikon disimpan dalam `vendor/`; tiga saiz butang standard
      (32/40/48px); bar skrol nipis; dropdown tanpa avatar; diskaun manual
      jadi togol RM/% + input teks perpuluhan; jubin produk ruang gambar 4:3
- [x] Gambar produk: **kekal ikon kelabu dalam mockup** (keputusan Sufi).
      Gambar sebenar dimuat naik oleh admin vendor — Fasa 6, PELAN.md 11
- [x] `kp-tile-name` tanpa `min-height` — jimat ruang
- [x] `mockup/superadmin/plans.html` — pelan & tanda modul
- [x] `mockup/order/index.html` — menu pesanan QR pelanggan (telefon)
- [x] `mockup/kitchen/index.html` — skrin dapur (tablet landskap, 3 lajur)
- [x] `mockup/shop/index.html` — kedai online peniaga dari rumah: semak, masa ambil, cara bayar
- [x] Amaran berlapis: sepanduk merah di `cashier/`, lajur "Menunggu disahkan" di `kitchen/`
- [ ] **Sufi setuju rangka & gaya** sebelum pusingan 2

**Pusingan 2 — skrin Session 1A/1B** (sebelum Fasa 1 dimulakan)

- [ ] Log masuk e-mel (admin) · log masuk PIN (juruwang/waiter)
- [ ] Pemilih kedai selepas log masuk · buka/tutup syif
- [ ] Modal variasi · sejarah transaksi juruwang · resit (58mm & 80mm)

> Skrin session lain dimockup pada permulaan session masing-masing.

---

## Session 1A — Skema, Teras & Auth (Fasa 1–2)

### Fasa 1 — Skema & teras
- [ ] Cipta pangkalan data `pos_saas` (utf8mb4_unicode_ci)
- [ ] Cipta pengguna MySQL `pos_user` (akses `pos_saas` sahaja)
- [ ] `database/migrate.php` — pelari migrasi CLI (PELAN.md 15.2):
      `up`, `status`, `seed [--demo]`, `fresh --demo`, `dump`, `superadmin`;
      jadual `schema_migrations`; `fresh`/`--demo` ditolak bila `env` bukan `local`
- [ ] `database/migrations/001…007_*.sql` — **39 jadual**, `vendor_id` pada
      setiap jadual perniagaan, setiap UNIQUE jadi unik per vendor
      (PELAN.md 3.5), setiap indeks bermula dengan `vendor_id` (PELAN.md 3.6)
- [ ] `database/schema.sql` — dijana dengan `migrate.php dump`, bukan ditulis tangan
- [ ] Jadual promosi wujud sejak sekarang walaupun UI dibina di Fasa 10:
      `promotions`, `promotion_products`, `promotion_categories`,
      `transaction_promotions`
- [ ] Lajur produk penuh: `cost_price`, `unit`, `min_stock`, `is_tax_exempt`
- [ ] Lajur diskaun pada `transactions`: `promo_discount`, `manual_discount`,
      `discount_tax_mode`; pada `transaction_items`: `promotion_id`,
      `promotion_name`, `discount_amount`
- [ ] `database/seeds/core/` — 10 modul (PELAN.md 9.4), bahasa ms/en,
      rentetan terjemahan sistem
- [ ] `database/seeds/demo/` — **DUA vendor**: KEDAI01 (retail), KEDAI02
      (restaurant), setiap satu dengan 18 produk, kategori, kaedah bayaran,
      tetapan, admin, kaunter; KEDAI02 dapat meja contoh **dengan `qr_token`**
      dan akaun waiter; satu `superadmin` demo (vendor_id NULL); beberapa
      transaksi lepas supaya dashboard berisi
- [ ] Vendor demo ketiga **KEDAI03 — peniaga dari rumah** (restaurant, tiada
      meja, `shop_slug = kak-ani`, modul `online_order` + `online_payment`),
      gerbang sandbox dengan kunci kosong untuk KEDAI02 & KEDAI03
- [ ] Akaun demo dalam seed `.php` (Argon2id melalui `password_hash()`);
      senarai log masuk dicetak hujung `fresh --demo` + `seeds/demo/README.md`
- [ ] Pelan demo dengan **harga contoh**: **Asas** (`pos` sahaja) ·
      **Pro** (semua 10 modul) · **Percubaan**. KEDAI01 = Asas, KEDAI02 = Pro —
      supaya sekatan modul teruji sejak awal, sama sebabnya seperti dua vendor
- [ ] Sahkan: `fresh --demo` dua kali berturut-turut → hasil sama, tiada
      data berganda, tiada ralat
- [ ] Sahkan: emoji produk selepas `fresh --demo` → `HEX(icon)` = `F09F8D9B`
      (pelari guna PDO, jadi perangkap `cp850` dalam 15.1 tidak berlaku)
- [ ] `orders.status` tambah `pending`, `orders.source`, `confirmed_by`;
      `opened_by` dan `order_items.added_by` jadi nullable;
      `dining_tables.qr_token` (untuk Fasa 9B)
- [ ] Jadual bahasa: `languages` (ms lalai, en aktif), `translations`
- [ ] `login_attempts` + lajur `users.failed_attempts`, `locked_until`,
      `pin_hash`, `outlet_id`; `email` dan `password_hash` jadi **nullable**
- [ ] **`outlets`** + `outlet_id` pada orders, transactions, dining_tables,
      terminals, shifts, stock_movements
- [ ] **`product_outlets`** — stok berpindah dari `products` ke sini
- [ ] `plan_outlet_tiers`, `invoices`, `invoice_lines`
- [ ] Seed: KEDAI01 satu kedai · **KEDAI02 DUA kedai** — supaya isu kedai
      berbilang terserlah awal, sama sebabnya seperti dua vendor (3.4)
- [ ] Seed `paper_width`: lalai `58` setiap vendor · kedai kedua KEDAI02
      ada baris tindihan `80` (untuk ujian lebar resit di Fasa 5)
- [ ] `config/database.php` + `.example.php` + kemas kini `.gitignore`
- [ ] `core/Database.php` (PDO utf8mb4), `Response.php`, `Request.php`,
      `Validator.php`, `BusinessDay.php`, **`VendorScope.php`**,
      **`Lang.php`** dengan helper `t()`
- [ ] Sahkan: `t()` berfungsi dan pulangkan kunci itu sendiri kalau
      terjemahan hilang — **jangan sekali-kali pulangkan kosong**
- [ ] Sahkan: query CLI pulangkan 18 produk **setiap vendor**, emoji tidak rosak
- [ ] Sahkan: `BusinessDay` pulangkan tarikh semalam bila jam 01:00 dan
      cutoff 04:00 — punca pepijat nombor take-away kalau silap

### Fasa 2 — Auth, vendor, peranan, kaunter & syif

> Baca PELAN.md bahagian 4 habis dulu — log masuk guna **e-mel sahaja**
> (unik global), dan hashing guna **Argon2id 19456/2/1**, bukan lalai PHP.

- [ ] `core/Auth.php` — sesi menyimpan `vendor_id`, `user_id`, `role`,
      `language`; `vendor_id` diperoleh dari baris pengguna, bukan borang
- [ ] `core/Csrf.php`
- [ ] `core/Module.php` — `enabled()` dan `require()` (PELAN.md 9.4).
      Wujud sekarang supaya setiap fasa modul selepas ini memanggilnya
- [ ] Sahkan: KEDAI01 (Asas) panggil endpoint bermodul → **403**;
      KEDAI02 (Pro) → berjaya
- [ ] `jobs/Auth/LoginJob.php` — **e-mel + kata laluan** (admin/tauke sahaja)
- [ ] `jobs/Auth/PinLoginJob.php` — **nama + PIN** untuk juruwang & waiter
- [ ] `jobs/Auth/RegisterDeviceJob.php`, `RevokeDeviceJob.php` — peranti
      diikat ke satu kedai, token dalam cookie jangka panjang
- [ ] `jobs/Outlet/ValidateOutletJob.php` — sahkan `outlet_id` milik vendor
- [ ] Pemilih kedai selepas log masuk (hanya jika vendor ada >1 kedai)
- [ ] Argon2id `memory_cost 19456`, `time_cost 2`, `threads 1` (PELAN.md 4.4)
- [ ] `password_needs_rehash()` pada setiap log masuk berjaya
- [ ] `jobs/Auth/ThrottleJob.php` — kunci 15 minit selepas 5 cubaan gagal,
      rekod setiap cubaan + IP dalam `login_attempts`
- [ ] `jobs/Auth/CheckSubscriptionJob.php` — vendor suspended/cancelled ditolak
- [ ] **Empat peranan**: superadmin, admin, cashier, waiter
- [ ] `jobs/Terminal/…` (jenis cashier/waiter), `jobs/Shift/…`
- [ ] `cashier/login.php`, `cashier/shift.php`
- [ ] Sahkan: hash yang dihasilkan bermula `$argon2id$` dan muat dalam
      VARCHAR(255)
- [ ] Sahkan: e-mel tidak wujud dan kata laluan salah beri **mesej yang sama**
- [ ] Sahkan: 6 cubaan gagal → akaun dikunci, cubaan ke-7 ditolak walaupun
      kata laluan betul
- [ ] Sahkan: e-mel yang sama **tidak boleh** didaftarkan pada dua vendor
- [ ] Sahkan: waiter **tanpa e-mel langsung** boleh log masuk dengan PIN
- [ ] Sahkan: PIN **tidak berfungsi** pada peranti yang belum didaftarkan
- [ ] Sahkan: PIN salah 3 kali → dikunci sehingga admin membukanya
- [ ] Sahkan: PIN disimpan sebagai hash Argon2id, bukan teks biasa
- [ ] Sahkan: admin membatalkan peranti dari jauh → peranti itu terus
      hilang akses
- [ ] Sahkan: `outlet_id` milik vendor lain dihantar → **ditolak**
- [ ] Sahkan: vendor `suspended` → hanya admin masuk, dan hanya untuk lihat
      mesej langganan
- [ ] Sahkan dengan curl: waiter panggil endpoint bayaran → **403**

---

## Session 1B — POS Kaunter (Fasa 3)

### Fasa 3 — POS kaunter (jualan penuh)
- [ ] `jobs/Product/ListProductsJob.php` (produk + variasi + stok)
- [ ] `jobs/Cart/CalculateCartJob.php` (port `calcUnitPrice` + `getTotals`)
- [ ] **Lubang penilaian promosi dalam `CalculateCartJob`** — ikut susunan
      pengiraan PELAN.md 7.5, dan baca `discount_tax_mode` dari tetapan.
      `ApplyPromotionsJob` boleh pulangkan kosong buat masa ini; yang penting
      susunan dan titik masuknya betul sekarang, bukan ditampal di Fasa 10
- [ ] `jobs/Order/OpenOrderJob.php`, `AddOrderItemJob.php`, `CloseOrderJob.php`
- [ ] `jobs/Stock/DeductStockJob.php` (`SELECT ... FOR UPDATE`)
- [ ] `jobs/Transaction/CreateTransactionJob.php` (DB transaction,
      jana `receipt_no` unik **per outlet**)
- [ ] `jobs/Transaction/ListTransactionsJob.php`, `GetReceiptJob.php`
- [ ] `api/` untuk semua di atas — **tiada SQL dalam api/**
- [ ] `cashier/index.php` + `cashier/js/` — pindah dari index.html,
      **buang butang Variasi dari navbar**
- [ ] Sahkan: jualan di KEDAI01 dan KEDAI02 kedua-duanya bermula `0001` —
      nombor resit unik per outlet, bukan global
- [ ] Sahkan: baris masuk ke `orders`, `order_items`, `transactions`,
      `transaction_items`, `stock_movements` dengan `vendor_id` betul
- [ ] Sahkan: refresh browser → stok kekal berkurang

> **Ingat keputusan 7.1 PELAN.md:** jualan kaunter tetap melalui `orders`
> (`order_type = counter`, dibuka & ditutup serentak). Jangan tulis terus
> ke `transactions` — kalau tidak Fasa 9 perlu tulis semula fasa ini.

**Hujung Session 1B: jualan kaunter berfungsi, dua vendor dan tiga kedai terasing.**

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
- Admin guna halaman yang sama untuk cetak semula di Fasa 11

Juruwang tekan Cetak → JS muatkan halaman ini dalam `iframe` tersembunyi →
`iframe.contentWindow.print()`. Skrin POS tidak berkelip, tiada tetingkap
baharu, tiada masalah popup blocker.

**Senarai kerja**

- [ ] `print/receipt.php` — dijana pelayan melalui `GetReceiptJob`
- [ ] **Semak `vendor_id` sebelum papar resit** — halaman ini menerima id
      dalam URL, jadi ia sasaran kebocoran paling jelas dalam sistem
- [ ] `css/receipt-58mm.css` — `@page { size: 58mm auto; margin: 0 }`, 9pt monospace
- [ ] `css/receipt-80mm.css` — sama, 80mm, 10pt
- [ ] `print/receipt.php` baca `paper_width` dari `settings` (tindihan kedai
      dahulu, kemudian lalai vendor) dan muatkan **satu** fail CSS yang sepadan.
      Nilai selain `58`/`80` → jatuh balik ke `58`
- [ ] **Buang emoji dari resit bercetak** — tapis nama produk, variasi dan
      nota dalam `GetReceiptJob` (mod cetak). Rapikan ruang berganda dan ruang
      di hujung selepas emoji dibuang. Skrin juruwang **kekal** papar emoji
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
- [ ] **Lebar ikut tetapan**: seed KEDAI01 = 58, satu kedai KEDAI02 tindih
      ke 80 → resit kedua-duanya keluar pada lebar masing-masing tanpa ubah kod
- [ ] **Tiada emoji pada resit**: `🍛 Nasi Lemak` → `Nasi Lemak` (tiada ruang
      di depan); produk yang namanya emoji sahaja tidak tinggal baris kosong
- [ ] Cari bait `F0 9F` dalam HTML resit yang dijana → **tiada**
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

**Keputusan Sufi (13 Nov 2026)**

- [x] **Lebar resit — vendor tetapkan sendiri** melalui `paper_width`
      (58/80). Lalai vendor, boleh ditindih per kedai. Nilai seed: `58`.
      UI tetapan dibina di Fasa 13; sebelum itu nilai datang dari seed
- [x] **Emoji pada resit bercetak — buang.** Kekal pada skrin

### Fasa 6 — Admin kedai: katalog
- [ ] Rangka `admin/` — login, sidebar, semak peranan **dan vendor** pada
      setiap halaman
- [ ] `admin/index.php` — dashboard (jualan hari ini, transaksi, top produk,
      stok rendah) — **vendor semasa sahaja**
- [ ] `admin/products.php` — CRUD + gambar + barcode/SKU +
      **harga kos, unit, stok minimum, dikecualikan cukai**
- [ ] **Import CSV pukal** (`ImportProductsCsvJob`) — kedai runcit dengan
      2,000 barang tidak mungkin taip satu per satu melalui borang
- [ ] Amaran stok rendah pada dashboard guna `min_stock` (bukan nombor tetap)
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

### Fasa 8 — Aplikasi waiter (modul `waiter_app`)
- [ ] `waiter/login.php`, `waiter/index.php` — **mobile-first**
- [ ] Setiap endpoint `waiter/` panggil `Module::require('waiter_app')`;
      `PinLoginJob` tolak peranan waiter bila modul tiada; `SaveUserJob`
      tolak pengguna waiter baharu bila modul tiada
- [ ] Sahkan: buang `waiter_app` dari pelan → waiter tidak boleh log masuk,
      tetapi juruwang masih boleh ambil pesanan meja dari kaunter
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

### Fasa 9B — Pesanan QR pelanggan (modul `qr_order`)

> Ditambah 13 Nov 2026. Baca PELAN.md 3.9 dahulu — ini satu-satunya halaman
> awam tanpa log masuk, jadi sasaran serangan paling jelas dalam sistem.

- [ ] `order/index.php?t={qr_token}` — menu mobile-first, troli, hantar
- [ ] `jobs/QrOrder/ResolveTableTokenJob.php` — token → vendor, outlet, meja;
      semak modul `qr_order`, tetapan `qr_order_enabled`, meja aktif
- [ ] `PublicMenuJob` — produk aktif + harga kedai + promosi semasa
      (hanya medan yang perlu — **tiada** `cost_price`, tiada stok sebenar)
- [ ] `SubmitQrOrderJob` — **bayar di kaunter** sahaja dalam fasa ini:
      `status = pending`, `source = qr`, harga dikira semula di pelayan,
      **stok belum ditolak**. Pilihan bayar online disambung di Fasa 9D
- [ ] `ListPendingQrOrdersJob`, `AcceptQrOrderJob` (tolak stok, gabung ke
      pesanan terbuka meja itu), `RejectQrOrderJob`
- [ ] **Amaran berlapis (PELAN.md 9.8):** bunyi + sepanduk kekal di skrin
      juruwang & waiter, getar Android, naik tahap selepas 2 minit (tinjau
      setiap 10 saat — tiada WebSocket)
- [ ] Telefon pelanggan papar "Menunggu disahkan · N min"; selepas 3 minit
      "Sila maklumkan pelayan berdekatan"
- [ ] Sahkan: pesanan `pending` 2 minit tanpa tindakan → sepanduk jadi merah,
      bunyi berulang
- [ ] `admin/tables.php`: cetak kad QR setiap meja, **jana semula** token
- [ ] Sahkan: token rawak / token meja vendor lain → halaman "tidak tersedia"
      yang sama, tiada kebocoran nama kedai
- [ ] Sahkan: harga diubah dalam pelayar → diabaikan, harga pelayan digunakan
- [ ] Sahkan: pesanan kedua semasa satu masih `pending` → ditolak
- [ ] Sahkan: stok tidak berubah sehingga **Terima** ditekan
- [ ] Sahkan: token dijana semula → QR lama terus "tidak tersedia"
- [ ] Sahkan: KEDAI01 (pelan Asas / runcit) → modul tiada langsung
- [ ] Sahkan pada viewport telefon (390x844)

### Fasa 9C — Dapur: skrin & slip automatik (modul `kitchen`)

> Ditambah 13 Nov 2026. Baca PELAN.md 9.5 dahulu.

- [ ] `kitchen/index.php` — skrin landskap tablet: lajur **Baharu ·
      Sedang dimasak · Siap**, tinjau setiap 5 saat
- [ ] Daftar peranti dapur (`terminals.type = kitchen`) — tiada PIN, token
      peranti sahaja; tetapan `auto_print` per peranti
- [ ] `jobs/Kitchen/CreateKitchenTicketJob.php` — dipanggil semasa waiter/
      juruwang hantar pesanan, dan semasa `AcceptQrOrderJob`; hanya item
      kategori `send_to_kitchen = 1`
- [ ] `AdvanceTicketJob` (new → preparing → ready → done),
      `CancelTicketItemJob` (cetak slip **BATAL**)
- [ ] `ClaimTicketPrintJob` — `UPDATE … SET printed_at = NOW() WHERE
      printed_at IS NULL`; cetak hanya jika baris dikemas kini = 1
- [ ] `print/kitchen-slip.php` — tiada harga, tiada emoji, huruf besar
- [ ] Lencana "Siap dihidang" pada skrin waiter dan juruwang
- [ ] `admin/categories.php` tambah suis "Hantar ke dapur"
- [ ] Sahkan: meja tambah pesanan kedua → **tiket kedua**, bukan tiket
      pertama dikemas kini
- [ ] Sahkan: dua tab dapur dibuka serentak → slip dicetak **sekali** sahaja
- [ ] Lajur kecil **"Menunggu disahkan"** di skrin dapur dengan butang
      **Terima** untuk pesanan QR bayar-di-kaunter (PELAN.md 9.8 lapisan 2)
- [ ] Sahkan: pesanan QR yang belum diterima muncul **hanya** di lajur
      "Menunggu disahkan", bukan sebagai tiket — tiket dicipta bila diterima
- [ ] Sahkan: token peranti dapur panggil endpoint harga/bayaran/laporan → **403**
- [ ] Sahkan: pesanan air kotak sahaja → tiada tiket langsung
- [ ] Sahkan: KEDAI02 dapur tidak nampak tiket vendor lain

**Hujung Session 3: kedai makan boleh guna sistem ini sepenuhnya.**

---

## Session 3B — Bayaran & Kedai Online (Fasa 9D–9E)

> Ditambah 13 Nov 2026. Baca PELAN.md 9.6–9.8 dahulu. Ini kali pertama
> sistem menyentuh wang sebenar dari luar kaunter.

### Fasa 9D — Bayaran online (modul `online_payment`)

- [ ] `core/Crypto.php` — `sodium_crypto_secretbox`, kunci induk dalam
      `config/app.php` (luar git)
- [ ] `core/Payment/PaymentGateway.php` + **ToyyibPay, Billplz, SenangPay,
      Stripe** — `createBill`, `verifyCallback`, `fetchStatus`
- [ ] `admin/payment-gateway.php` — pilih gerbang, masukkan kunci (papar 4
      aksara akhir sahaja), mod sandbox, butang "Uji sambungan"
- [ ] `CreateOnlinePaymentJob` — `reference` rawak, `expires_at`, URL bayar
- [ ] `pay/callback.php` → `HandleGatewayCallbackJob` — tandatangan, amaun,
      `fetchStatus`, `UPDATE … WHERE status = 'pending'`, tolak stok,
      cipta `transactions` (tanpa kaunter/syif), cipta tiket dapur
- [ ] `pay/return.php` — **papar status sahaja**, tidak menukar apa-apa
- [ ] `ExpireUnpaidOrdersJob` — dipanggil secara malas
- [ ] Sambung ke QR meja: pilihan "Bayar online" ikut `qr_payment_options`
- [ ] Skrin admin "Perlu tindakan" — dibayar tetapi stok habis
- [ ] `MarkRefundedJob` — admin tanda dipulangkan → transaksi refund
- [ ] Sahkan: buka `pay/return.php` dengan URL palsu "berjaya" → pesanan
      **kekal** belum dibayar
- [ ] Sahkan: callback dengan tandatangan salah / amaun diubah → ditolak, dilog
- [ ] Sahkan: callback sama dihantar 3 kali → stok ditolak **sekali**
- [ ] Sahkan: callback rujukan KEDAI02 ditandatangan kunci KEDAI03 → ditolak
- [ ] Sahkan: tidak bayar 15 minit → pesanan batal, stok tidak berubah
- [ ] Sahkan: kunci gerbang dalam DB ialah teks tersulit, bukan teks biasa
- [ ] Sahkan setiap gerbang dalam **sandbox** sebelum mod sebenar

### Fasa 9E — Kedai online, ambil sendiri (modul `online_order`)

- [ ] `outlets.shop_slug` + tetapan `online_order_enabled`,
      `pickup_payment_options`, `pickup_lead_minutes`, `pickup_hours`
- [ ] `s/{shop_slug}` — menu, troli, borang nama/telefon/masa ambil,
      pilihan bayar (mobile-first)
- [ ] `SubmitPickupOrderJob` — `order_type = pickup`, `source = online`
- [ ] Halaman status pelanggan melalui `public_token`
- [ ] Senarai pesanan ambil sendiri di admin/juruwang: Terima, Siap untuk
      diambil, Sudah diambil; butang WhatsApp `wa.me` dengan mesej siap
- [ ] Bayar semasa ambil → bayar di kaunter seperti biasa bila diambil
- [ ] Padam/kaburkan nama & telefon pelanggan selepas 90 hari (PDPA)
- [ ] Sahkan: slug kedai lain / slug tidak wujud → halaman "tidak tersedia"
- [ ] Sahkan: masa ambil di luar `pickup_hours` → ditolak di pelayan
- [ ] Sahkan: `public_token` pesanan lain → tiada data bocor
- [ ] Sahkan: KEDAI03 (peniaga dari rumah) — tempah, bayar sandbox, siap,
      ambil — dari awal hingga akhir
- [ ] Sahkan pada viewport telefon (390x844)

**Hujung Session 3B: pelanggan boleh pesan dan bayar sendiri, di meja atau
dari rumah.**

---

## Session 4 — Promosi, Operasi & Admin Penuh (Fasa 10–13)

### Fasa 10 — Promosi & diskaun

> Jadual sudah wujud sejak Fasa 1 dan titik masuk sudah ada dalam
> `CalculateCartJob` sejak Fasa 3. Fasa ini membina enjin dan UI.
> Baca PELAN.md 7.4–7.8 sebelum mula — empat peraturan di sana sudah
> diputuskan Sufi dan tidak boleh diubah sambil lalu.

- [ ] `jobs/Promotion/SavePromotionJob.php`, `ListPromotionsJob.php`,
      `TogglePromotionJob.php`, `ActivePromotionsJob.php`
- [ ] `jobs/Promotion/ApplyPromotionsJob.php` — enjin sebenar, dipanggil
      oleh `CalculateCartJob`
- [ ] Enam jenis: `product_price`, `product_percent`, `category_percent`,
      `bill_percent`, `bill_fixed`, `buy_x_get_y`
- [ ] Julat tarikh ikut `business_day`; happy hour ikut jam dinding (7.7)
- [ ] `days_of_week` mask — promosi hujung minggu sahaja, dan sebagainya
- [ ] Konflik: `priority` menurun, satu promosi satu item, kecuali
      `is_stackable` (7.6)
- [ ] `admin/promotions.php` — CRUD, pilih produk/kategori, kalendar tarikh
- [ ] `admin/settings.php` tambah **`discount_tax_mode`** (sebelum/selepas
      cukai) + had diskaun manual
- [ ] Promosi disalin ke `transaction_promotions` dan
      `transaction_items.promotion_name`
- [ ] Resit papar baris diskaun dan nama promosi
- [ ] Laporan promosi: berapa kali digunakan, berapa jumlah diskaun diberi
- [ ] Semua endpoint promosi panggil `Module::require('promotions')`;
      `CalculateCartJob` langkau promosi jika modul tiada
- [ ] Sahkan: vendor turun ke pelan tanpa `promotions` → promosi aktif
      **berhenti** memberi diskaun, datanya kekal

**Pengesahan**

- [ ] Tukar `discount_tax_mode` → jumlah cukai berubah mengikut mod, dan
      **transaksi lama tidak berubah** (mod disimpan pada setiap transaksi)
- [ ] Promosi item **sentiasa** menjejaskan cukai dalam kedua-dua mod —
      ini betul, bukan pepijat (PELAN.md 7.5)
- [ ] Dua promosi bertindih pada satu produk → hanya `priority` tertinggi kena
- [ ] Promosi tamat `31 Ogos`, jualan jam 01:00 pada 1 Sept dengan
      `business_day` 31 Ogos → **masih kena**
- [ ] Happy hour 14:00–17:00 → jualan jam 13:59 tidak kena, 14:01 kena
- [ ] `max_uses` dihormati walaupun dua kaunter membayar serentak
      (`used_count` dinaikkan dalam DB transaction yang sama)
- [ ] Diskaun manual juruwang dikenakan **selepas** promosi
- [ ] Had diskaun manual: `0` = tiada had (kelakuan sekarang kekal)
- [ ] Produk `is_tax_exempt` dikecualikan dari asas cukai
- [ ] Promosi KEDAI01 **tidak** kena pada jualan KEDAI02

### Fasa 11 — Stok, transaksi, void & refund
- [ ] `admin/stock.php` — baki, terima stok, pelarasan, log pergerakan
- [ ] `admin/transactions.php` — tapis tarikh/juruwang/kaunter/kaedah/jenis pesanan
- [ ] `jobs/Transaction/VoidTransactionJob.php` — pulang stok penuh
- [ ] `jobs/Transaction/RefundTransactionJob.php` — refund separa, transaksi negatif
- [ ] Cetak semula resit dari admin
- [ ] Sahkan: void pulangkan stok betul; refund separa hanya pulangkan item dipilih
- [ ] Sahkan: admin KEDAI01 tidak boleh void transaksi KEDAI02

### Fasa 12 — Laporan
- [ ] `admin/reports.php` — harian, bulanan, ikut kaedah bayaran, ikut juruwang
- [ ] **Laporan ikut jenis pesanan** (dine-in vs take away vs kaunter)
- [ ] Laporan tutup syif (Z-report)
- [ ] Eksport CSV
- [ ] Sahkan: jumlah laporan = jumlah dikira terus dari DB melalui SQL
- [ ] Sahkan: refund ditolak, transaksi void dikecualikan
- [ ] Sahkan: **jumlah KEDAI01 tidak termasuk sebarang jualan KEDAI02** —
      bandingkan dengan `SUM` bertapis vendor

### Fasa 13 — Tetapan kedai
- [ ] `admin/users.php` — admin/cashier/waiter (dalam vendor sahaja)
- [ ] `admin/terminals.php` — kaunter & peranti waiter
- [ ] `admin/tables.php` — susun atur meja, kawasan, kapasiti
- [ ] `admin/payment-methods.php`
- [ ] `admin/settings.php` — nama kedai, kadar cukai, caj perkhidmatan,
      caj bungkus, `day_cutoff_time`, footer, lebar kertas (58/80 —
      lalai vendor, boleh ditindih per kedai)
- [ ] `admin/logs.php` — log aktiviti vendor
- [ ] Sahkan: tukar kadar cukai KEDAI01 → jualan KEDAI02 tidak terjejas
- [ ] Sahkan: jualan lama tidak berubah bila kadar ditukar

> `business_type` **tiada** dalam tetapan kedai — ia milik superadmin
> (Fasa 14), kerana ia menentukan ciri yang dilanggan.

---

## Session 5 — Platform SaaS (Fasa 14–16)

### Fasa 14 — Panel superadmin
- [ ] `superadmin/` — login berasingan, layout berasingan
- [ ] `superadmin/vendors.php` — senarai, cari, lihat penggunaan
- [ ] `superadmin/plans.php` — pelan, harga, had, **tanda modul per pelan**
      (`SavePlanModulesJob`; modul teras `pos` tidak boleh dinyahtanda)
- [ ] Sahkan: superadmin buang modul dari pelan → vendor pelan itu terus
      kena 403 pada permintaan **seterusnya**, tanpa log keluar
- [ ] `superadmin/subscriptions.php` — status, tempoh, tandakan bayar
- [ ] `jobs/Vendor/…`, `jobs/Plan/…`
- [ ] Dashboard platform: jumlah vendor, aktif vs suspended, jualan agregat
- [ ] Sahkan: superadmin (vendor_id NULL) **tidak boleh** masuk POS vendor
- [ ] Sahkan: admin vendor **tidak boleh** capai `/superadmin/` langsung

### Fasa 15 — Onboarding, had pelan & penggantungan
- [ ] `jobs/Vendor/ProvisionVendorJob.php` — cipta vendor baharu lengkap:
      tetapan lalai, kaedah bayaran, kategori, akaun admin, kaunter pertama
- [ ] `core/PlanLimit.php` — kuatkuasa `max_terminals`, `max_users`,
      `max_products` **dalam job simpan**, bukan hanya di UI
- [ ] Penggantungan: vendor `suspended` → hanya admin masuk, hanya untuk
      melihat mesej langganan
- [ ] Sahkan: vendor baharu boleh terus berjualan selepas provision, tanpa
      sebarang langkah manual dalam DB
- [ ] Sahkan: had pelan ditolak melalui API terus, bukan hanya butang disable
- [ ] Audit modul: setiap endpoint `stock`, `reports`, `csv_import`,
      `promotions`, `waiter_app`, `qr_order`, `kitchen`, `online_payment`, `online_order` memanggil `Module::require()` — grep, bukan anggapan
- [ ] Sidebar admin sorok menu modul yang tiada; halaman "Naik taraf pelan"
      bila URL modul dibuka terus

### Fasa 16 — Kedai berbilang, langganan & bil

> Jadual `outlets`, `plan_outlet_tiers`, `invoices`, `invoice_lines` sudah
> wujud sejak Fasa 1 dan `outlet_id` sudah ada pada semua jadual operasi.
> Fasa ini membina pengurusan dan pengebilan. Baca PELAN.md 9.

- [ ] `admin/outlets.php` — tauke tambah / sunting / tutup kedai
- [ ] `jobs/Outlet/SaveOutletJob.php` — kuatkuasa `max_outlets` pelan
- [ ] `jobs/Outlet/SwitchOutletJob.php` — tauke bertukar antara kedai
- [ ] Pemilih kedai pada bar atas admin (hanya jika vendor ada >1 kedai)
- [ ] `admin/product-outlets.php` — tetapkan `price_override`, `stock`,
      `min_stock`, `is_available` setiap kedai
- [ ] `superadmin/plans.php` — editor peringkat `plan_outlet_tiers`
- [ ] `jobs/Billing/CalculateOutletPriceJob.php` — kira dari peringkat,
      **bukan** nombor tetap dalam kod
- [ ] `jobs/Billing/GenerateInvoiceJob.php` — jana sebagai `draft`,
      prorata untuk kedai yang dibuka pertengahan kitaran
- [ ] `superadmin/invoices.php` — semak, keluarkan, tandakan dibayar
- [ ] `admin/billing.php` — vendor lihat bil sendiri

**Pengesahan**

- [ ] Vendor 3 kedai dengan peringkat 99 / 79 / 79 → bil RM 257
- [ ] Kedai dibuka pada 15 haribulan → baris prorata, bukan caj penuh
- [ ] Tukar harga peringkat → **bil lama tidak berubah** (`invoice_lines`
      simpan `unit_price` sendiri)
- [ ] `max_outlets` ditolak melalui API terus, bukan hanya butang disable
- [ ] Stok Kedai A tidak menjejaskan stok Kedai B bagi produk yang sama
- [ ] `price_override` NULL → guna `products.price`; ditetapkan → guna override
- [ ] Laporan gabungan tauke = jumlah semua kedainya
- [ ] Juruwang Kedai A **tidak** nampak jualan Kedai B
- [ ] `outlet_id` milik vendor lain dihantar melalui API → **ditolak**
      (`ValidateOutletJob`)

---

## Session 6 — Bahasa, Audit & Dokumentasi (Fasa 17–19)

### Fasa 17 — Bahasa & modul terjemahan

> `Lang.php` dan helper `t()` sudah wujud sejak Fasa 1, dan setiap rentetan
> dari Fasa 2 ke sini sudah melaluinya. Fasa ini membina modul pentadbiran
> dan melengkapkan set Bahasa Inggeris. Baca PELAN.md 7.9–7.11 dahulu.

- [ ] `superadmin/languages.php` — senarai bahasa, tambah bahasa baharu,
      hidup/mati
- [ ] `superadmin/translations.php` — editor kunci & nilai, tapis ikut bahasa,
      cari kunci
- [ ] `jobs/Language/MissingKeysJob.php` — senaraikan kunci yang belum
      diterjemah bagi setiap bahasa
- [ ] `jobs/Language/ExportTranslationsJob.php` — jana `lang/{code}.php`
      sebagai cache, supaya tiada pertanyaan DB setiap permintaan
- [ ] Import/eksport CSV terjemahan — supaya penterjemah luar boleh bekerja
      tanpa akses sistem
- [ ] Set Bahasa Inggeris **lengkap** untuk semua skrin sedia ada
- [ ] `admin/settings.php` tambah `default_language` (pilihan vendor)
- [ ] Pemilih bahasa untuk pengguna sendiri (`users.language`)

**Pengesahan**

- [ ] Tukar bahasa vendor ke `en` → seluruh antara muka bertukar
- [ ] **Nama produk kekal seperti vendor taip** — tidak diterjemah (7.10),
      ini betul dan bukan pepijat
- [ ] **Resit ikut bahasa vendor, bukan bahasa juruwang** — juruwang guna
      antara muka Inggeris, resit pelanggan tetap Melayu kalau vendor pilih
      Melayu (7.11)
- [ ] `MissingKeysJob` pulangkan kosong untuk `ms` dan `en`
- [ ] Padam satu terjemahan → skrin papar kunci, **bukan ruang kosong**
- [ ] Tambah bahasa ketiga (cth. `zh`) melalui UI dan sahkan ia muncul
      sebagai pilihan vendor — modul ini mesti benar-benar boleh tambah
      bahasa, bukan hanya menyokong dua yang sedia ada
- [ ] `grep` untuk rentetan Melayu yang masih ditulis terus dalam kod
      paparan — sepatutnya tiada; kalau ada, ia terlepas sejak fasa awal

### Fasa 18 — Audit kebocoran antara vendor

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

### Fasa 19 — Dokumentasi
- [ ] Panduan juruwang (kemas kini `docs/panduan-pengguna.md`)
- [ ] **Panduan waiter** (baharu)
- [ ] **Panduan admin kedai** (baharu)
- [ ] **Panduan superadmin** (baharu)
- [ ] Kemas kini `docs/variasi/` — editor kini halaman penuh dalam admin
- [ ] Screenshot baharu melalui skill `user-manual-auto`
- [ ] README pemasangan: import schema, cipta pos_user, provision vendor pertama
- [ ] Jalankan `/code-review` ke atas keseluruhan projek

---

## Perkara tertangguh (bukan sebahagian 23 fasa)

- **Bayaran langganan dalam talian** — superadmin tandakan status secara
  manual buat masa ini. Gerbang pembayaran belum dibincangkan
- **Set semula kata laluan melalui e-mel** — perlukan SMTP. Buat masa ini
  admin vendor set semula untuk kakitangannya, superadmin untuk admin vendor
- **Modul tambahan per vendor** (add-on di luar pelan) — gaya ringkas dipilih:
  modul ikut pelan sahaja. `vendor_modules` boleh ditambah kemudian
- **Pesanan QR untuk take away / tanpa meja** — versi pertama untuk meja sahaja
- **Penghantaran ke rumah pelanggan (delivery)** — kedai online versi pertama untuk ambil sendiri sahaja; caj & zon penghantaran belum dibincangkan
- **Pemulangan wang automatik melalui API gerbang** — buat masa ini vendor pulangkan dari papan pemuka gerbang
- **Komisen platform atas bayaran online** — wang terus ke vendor; platform hanya caj langganan
- **`user_vendors`** — satu e-mel menguruskan beberapa kedai. Hanya perlu
  bila ada pelanggan sebenar dengan dua cawangan (PELAN.md 4.1)
- **`product_translations`** — terjemahan nama produk (PELAN.md 7.10)
- **Subdomain per vendor** (`kedai01.pos.com`) — perlu DNS dan vhost;
  boleh ditambah kemudian tanpa ubah skema
- **Eksport data vendor** bila vendor berhenti melanggan
- **ESC/POS mentah + buka laci wang** — tunggu jenama printer termal
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
| 26 Ogos 2026 | **Modul promosi ditambah** — 22 jadual → 25, 16 fasa → 17 | Pelan langsung tiada promosi produk; hanya diskaun manual juruwang |
| 26 Ogos 2026 | Lajur produk ditambah: `cost_price`, `min_stock`, `unit`, `is_tax_exempt` | Tanpa `cost_price` laporan tidak boleh kira untung; `min_stock` diperlukan oleh amaran stok rendah yang pelan sudah janji |
| 26 Ogos 2026 | `discount_tax_mode` jadi tetapan vendor, disimpan pada setiap transaksi | Keputusan Sufi: vendor tentukan sendiri diskaun sebelum atau selepas cukai |
| 27 Ogos 2026 | **Log masuk guna e-mel** — `users.username` dibuang, `users.email` unik **global** | Keputusan Sufi. Ini satu-satunya pengecualian kepada peraturan UNIQUE-per-vendor (3.5), kerana e-mel mengenal pasti pengguna sebelum sistem tahu vendor mana |
| 27 Ogos 2026 | **Argon2id 19456/2/1** dipilih, bukan bcrypt dan bukan lalai PHP | Sufi serahkan keputusan keselamatan. Diukur pada mesin sebenar: lebih kuat daripada bcrypt dan lebih laju (123ms) daripada bcrypt cost 10 (146ms). Lalai PHP 801ms terlalu perlahan |
| 27 Ogos 2026 | **Dwibahasa ditambah** — 25 jadual → 28, 17 fasa → 18 | Keputusan Sufi: lalai Melayu, vendor boleh pilih Inggeris, superadmin boleh tambah bahasa |
| 27 Ogos 2026 | `t()` wajib wujud sejak Fasa 1 walaupun modul terjemahan di Fasa 16 | Terjemahan menyentuh setiap skrin. Kalau ditambah lewat, setiap paparan perlu dibuka semula dan setiap rentetan yang terlepas jadi pepijat senyap |
| 27 Ogos 2026 | Nama produk **tidak** diterjemah | Nama makanan selalunya tidak diterjemah, dan memaksa vendor mengisi nama Inggeris untuk ribuan barang ialah beban yang tiada siapa mahu. `product_translations` boleh ditambah kemudian tanpa memecahkan apa-apa |
| 27 Ogos 2026 | **Model tiga lapisan: vendor → outlet → users.** 28 jadual → 34, 18 fasa → 19 | Pembetulan model. Versi awal menganggap vendor = kedai, jadi tauke 3 kedai perlu 3 langganan dan 3 e-mel, tanpa laporan gabungan |
| 27 Ogos 2026 | Stok berpindah dari `products` ke `product_outlets`; harga boleh ditindih per kedai | Satu lajur stok pada produk tiada makna apabila vendor ada tiga kedai. Keputusan Sufi: katalog dikongsi, harga & stok per kedai |
| 27 Ogos 2026 | **PIN untuk juruwang & waiter**, e-mel untuk admin sahaja | Waiter log masuk 20–30 kali sehari pada tablet berkongsi. Kalau menyusahkan, mereka akan berkongsi satu akaun dan sistem hilang jejak siapa buat apa. `users.email` jadi nullable |
| 27 Ogos 2026 | Kedai tambahan dicaj mengikut **peringkat**, bukan diskaun % tetap | Caj per lokasi ialah norma industri POS SaaS. Peringkat dipilih kerana peratus tetap tidak menjawab kedai ke-5 atau ke-20, dan peringkat boleh menghasilkan peratus rata juga |
| 13 Nov 2026 | **Lebar resit jadi tetapan vendor** (`paper_width` 58/80, tindihan per kedai), bukan satu lalai sistem | Keputusan Sufi. Kedai berbeza guna printer berbeza; satu vendor boleh ada kaunter 58mm dan 80mm |
| 13 Nov 2026 | **Emoji dibuang dari resit bercetak**, kekal pada skrin | Keputusan Sufi. Driver termal murah cetak emoji sebagai kotak hitam |
| 13 Nov 2026 | **Modul per pelan** — `plans.features_json` diganti `modules` + `plan_modules`. 34 jadual → 36 | Keputusan Sufi: superadmin tentukan modul dalam setiap pelan, gaya ringkas. Jadual sebenar boleh di-JOIN dan disemak dengan kekunci asing; JSON tidak |
| 13 Nov 2026 | **Bayaran online** — modul `online_payment`, wang terus ke **akaun gerbang vendor sendiri**; ToyyibPay, Billplz, SenangPay, Stripe melalui satu antara muka. Jadual `vendor_payment_gateways`, `online_payments` (37 → 39) | Keputusan Sufi. Platform tidak memegang wang pelanggan — tiada pembayaran balik kepada vendor, tiada isu pelesenan. Bayar online → terus ke dapur; bayar di kaunter → perlu Terima |
| 13 Nov 2026 | **Kedai online, ambil sendiri** — modul `online_order`, `s/{shop_slug}`, Session 3B baharu (Fasa 9D–9E), 21 → 23 fasa, 10 modul | Keputusan Sufi: sistem juga untuk peniaga dari rumah (makanan atau barang). Tiada jenis perniagaan baharu — peniaga makanan guna `restaurant`, barang guna `retail`. Delivery tertangguh |
| 13 Nov 2026 | **Amaran berlapis** untuk pesanan yang perlu Terima (PELAN.md 9.8) | Sufi bimbang kakitangan tidak perasan pesanan QR. Bunyi + sepanduk kekal, skrin dapur juga boleh Terima, naik tahap selepas 2 minit, pelanggan nampak masa menunggu |
| 13 Nov 2026 | **Modul dapur `kitchen`** — skrin + slip automatik, Fasa 9C; jadual `kitchen_tickets` (36 → 37), 8 modul, 20 → 21 fasa | Keputusan Sufi. Pelan sebelum ini tiada saluran ke dapur langsung. Pelayar hanya mencetak ke printer komputernya sendiri, jadi dapur perlukan peranti sendiri; skrin dan slip digabung dalam satu modul |
| 13 Nov 2026 | **`waiter_app` jadi modul** (7 modul) | Keputusan Sufi. Tanpanya kedai makan masih ambil pesanan meja dari skrin juruwang |
| 13 Nov 2026 | `schema.sql` + `seed.sql` tulisan tangan → **`database/migrate.php`** + migrasi bernombor + seed `core`/`demo` | Keputusan Sufi: persediaan satu arahan, dan skema boleh berubah di pelayan sebenar tanpa sunting tangan. Bonus: PDO utf8mb4 mengelak perangkap `cp850` |
| 13 Nov 2026 | **Pesanan QR pelanggan** ditambah sebagai modul `qr_order` — Fasa 9B, 19 → 20 fasa | Permintaan Sufi. Pesanan masuk `pending` dan perlu diterima kakitangan supaya QR yang diimbas dari luar kedai tidak boleh menolak stok |
| 27 Ogos 2026 | Kedai dibuka pertengahan kitaran diprorata | Jangkaan pelanggan, dan menghapuskan insentif menunggu awal bulan sebelum membuka kedai |
