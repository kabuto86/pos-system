# Pelan Induk — Migrasi KedaiPOS ke MySQL + PHP Vanila

> **Dokumen rujukan tetap.** Baca fail ini SEBELUM menulis sebarang kod dalam
> mana-mana session. Keputusan di sini sudah disahkan oleh Sufi — jangan ubah
> tanpa bertanya. Untuk status semasa, lihat [PROGRES.md](PROGRES.md).

Tarikh keputusan: 24 Ogos 2026
Persekitaran: XAMPP · PHP 8.2.12 · MariaDB 10.4.32 · `C:\xampp\htdocs\claude-learn1`

---

## 1. Konvensyen projek (dari CLAUDE.md — WAJIB)

- Bahasa Melayu untuk semua teks yang dipaparkan kepada pengguna
- Bahasa Inggeris untuk nama fail, nama fungsi, nama pemboleh ubah, nama lajur DB
- Bootstrap sahaja untuk gaya — **tiada inline CSS**
- PHP vanila — **tiada struktur Laravel**, tiada Composer, tiada framework
- **Satu job class = satu kerja.** Fail dalam `api/` mesti nipis (10–15 baris):
  semak sesi → sahkan input → panggil satu job → pulangkan JSON.
  Tiada fail yang tahu segala-galanya (God Controller).

## 2. Keputusan yang disahkan Sufi

| # | Soalan | Jawapan | Kesan pada reka bentuk |
|---|---|---|---|
| 1 | Bilangan kaunter | **Dinamik** — vendor boleh tambah kaunter bila-bila | Jadual `terminals`; kunci stok jadi **wajib**; nombor resit mesti unik merentas kaunter |
| 2 | Syif kaunter | **Ya** — perlu tahu siapa jaga kaunter | Jadual `shifts`; `transactions.shift_id`; laporan tutup syif |
| 3 | Batal / refund | **Ya** | Jadual `stock_movements` wajib; refund = transaksi negatif berpaut pada asal |
| 4 | Gambar produk | **Muat naik sendiri**, ada gambar lalai jika tiada | `products.image_path`; folder `uploads/products/`; rantaian jatuh balik gambar → emoji → lalai |
| 5 | Printer | **Termal**, jenama belum pasti | Guna driver printer Windows + CSS 58mm/80mm. **Jangan** guna ESC/POS mentah buat masa ini |

### Nota penting keputusan #5 — printer termal

Hampir semua printer termal di pasaran dipasang sebagai **printer Windows biasa**
melalui driver pengeluar. Selagi begitu, `window.print()` + helaian gaya lebar
tetap sudah memadai, dan sistem ini akan serasi dengan mana-mana jenama tanpa
kod khas.

Kod ESC/POS mentah (arahan binari terus ke printer) hanya diperlukan untuk:

- Buka laci wang (cash drawer kick)
- Cetak lebih pantas tanpa dialog print

Kedua-duanya **ditangguh** sehingga Sufi tahu jenama sebenar. Reka bentuk
sekarang tidak menghalang penambahan itu kemudian.

Lebar kertas (58mm / 80mm) dan nama printer disimpan dalam jadual `settings`.

## 3. Skema pangkalan data — 14 jadual

Pangkalan data: `pos_system` · Set aksara: `utf8mb4_unicode_ci` · Enjin: `InnoDB`

> **utf8mb4 wajib** pada pangkalan data, jadual, lajur DAN sambungan PDO —
> ikon emoji akan jadi tanda soal kalau salah satu terlepas.

### A. Katalog

**`categories`** — id, name, sort_order, is_active, created_at

**`products`** — id, category_id(FK), name, icon, **image_path** (nullable),
price, stock, is_active, created_at, updated_at

**`variation_groups`** — id, product_id(FK), **code**, name,
type ENUM(single/multi), is_required, sort_order

**`variation_options`** — id, group_id(FK), **code**, label, price_delta,
sort_order, is_active

> Lajur `code` (contoh: lauk, ayam) **mesti dikekalkan**. Fungsi `makeLineId()`
> dalam js/data.js bergantung padanya untuk hasilkan kunci troli yang stabil.
> Kalau guna id nombor sahaja, kunci berubah setiap kali admin menyunting dan
> baris troli yang sepatutnya bergabung akan berpecah.

### B. Jualan

