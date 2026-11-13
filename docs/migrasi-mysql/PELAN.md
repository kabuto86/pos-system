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

### 3.9 Halaman awam — satu-satunya pengecualian

Tiga bahagian sistem tanpa log masuk:

| Laluan | Untuk | Pelanggan bawa | Pelayan cari |
|---|---|---|---|
| `order/?t=…` | Pesanan QR di meja | `qr_token` meja | vendor, outlet, meja |
| `s/{shop_slug}` | Kedai online, ambil sendiri (9.7) | `shop_slug` kedai | vendor, outlet |
| `pay/callback.php` | Panggilan balik gerbang pembayaran (9.6) | rujukan bayaran kita | vendor, pesanan |

Peraturan 3.1 masih dipatuhi dalam semangatnya: `vendor_id` **tidak pernah**
dihantar oleh pelanggan atau gerbang. Pelayan sentiasa mencarinya daripada
pengecam yang disimpan dalam pangkalan data kita sendiri.

Peraturan khusus QR meja:

- `qr_token` 32 aksara heks dari `random_bytes(16)` — tidak boleh diteka,
  bukan id meja berjujukan
- Token tidak sah, meja tidak aktif, modul `qr_order` tiada dalam pelan, atau
  tetapan `qr_order_enabled` dimatikan → **halaman sama** "Pesanan QR tidak
  tersedia", tanpa membezakan sebabnya
- **Bayar online** → `awaiting_payment`; bila gerbang sahkan bayaran, pesanan
  **terus aktif dan masuk dapur** tanpa Terima (9.6)
- **Bayar di kaunter** → `pending`. **Stok tidak ditolak** dan dapur tidak
  nampak apa-apa sehingga kakitangan tekan **Terima** — dengan amaran berlapis
  supaya tiada pesanan terlepas (9.8)
- Vendor tetapkan pilihan bayaran yang dibenarkan: online sahaja, kaunter
  sahaja, atau kedua-duanya (`qr_payment_options`)
- Hanya **satu** pesanan `pending` setiap meja pada satu masa, had 20 baris
  dan 20 unit setiap baris — menghalang usikan dari luar kedai
- Harga, promosi dan cukai dikira semula di pelayan; harga dari pelayar diabaikan
- Admin boleh **jana semula** token meja → QR lama yang dicetak terus mati

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
| `waiter` | Ada | Buka meja, ambil & tambah pesanan, **terima pesanan QR** | **Bayaran, tutup bil, void, refund, laporan** |
| *pelanggan* | *dari token meja / slug kedai* | Lihat menu, hantar pesanan, bayar online, lihat status pesanannya sendiri | Apa-apa selain itu — **bukan akaun**, tiada log masuk |

> `superadmin` ialah pemilik platform (Sufi). `vendor_id` NULL menjadikannya
> jelas dalam kod bahawa akaun ini tiada kedai — dan menjadikan mana-mana
> pertanyaan POS gagal dengan serta-merta jika tersilap digunakan.

> Sekatan waiter **mesti disemak di dalam setiap endpoint**. Menyorok butang
> di UI bukan kawalan keselamatan.

## 6. Skema pangkalan data — 39 jadual

Pangkalan data: `pos_saas` · `utf8mb4_unicode_ci` · InnoDB

> **utf8mb4 wajib** pada pangkalan data, jadual, lajur DAN sambungan PDO.
> **Setiap jadual perniagaan mempunyai `vendor_id`** kecuali yang ditanda.

### A. Platform & Langganan (11)

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
**shop_slug**(nullable, UNIQUE **global** — `s/kak-ani`, lihat 9.7),
is_active, opened_at, closed_at, created_at
· UNIQUE(vendor_id, code)

> Kedai / cawangan. Stok, kaunter, syif, pesanan dan jualan semuanya milik
> outlet, bukan vendor. Lihat 1.1.

