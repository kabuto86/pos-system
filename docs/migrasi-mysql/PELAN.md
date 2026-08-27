# Pelan Induk — KedaiPOS SaaS: MySQL + PHP Vanila

> **Dokumen rujukan tetap.** Baca fail ini SEBELUM menulis sebarang kod dalam
> mana-mana session. Keputusan di sini sudah disahkan oleh Sufi — jangan ubah
> tanpa bertanya. Untuk status semasa, lihat [PROGRES.md](PROGRES.md).

Kemas kini terakhir: 27 Ogos 2026 (kedai berbilang, PIN kakitangan, bil langganan)
Persekitaran rujukan: XAMPP · PHP 8.2.12 · MariaDB 10.4.32

---

## 1. Apa sistem ini sebenarnya

**Satu SaaS.** Satu kod, satu pangkalan data, banyak vendor.

### 1.1 Tiga lapisan — vendor bukan kedai

```
vendor  (syarikat yang melanggan)     <- bayar langganan, pemilik akaun
  └── outlet  (kedai / cawangan)      <- stok, kaunter, syif, jualan, meja
        └── users  (kakitangan)       <- juruwang, waiter
```

Satu vendor boleh memiliki **beberapa kedai**. Tauke log masuk sekali dan
melihat semua kedainya, termasuk laporan gabungan.

> **Pembetulan model, 27 Ogos 2026.** Versi awal pelan ini menganggap satu
> vendor = satu kedai. Itu salah: tauke dengan 3 kedai terpaksa membuat 3
> langganan berasingan dengan 3 e-mel berbeza, dan tidak boleh melihat
> laporan gabungan. Lapisan `outlets` membetulkannya.

Setiap vendor memilih **jenis perniagaan**, dan pilihan itu menentukan aliran
kerja semua kedainya:

| | **Kedai Runcit** (`retail`) | **Kedai Makan** (`restaurant`) |
|---|---|---|
| Ambil pesanan | Di kaunter sahaja | Oleh **waiter** atau di kaunter |
| Jenis pesanan | Tiada | **Dine-in** atau **Take away** |
| Pengenalan pesanan | Tiada | Dine-in → **nombor meja**<br>Take away → **nombor take-away** |
| Bila bayar | Terus di kaunter | Bila pelanggan nak balik |
| Tambah pesanan | Tidak | Ya, sepanjang pelanggan makan |
| Bil | Satu | Boleh **gabung** dan **pecah** |
| Khusus | **Imbas barcode**, carian barang | Peranan waiter, susun atur meja |

Jenis perniagaan disimpan dalam `vendors.business_type`. Ciri yang tidak
berkenaan **disembunyikan sepenuhnya**.

## 2. Konvensyen projek (dari CLAUDE.md — WAJIB)

- Bahasa Melayu untuk semua teks yang dipaparkan kepada pengguna
- Bahasa Inggeris untuk nama fail, nama fungsi, nama pemboleh ubah, nama lajur DB
- Bootstrap sahaja untuk gaya — **tiada inline CSS**
- PHP vanila — **tiada struktur Laravel**, tiada Composer, tiada framework
- **Satu job class = satu kerja.** Fail dalam `api/` mesti nipis (10–15 baris):
  semak sesi → sahkan input → panggil satu job → pulangkan JSON

## 3. ⚠ Peraturan multi-tenant — baca sebelum apa-apa lagi

Ini bahagian paling penting dalam keseluruhan dokumen. Satu pertanyaan tanpa
tapisan vendor bermakna satu vendor boleh membaca jualan vendor lain.

### 3.1 `vendor_id` datang dari SESI, tidak pernah dari permintaan

```
BETUL  : $vendorId = Auth::vendorId();          // dari sesi
SALAH  : $vendorId = $_POST['vendor_id'];       // pengguna boleh tukar
SALAH  : $vendorId = $_GET['vendor'];
```

Kalau mana-mana endpoint menerima `vendor_id` daripada browser, vendor A boleh
tukar satu nombor dan membaca segala-galanya milik vendor B. Tiada
pengecualian, termasuk untuk "kemudahan ujian".

### 3.2 Setiap job menerima `vendor_id` melalui constructor

Job **tidak** membaca sesi sendiri dan **tidak** menerima id daripada input.
Ia diberikan oleh pemanggil, yang mengambilnya dari `Auth`. Ini menjadikan
job boleh diuji, dan menjadikan kebocoran mudah dilihat semasa membaca kod.

### 3.3 Tiada SQL mentah dalam `api/`

Semua pertanyaan berada dalam job class. Fail `api/` hanya memanggil job.
Kalau SQL bertaburan dalam endpoint, mustahil untuk mengaudit tapisan vendor.

### 3.4 Seed mesti ada DUA vendor sejak Fasa 1

Kalau hanya satu vendor wujud semasa membina, kebocoran **mustahil dikesan** —
semua data memang milik vendor itu. Dengan dua vendor sejak hari pertama,
`WHERE vendor_id` yang tertinggal akan terserlah serta-merta.

Seed: `KEDAI01` (kedai runcit) dan `KEDAI02` (kedai makan) — dua jenis
perniagaan sekali gus, jadi kedua-dua mod boleh diuji bila-bila masa.

### 3.5 Setiap kekangan UNIQUE jadi unik PER VENDOR

Ini paling mudah terlepas pandang. Dua vendor berbeza mesti boleh mempunyai
produk dengan barcode yang sama, meja bernama `A1`, dan resit nombor 0001.

Sesetengahnya unik **per vendor** (data katalog yang dikongsi antara kedai),
sesetengahnya **per outlet** (data operasi kedai). Perhatikan bezanya:

| Dulu | Sekarang |
|---|---|
| `products.barcode` UNIQUE | UNIQUE(`vendor_id`, `barcode`) |
| `outlets.code` | UNIQUE(`vendor_id`, `code`) |
| `transactions.receipt_no` UNIQUE | UNIQUE(`outlet_id`, `receipt_no`) |
| `terminals.code` UNIQUE | UNIQUE(`outlet_id`, `code`) |
| `dining_tables.code` UNIQUE | UNIQUE(`outlet_id`, `code`) |
| `settings.setting_key` PK | PK(`vendor_id`, `outlet_id`, `setting_key`) |
| `orders.takeaway_no` | UNIQUE(`outlet_id`, `business_day`, `takeaway_no`) |

> **Pengecualian tunggal: `users.email` unik SECARA GLOBAL**, bukan per vendor.
> Sebabnya e-mel itulah yang mengenal pasti pengguna sebelum sistem tahu
> vendor mana. Lihat bahagian 4.

### 3.6 Setiap indeks bermula dengan `vendor_id`

