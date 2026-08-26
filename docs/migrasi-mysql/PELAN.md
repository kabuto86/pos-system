# Pelan Induk — KedaiPOS: MySQL + PHP Vanila

> **Dokumen rujukan tetap.** Baca fail ini SEBELUM menulis sebarang kod dalam
> mana-mana session. Keputusan di sini sudah disahkan oleh Sufi — jangan ubah
> tanpa bertanya. Untuk status semasa, lihat [PROGRES.md](PROGRES.md).

Kemas kini terakhir: 26 Ogos 2026 (skop diluaskan — dua jenis perniagaan)
Persekitaran rujukan: XAMPP · PHP 8.2.12 · MariaDB 10.4.32

---

## 1. Apa sistem ini sebenarnya

Satu sistem POS yang dilanggan oleh vendor. Semasa pemasangan, vendor memilih
**jenis perniagaan**, dan pilihan itu menentukan aliran kerja seluruh sistem:

| | **Kedai Runcit** (`retail`) | **Kedai Makan** (`restaurant`) |
|---|---|---|
| Ambil pesanan | Di kaunter sahaja | Oleh **waiter** atau di kaunter |
| Jenis pesanan | Tiada | **Dine-in** atau **Take away** |
| Pengenalan pesanan | Tiada | Dine-in → **nombor meja**<br>Take away → **nombor take-away** |
| Bila bayar | Terus di kaunter | Bila pelanggan nak balik |
| Tambah pesanan | Tidak | Ya, sepanjang pelanggan makan |
| Bil | Satu | Boleh **gabung** dan **pecah** |
| Khusus | **Imbas barcode**, carian barang | Peranan waiter, susun atur meja |

Ditetapkan melalui `settings.business_type`. Ciri yang tidak berkenaan
**disembunyikan sepenuhnya** — kedai runcit tidak nampak butang meja, kedai
makan tidak nampak medan barcode.

> **Andaian yang perlu disahkan Sufi:** satu pemasangan = satu vendor
> (satu folder, satu pangkalan data). Langganan diurus di luar sistem.
> Lihat bahagian 12 kalau vendor perlu dikongsi dalam satu pemasangan.

## 2. Konvensyen projek (dari CLAUDE.md — WAJIB)

- Bahasa Melayu untuk semua teks yang dipaparkan kepada pengguna
- Bahasa Inggeris untuk nama fail, nama fungsi, nama pemboleh ubah, nama lajur DB
- Bootstrap sahaja untuk gaya — **tiada inline CSS**
- PHP vanila — **tiada struktur Laravel**, tiada Composer, tiada framework
- **Satu job class = satu kerja.** Fail dalam `api/` mesti nipis (10–15 baris):
  semak sesi → sahkan input → panggil satu job → pulangkan JSON

## 3. Keputusan yang disahkan Sufi

| # | Perkara | Keputusan | Kesan |
|---|---|---|---|
| 1 | Kaunter | **Dinamik** — vendor boleh tambah | Jadual `terminals`; kunci stok **wajib**; nombor resit unik merentas kaunter |
| 2 | Syif | **Ya** | Jadual `shifts`; setiap resit tahu siapa juruwangnya |
| 3 | Batal / refund | **Ya** | `stock_movements` wajib; refund = transaksi negatif berpaut pada asal |
| 4 | Gambar produk | **Muat naik**, ada lalai | `products.image_path`; rantaian gambar → emoji → lalai |
| 5 | Printer | **Termal**, jenama belum pasti | Driver Windows + CSS 58mm/80mm. **Bukan** ESC/POS mentah |
| 6 | Jenis perniagaan | **Dua** — runcit & kedai makan | `settings.business_type` menggating ciri |
| 7 | Kedai runcit | Aliran sekarang + **barcode & carian** | `products.barcode` |
| 8 | Ambil pesanan | Waiter **atau** kaunter | Peranan `waiter`; aplikasi `/waiter/` berasingan |
| 9 | Waiter | **Tiada akses bayaran langsung** | Ditguatkuasa di pelayan, bukan sekadar sorok butang |
| 10 | Dine-in | Nombor meja, tambah pesanan, bayar di hujung | `dining_tables`, `orders` |
| 11 | Take away | Nombor take-away, bayar di kaunter | `orders.takeaway_no`, reset setiap hari perniagaan |
| 12 | Bil dine-in | **Gabung dan pecah** | `transaction_orders`; `order_items.paid_qty` |

