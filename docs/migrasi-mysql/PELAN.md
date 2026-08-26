# Pelan Induk — KedaiPOS SaaS: MySQL + PHP Vanila

> **Dokumen rujukan tetap.** Baca fail ini SEBELUM menulis sebarang kod dalam
> mana-mana session. Keputusan di sini sudah disahkan oleh Sufi — jangan ubah
> tanpa bertanya. Untuk status semasa, lihat [PROGRES.md](PROGRES.md).

Kemas kini terakhir: 26 Ogos 2026 (SaaS multi-tenant + modul promosi)
Persekitaran rujukan: XAMPP · PHP 8.2.12 · MariaDB 10.4.32

---

## 1. Apa sistem ini sebenarnya

**Satu SaaS.** Satu kod, satu pangkalan data, banyak vendor. Setiap vendor
melanggan dan memilih **jenis perniagaan**, dan pilihan itu menentukan aliran
kerja mereka:

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
juruwang bernama `ali`, produk barcode yang sama, dan resit nombor 0001.

| Dulu | Sekarang |
|---|---|
| `users.username` UNIQUE | UNIQUE(`vendor_id`, `username`) |
| `products.barcode` UNIQUE | UNIQUE(`vendor_id`, `barcode`) |
| `transactions.receipt_no` UNIQUE | UNIQUE(`vendor_id`, `receipt_no`) |
| `terminals.code` UNIQUE | UNIQUE(`vendor_id`, `code`) |
| `dining_tables.code` UNIQUE | UNIQUE(`vendor_id`, `code`) |
| `settings.setting_key` PK | PK(`vendor_id`, `setting_key`) |
| `orders.takeaway_no` | UNIQUE(`vendor_id`, `business_day`, `takeaway_no`) |

### 3.6 Setiap indeks bermula dengan `vendor_id`

`INDEX (vendor_id, business_day)`, bukan `INDEX (business_day)`. Semua
pertanyaan menapis vendor dahulu, jadi indeks mesti mengikut susunan itu.
Kalau tidak, prestasi merudum apabila vendor bertambah.

### 3.7 Muat naik diasingkan mengikut vendor

`uploads/products/{vendor_id}/{hash}.jpg` — bukan satu folder berkongsi.

## 4. Cara vendor dikenal pasti semasa log masuk

Skrin log masuk meminta **tiga** medan:

```
Kod Kedai   : KEDAI01
Nama Pengguna : ali
Kata Laluan : ••••••••
```

Sebabnya: nama pengguna hanya unik dalam vendor, jadi sistem perlu tahu
vendor dahulu sebelum boleh mencari pengguna.

> **Perlu disahkan Sufi.** Dua pilihan lain wujud:
> **subdomain** (`kedai01.pos.com`) lebih kemas untuk pengeluaran tetapi perlu
> DNS dan vhost — menyusahkan di XAMPP semasa pembangunan;
> **e-mel sebagai nama pengguna** (unik global) membuang medan Kod Kedai
> tetapi menyusahkan waiter yang log masuk berpuluh kali sehari.
> Cadangan saya: **Kod Kedai + nama pengguna** sekarang. Ia berfungsi di
> mana-mana, dan subdomain boleh ditambah kemudian tanpa mengubah skema —
> subdomain cuma mengisi medan Kod Kedai secara automatik.

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

## 6. Skema pangkalan data — 25 jadual

Pangkalan data: `pos_saas` · `utf8mb4_unicode_ci` · InnoDB

> **utf8mb4 wajib** pada pangkalan data, jadual, lajur DAN sambungan PDO.
> **Setiap jadual perniagaan mempunyai `vendor_id`** kecuali yang ditanda.

### A. Platform (3) — tiada `vendor_id`

**`vendors`** — id, code(UNIQUE), name, business_type ENUM(retail/restaurant),
status ENUM(trial/active/suspended/cancelled), phone, address,
created_at, updated_at

**`plans`** — id, code, name, price_monthly,
max_terminals, max_users, max_products, features_json, is_active

**`subscriptions`** — id, vendor_id(FK), plan_id(FK),
status ENUM(trial/active/past_due/cancelled),
started_at, trial_ends_at, current_period_end, cancelled_at, note

> Bayaran langganan dalam talian **tidak** termasuk dalam skop sekarang.
> Superadmin menandakan status secara manual. Lihat "Perkara tertangguh".

### B. Katalog (4)

**`categories`** — id, **vendor_id**, name, sort_order, is_active, created_at

**`products`** — id, **vendor_id**, category_id(FK), name, icon, image_path,
barcode, sku, price, **cost_price**, **unit**, stock, **min_stock**,
**is_tax_exempt**, is_active, sort_order, created_at, updated_at
· UNIQUE(vendor_id, barcode)