`INDEX (vendor_id, business_day)`, bukan `INDEX (business_day)`. Semua
pertanyaan menapis vendor dahulu, jadi indeks mesti mengikut susunan itu.
Kalau tidak, prestasi merudum apabila vendor bertambah.

### 3.7 Muat naik diasingkan mengikut vendor

`uploads/products/{vendor_id}/{hash}.jpg` — bukan satu folder berkongsi.

### 3.8 `vendor_id` ialah keselamatan · `outlet_id` ialah perniagaan

Dua dimensi berbeza dengan peraturan berbeza. **Jangan campurkan.**

```
WHERE vendor_id = ?    <- sempadan KESELAMATAN
                          dari sesi sahaja, tidak pernah dari input
  AND outlet_id = ?    <- skop PERNIAGAAN
                          boleh dari input, TETAPI mesti disahkan
                          bahawa outlet itu milik vendor semasa
```

Kenapa `vendor_id` kekal pada **setiap** jadual walaupun `outlet_id` sudah
menunjuk kepada kedai: supaya peraturan audit kekal satu baris mudah —
*"setiap pertanyaan menapis vendor_id"*. Kalau keselamatan bergantung pada
`outlet_id` sahaja, setiap semakan perlu menyusuri `outlets` untuk tahu
vendor mana, dan satu penyusuran yang terlepas menjadi kebocoran.

`ValidateOutletJob` mengesahkan `outlet_id` milik vendor semasa. Setiap
endpoint yang menerima `outlet_id` mesti memanggilnya.

## 4. Log masuk & keselamatan kata laluan

**Dua laluan log masuk yang berbeza**, kerana dua jenis pengguna mempunyai
keperluan yang bertentangan.

### 4.1 Kenapa dua laluan

Waiter kedai makan selalunya pekerja sambilan, kerap bertukar, berkongsi
tablet, dan log masuk **20–30 kali sehari**. Menaip
`ahmad.bin.ali@gmail.com` + kata laluan setiap kali ialah seksaan — dan
kesannya bukan sekadar menyusahkan: kakitangan akan mula berkongsi satu
akaun supaya tidak perlu log masuk semula, dan sistem hilang keupayaan
mengetahui siapa membuat apa.

Sebab itu POS sebenar memisahkan **akaun** daripada **kakitangan**:

| Lapisan | Siapa | Cara |
|---|---|---|
| **Akaun** | superadmin, tauke, admin | E-mel + kata laluan |
| **Peranti** | Kaunter / tablet | Didaftarkan **sekali** ke satu kedai |
| **Kakitangan** | Juruwang, waiter | Tekan **nama + PIN** pada peranti berdaftar |

```
E-mel       : ali@kedaimakcik.com        [tauke / admin sahaja]
Kata Laluan : ••••••••
              -> pilih kedai (kalau lebih daripada satu)

------------------------------------------------------

Peranti "Kaunter 1" sudah berdaftar ke Kedai Ampang
  [ Ahmad ]  [ Siti ]  [ Kumar ]        <- tekan nama
  PIN: • • • •                          <- 4-6 digit
```

Satu e-mel tauke memberi capaian ke **semua** kedainya. Tiada lagi tiga
e-mel untuk tiga kedai.

### 4.2 Kenapa PIN cukup selamat di sini

PIN 4 digit sahaja memang lemah — 10,000 kombinasi. Tetapi konteksnya
berbeza sepenuhnya daripada kata laluan internet:

- Ia **hanya berfungsi pada peranti yang sudah didaftarkan** ke kedai itu.
  Bukan capaian jarak jauh — penyerang perlu berdiri dalam kedai
- Dihadkan 3 cubaan, kemudian PIN dikunci sehingga admin membukanya
- Kakitangan **tekan nama dahulu**, kemudian PIN. Tiada penomboran, dan
  tiada bocor siapa mempunyai akaun
- PIN tetap di-hash seperti kata laluan, tidak pernah disimpan mentah
- PIN unik dalam satu kedai, jadi tidak boleh disalah anggap milik orang lain

Akibatnya **waiter tidak perlukan e-mel langsung.** `users.email` menjadi
nullable — wajib untuk `superadmin` dan `admin`, kosong untuk kakitangan
yang hanya menggunakan PIN.

> Kerana `email` nullable, `UNIQUE(email)` masih betul: MySQL membenarkan
> berbilang NULL dalam indeks UNIQUE.

### 4.3 Pendaftaran peranti

Peranti didaftarkan sekali oleh admin: log masuk dengan e-mel, pilih kedai,
namakan peranti. Sistem menyimpan token peranti dalam cookie jangka panjang
dan mengikat `terminal_id` kepadanya.

Selepas itu peranti sentiasa "berada" di kedai tersebut sehingga admin
membatalkan pendaftarannya. Skrin PIN sahaja yang dipaparkan.

- Admin boleh membatalkan mana-mana peranti dari jauh — penting apabila
  tablet hilang atau pekerja berhenti
- Token peranti **tidak** memberi capaian data dengan sendirinya; ia hanya
  menentukan kedai mana dan membenarkan skrin PIN

### 4.4 Hashing kata laluan & PIN — Argon2id

Diukur pada mesin Sufi, 27 Ogos 2026:

| Algoritma | Hash | Verify |
|---|---|---|
| bcrypt cost 10 | 146 ms | 156 ms |
| bcrypt cost 12 | 633 ms | 606 ms |
| argon2id lalai PHP (64MB, t=4) | 801 ms | 782 ms |
| **argon2id 19MB, t=2, p=1** | **123 ms** | **115 ms** |

**Guna Argon2id dengan parameter OWASP:**

```php
password_hash($password, PASSWORD_ARGON2ID, [
    'memory_cost' => 19456,   // 19 MiB
    'time_cost'   => 2,
    'threads'     => 1,
]);
```

Ia lebih kuat daripada bcrypt **dan** lebih laju daripada bcrypt cost 10.
Lalai PHP untuk argon2id (64MB, t=4) terlalu perlahan pada 801ms — jangan
guna lalai, tetapkan parameter secara eksplisit.

**PIN juga di-hash dengan Argon2id yang sama.** Jangan sekali-kali simpan
PIN sebagai teks biasa atau MD5 — ia kata laluan, cuma pendek.

`users.password_hash` mesti **VARCHAR(255)** — argon2id menghasilkan 97
aksara, bcrypt 60. 255 memberi ruang untuk algoritma masa depan.

> Setiap log masuk berjaya menggunakan ~19MB memori seketika. Untuk beratus
> vendor ini masih selamat kerana log masuk jarang berbanding muat halaman,
> tetapi ia sebab lain kenapa lalai 64MB tidak diguna.

### 4.5 Peraturan log masuk yang lain

- **`password_needs_rehash()` pada setiap log masuk berjaya.** Kalau parameter
  ditingkatkan kemudian, kata laluan lama dinaik taraf secara senyap tanpa
  pengguna perlu tukar apa-apa.