## 4. Tiga keputusan seni bina yang menentukan segalanya

### 4.1 Semua jualan lalui `orders` — termasuk kedai runcit

Di kedai runcit, pesanan dibuka dan dibayar dalam satu klik; juruwang tidak
nampak pun kewujudannya.

**Sebab:** kalau runcit menulis terus ke `transactions` sementara kedai makan
melalui `orders`, `CreateTransactionJob` perlu ditulis dua kali dan kod POS
kaunter perlu ditulis semula apabila mod kedai makan dibina. Satu laluan
bermakna tiada kerja berulang, dan ciri "tahan pesanan" untuk kedai runcit
(pelanggan pergi ambil barang lain dahulu) datang percuma kemudian.

### 4.2 `orders` dan `transactions` adalah dua benda berbeza

| `orders` | `transactions` |
|---|---|
| Apa yang **dipesan** | Apa yang **dibayar** |
| Boleh berubah sepanjang makan | Kekal selamanya selepas dibuat |
| Satu meja, satu pesanan | Satu bayaran |
| Gabung bil: **banyak** order → satu transaction | Pecah bil: satu order → **banyak** transaction |

Sebab itu keduanya perlu wujud berasingan, dan hubungannya banyak-ke-banyak
melalui `transaction_orders`.

### 4.3 Hari perniagaan bukan tarikh kalendar

Kedai makan tutup pukul 2 pagi. Nombor take-away `001` yang dikeluarkan pukul
1 pagi masih milik hari semalam.

Jadi `orders.business_day` dan `transactions.business_day` (jenis DATE)
dikira dari `settings.day_cutoff_time` (lalai `04:00`), **bukan** dari
`CURDATE()`. Terlepas perkara ini, nombor take-away akan bertembung setiap
malam dan laporan harian akan silap.

## 5. Peranan pengguna

| Peranan | Boleh | Tidak boleh |
|---|---|---|
| `admin` | Semua | — |
| `cashier` | POS, bayaran, buka/tutup syif, sejarah syif sendiri | Urus katalog, laporan penuh, tetapan |
| `waiter` | Buka meja, ambil & tambah pesanan, lihat status meja | **Bayaran, tutup bil, void, refund, laporan** |

> Sekatan waiter **mesti disemak di dalam setiap endpoint**. Menyorok butang
> di UI bukan kawalan keselamatan — sesiapa boleh panggil API terus.

## 6. Skema pangkalan data — 19 jadual

Pangkalan data: `pos_system` · `utf8mb4_unicode_ci` · InnoDB

> **utf8mb4 wajib** pada pangkalan data, jadual, lajur DAN sambungan PDO.

### A. Katalog (4)

**`categories`** — id, name, sort_order, is_active, created_at

**`products`** — id, category_id(FK), name, icon, image_path,
**barcode** (UNIQUE, nullable), **sku** (nullable), price, stock,
is_active, created_at, updated_at

**`variation_groups`** — id, product_id(FK), **code**, name,
type ENUM(single/multi), is_required, sort_order

**`variation_options`** — id, group_id(FK), **code**, label, price_delta,
sort_order, is_active

> Lajur `code` (contoh: lauk, ayam) **mesti dikekalkan**. `makeLineId()`
> bergantung padanya untuk kunci troli yang stabil. Kalau guna id nombor
> sahaja, kunci berubah setiap kali admin menyunting dan baris yang
> sepatutnya bergabung akan berpecah.