> `cost_price` — tanpanya laporan hanya boleh beritahu berapa **jualan**,
> bukan berapa **untung**. Untuk kedai runcit bermargin nipis, untung ialah
> angka yang paling dicari.
> `min_stock` — ambang amaran "stok rendah" pada dashboard. Tanpa lajur ini,
> ciri itu tiada makna.
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

**`orders`** — id, **vendor_id**, order_no, **business_day**(DATE),
**order_type** ENUM(dine_in/takeaway/counter),
table_id(FK, nullable), **takeaway_no**(nullable),
status ENUM(open/billed/paid/cancelled), guest_count,
opened_by(FK users), terminal_id(FK, nullable), note, opened_at, closed_at
· UNIQUE(vendor_id, business_day, takeaway_no)

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

**`dining_tables`** — id, **vendor_id**, code, name, area, capacity,
status ENUM(free/occupied/reserved), current_order_id, is_active, sort_order

### D. Bayaran (4)

**`transactions`** — id, **vendor_id**, receipt_no, **business_day**(DATE),
type ENUM(sale/refund), ref_transaction_id(nullable),
terminal_id(FK), shift_id(FK), user_id(FK),
**order_type**, **table_label**, **takeaway_no** (salinan gambaran),
subtotal, tax_rate, tax, **service_charge**, **packaging_fee**,
**promo_discount**, **manual_discount**, discount,
**discount_tax_mode** ENUM(before_tax/after_tax),
total, payment_method_id(FK),
cash_received, change_amount, status ENUM(paid/void),
void_reason, voided_at, voided_by, created_at
· UNIQUE(vendor_id, receipt_no)

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

### F. Operasi (7)

**`terminals`** — id, **vendor_id**, code, name,
**type** ENUM(cashier/waiter), receipt_prefix, is_active, last_seen_at
· UNIQUE(vendor_id, code)

**`shifts`** — id, **vendor_id**, terminal_id(FK), user_id(FK), business_day,
opened_at, opening_float, closed_at, closing_cash, expected_cash,
variance, status ENUM(open/closed), note

**`stock_movements`** — id, **vendor_id**, product_id(FK),
type ENUM(sale/refund/void/restock/adjustment), qty_change, balance_after,
ref_transaction_id, ref_order_id, user_id, note, created_at

**`payment_methods`** — id, **vendor_id**, code, label, icon, needs_cash,
note, is_active, sort_order

**`users`** — id, **vendor_id (NULL untuk superadmin)**, username,
password_hash, full_name, role ENUM(superadmin/admin/cashier/waiter),
is_active, last_login_at, created_at
· UNIQUE(vendor_id, username)

**`settings`** — **vendor_id**, setting_key, setting_value, updated_at,
updated_by · PK(vendor_id, setting_key)

> Isi awal setiap vendor: `day_cutoff_time` (04:00), `shop_name`,
> `shop_address`, `tax_rate` (0.06), `service_charge_rate` (0),
> `packaging_fee` (0), `receipt_footer`, `paper_width` (58/80),
> `printer_name`, `currency_prefix` (RM),
> **`discount_tax_mode`** (`after_tax` — kekalkan kelakuan sekarang),
> **`manual_discount_max_percent`** (0 = tiada had),
> **`manual_discount_needs_approval`** (0)
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

## 9. Had pelan langganan

Dikuatkuasakan dalam job simpan, bukan hanya di UI:

| Had | Disemak dalam |
|---|---|
| `max_terminals` | `SaveTerminalJob` |
| `max_users` | `SaveUserJob` |
| `max_products` | `SaveProductJob` |

Vendor `suspended` atau `cancelled`: log masuk ditolak untuk semua peranan
kecuali `admin`, yang dibenarkan masuk **hanya** untuk melihat mesej
langganan tamat. Tiada akses POS, tiada akses data.

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
│                   BusinessDay.php · VendorScope.php · PlanLimit.php
├── jobs/           SATU KELAS = SATU KERJA — semua terima vendor_id
│   ├── Auth/        LoginJob · LogoutJob · CheckSubscriptionJob
│   ├── Vendor/      ListVendorsJob · SaveVendorJob · SuspendVendorJob
│   │                ProvisionVendorJob
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
│   └── Setting/     GetSettingsJob · SaveSettingsJob
├── api/            endpoint nipis, pulangkan JSON — TIADA SQL di sini
├── cashier/        index.php · login.php · shift.php · js/
├── waiter/         index.php · login.php · tables.php · order.php · js/
│                   (mobile-first — waiter guna telefon/tablet)
├── admin/          admin kedai (per vendor) — katalog, stok, laporan, tetapan
├── superadmin/     panel platform — vendor, pelan, langganan
├── print/          receipt.php
├── uploads/        products/{vendor_id}/ (.gitignore isinya)
├── assets/img/     product-default.png
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
- [ ] `password_hash()` / `password_verify()`
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
5. Log masuk: Kod Kedai `KEDAI01` (runcit) atau `KEDAI02` (kedai makan)
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