- **Mesej ralat yang sama** untuk e-mel tidak wujud dan kata laluan salah:
  *"E-mel atau kata laluan tidak sah"*. Membezakannya memberitahu penyerang
  e-mel mana yang berdaftar.
- **Hadkan cubaan.** Selepas 5 kali gagal, akaun dikunci 15 minit
  (`users.failed_attempts`, `users.locked_until`). Setiap cubaan direkod
  dalam `login_attempts` bersama IP — untuk audit dan pengesanan serangan.
- **`session_regenerate_id(true)`** selepas log masuk berjaya.
- **Semak status langganan selepas pengesahan**, bukan sebelum — kalau tidak,
  penyerang boleh mengenal pasti vendor yang wujud.
- Set semula kata laluan melalui e-mel **ditangguhkan** (perlukan SMTP).
  Buat masa ini admin vendor menetapkan semula untuk kakitangannya, dan
  superadmin untuk admin vendor.

> **Nota praktikal.** Waiter menaip e-mel penuh berpuluh kali sehari pada
> tablet berkongsi memang menyusahkan. Penyelesaian lazim POS ialah PIN
> pendek selepas log masuk pertama pada peranti itu. Tidak dibina sekarang —
> dicatat dalam "Perkara tertangguh" supaya ia tidak hilang.

## 5. Peranan pengguna

| Peranan | `vendor_id` | Boleh | Tidak boleh |
|---|---|---|---|
| `superadmin` | **NULL** | Urus vendor, pelan, langganan merentas platform | Masuk POS mana-mana vendor |
| `admin` | Ada | Semua dalam vendornya | Melihat vendor lain |
| `cashier` | Ada | POS, bayaran, syif, sejarah syif sendiri | Katalog, laporan penuh, tetapan |
| `waiter` | Ada | Buka meja, ambil & tambah pesanan | **Bayaran, tutup bil, void, refund, laporan** |

> `superadmin` ialah pemilik platform (Sufi). `vendor_id` NULL menjadikannya
> jelas dalam kod bahawa akaun ini tiada kedai — dan menjadikan mana-mana
> pertanyaan POS gagal dengan serta-merta jika tersilap digunakan.

> Sekatan waiter **mesti disemak di dalam setiap endpoint**. Menyorok butang
> di UI bukan kawalan keselamatan.

## 6. Skema pangkalan data — 34 jadual

Pangkalan data: `pos_saas` · `utf8mb4_unicode_ci` · InnoDB

> **utf8mb4 wajib** pada pangkalan data, jadual, lajur DAN sambungan PDO.
> **Setiap jadual perniagaan mempunyai `vendor_id`** kecuali yang ditanda.

### A. Platform & Langganan (9)

**`languages`** — code(PK, cth. `ms`, `en`), name, native_name,
is_active, is_default, sort_order

**`translations`** — language_code(FK), translation_key, value
· PK(language_code, translation_key)

> Terjemahan adalah **peringkat platform**, diurus superadmin. Vendor tidak
> menulis terjemahan sendiri — mereka hanya memilih bahasa yang tersedia.
> Lihat 7.9.

**`vendors`** — id, code(UNIQUE), name, business_type ENUM(retail/restaurant),
status ENUM(trial/active/suspended/cancelled), phone, address,
created_at, updated_at

**`outlets`** — id, **vendor_id**(FK), code, name, address, phone,
is_active, opened_at, closed_at, created_at
· UNIQUE(vendor_id, code)

> Kedai / cawangan. Stok, kaunter, syif, pesanan dan jualan semuanya milik
> outlet, bukan vendor. Lihat 1.1.

**`plans`** — id, code, name, **base_price**, **price_per_outlet**,
max_outlets, max_terminals_per_outlet, max_users, max_products,
features_json, is_active

**`plan_outlet_tiers`** — id, plan_id(FK), from_outlet, to_outlet,
unit_price · lihat 9.2

**`subscriptions`** — id, vendor_id(FK), plan_id(FK),
status ENUM(trial/active/past_due/cancelled),
started_at, trial_ends_at, current_period_end, cancelled_at, note

**`invoices`** — id, **vendor_id**(FK), invoice_no(UNIQUE),
period_start, period_end, subtotal, tax, total,
status ENUM(draft/issued/paid/void), issued_at, due_at, paid_at, note

**`invoice_lines`** — id, invoice_id(FK), description,
outlet_id (nullable), qty, unit_price, amount, is_prorated

> `outlet_id` nullable kerana sesetengah baris ialah yuran asas, bukan
> caj kedai tertentu.

**`languages`** dan **`translations`** — lihat di bawah.

### B. Katalog (5)

**`categories`** — id, **vendor_id**, name, sort_order, is_active, created_at

**`products`** — id, **vendor_id**, category_id(FK), name, icon, image_path,
barcode, sku, **price** (lalai), **cost_price**, **unit**,
**is_tax_exempt**, is_active, sort_order, created_at, updated_at
· UNIQUE(vendor_id, barcode)

**`product_outlets`** — **vendor_id**, **outlet_id**(FK), product_id(FK),
**price_override** (nullable), **stock**, **min_stock**, is_available
· PK(outlet_id, product_id)

> **Diputuskan Sufi, 27 Ogos 2026: produk di peringkat vendor, harga & stok
> boleh ditindih per kedai.**
>
> Katalog dikongsi — tauke menambah "Nasi Lemak" **sekali** dan ia muncul di
> semua kedai. Tetapi:
>
> - **Stok sentiasa per kedai.** Stok Ampang bukan stok Kajang. Sebab itu
>   `stock` berpindah dari `products` ke `product_outlets` — satu lajur stok
>   pada produk tiada makna apabila vendor ada tiga kedai.
> - **Harga boleh ditindih.** `price_override` NULL bermakna guna
>   `products.price`. Kedai dalam bandar boleh caj lebih tinggi tanpa
>   memecahkan katalog.
> - **`is_available`** — kedai boleh mematikan satu produk tanpa membuangnya
>   dari katalog vendor.
>
> Model ini menampung kedua-dua kes: rangkaian restoran yang mahu menu
> seragam, dan kedai runcit berbeza lokasi yang mahu harga berbeza.

> `cost_price` — tanpanya laporan hanya boleh beritahu berapa **jualan**,
> bukan berapa **untung**. Untuk kedai runcit bermargin nipis, untung ialah
> angka yang paling dicari.
> `min_stock` — ambang amaran "stok rendah", **per kedai** kerana setiap
> kedai ada kadar jualan berbeza.
> `unit` — kg / pcs / botol / bungkus. "Gula 1" tanpa unit tidak bermakna
> untuk kedai runcit.
> `is_tax_exempt` — sesetengah barang tidak dikenakan cukai.