### B. Pesanan (4) — teras mod kedai makan

**`orders`** — id, order_no, **business_day**(DATE),
**order_type** ENUM(dine_in/takeaway/counter),
table_id(FK, nullable), **takeaway_no**(nullable),
status ENUM(open/billed/paid/cancelled), guest_count,
opened_by(FK users), terminal_id(FK, nullable), note,
opened_at, closed_at

> `order_type = counter` digunakan oleh mod kedai runcit — pesanan yang dibuka
> dan dibayar serentak.
> `takeaway_no` unik setiap `business_day`, dipapar 3 digit (001, 002…).
> Juruwang taip nombor ini untuk memanggil pesanan.

**`order_items`** — id, order_id(FK), product_id,
**product_name**, **icon**, **base_price**, **unit_price**, variant_label,
qty, **paid_qty**, line_total, status ENUM(ordered/served/cancelled),
note, added_by(FK users), added_at

> `paid_qty` yang membolehkan pecah bil: satu baris pesanan boleh dibayar
> separa oleh beberapa orang. Pesanan hanya `paid` bila setiap baris
> mempunyai `paid_qty = qty`.
> `note` untuk permintaan bebas pelanggan ("kurang pedas", "tanpa bawang")
> yang tiada dalam variasi.

**`order_item_options`** — id, order_item_id(FK), **group_name**,
**option_label**, **price_delta**

**`dining_tables`** — id, code, name, area, capacity,
status ENUM(free/occupied/reserved), current_order_id, is_active, sort_order

### C. Bayaran (4)

**`transactions`** — id, receipt_no(UNIQUE), **business_day**(DATE),
type ENUM(sale/refund), ref_transaction_id(nullable),
terminal_id(FK), shift_id(FK), user_id(FK),
**order_type**, **table_label**, **takeaway_no** (salinan gambaran),
subtotal, tax_rate, tax, **service_charge**, **packaging_fee**,
discount, total, payment_method_id(FK),
cash_received, change_amount, status ENUM(paid/void),
void_reason, voided_at, voided_by, created_at

> `service_charge` dan `packaging_fee` disediakan sekarang dengan nilai **0**.
> Menambah lajur pada jadual yang sudah ada jutaan baris jauh lebih menyakitkan
> daripada menyediakannya awal. Kadar dalam `settings`, lalai 0 — tidak
> mengubah apa-apa sehingga Sufi menghidupkannya.

**`transaction_items`** — id, transaction_id(FK), **order_item_id**(FK, nullable),
product_id, **product_name**, **icon**, **base_price**, **unit_price**,
qty, line_total, variant_label, refunded_qty

**`transaction_item_options`** — id, item_id(FK), **group_name**,
**option_label**, **price_delta**

**`transaction_orders`** — transaction_id(FK), order_id(FK)
> Jadual penghubung untuk **gabung bil**: satu bayaran menutup beberapa
> pesanan (contoh: meja 5 dan meja 6 bayar sekali).

> Medan **tebal** dalam jadual transaksi ialah salinan gambaran (snapshot) —
> nama dan harga **disalin masuk**, bukan dirujuk melalui FK. Kalau admin padam
> pilihan "Rendang daging" tahun depan, resit tahun ini mesti kekal betul.

### D. Operasi (7)

**`terminals`** — id, code(UNIQUE), name, **type** ENUM(cashier/waiter),
receipt_prefix, is_active, last_seen_at, created_at

**`shifts`** — id, terminal_id(FK), user_id(FK), business_day,
opened_at, opening_float, closed_at, closing_cash, expected_cash,
variance, status ENUM(open/closed), note

**`stock_movements`** — id, product_id(FK),
type ENUM(sale/refund/void/restock/adjustment), qty_change, balance_after,
ref_transaction_id, ref_order_id, user_id, note, created_at