**`transactions`** — id, receipt_no(UNIQUE), **type ENUM(sale/refund)**,
**ref_transaction_id** (nullable, untuk refund), terminal_id(FK), shift_id(FK),
user_id(FK), subtotal, tax_rate, tax, discount, total, payment_method_id(FK),
cash_received, change_amount, status ENUM(paid/void),
void_reason, voided_at, voided_by, created_at

**`transaction_items`** — id, transaction_id(FK), product_id,
**product_name**, **icon**, **image_path**, **base_price**, **unit_price**,
qty, line_total, variant_label, refunded_qty

**`transaction_item_options`** — id, item_id(FK), **group_name**,
**option_label**, **price_delta**

> Medan **tebal** ialah salinan gambaran (snapshot) — nama dan harga **disalin
> masuk**, bukan dirujuk melalui FK. Sebab: kalau admin padam pilihan "Rendang
> daging" tahun depan, resit tahun ini mesti kekal betul. Ini keputusan reka
> bentuk, bukan pertindihan data yang tidak sengaja.

### Batal (void) vs Pemulangan (refund) — dua perkara berbeza

| | Void | Refund |
|---|---|---|
| Bila | Silap juruwang, syif sama, belum selesai | Pelanggan pulangkan barang, kemudian hari |
| Kesan | `transactions.status = void` | Rekod **baharu** type=refund, jumlah negatif, `ref_transaction_id` = resit asal |
| Stok | Dipulangkan penuh | Dipulangkan ikut item yang dipulangkan sahaja |
| Laporan | Dikecualikan terus | Ditolak daripada jumlah jualan |
| Kebenaran | Admin | Admin |

Refund sebagai baris negatif berasingan bermakna laporan jualan boleh sekadar
`SUM(total)` dan angka tetap betul — tiada logik khas diperlukan.

### C. Operasi

**`terminals`** — id, code(UNIQUE), name, receipt_prefix, is_active,
last_seen_at, created_at

> Kaunter didaftarkan oleh admin. Juruwang pilih kaunter semasa log masuk.
> `receipt_prefix` (contoh: K1, K2) menghalang nombor resit bertembung.
> Format nombor resit: `{prefix}-{YYYYMMDD}-{urutan}`, contoh `K1-20260824-0042`.

**`shifts`** — id, terminal_id(FK), user_id(FK), opened_at, opening_float,
closed_at, closing_cash, expected_cash, variance, status ENUM(open/closed), note

**`stock_movements`** — id, product_id(FK), type ENUM(sale/refund/void/restock/adjustment),
qty_change, balance_after, ref_transaction_id, user_id, note, created_at

**`payment_methods`** — id, code, label, icon, needs_cash, note, is_active, sort_order

**`users`** — id, username(UNIQUE), password_hash, full_name,
role ENUM(admin/cashier), is_active, last_login_at, created_at

**`settings`** — setting_key(PK), setting_value, updated_at, updated_by

> Isi awal: shop_name, shop_address, tax_rate (0.06), receipt_footer,
> paper_width (58/80), printer_name, currency_prefix (RM)

**`activity_logs`** — id, user_id, action, entity, entity_id, detail_json, created_at

## 4. Struktur folder

```
claude-learn1/
├── config/         database.php (.gitignore) · database.example.php · app.php
├── core/           Database.php · Auth.php · Csrf.php · Request.php
│                   Response.php · Validator.php · Uploader.php
├── jobs/           SATU KELAS = SATU KERJA
│   ├── Auth/        LoginJob · LogoutJob
│   ├── Product/     ListProductsJob · SaveProductJob · DeleteProductJob
│   │                UploadProductImageJob · ListCategoriesJob · SaveCategoryJob
│   ├── Variation/   GetVariationsJob · SaveVariationsJob · ResetVariationsJob
│   ├── Cart/        CalculateCartJob · ValidateStockJob
│   ├── Transaction/ CreateTransactionJob · ListTransactionsJob · GetReceiptJob
│   │                VoidTransactionJob · RefundTransactionJob
│   ├── Stock/       DeductStockJob · RestoreStockJob · AdjustStockJob
│   │                ListStockMovementsJob
│   ├── Shift/       OpenShiftJob · CloseShiftJob · CurrentShiftJob · ShiftReportJob
│   ├── Terminal/    ListTerminalsJob · SaveTerminalJob · RegisterTerminalJob
│   ├── Report/      DailySalesJob · SalesByPaymentJob · TopProductsJob · ExportCsvJob
│   ├── User/        ListUsersJob · SaveUserJob · ResetPasswordJob
│   └── Setting/     GetSettingsJob · SaveSettingsJob
├── api/            endpoint nipis, pulangkan JSON
├── cashier/        index.php · login.php · shift.php · js/
├── admin/          index.php + 11 halaman · partials/ · js/
├── uploads/        products/ (isinya di-.gitignore, kekalkan .gitkeep)
├── assets/img/     product-default.png (dikomit)
├── css/            style.css · receipt-58mm.css · receipt-80mm.css
├── vendor/bootstrap/
└── database/       schema.sql · seed.sql
```