**`variation_groups`** — id, **vendor_id**, product_id(FK), **code**, name,
type ENUM(single/multi), is_required, sort_order

**`variation_options`** — id, **vendor_id**, group_id(FK), **code**, label,
price_delta, sort_order, is_active

> Lajur `code` (contoh: lauk, ayam) **mesti dikekalkan**. `makeLineId()`
> bergantung padanya untuk kunci troli yang stabil.

### C. Pesanan (4) — teras mod kedai makan

**`orders`** — id, **vendor_id**, **outlet_id**(FK), order_no, **business_day**(DATE),
**order_type** ENUM(dine_in/takeaway/counter),
table_id(FK, nullable), **takeaway_no**(nullable),
status ENUM(open/billed/paid/cancelled), guest_count,
opened_by(FK users), terminal_id(FK, nullable), note, opened_at, closed_at
· UNIQUE(outlet_id, business_day, takeaway_no)

> `order_type = counter` digunakan oleh mod kedai runcit — pesanan yang
> dibuka dan dibayar serentak. `takeaway_no` dipapar 3 digit (001, 002…);
> juruwang taip nombor ini untuk memanggil pesanan.

**`order_items`** — id, **vendor_id**, order_id(FK), product_id,
**product_name**, **icon**, **base_price**, **unit_price**, variant_label,
qty, **paid_qty**, line_total, status ENUM(ordered/served/cancelled),
note, added_by(FK users), added_at

> `paid_qty` yang membolehkan pecah bil: satu baris pesanan boleh dibayar
> separa oleh beberapa orang. Pesanan hanya `paid` bila setiap baris
> mempunyai `paid_qty = qty`.
> `note` untuk permintaan bebas ("kurang pedas") yang tiada dalam variasi.

**`order_item_options`** — id, **vendor_id**, order_item_id(FK),
**group_name**, **option_label**, **price_delta**

**`dining_tables`** — id, **vendor_id**, **outlet_id**(FK), code, name, area, capacity,
status ENUM(free/occupied/reserved), current_order_id, is_active, sort_order

### D. Bayaran (4)

**`transactions`** — id, **vendor_id**, **outlet_id**(FK), receipt_no, **business_day**(DATE),
type ENUM(sale/refund), ref_transaction_id(nullable),
terminal_id(FK), shift_id(FK), user_id(FK),
**order_type**, **table_label**, **takeaway_no** (salinan gambaran),
subtotal, tax_rate, tax, **service_charge**, **packaging_fee**,
**promo_discount**, **manual_discount**, discount,
**discount_tax_mode** ENUM(before_tax/after_tax),
total, payment_method_id(FK),
cash_received, change_amount, status ENUM(paid/void),
void_reason, voided_at, voided_by, created_at
· UNIQUE(outlet_id, receipt_no)

> `service_charge` dan `packaging_fee` disediakan sekarang dengan nilai **0**.
> Menambah lajur pada jadual yang sudah ada jutaan baris — merentas semua
> vendor — jauh lebih menyakitkan daripada menyediakannya awal.

**`transaction_items`** — id, **vendor_id**, transaction_id(FK),
order_item_id(FK, nullable), product_id,
**product_name**, **icon**, **base_price**, **unit_price**,
**promotion_id**, **promotion_name**, **discount_amount**,
qty, line_total, variant_label, refunded_qty

**`transaction_item_options`** — id, **vendor_id**, item_id(FK),
**group_name**, **option_label**, **price_delta**

**`transaction_orders`** — **vendor_id**, transaction_id(FK), order_id(FK)
> Jadual penghubung untuk **gabung bil**: satu bayaran menutup beberapa
> pesanan (contoh: meja 5 dan meja 6 bayar sekali).

> Medan **tebal** ialah salinan gambaran (snapshot) — nama dan harga
> **disalin masuk**, bukan dirujuk melalui FK. Kalau admin padam pilihan
> "Rendang daging" tahun depan, resit tahun ini mesti kekal betul.

### E. Promosi (4)

**`promotions`** — id, **vendor_id**, name, code (nullable, untuk kupon),
`type` ENUM(product_price/product_percent/category_percent/
bill_percent/bill_fixed/buy_x_get_y),
value, buy_qty, get_qty, get_product_id,
**starts_on**, **ends_on** (DATE — ikut `business_day`),
**time_start**, **time_end** (TIME, nullable — happy hour),
**days_of_week** (mask 7 aksara, cth. `1111100` = Isnin–Jumaat),
min_qty, min_spend, max_uses, used_count, max_uses_per_transaction,
**priority**, **is_stackable**, is_active, created_by, created_at

**`promotion_products`** — **vendor_id**, promotion_id(FK), product_id(FK)

**`promotion_categories`** — **vendor_id**, promotion_id(FK), category_id(FK)

**`transaction_promotions`** — **vendor_id**, transaction_id(FK),
promotion_id, **promotion_name**, **promotion_type**, discount_amount

> Nama dan jenis promosi **disalin masuk** ke transaksi. Kalau vendor menyunting
> atau memadam promosi bulan depan, resit bulan ini mesti kekal menunjukkan
> diskaun yang sebenarnya dikenakan. Prinsip yang sama seperti nama produk.

### F. Operasi (8)

**`terminals`** — id, **vendor_id**, **outlet_id**(FK), code, name,
**type** ENUM(cashier/waiter), receipt_prefix, is_active, last_seen_at
· UNIQUE(outlet_id, code)

**`shifts`** — id, **vendor_id**, **outlet_id**(FK), terminal_id(FK), user_id(FK), business_day,
opened_at, opening_float, closed_at, closing_cash, expected_cash,
variance, status ENUM(open/closed), note

**`stock_movements`** — id, **vendor_id**, **outlet_id**(FK), product_id(FK),
type ENUM(sale/refund/void/restock/adjustment), qty_change, balance_after,
ref_transaction_id, ref_order_id, user_id, note, created_at

**`payment_methods`** — id, **vendor_id**, code, label, icon, needs_cash,
note, is_active, sort_order

**`users`** — id, **vendor_id (NULL untuk superadmin)**, **email**,
**password_hash VARCHAR(255)** (nullable), **pin_hash** (nullable), full_name,
role ENUM(superadmin/admin/cashier/waiter), **outlet_id** (nullable),
**language** (nullable),
is_active, **failed_attempts**, **locked_until**, last_login_at, created_at
· **UNIQUE(email) — global, bukan per vendor** (lihat 3.5 dan 4)

**`login_attempts`** — id, email, ip_address, user_agent, success,
attempted_at · INDEX(email, attempted_at), INDEX(ip_address, attempted_at)

> Tiada `vendor_id` — semasa cubaan log masuk, sistem belum tahu vendor mana.
> Berguna untuk audit dan mengesan serangan meneka kata laluan.