**`payment_methods`** — id, code, label, icon, needs_cash, note, is_active, sort_order

**`users`** — id, username(UNIQUE), password_hash, full_name,
role ENUM(**admin/cashier/waiter**), is_active, last_login_at, created_at

**`settings`** — setting_key(PK), setting_value, updated_at, updated_by

> Isi awal: `business_type` (retail/restaurant), `day_cutoff_time` (04:00),
> `shop_name`, `shop_address`, `tax_rate` (0.06), `service_charge_rate` (0),
> `packaging_fee` (0), `receipt_footer`, `paper_width` (58/80),
> `printer_name`, `currency_prefix` (RM)

**`activity_logs`** — id, user_id, action, entity, entity_id, detail_json, created_at

## 7. Aliran kerja setiap mod

### Kedai runcit
```
Imbas barcode / cari barang  ->  troli  ->  Bayar  ->  resit
                                   |
                            (orders dibuka & ditutup
                             serentak, tidak kelihatan)
```

### Kedai makan — dine-in
```
WAITER                          KAUNTER
  Pilih meja 5
  Tambah pesanan  ------------>  (pesanan terbuka, status: open)
  Tambah lagi     ------------>
  Tambah lagi     ------------>
                                 Juruwang pilih meja 5
                                 Gabung dengan meja 6? / Pecah bil?
                                 BAYAR  -> resit -> meja jadi free
```

### Kedai makan — take away
```
WAITER / KAUNTER                KAUNTER
  Pilih Take away
  Sistem beri No. 007  -------->  (pesanan terbuka)
  Beritahu pelanggan
                                 Pelanggan datang bayar
                                 Juruwang taip 007
                                 BAYAR  -> resit
```

## 8. Barcode — lebih mudah daripada yang disangka

Pengimbas barcode USB **berkelakuan sebagai papan kekunci**. Ia menaip digit
diikuti Enter. Tiada driver, tiada perpustakaan, tiada kebenaran browser.

Jadi kerjanya hanyalah: medan input yang sentiasa berfokus, kesan Enter, cari
`products.barcode`, masuk troli. Kalau tidak dijumpai — bunyi/toast ralat dan
kekalkan fokus.

Yang perlu diberi perhatian:

- Fokus mesti kembali ke medan imbas selepas setiap tindakan, kalau tidak
  imbasan seterusnya akan menaip ke tempat lain
- Produk yang **ada variasi** tidak boleh terus masuk troli walaupun diimbas —
  modal variasi mesti terbuka dahulu
- Barcode mesti UNIQUE; dua produk sama barcode bermakna juruwang jual barang salah

## 9. Gambar produk — rantaian jatuh balik

1. `products.image_path` ada dan fail wujud → papar gambar
2. Tiada gambar tetapi `products.icon` ada → papar emoji (kekalkan data sedia ada)
3. Kedua-dua tiada → `assets/img/product-default.png`

Muat naik (`core/Uploader.php`): JPG/PNG/WEBP sahaja disahkan dengan `finfo`
(**bukan** sambungan fail), maksimum 2MB, nama fail jadi hash rawak,
`uploads/.htaccess` halang perlaksanaan PHP.

## 10. Struktur folder