## 5. Gambar produk — rantaian jatuh balik

Susunan paparan pada kad produk dan resit:

1. `products.image_path` ada dan fail wujud → papar gambar
2. Tiada gambar tetapi `products.icon` ada → papar emoji (kekalkan data sedia ada)
3. Kedua-dua tiada → papar `assets/img/product-default.png`

Peraturan muat naik (`core/Uploader.php`):

- Terima JPG, PNG, WEBP sahaja — sahkan dengan `finfo`, **bukan** sambungan fail
- Maksimum 2MB
- Nama fail ditukar kepada hash rawak — jangan guna nama asal
- `uploads/.htaccess` mesti halang perlaksanaan PHP dalam folder itu

## 6. Keselamatan — senarai semak wajib

- [ ] Pengguna MySQL khas `pos_user` dengan akses ke `pos_system` sahaja
      (JANGAN guna `root`; pangkalan data `tuisyen` milik projek lain Sufi
      mesti kekal terlindung)
- [ ] `password_hash()` / `password_verify()` — tiada kata laluan mentah
- [ ] PDO prepared statement untuk **setiap** pertanyaan
- [ ] `session_regenerate_id(true)` selepas log masuk
- [ ] Token CSRF pada semua POST
- [ ] Semak peranan **di dalam** setiap endpoint, bukan sekadar sorok butang
- [ ] Pelayan **kira semula** semua harga — jangan percaya harga dari browser
- [ ] `htmlspecialchars()` pada setiap output PHP
- [ ] `config/database.php` dalam `.gitignore`

## 7. Perkara yang mudah tersilap

1. **`CreateTransactionJob` mesti guna DB transaction sebenar**
   (`beginTransaction` / `commit` / `rollBack`). Kalau stok ditolak tetapi
   simpan jualan gagal, stok hilang tanpa jualan.
2. **Kunci stok dengan `SELECT ... FOR UPDATE`.** Kaunter dinamik bermakna dua
   juruwang boleh jual item terakhir yang sama pada saat yang sama.
3. **Nombor resit dijana dalam DB transaction yang sama**, bukan di PHP sebelum
   itu — kalau tidak dua kaunter boleh dapat nombor sama.
4. **utf8mb4 pada sambungan PDO**, bukan hanya pada jadual.
5. **Jangan sentuh pangkalan data `tuisyen`.**
6. Selepas migrasi, sistem **wajib** ada Apache + MySQL berjalan. Tidak boleh
   lagi buka `index.html` terus dari fail.

## 8. Pemindahan data sedia ada

| Sumber | Destinasi |
|---|---|
| 18 produk dalam js/data.js | `database/seed.sql` (jana automatik daripada fail sedia ada) |
| `PAYMENT_METHODS` | 3 baris dalam `payment_methods` |
| `TAX_RATE = 0.06` | Satu baris dalam `settings` |
| Sejarah dalam localStorage | **Buang** — data demo sahaja |
| Kategori (Makanan/Minuman/Snek) | 3 baris dalam `categories` |

## 9. Logik sedia ada yang boleh dipindah terus

Fungsi berikut dalam [../../js/data.js](../../js/data.js) ialah fungsi tulen dan
boleh disalin hampir baris demi baris ke job class PHP. **Jangan tulis semula
dari awal** — kelakuannya sudah betul dan sudah diuji pengguna:

| Fungsi JS | Destinasi PHP |
|---|---|
| `calcUnitPrice()` | `CalculateCartJob` |
| `makeLineId()` | `CalculateCartJob` |
| `buildVariantLabel()` | `CalculateCartJob` |
| `getTotals()` (js/app.js) | `CalculateCartJob` |
| `suggestCashAmounts()` | Kekal di JS sahaja — hal paparan |
| `formatRM()`, `escapeHtml()` | Kekal di JS; PHP guna `number_format` + `htmlspecialchars` |