**`settings`** — **vendor_id**, **outlet_id (NULL = lalai vendor)**,
setting_key, setting_value, updated_at,
updated_by · PK(vendor_id, outlet_id, setting_key)

> `outlet_id` NULL bermakna nilai lalai untuk seluruh vendor. Baris dengan
> `outlet_id` ditetapkan menindihnya untuk kedai itu — corak yang sama
> seperti `product_outlets.price_override`. Nama kedai, alamat dan printer
> semestinya per kedai; kadar cukai biasanya lalai vendor.

> Isi awal setiap vendor: `day_cutoff_time` (04:00), `shop_name`,
> `shop_address`, `tax_rate` (0.06), `service_charge_rate` (0),
> `packaging_fee` (0), `receipt_footer`, `paper_width` (58/80),
> `printer_name`, `currency_prefix` (RM),
> **`discount_tax_mode`** (`after_tax` — kekalkan kelakuan sekarang),
> **`manual_discount_max_percent`** (0 = tiada had),
> **`manual_discount_needs_approval`** (0), **`default_language`** (ms)
>
> `business_type` **tiada di sini** — ia dalam `vendors`, kerana ia menentukan
> ciri yang dilanggan, bukan pilihan yang boleh ditukar sesuka hati.

**`activity_logs`** — id, **vendor_id**, user_id, action, entity, entity_id,
detail_json, created_at

## 7. Keputusan seni bina

### 7.1 Semua jualan lalui `orders` — termasuk kedai runcit

Di kedai runcit, pesanan dibuka dan dibayar dalam satu klik; juruwang tidak
nampak pun kewujudannya.

**Sebab:** kalau runcit menulis terus ke `transactions` sementara kedai makan
melalui `orders`, `CreateTransactionJob` perlu ditulis dua kali dan kod POS
kaunter perlu ditulis semula apabila mod kedai makan dibina.

### 7.2 `orders` dan `transactions` adalah dua benda berbeza

| `orders` | `transactions` |
|---|---|
| Apa yang **dipesan** | Apa yang **dibayar** |
| Boleh berubah sepanjang makan | Kekal selamanya |
| Gabung bil: **banyak** order → satu transaction | Pecah bil: satu order → **banyak** transaction |

### 7.3 Hari perniagaan bukan tarikh kalendar

Kedai makan tutup pukul 2 pagi. Nombor take-away `001` yang dikeluarkan pukul
1 pagi masih milik hari semalam.

`business_day` dikira dari `settings.day_cutoff_time` (lalai `04:00`),
**bukan** `CURDATE()`. Terlepas perkara ini, nombor take-away akan bertembung
setiap malam dan laporan harian akan silap.

> Setiap vendor mempunyai `day_cutoff_time` sendiri — kedai mamak dan kedai
> runcit tidak tutup pada waktu yang sama.

### 7.4 Promosi dinilai di pelayan, dalam `CalculateCartJob`

Lubang penilaian promosi mesti wujud dalam `CalculateCartJob` **sejak Fasa 3**,
walaupun UI promosi belum dibina sehingga Fasa 10.

**Sebab:** kalau enjin promosi ditampal kemudian, `CalculateCartJob` — fungsi
yang mengira setiap sen dalam sistem ini — perlu ditulis semula, sedangkan ia
sudah diuji dan sudah digunakan oleh pesanan, gabung bil dan pecah bil.
Alasan yang sama seperti keputusan 7.1.

Harga promosi **tidak pernah** dikira di browser. Browser boleh memaparkannya
untuk kepantasan, tetapi angka yang disimpan sentiasa datang dari pelayan.

### 7.5 Susunan pengiraan — dan apa yang boleh dikonfigur

```
1. Harga unit      = harga asas + price_delta variasi
2. Promosi ITEM    -> kurangkan harga item
                      (product_price, product_percent,
                       category_percent, buy_x_get_y)
3. Subjumlah       = jumlah semua item selepas promosi item
4. Diskaun BIL     = promosi bil (bill_percent, bill_fixed)
                     + diskaun manual juruwang
5. Cukai           -> bergantung pada discount_tax_mode
6. Caj perkhidmatan / caj bungkus
7. Jumlah
```

**`discount_tax_mode` — tetapan setiap vendor:**

| Mod | Kiraan cukai | Kesan |
|---|---|---|
| `after_tax` (lalai) | `cukai = subjumlah × kadar`, diskaun bil ditolak selepas | Cukai kekal penuh. **Kelakuan sistem sekarang** |
| `before_tax` | `cukai = (subjumlah − diskaun bil) × kadar` | Cukai turun mengikut diskaun |

> **Nuansa penting yang mudah disalah faham.** Tetapan ini mengawal **diskaun
> peringkat bil sahaja**. Promosi peringkat **item** sentiasa menjejaskan cukai
> dalam kedua-dua mod — bukan kerana tetapan, tetapi kerana ia benar-benar
> mengubah harga jualan barang itu. Kalau Nasi Lemak dijual RM3.90 dan bukan
> RM4.50, jumlah bercukai memang RM3.90. Tiada tetapan boleh mengubah hakikat
> itu tanpa menjadikan cukai salah kira.

`transactions.discount_tax_mode` **disimpan pada setiap transaksi**. Vendor
boleh menukar tetapan pada bila-bila masa, dan resit lama mesti masih boleh
diterangkan semula dengan mod yang digunakan pada masa itu.

Produk `is_tax_exempt` dikecualikan daripada asas cukai dalam kedua-dua mod.

### 7.6 Promosi bertindih — `priority` menang, tidak bertindan

Apabila lebih daripada satu promosi kena pada item yang sama:

1. Susun mengikut `priority` menurun
2. **Satu promosi sahaja dikenakan** pada setiap item
3. Kecuali promosi itu ditanda `is_stackable`, barulah ia boleh bergabung

Tanpa peraturan ini, kelakuan menjadi rawak dan vendor akan melaporkannya
sebagai pepijat — sedangkan puncanya reka bentuk yang tidak lengkap.

### 7.7 Julat tarikh ikut `business_day`, happy hour ikut jam dinding

Promosi tamat `31 Ogos`. Jualan pada jam 1 pagi 1 September, semasa
`business_day` masih 31 Ogos (cutoff 4 pagi) — **promosi masih kena**. Itu
yang tauke jangkakan, kerana bagi mereka malam itu masih hari Isnin.

Tetapi happy hour `14:00–17:00` menggunakan **jam dinding sebenar**, kerana
maksudnya memang waktu petang, bukan tempoh hari perniagaan.

### 7.8 Diskaun manual juruwang dikekalkan

Medan diskaun yang juruwang taip sendiri kekal, dan dikenakan **selepas**
semua promosi.

Kawalan disediakan dalam tetapan tetapi **dimatikan secara lalai**, supaya
kelakuan kekal sama seperti sekarang:

- `manual_discount_max_percent` — `0` bermakna tiada had
- `manual_discount_needs_approval` — `0` bermakna tiada kelulusan diperlukan

Vendor boleh menghidupkannya bila-bila masa. Juruwang yang boleh menaip
diskaun tanpa had ialah lubang kebocoran wang paling biasa dalam POS, jadi
kawalan itu ada apabila vendor memerlukannya — tetapi tidak dipaksa sekarang.

### 7.9 Dwibahasa — `t()` mesti wujud sejak Fasa 1

**Diputuskan Sufi, 27 Ogos 2026.** Bahasa lalai kekal **Bahasa Melayu**.
Vendor boleh memilih Bahasa Inggeris. Superadmin boleh menambah bahasa baharu
melalui modul terjemahan.

Ini keputusan seni bina, bukan ciri hujung projek. Sebabnya:

> Terjemahan menyentuh **setiap skrin dalam sistem**. Kalau ia ditambah di
> Session 5 sedangkan Fasa 2 hingga 13 menulis teks Melayu terus dalam kod,
> setiap paparan perlu dibuka semula dan setiap rentetan diganti. Itu kerja
> berhari-hari, dan setiap rentetan yang terlepas menjadi pepijat senyap yang
> hanya kelihatan kepada pengguna Inggeris.

Jadi `core/Lang.php` dan helper `t()` **wujud dari Fasa 1**, dan setiap
rentetan yang ditulis dari Fasa 2 ke hadapan melaluinya. Modul pentadbiran
terjemahan dibina kemudian (Fasa 16) — yang penting titik masuknya betul
sekarang. Alasan yang sama seperti 7.1 dan 7.4.

### 7.10 Dua jenis teks — hanya satu diterjemah

| | Contoh | Diterjemah? |
|---|---|---|
| **Teks antara muka** | "Bayar", "Troli", "Stok habis", "Wang Diterima" | **Ya** |
| **Data vendor** | "Nasi Lemak", "Rendang daging", "Kaunter 1" | **Tidak** |

Nama produk kekal seperti yang vendor taip. Ini bukan kekurangan — nama
makanan memang selalunya tidak diterjemah, dan memaksa vendor mengisi nama
Inggeris untuk 2,000 barang kedai runcit ialah beban yang tiada siapa mahu.

Kalau nanti benar-benar diperlukan, jadual `product_translations` boleh
ditambah tanpa mengubah apa-apa yang sedia ada — `products.name` kekal
sebagai nilai lalai dan jatuh balik.

### 7.11 Peraturan menulis rentetan

**Jangan sekali-kali mencantum serpihan yang diterjemah.** Susunan perkataan
berbeza antara bahasa:

```
SALAH  : t('stok') . ' ' . $nama . ' ' . t('tidak_cukup')
BETUL  : t('stok_tidak_cukup', ['produk' => $nama])
         ms: "Stok {produk} tidak mencukupi"
         en: "Insufficient stock for {produk}"
```

Peraturan lain:

- Kunci terjemahan dalam **Bahasa Inggeris** (konvensyen kod, ikut CLAUDE.md),
  nilai dalam bahasa masing-masing
- Kunci hilang → pulangkan nilai Melayu, kemudian kunci itu sendiri.
  **Jangan sekali-kali pulangkan kosong** — skrin kosong lebih teruk daripada
  perkataan yang salah bahasa
- Semua rentetan dimuatkan **sekali** setiap permintaan ke dalam array,
  bukan satu pertanyaan setiap `t()`

**Bahasa mana yang digunakan:**

| Konteks | Sumber |
|---|---|
| Antara muka pengguna | `users.language`, jatuh balik ke `settings.default_language` |
| **Resit bercetak** | `settings.default_language` vendor — **bukan** bahasa juruwang |

> Resit dibaca oleh **pelanggan**, bukan juruwang. Juruwang yang memilih
> antara muka Inggeris tidak sepatutnya menyebabkan resit pelanggan bertukar
> bahasa.

## 8. Aliran kerja setiap mod

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

## 9. Langganan, had pelan & bil

### 9.1 Had pelan

Dikuatkuasakan dalam job simpan, bukan hanya di UI:

| Had | Disemak dalam |
|---|---|
| `max_outlets` | `SaveOutletJob` |
| `max_terminals_per_outlet` | `SaveTerminalJob` |
| `max_users` | `SaveUserJob` |
| `max_products` | `SaveProductJob` |

Vendor `suspended` atau `cancelled`: log masuk ditolak untuk semua peranan
kecuali `admin`, yang dibenarkan masuk **hanya** untuk melihat mesej
langganan tamat. Tiada akses POS, tiada akses data.

### 9.2 Harga per kedai — model berperingkat

**Diputuskan Sufi, 27 Ogos 2026: kedai tambahan dicaj dan masuk bil.**

Ini amalan standard industri. Caj per lokasi ialah norma dalam POS SaaS —
Square, Loyverse, Toast, Lightspeed dan StoreHub semuanya mengecaj mengikut
bilangan kedai. Diskaun untuk kedai tambahan juga lazim, biasanya dinyatakan
sebagai **peringkat** dan bukan peratus.

> Harga sebenar mana-mana platform tidak dicatat di sini kerana ia berubah
> kerap. Sufi patut menyemak harga semasa pesaing sebelum menetapkan sendiri.

Sebab peringkat dipilih dan bukan "diskaun % untuk kedai ke-2": peratus
tetap tidak menjawab kedai ke-5 atau ke-20, dan setiap kadar baharu akan
memerlukan perubahan kod. Peringkat menyelesaikan itu — dan **boleh
menghasilkan peratus rata juga**, cukup tetapkan satu peringkat sahaja.

`plan_outlet_tiers` menyimpan peringkat. Contoh pelan:

| Peringkat | Kedai | Harga seunit |
|---|---|---|
| 1 | 1 | RM 99 |
| 2 | 2–5 | RM 79 (20% diskaun) |
| 3 | 6+ | RM 59 (40% diskaun) |

Vendor dengan 3 kedai: `99 + 79 + 79 = RM 257` sebulan.

`GenerateInvoiceJob` mengira daripada peringkat, bukan daripada nombor tetap
dalam kod. Menukar harga bermakna menyunting baris `plan_outlet_tiers`.

### 9.3 Bila kedai ditambah di tengah kitaran

Kedai dibuka pada 15 haribulan sedangkan kitaran bil berakhir 30 haribulan.

**Cadangan: prorata** — caj separuh bulan sahaja, dan tandakan
`invoice_lines.is_prorated`. Ini yang pelanggan jangkakan, dan ia menghapuskan
insentif menunggu awal bulan sebelum membuka kedai.

Peraturan lain:

- **Kedai ditutup: tiada bayaran balik**, caj berhenti pada kitaran berikutnya.
  Standard industri, dan menghindari penyalahgunaan buka-tutup
- **Bil dijana sebagai `draft`** dahulu supaya superadmin boleh menyemak
  sebelum `issued`
- **Bil disimpan sebagai salinan gambaran.** Menukar harga pelan bulan depan
  **tidak** boleh mengubah bil bulan lepas — sebab itu `invoice_lines`
  menyimpan `unit_price` sendiri dan tidak merujuk `plan_outlet_tiers`
- Bayaran dalam talian masih **ditangguhkan**. Superadmin menandakan
  `paid` secara manual buat masa ini

## 10. Barcode — lebih mudah daripada yang disangka

Pengimbas barcode USB **berkelakuan sebagai papan kekunci**. Ia menaip digit
diikuti Enter. Tiada driver, tiada perpustakaan, tiada kebenaran browser.

Kerjanya: medan input yang sentiasa berfokus, kesan Enter, cari
`products.barcode` **dalam vendor semasa**, masuk troli.

Yang perlu diberi perhatian:

- Fokus mesti kembali ke medan imbas selepas setiap tindakan
- Produk yang **ada variasi** tidak boleh terus masuk troli walaupun diimbas —
  modal variasi mesti terbuka dahulu
- Barcode unik **per vendor**, bukan global — dua kedai berlainan memang
  menjual barang yang sama dengan barcode yang sama

## 11. Gambar produk — rantaian jatuh balik

1. `products.image_path` ada dan fail wujud → papar gambar
2. Tiada gambar tetapi `products.icon` ada → papar emoji
3. Kedua-dua tiada → `assets/img/product-default.png`

Muat naik (`core/Uploader.php`): JPG/PNG/WEBP sahaja disahkan dengan `finfo`
(**bukan** sambungan fail), maksimum 2MB, nama fail jadi hash rawak,
disimpan dalam `uploads/products/{vendor_id}/`,
`uploads/.htaccess` halang perlaksanaan PHP.

## 12. Struktur folder

```
claude-learn1/
├── config/         database.php (.gitignore) · database.example.php · app.php
├── core/           Database.php · Auth.php · Csrf.php · Request.php
│                   Response.php · Validator.php · Uploader.php
│                   BusinessDay.php · VendorScope.php · PlanLimit.php · Lang.php
├── jobs/           SATU KELAS = SATU KERJA — semua terima vendor_id
│   ├── Auth/        LoginJob · LogoutJob · CheckSubscriptionJob · ThrottleJob
│   │                PinLoginJob · RegisterDeviceJob · RevokeDeviceJob
│   ├── Vendor/      ListVendorsJob · SaveVendorJob · SuspendVendorJob
│   │                ProvisionVendorJob
│   ├── Outlet/      ListOutletsJob · SaveOutletJob · ValidateOutletJob
│   │                CloseOutletJob · SwitchOutletJob
│   ├── Billing/     GenerateInvoiceJob · ListInvoicesJob · MarkPaidJob
│   │                CalculateOutletPriceJob
│   ├── Plan/        ListPlansJob · SavePlanJob · SaveSubscriptionJob
│   ├── Product/     ListProductsJob · FindByBarcodeJob · SearchProductsJob
│   │                SaveProductJob · DeleteProductJob · UploadProductImageJob
│   │                ImportProductsCsvJob · LowStockJob
│   │                ListCategoriesJob · SaveCategoryJob
│   ├── Variation/   GetVariationsJob · SaveVariationsJob · ResetVariationsJob
│   ├── Promotion/   ListPromotionsJob · SavePromotionJob · TogglePromotionJob
│   │                ActivePromotionsJob · ApplyPromotionsJob
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
│   ├── Setting/     GetSettingsJob · SaveSettingsJob
│   └── Language/    ListLanguagesJob · SaveLanguageJob · SaveTranslationJob
│                    MissingKeysJob · ExportTranslationsJob
├── api/            endpoint nipis, pulangkan JSON — TIADA SQL di sini
├── cashier/        index.php · login.php · shift.php · js/
├── waiter/         index.php · login.php · tables.php · order.php · js/
│                   (mobile-first — waiter guna telefon/tablet)
├── admin/          admin kedai (per vendor) — katalog, stok, laporan, tetapan
├── superadmin/     panel platform — vendor, pelan, langganan
├── print/          receipt.php
├── uploads/        products/{vendor_id}/ (.gitignore isinya)
├── assets/img/     product-default.png
├── lang/           ms.php · en.php (cache terjemahan, dijana dari DB)
├── css/            style.css · receipt-58mm.css · receipt-80mm.css
├── vendor/bootstrap/
└── database/       schema.sql · seed.sql
```

## 13. Keselamatan — senarai semak wajib

- [ ] **`vendor_id` dari sesi, tidak pernah dari permintaan** (lihat 3.1)
- [ ] **Setiap pertanyaan menapis `vendor_id`** — tiada pengecualian
- [ ] **Tiada SQL mentah dalam `api/`** — semua dalam job class
- [ ] Seed dua vendor sejak Fasa 1, uji kebocoran setiap fasa
- [ ] Pengguna MySQL khas `pos_user`, akses ke `pos_saas` sahaja (bukan `root`)
- [ ] **Argon2id** dengan `memory_cost 19456`, `time_cost 2`, `threads 1`
      (bukan lalai PHP — lihat 4.4). `password_hash` VARCHAR(255)
- [ ] `password_needs_rehash()` pada setiap log masuk berjaya
- [ ] Mesej ralat log masuk yang sama untuk e-mel salah dan kata laluan salah
- [ ] Kunci akaun selepas 5 cubaan gagal; rekod setiap cubaan + IP
- [ ] PDO prepared statement untuk **setiap** pertanyaan
- [ ] `session_regenerate_id(true)` selepas log masuk
- [ ] Token CSRF pada semua POST
- [ ] **Setiap endpoint bayaran menolak peranan `waiter`**
- [ ] Status langganan disemak semasa log masuk **dan** pada setiap permintaan
- [ ] Pelayan **kira semula** semua harga — jangan percaya harga dari browser
- [ ] `htmlspecialchars()` pada setiap output PHP
- [ ] `config/database.php` dalam `.gitignore`

## 14. Perkara yang mudah tersilap

1. **Kebocoran antara vendor** — risiko nombor satu. Lihat bahagian 3.
2. **`CreateTransactionJob` mesti guna DB transaction sebenar**
   (`beginTransaction`/`commit`/`rollBack`).
3. **Kunci stok dengan `SELECT ... FOR UPDATE`.** Kaunter dinamik + waiter
   bermakna beberapa orang boleh pesan item terakhir yang sama serentak.
4. **Nombor resit dan nombor take-away dijana dalam DB transaction yang sama**,
   dan **unik per vendor** — bukan global.