```
claude-learn1/
├── config/         database.php (.gitignore) · database.example.php · app.php
├── core/           Database.php · Auth.php · Csrf.php · Request.php
│                   Response.php · Validator.php · Uploader.php · BusinessDay.php
├── jobs/           SATU KELAS = SATU KERJA
│   ├── Auth/        LoginJob · LogoutJob
│   ├── Product/     ListProductsJob · FindByBarcodeJob · SearchProductsJob
│   │                SaveProductJob · DeleteProductJob · UploadProductImageJob
│   │                ListCategoriesJob · SaveCategoryJob
│   ├── Variation/   GetVariationsJob · SaveVariationsJob · ResetVariationsJob
│   ├── Order/       OpenOrderJob · AddOrderItemJob · UpdateOrderItemJob
│   │                CancelOrderItemJob · GetOpenOrdersJob · FindByTakeawayNoJob
│   │                CloseOrderJob · CancelOrderJob
│   ├── Table/       ListTablesJob · SaveTableJob · TableStatusJob
│   ├── Cart/        CalculateCartJob · ValidateStockJob
│   ├── Transaction/ CreateTransactionJob · MergeBillJob · SplitBillJob
│   │                ListTransactionsJob · GetReceiptJob
│   │                VoidTransactionJob · RefundTransactionJob
│   ├── Stock/       DeductStockJob · RestoreStockJob · AdjustStockJob
│   │                ListStockMovementsJob
│   ├── Shift/       OpenShiftJob · CloseShiftJob · CurrentShiftJob · ShiftReportJob
│   ├── Terminal/    ListTerminalsJob · SaveTerminalJob
│   ├── Report/      DailySalesJob · SalesByPaymentJob · SalesByOrderTypeJob
│   │                TopProductsJob · ExportCsvJob
│   ├── User/        ListUsersJob · SaveUserJob · ResetPasswordJob
│   └── Setting/     GetSettingsJob · SaveSettingsJob
├── api/            endpoint nipis, pulangkan JSON
├── cashier/        index.php · login.php · shift.php · js/
├── waiter/         index.php · login.php · tables.php · order.php · js/
│                   (mobile-first — waiter guna telefon/tablet)
├── admin/          index.php + halaman pentadbiran · partials/ · js/
├── print/          receipt.php
├── uploads/        products/ (.gitignore isinya, kekalkan .gitkeep)
├── assets/img/     product-default.png
├── css/            style.css · receipt-58mm.css · receipt-80mm.css
├── vendor/bootstrap/
└── database/       schema.sql · seed.sql
```

## 11. Keselamatan — senarai semak wajib

- [ ] Pengguna MySQL khas `pos_user`, akses ke `pos_system` sahaja (bukan `root`)
- [ ] `password_hash()` / `password_verify()`
- [ ] PDO prepared statement untuk **setiap** pertanyaan
- [ ] `session_regenerate_id(true)` selepas log masuk
- [ ] Token CSRF pada semua POST
- [ ] **Setiap endpoint bayaran menolak peranan `waiter`** — bukan sekadar sorok butang
- [ ] Semak peranan di dalam setiap endpoint admin
- [ ] Pelayan **kira semula** semua harga — jangan percaya harga dari browser
- [ ] `htmlspecialchars()` pada setiap output PHP
- [ ] `config/database.php` dalam `.gitignore`

## 12. Kalau vendor perlu dikongsi dalam satu pemasangan

Pelan ini menganggap **satu pemasangan = satu vendor**. Kalau Sufi mahu banyak
vendor dalam satu pemasangan (multi-tenant sebenar), yang berikut berubah dan
ia menyentuh **setiap** jadual:

- Jadual baharu: `vendors`, `subscriptions`, `plans`
- `vendor_id` pada setiap jadual, dan setiap pertanyaan mesti menapisnya
- Kebocoran data antara vendor jadi risiko keselamatan paling besar dalam sistem
- Nombor resit, nombor take-away, syif — semua jadi unik **per vendor**

**Ini keputusan yang perlu dibuat sebelum Fasa 1**, kerana menambah `vendor_id`
selepas data wujud bermakna migrasi setiap jadual. Cadangan saya: kekal satu
pemasangan satu vendor. Ia lebih selamat, lebih mudah difahami, dan langganan
tetap boleh dijual — cuma setiap pelanggan dapat pemasangan sendiri.

## 13. Perkara yang mudah tersilap