**`plans`** — id, code, name, **base_price**, **price_per_outlet**,
max_outlets, max_terminals_per_outlet, max_users, max_products,
is_active

**`plan_outlet_tiers`** — id, plan_id(FK), from_outlet, to_outlet,
unit_price · lihat 9.2

**`modules`** — code(PK, cth. `promotions`), name_key, description_key,
is_core, requires_business_type ENUM(any/retail/restaurant), sort_order
· *tiada vendor_id — peringkat platform*

**`plan_modules`** — plan_id(FK), module_code(FK) · PK(plan_id, module_code)

> Menggantikan `plans.features_json` yang asalnya tidak ditakrif. Superadmin
> tanda modul mana yang termasuk dalam setiap pelan — lihat 9.4.

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

**`categories`** — id, **vendor_id**, name, sort_order, is_active,
**send_to_kitchen** (1), created_at

> `send_to_kitchen = 0` untuk barang siap yang tidak perlu dimasak (air
> kotak, kuih dalam bekas) — ia tidak masuk tiket dapur.

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

### C. Pesanan (5) — teras mod kedai makan

**`orders`** — id, **vendor_id**, **outlet_id**(FK), order_no, **business_day**(DATE),
**order_type** ENUM(dine_in/takeaway/counter/**pickup**),
table_id(FK, nullable), **takeaway_no**(nullable),
status ENUM(**awaiting_payment**/**pending**/open/billed/paid/cancelled), guest_count,
**source** ENUM(staff/qr/**online**),
**payment_choice** ENUM(counter/online, nullable — NULL untuk pesanan kakitangan),
**customer_name**, **customer_phone**, **pickup_at** (nullable — pesanan `pickup` sahaja),
**public_token** CHAR(32) (nullable — pautan status pesanan untuk pelanggan),
opened_by(FK users, **nullable** — NULL bila `source` = qr / online),
confirmed_by(FK users, nullable), confirmed_at,
terminal_id(FK, nullable), note, opened_at, closed_at
· UNIQUE(outlet_id, business_day, takeaway_no)

> `order_type = counter` digunakan oleh mod kedai runcit — pesanan yang
> dibuka dan dibayar serentak. `takeaway_no` dipapar 3 digit (001, 002…);
> juruwang taip nombor ini untuk memanggil pesanan.

**`order_items`** — id, **vendor_id**, order_id(FK), product_id,
**product_name**, **icon**, **base_price**, **unit_price**, variant_label,
qty, **paid_qty**, line_total, status ENUM(ordered/served/cancelled),
**kitchen_ticket_id**(FK, nullable),
note, added_by(FK users), added_at

> `paid_qty` yang membolehkan pecah bil: satu baris pesanan boleh dibayar
> separa oleh beberapa orang. Pesanan hanya `paid` bila setiap baris
> mempunyai `paid_qty = qty`.
> `note` untuk permintaan bebas ("kurang pedas") yang tiada dalam variasi.
> `added_by` **nullable** — NULL untuk item yang dipesan pelanggan melalui QR.

**`kitchen_tickets`** — id, **vendor_id**, **outlet_id**(FK), order_id(FK),
ticket_no, business_day,
status ENUM(new/preparing/ready/done/cancelled),
created_at, started_at, ready_at, printed_at
· UNIQUE(outlet_id, business_day, ticket_no)

> Satu tiket = satu **hantaran** ke dapur, bukan satu pesanan. Meja 5 pesan
> nasi lemak, 20 minit kemudian tambah teh tarik → dua tiket, kerana dapur
> perlu tahu apa yang **baru** masuk. `printed_at` menghalang slip dicetak
> dua kali bila skrin dapur dimuat semula. Lihat 9.5.

**`order_item_options`** — id, **vendor_id**, order_item_id(FK),
**group_name**, **option_label**, **price_delta**

**`dining_tables`** — id, **vendor_id**, **outlet_id**(FK), code, name, area, capacity,
status ENUM(free/occupied/reserved), current_order_id, is_active, sort_order,
**qr_token** CHAR(32) UNIQUE (global, rawak — lihat 3.9)

### D. Bayaran (6)

**`transactions`** — id, **vendor_id**, **outlet_id**(FK), receipt_no, **business_day**(DATE),
type ENUM(sale/refund), ref_transaction_id(nullable),
terminal_id(FK, **nullable**), shift_id(FK, **nullable**), user_id(FK, **nullable**)
— ketiga-tiganya NULL untuk bayaran online (tiada kaunter, tiada syif),
**online_payment_id**(FK, nullable),
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

**`vendor_payment_gateways`** — id, **vendor_id**, gateway
ENUM(toyyibpay/billplz/senangpay/stripe), **credentials_enc** (JSON
disulitkan), is_sandbox, is_active, verified_at, updated_by, updated_at
· UNIQUE(vendor_id, gateway)

> Kunci API **milik vendor** — wang pelanggan terus ke akaun vendor, platform
> tidak memegang wang (keputusan Sufi, 13 Nov 2026). Disulitkan dengan
> `sodium_crypto_secretbox`, kunci induk dalam `config/app.php` (luar git).
> Kunci tidak pernah dipapar semula selepas disimpan — hanya 4 aksara akhir.
> Satu sahaja boleh `is_active = 1` setiap vendor.

**`online_payments`** — id, **vendor_id**, **outlet_id**, order_id(FK),
gateway, **reference** CHAR(32) UNIQUE (rawak — dihantar kepada gerbang),
gateway_bill_id, amount, currency, status
ENUM(pending/paid/failed/expired/refunded), paid_at, expires_at,
callback_payload (JSON, untuk audit), created_at
· UNIQUE(gateway, gateway_bill_id)

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
**type** ENUM(cashier/waiter/**kitchen**), receipt_prefix,
**auto_print** (0 — peranti dapur sahaja: cetak slip bila tiket baharu masuk),
is_active, last_seen_at
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
> `packaging_fee` (0), `receipt_footer`, `paper_width` (58/80, seed `58`;
> vendor tetapkan sendiri, boleh ditindih per kedai),
> `printer_name`, `currency_prefix` (RM),
> **`discount_tax_mode`** (`after_tax` — kekalkan kelakuan sekarang),
> **`manual_discount_max_percent`** (0 = tiada had),
> **`manual_discount_needs_approval`** (0), **`default_language`** (ms),
> **`qr_order_enabled`** (0 — per kedai; hanya bermakna jika modul `qr_order` ada),
> **`qr_payment_options`** (`counter` / `online` / `both`),
> **`online_order_enabled`** (0), **`pickup_payment_options`** (`counter` / `online` / `both`),
> **`pickup_lead_minutes`** (30), **`pickup_hours`** (JSON jam buka ambil),
> **`online_payment_expiry_minutes`** (15)
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

### Kedai makan — pesanan QR pelanggan (modul `qr_order`)

```
PELANGGAN (telefon sendiri)        SISTEM / KAKITANGAN
  Imbas QR di meja 5
  Pilih item, pilih cara bayar

  (a) BAYAR ONLINE
  Ke halaman gerbang (FPX/kad)
  Bayar ---------------------->  Gerbang panggil pay/callback.php
                                 Tandatangan + amaun disahkan
                                 Stok ditolak → TERUS ke dapur
  "Dibayar, sedang disediakan"   (tiada butang Terima)

  (b) BAYAR DI KAUNTER
  Hantar pesanan ------------->  Bunyi + sepanduk: "Meja 5 — pesanan QR"
  "Menunggu disahkan · 1 min"      (kaunter, waiter, DAN skrin dapur)
                                 Kakitangan / dapur tekan TERIMA
                                 Stok ditolak → ke dapur
  "Pesanan diterima"             Bayar di kaunter selepas makan
```

### Peniaga dari rumah — kedai online, ambil sendiri (modul `online_order`)

```
PELANGGAN (pautan dari WhatsApp/IG)  PENIAGA
  Buka kedaipos.my/s/kak-ani
  Pilih barang, isi nama, telefon,
  masa ambil, cara bayar
  (a) Bayar online ---------------->  Disahkan gerbang → terus aktif
                                     (masuk dapur jika makanan)
  (b) Bayar semasa ambil ---------->  Perlu TERIMA (sama seperti QR kaunter)
  Halaman status (pautan rawak)       Tandakan "Siap untuk diambil"
  "Siap — sila datang ambil"          Pelanggan datang, ambil, (bayar)
                                     Tandakan "Sudah diambil"
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

### 9.4 Modul per pelan

**Diputuskan Sufi, 13 Nov 2026:** superadmin tentukan modul mana yang
tersedia dalam setiap pelan. Gaya ringkas — tanda kotak per pelan, tiada
tambahan per vendor.

| Kod | Modul | Teras? | Jenis perniagaan |
|---|---|---|---|
| `pos` | Jualan kaunter, katalog asas, resit, syif, dashboard | **Ya** — sentiasa ada | semua |
| `promotions` | Promosi & diskaun automatik | | semua |
| `stock` | Terima stok, pelarasan, log pergerakan, amaran stok rendah | | semua |
| `reports` | Laporan lanjutan, Z-report, eksport CSV | | semua |
| `csv_import` | Import produk pukal dari CSV | | semua |
| `waiter_app` | Aplikasi waiter — ambil pesanan di meja dari telefon | | kedai makan |
| `qr_order` | Pesanan QR pelanggan | | kedai makan |
| `kitchen` | Dapur — skrin pesanan + slip automatik | | kedai makan |
| `online_payment` | Bayaran online melalui gerbang vendor sendiri (9.6) | | semua |
| `online_order` | Kedai online, ambil sendiri — untuk peniaga dari rumah (9.7) | | semua |

> `online_payment` ialah modul **sokongan**: ia menambah pilihan "bayar online"
> pada `qr_order` dan `online_order`. Tanpanya, kedua-dua modul itu masih
> berfungsi dengan "bayar di kaunter / semasa ambil" sahaja.

> **Tanpa `waiter_app`:** kedai makan masih boleh buka meja dan ambil pesanan
> dari **skrin juruwang** (Fasa 7). Peranan `waiter` tidak boleh log masuk,
> `SaveUserJob` menolak pengguna baharu berperanan waiter, dan semua
> endpoint `waiter/` memanggil `Module::require('waiter_app')`.
>
> **Tanpa `qr_order`:** halaman `order/` papar "tidak tersedia" (3.9).
> Kedua-dua modul bebas — pelan boleh ada satu, kedua-dua, atau tiada.

> Stok **tetap ditolak** semasa jualan walaupun tanpa modul `stock` — modul
> itu hanya menambah alat pengurusannya. Menutup modul tidak boleh
> merosakkan ketepatan data.

**Penguatkuasaan — `core/Module.php`:**

- `Module::enabled($vendorId, 'promotions')` — satu pertanyaan
  `subscriptions → plan_modules`, di-cache untuk satu permintaan sahaja
  (bukan dalam sesi, supaya perubahan pelan berkuat kuasa serta-merta)
- Setiap endpoint modul panggil `Module::require()` → **403** jika tiada.
  Menyorok menu di sidebar bukan kawalan keselamatan (sama seperti peranan)
- `CalculateCartJob` **tidak** menilai promosi jika modul `promotions`
  tiada — kalau tidak, promosi lama masih memberi diskaun selepas turun pelan
- `requires_business_type` — `qr_order` tidak dipapar langsung untuk kedai runcit

**Turun pelan:** data modul **disimpan, tidak dipadam**. Promosi tidak
dinilai, menu tersorok, QR meja papar "tidak tersedia". Naik pelan semula →
semuanya kembali seperti asal.

### 9.5 Modul dapur (`kitchen`)

**Diputuskan Sufi, 13 Nov 2026.** Satu halaman `kitchen/` yang papar pesanan
masuk, dan — jika peranti itu ada printer — cetak slip secara automatik.
Skrin dan slip ialah **satu modul**, bukan dua.

**Kenapa dapur perlukan peranti sendiri.** Pelayar hanya boleh mencetak ke
printer komputer yang membukanya, dan pelayan SaaS di internet tidak boleh
sampai ke printer dalam WiFi kedai. Jadi kaunter tidak boleh mencetak ke
dapur. Dapur perlukan tablet atau PC kecil sendiri; printer termal pada
peranti itu adalah pilihan.

**Peranti dapur** = `terminals.type = kitchen`, didaftarkan seperti peranti
lain (4.3). Skrin dapur **tidak memerlukan PIN** — ia menyala sepanjang hari
dan tidak menyentuh wang. Token peranti sahaja memberi capaian kepada tiket
kedai itu, dan **tiada lagi**: tiada harga, tiada bayaran, tiada laporan.

**Bila tiket dicipta:**

| Sumber | Tiket dicipta bila |
|---|---|
| Waiter / juruwang | Pesanan **dihantar** |
| Pelanggan QR | Kakitangan tekan **Terima** — bukan semasa pelanggan hantar |
| Kaunter runcit | Tidak pernah — modul ini kedai makan sahaja |

Hanya item dari kategori `send_to_kitchen = 1` masuk tiket. Tiket tanpa
item yang perlu dimasak tidak dicipta langsung.

**Aliran tiket:** `new` → (tukang masak tekan) `preparing` → `ready` →
(waiter/juruwang hantar ke meja) `done`. Status `ready` memaparkan lencana
"Siap dihidang" pada skrin waiter dan juruwang. Item dibatalkan selepas
tiket dicipta → tiket ditanda dan slip **BATAL** dicetak.

**Slip dapur** (`print/kitchen-slip.php`, guna `paper_width` kedai):
nombor tiket besar, Meja 5 / Take away 007, masa, item + pilihan + nota
dalam huruf besar. **Tiada harga.** Tiada emoji (sama seperti resit).

**Cetak automatik:** skrin dapur meninjau setiap 5 saat. Tiket `new` dengan
`printed_at` NULL → cetak melalui iframe tersembunyi (cara Fasa 5) → tanda
`printed_at`. Chrome dibuka dengan `--kiosk-printing` supaya tiada dialog.
`printed_at` ditanda **di pelayan dalam satu UPDATE bersyarat**
(`… WHERE printed_at IS NULL`) supaya dua tab dapur tidak mencetak dua kali.

### 9.6 Bayaran online (`online_payment`)

**Diputuskan Sufi, 13 Nov 2026:** wang terus ke **akaun gerbang vendor
sendiri**; platform tidak memegang wang pelanggan. Empat gerbang disokong:
**ToyyibPay, Billplz, SenangPay, Stripe**.

**Reka bentuk — satu antara muka, empat penyesuai** (`core/Payment/`):

```php
interface PaymentGateway {
    public function createBill(OnlinePayment $p, array $customer): string; // URL bayar
    public function verifyCallback(array $request): CallbackResult;        // tandatangan
    public function fetchStatus(string $gatewayBillId): string;            // semak semula
}
// ToyyibPayGateway · BillplzGateway · SenangPayGateway · StripeGateway
```

Kod pesanan tidak tahu gerbang mana yang digunakan. Gerbang kelima nanti =
satu kelas baharu, tiada perubahan lain.

**Peraturan yang tidak boleh dilanggar:**

1. **Hanya panggilan balik pelayan-ke-pelayan menandakan "dibayar".** Halaman
   "kembali" yang pelanggan lihat selepas bayar **tidak dipercayai** — ia
   boleh dipalsukan dengan menaip URL. Ia hanya memaparkan status semasa.
2. **Tandatangan disahkan** dengan kunci vendor itu (dicari melalui
   `online_payments.reference` → vendor), **dan** amaun + mata wang dibanding
   dengan rekod kita. Tidak sepadan → tolak dan log.
3. **Semak semula** dengan `fetchStatus()` sebelum menanda dibayar, jika
   gerbang menyokongnya — pertahanan kedua jika kunci tandatangan bocor.
4. **Idempotent:** gerbang sering memanggil balik lebih sekali. `UPDATE …
   WHERE status = 'pending'` — panggilan kedua tidak menolak stok dua kali.
5. **Tamat tempoh** selepas `online_payment_expiry_minutes` (15): pesanan
   `awaiting_payment` dibatalkan. Stok tidak pernah ditolak, jadi tiada apa
   untuk dipulangkan. Tiada cron diwajibkan: `ExpireUnpaidOrdersJob` dipanggil
   secara malas setiap kali senarai pesanan atau skrin dapur dimuat; cron /
   Task Scheduler pilihan sahaja. Panggilan balik yang tiba **selepas** tamat
   tempoh tetap diterima jika amaun betul — wang sudah ditolak dari pelanggan.
6. **Stok habis semasa bayaran disahkan** (dijual di kaunter dalam 15 minit
   itu): pesanan tetap dibayar, ditanda **"Perlu tindakan"** di skrin admin —
   vendor sama ada sediakan juga atau pulangkan wang melalui papan pemuka
   gerbang. Sistem tidak memulangkan wang secara automatik.
7. Bayaran disahkan → `transactions` dicipta dengan `online_payment_id`,
   tanpa kaunter/syif/juruwang, supaya laporan jualan merangkumi semuanya.

**Pulangan wang:** dibuat vendor dalam papan pemuka gerbang; admin tanda
"dipulangkan" dalam sistem → transaksi refund dicipta. Pemulangan automatik
melalui API tertangguh.

### 9.7 Kedai online, ambil sendiri (`online_order`)

**Diputuskan Sufi, 13 Nov 2026** — untuk peniaga dari rumah (makanan atau
barang) dan kedai biasa yang mahu terima tempahan.

- Setiap kedai boleh ada **`shop_slug`** → pautan `s/kak-ani` untuk dikongsi
  di WhatsApp / Instagram. Slug unik **global**, huruf kecil, nombor, sengkang
- Pelanggan isi **nama, telefon, masa ambil** — tiada akaun. Masa ambil
  dihadkan oleh `pickup_hours` dan `pickup_lead_minutes`
- Bayar online → terus aktif. Bayar semasa ambil → perlu **Terima** (9.8)
- Pelanggan dapat **pautan status** (`public_token` rawak) — "Diterima",
  "Sedang disediakan", "Siap untuk diambil". Tanpa SMS: butang WhatsApp
  (`wa.me/…`) dengan mesej siap ditulis, dihantar dari telefon peniaga sendiri
- **Tiada jenis perniagaan baharu.** Peniaga makanan → `restaurant` (pesanan
  masuk dapur jika ada modul `kitchen`); peniaga barang → `retail`
- **Data peribadi (PDPA):** nama dan telefon pelanggan hanya dipapar kepada
  vendor itu, dan dipadam/dikaburkan selepas 90 hari
- Had sama seperti QR: 20 baris, 20 unit, satu pesanan belum-dibayar setiap
  nombor telefon pada satu masa

**Tertangguh:** penghantaran ke rumah pelanggan (delivery), caj
penghantaran, zon kawasan.

### 9.8 Pesanan yang perlu ditekan Terima — jangan sampai terlepas

Hanya pesanan **bayar di kaunter / semasa ambil** perlu Terima. Risikonya:
tiada siapa perasan, pelanggan menunggu, makanan tidak dimasak. Lapisan:

1. **Bunyi + sepanduk kekal** di skrin juruwang dan waiter sehingga diterima
   atau ditolak; telefon waiter Android bergetar. (Pelayar hanya benarkan
   bunyi selepas pengguna menekan skrin sekali — butang "Buka syif" memenuhi
   syarat itu.)
2. **Skrin dapur juga papar** lajur "Menunggu disahkan" dengan butang
   **Terima** — tiga tempat boleh perasan, bukan satu.
3. **Naik tahap selepas 2 minit:** sepanduk merah berkelip, bunyi berulang.
4. **Pelanggan nampak masa menunggu.** Selepas 3 minit: "Sila maklumkan
   pelayan berdekatan" (QR meja) atau butang WhatsApp kepada peniaga (ambil
   sendiri).

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
│                   Response.php · Validator.php · Uploader.php · Crypto.php
│                   Payment/ — PaymentGateway · ToyyibPayGateway · BillplzGateway
│                              SenangPayGateway · StripeGateway
│                   BusinessDay.php · VendorScope.php · PlanLimit.php · Module.php · Lang.php
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
│   │                SavePlanModulesJob
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
│   │                RegenerateTableQrJob
│   ├── QrOrder/     ResolveTableTokenJob · PublicMenuJob · SubmitQrOrderJob
│   │                ListPendingQrOrdersJob · AcceptQrOrderJob · RejectQrOrderJob
│   ├── Payment/     CreateOnlinePaymentJob · HandleGatewayCallbackJob
│   │                ExpireUnpaidOrdersJob · SaveGatewayCredentialsJob · MarkRefundedJob
│   ├── Storefront/  ResolveShopSlugJob · SubmitPickupOrderJob · OrderStatusJob
│   ├── Kitchen/     ListKitchenTicketsJob · CreateKitchenTicketJob
│   │                AdvanceTicketJob · ClaimTicketPrintJob · CancelTicketItemJob
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
├── superadmin/     panel platform — vendor, pelan, modul, langganan
├── kitchen/        skrin dapur — peranti dapur berdaftar, tiada PIN (9.5)
├── order/          AWAM — pesanan QR pelanggan, tiada log masuk (3.9)
├── s/              AWAM — kedai online, ambil sendiri: s/{shop_slug} (9.7)
├── pay/            AWAM — callback.php (gerbang) · return.php (papar status sahaja)
│                   index.php?t={qr_token} · mobile-first
├── print/          receipt.php · kitchen-slip.php
├── uploads/        products/{vendor_id}/ (.gitignore isinya)
├── assets/img/     product-default.png
├── lang/           ms.php · en.php (cache terjemahan, dijana dari DB)
├── css/            style.css · receipt.css (58 & 80 dalam satu fail, kelas .kp-receipt-58 / -80)
├── vendor/bootstrap/
└── database/       lihat 15.2
    ├── migrate.php          pelari CLI — up · status · seed · fresh · dump
    ├── migrations/          001_platform.sql … 007_operations.sql
    ├── seeds/core/          wajib di semua persekitaran (modul, bahasa)
    ├── seeds/demo/          data demo — dev sahaja (pelan, vendor, produk)
    └── schema.sql           JANA oleh `migrate.php dump` — rujukan, jangan sunting
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
3. Salin `config/database.example.php` → `config/database.php`, isi
   kredensial dan `'env' => 'local'`
4. `php database/migrate.php fresh --demo` — cipta semua jadual, isi data
   teras dan data demo (lihat 15.2)
5. Log masuk dengan akaun demo — senarainya dicetak di hujung arahan
   langkah 4, dan dalam `database/seeds/demo/README.md`
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

> **Pelari migrasi (15.2) mengelak perangkap ini sepenuhnya** kerana ia
> menjalankan fail melalui PDO utf8mb4, bukan `mysql.exe`. Peraturan di atas
> masih terpakai jika sesiapa mengimport fail SQL secara manual.

### 15.2 Migrasi, schema & seed

**Diputuskan Sufi, 13 Nov 2026:** pangkalan data dibina melalui migrasi
bernombor + seed, supaya mesin baharu atau pelayan sebenar boleh disediakan
dengan satu arahan, dan perubahan skema selepas ini tidak perlu disunting
tangan dalam phpMyAdmin.

**`database/migrate.php`** — PHP vanila, CLI sahaja (`php_sapi_name()` mesti
`cli`), sambung melalui `core/Database.php` (PDO utf8mb4):

| Arahan | Buat apa |
|---|---|
| `php database/migrate.php up` | Jalankan migrasi yang belum dijalankan, ikut nombor |
| `php database/migrate.php status` | Senarai migrasi: sudah / belum |
| `php database/migrate.php seed` | Jalankan `seeds/core/` sahaja |
| `php database/migrate.php seed --demo` | `seeds/core/` + `seeds/demo/` |
| `php database/migrate.php fresh --demo` | **Padam semua jadual**, `up`, kemudian seed demo |
| `php database/migrate.php dump` | Jana semula `schema.sql` dari pangkalan data semasa |
| `php database/migrate.php superadmin` | Cipta akaun superadmin — tanya e-mel & kata laluan di terminal. Untuk pelayan sebenar, di mana seed demo tidak dijalankan |

- Rekod migrasi dalam jadual sistem **`schema_migrations`**(version PK,
  applied_at) — jadual ke-40, bukan sebahagian model aplikasi
- **Migrasi tidak disunting selepas di-commit.** Ubah skema = fail baharu
  (`008_add_xxx.sql`). Inilah yang membolehkan pelayan sebenar dinaik taraf
  tanpa kehilangan data
- Satu kenyataan SQL berakhir dengan `;` di hujung baris — pelari memecah
  fail pada sempadan itu supaya ralat menunjuk kenyataan yang tepat
- DDL MySQL auto-commit, jadi migrasi yang gagal separuh jalan **tidak**
  digulung balik. Pelari berhenti serta-merta dan cetak fail + kenyataan
- `fresh` dan `--demo` **ditolak** jika `config.env` bukan `local`
- Seed boleh `.sql` atau `.php`. Akaun demo mesti `.php` kerana kata laluan
  dan PIN perlu `password_hash()` Argon2id — hash tidak boleh ditulis tangan
- Seed demo **idempotent**: dijalankan dua kali tidak menggandakan data
  (`INSERT … ON DUPLICATE KEY UPDATE`)

**Pembahagian seed:**

| `seeds/core/` — wajib, semua persekitaran | `seeds/demo/` — `local` sahaja |
|---|---|
| `modules` (10 modul, 9.4) | `plans` Asas / Pro / Percubaan — **harga contoh**, Sufi tetapkan sebenar melalui panel superadmin |
| `languages` (ms, en) | `plan_modules`, `plan_outlet_tiers` |
| `translations` rentetan sistem | KEDAI01 (runcit, Asas, 1 kedai) · KEDAI02 (kedai makan, Pro, 2 kedai) |
| | KEDAI03 — **peniaga dari rumah** (makanan, `online_order` + `online_payment`, `s/kak-ani`, tiada meja) |
| | Gerbang **sandbox** untuk KEDAI02 & KEDAI03 — kunci kosong, diisi sendiri dari akaun ujian gerbang |
| | 18 produk setiap vendor, kategori, variasi, kaedah bayaran, tetapan |
| | Kaunter, meja + `qr_token`, akaun admin / juruwang / waiter, superadmin demo |
| | Beberapa transaksi lepas — supaya dashboard & laporan ada isi |

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