5. **Stok ditolak bila pesanan dibuat, bukan bila dibayar.** Pembatalan
   pesanan mesti memulangkan stok.
6. **`business_day`, bukan `CURDATE()`.** Lihat 7.3.
7. **Pecah bil mesti kemas kini `paid_qty`** dalam DB transaction yang sama —
   kalau tidak, item sama boleh dibayar dua kali.
8. **Indeks bermula dengan `vendor_id`** (lihat 3.6).
9. **utf8mb4 pada sambungan PDO**, bukan hanya pada jadual.
10. **Import `seed.sql` mesti guna `--default-character-set=utf8mb4`.**
    Disahkan pada mesin ini (26 Ogos 2026): `mysql.exe` di Windows lalai kepada
    **`cp850`**. Tanpa flag itu, `🍛` disimpan sebagai 4 aksara sampah
    (`C2ADC692C3ACC3B8`) dan bukan 1 aksara (`F09F8D9B`). Yang lebih bahaya:
    membacanya semula melalui `mysql.exe` yang sama **nampak betul**, jadi
    kerosakan hanya terserlah bila PDO membacanya — iaitu di dalam aplikasi.
    Lihat resepi lengkap dalam bahagian 15.1.
11. **Promosi dinilai di pelayan sahaja.** Browser boleh memaparkan harga
    promosi untuk kepantasan, tetapi angka yang disimpan sentiasa datang dari
    `CalculateCartJob`. Sama seperti harga biasa — jangan percaya browser.
12. **`promotions.used_count` mesti dinaikkan dalam DB transaction yang sama**
    dengan penyimpanan jualan. Kalau tidak, promosi berhad (`max_uses`) boleh
    digunakan melebihi had semasa dua kaunter membayar serentak.
13. **Promosi disalin ke transaksi**, bukan dirujuk. Vendor menyunting promosi
    bulan depan tidak boleh mengubah resit bulan ini.
14. **Tetapan `discount_tax_mode` mengawal diskaun peringkat BIL sahaja.**
    Promosi peringkat item sentiasa menjejaskan cukai kerana ia mengubah harga
    jualan sebenar. Lihat 7.5.
15. **`users.email` unik GLOBAL, bukan per vendor.** Ia satu-satunya
    pengecualian kepada peraturan 3.5, kerana e-mel mengenal pasti pengguna
    sebelum sistem tahu vendor mana.
16. **Jangan guna parameter lalai PHP untuk argon2id** — 801ms terlalu
    perlahan. Tetapkan 19456/2/1 secara eksplisit (4.4).
17. **Jangan mencantum serpihan yang diterjemah.** Guna placeholder.
    Susunan perkataan berbeza antara bahasa (7.11).
18. **Resit ikut bahasa vendor, bukan bahasa juruwang.** Resit dibaca
    pelanggan (7.11).

## 15. Persediaan mesin pembangunan baharu

Repo ini mungkin di-clone pada mesin lain. Nilai di bawah dirakam dari mesin
pejabat — **jangan andaikan ia sama**.

| Perkara | Mesin pejabat | Semak di mesin baharu |
|---|---|---|
| Laluan projek | `C:\xampp\htdocs\claude-learn1` | Guna laluan sebenar |
| PHP | 8.2.12 | `php -v` — minimum 8.0 |
| MariaDB/MySQL | 10.4.32 (XAMPP) | `mysql --version` |
| Kata laluan `root` | Tiada | Mungkin ada di mesin lain |
| DB projek lain | `tuisyen` wujud | Mungkin tiada |

Langkah pemasangan:

1. Pastikan Apache + MySQL berjalan dalam XAMPP Control Panel
2. `CREATE DATABASE pos_saas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
   kemudian cipta `pos_user` dengan akses ke `pos_saas` sahaja
3. Import (perhatikan flag charset — lihat 15.1):
   `mysql --default-character-set=utf8mb4 -u root pos_saas < database/schema.sql`
   diikuti `seed.sql`
4. Salin `config/database.example.php` → `config/database.php`, isi kredensial
5. Log masuk dengan e-mel akaun seed — vendor KEDAI01 (runcit) atau
   KEDAI02 (kedai makan). E-mel sebenar ada dalam `database/seed.sql`
6. Superadmin: `http://localhost/{folder}/superadmin/`

### 15.1 Emoji dan `mysql.exe` di Windows — perangkap yang sudah disahkan

Diuji pada mesin pejabat, 26 Ogos 2026. `mysql.exe` di Windows bersambung
dengan `character_set_client = cp850` secara lalai, bukan utf8mb4.

Kesannya pada `seed.sql` yang penuh dengan ikon emoji:

| Cara | Tersimpan sebagai | Betul? |
|---|---|---|
| `mysql -u root db < seed.sql` | `C2ADC692C3ACC3B8` — 4 aksara, 8 bait | ❌ rosak |
| `mysql -e "INSERT … '🍛' …"` | `3F3F` — jadi `??` | ❌ rosak |
| `mysql --default-character-set=utf8mb4 -u root db < seed.sql` | `F09F8D9B` — 1 aksara, 4 bait | ✅ betul |

**Yang paling merbahaya:** cara pertama, bila dibaca semula melalui
`mysql.exe` yang sama, **nampak betul** — kerana ia ditukar balik oleh
penyongsangan yang sama. Kerosakan hanya terserlah apabila PDO membacanya,
iaitu di dalam aplikasi, selepas semua data sudah dimasukkan.

Peraturan yang mesti diikut:

1. `seed.sql` dan `schema.sql` disimpan sebagai **UTF-8 tanpa BOM**
2. Baris pertama setiap fail: `SET NAMES utf8mb4;`
3. Import sentiasa dengan `--default-character-set=utf8mb4`
4. **Jangan hantar emoji sebagai argumen baris arahan** (`-e "…'🍛'…"`) —
   baris arahan Windows menukarnya menjadi `??` tanpa amaran
5. Sahkan selepas import, jangan andaikan:
   `SELECT HEX(icon), CHAR_LENGTH(icon), LENGTH(icon) FROM products LIMIT 3;`
   — `🍛` mesti `F09F8D9B`, 1 aksara, 4 bait

## 16. Logik sedia ada yang boleh dipindah terus

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

## 17. Pemindahan data sedia ada

| Sumber | Destinasi |
|---|---|
| 18 produk dalam js/data.js | `seed.sql` — diberikan kepada **kedua-dua** vendor contoh |
| `PAYMENT_METHODS` | 3 baris per vendor dalam `payment_methods` |
| `TAX_RATE = 0.06` | Satu baris per vendor dalam `settings` |
| Kategori (Makanan/Minuman/Snek) | 3 baris per vendor dalam `categories` |
| Sejarah dalam localStorage | **Buang** — data demo sahaja |