1. **`CreateTransactionJob` mesti guna DB transaction sebenar**
   (`beginTransaction`/`commit`/`rollBack`). Kalau stok ditolak tetapi jualan
   gagal disimpan, stok hilang tanpa jualan.
2. **Kunci stok dengan `SELECT ... FOR UPDATE`.** Kaunter dinamik + waiter
   bermakna beberapa orang boleh pesan item terakhir yang sama serentak.
3. **Nombor resit dan nombor take-away dijana dalam DB transaction yang sama**,
   bukan di PHP sebelum itu.
4. **Stok ditolak bila pesanan dibuat, bukan bila dibayar.** Kalau tunggu
   bayaran, dua meja boleh pesan ikan terakhir yang sama. Pembatalan pesanan
   mesti memulangkan stok.
5. **`business_day`, bukan `CURDATE()`.** Lihat bahagian 4.3.
6. **Pecah bil mesti kemas kini `paid_qty`** dalam DB transaction yang sama —
   kalau tidak, item sama boleh dibayar dua kali.
7. **utf8mb4 pada sambungan PDO**, bukan hanya pada jadual.
8. Selepas migrasi, sistem **wajib** ada Apache + MySQL berjalan.

## 14. Persediaan mesin pembangunan baharu

Repo ini mungkin di-clone pada mesin lain (contoh: laptop rumah Sufi). Nilai
di bawah dirakam dari mesin pejabat — **jangan andaikan ia sama**.

| Perkara | Mesin pejabat | Semak di mesin baharu |
|---|---|---|
| Laluan projek | `C:\xampp\htdocs\claude-learn1` | Guna laluan sebenar |
| PHP | 8.2.12 | `php -v` — minimum 8.0 |
| MariaDB/MySQL | 10.4.32 (XAMPP) | `mysql --version` |
| Kata laluan `root` | Tiada | Mungkin ada di mesin lain |
| DB projek lain | `tuisyen` wujud | Mungkin tiada |

Langkah pemasangan:

1. Pastikan Apache + MySQL berjalan dalam XAMPP Control Panel
2. `CREATE DATABASE pos_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
   kemudian cipta `pos_user` dengan akses ke `pos_system` sahaja
3. `mysql -u root pos_system < database/schema.sql` diikuti `seed.sql`
4. Salin `config/database.example.php` → `config/database.php`, isi kredensial
5. Pilih `business_type` dalam seed atau melalui admin
6. Buka `http://localhost/{nama-folder}/cashier/`

> `config/database.php` dalam `.gitignore` — setiap mesin ada kredensial
> sendiri. Halaman putih atau ralat sambungan? Fail itu yang pertama disemak.

## 15. Logik sedia ada yang boleh dipindah terus

Fungsi berikut dalam [../../js/data.js](../../js/data.js) ialah fungsi tulen
dan boleh disalin hampir baris demi baris ke job class PHP. **Jangan tulis
semula dari awal** — kelakuannya sudah betul dan sudah diuji pengguna:

| Fungsi JS | Destinasi PHP |
|---|---|
| `calcUnitPrice()` | `CalculateCartJob` |
| `makeLineId()` | `CalculateCartJob` |
| `buildVariantLabel()` | `CalculateCartJob` |
| `getTotals()` (js/app.js) | `CalculateCartJob` |
| `suggestCashAmounts()` | Kekal di JS — hal paparan |
| `formatRM()`, `escapeHtml()` | Kekal di JS; PHP guna `number_format` + `htmlspecialchars` |

## 16. Pemindahan data sedia ada

| Sumber | Destinasi |
|---|---|
| 18 produk dalam js/data.js | `database/seed.sql` |
| `PAYMENT_METHODS` | 3 baris dalam `payment_methods` |
| `TAX_RATE = 0.06` | Satu baris dalam `settings` |
| Kategori (Makanan/Minuman/Snek) | 3 baris dalam `categories` |
| Sejarah dalam localStorage | **Buang** — data demo sahaja |
