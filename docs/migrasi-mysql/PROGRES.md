# Progres Migrasi — Status Semasa

> **Kemas kini fail ini di HUJUNG setiap fasa**, sebelum commit. Inilah satu-satunya
> sumber kebenaran tentang di mana kerja terhenti. Baca [PELAN.md](PELAN.md) untuk
> keputusan reka bentuk.

**Status keseluruhan:** Belum bermula — pelan sahaja siap
**Fasa terakhir siap:** —
**Fasa seterusnya:** Fasa 1

---

## Session 1 — Teras + POS Juruwang

### Fasa 1 — Skema & teras
- [ ] Cipta pangkalan data `pos_system` (utf8mb4_unicode_ci)
- [ ] Cipta pengguna MySQL `pos_user` (akses `pos_system` sahaja)
- [ ] `database/schema.sql` — 14 jadual
- [ ] `database/seed.sql` — 18 produk + 3 kategori + 3 kaedah bayaran + tetapan + 1 admin + 1 kaunter
- [ ] `config/database.php` + `.example.php` + kemas kini `.gitignore`
- [ ] `core/Database.php` (PDO, utf8mb4), `Response.php`, `Request.php`, `Validator.php`
- [ ] Sahkan: query dari CLI pulangkan 18 produk, emoji tidak rosak

### Fasa 2 — Auth, kaunter & syif
- [ ] `core/Auth.php`, `core/Csrf.php`
- [ ] `jobs/Auth/LoginJob.php`, `LogoutJob.php`
- [ ] `jobs/Terminal/…`, `jobs/Shift/OpenShiftJob.php`, `CloseShiftJob.php`, `CurrentShiftJob.php`
- [ ] `cashier/login.php` — log masuk + pilih kaunter
- [ ] `cashier/shift.php` — buka syif (wang mula) / tutup syif (kira wang, beza)
- [ ] Sahkan: log masuk berjaya, syif terbuka dalam DB, peranan cashier tak boleh masuk `/admin/`

### Fasa 3 — POS juruwang penuh
- [ ] `jobs/Product/ListProductsJob.php` (produk + variasi + stok)
- [ ] `jobs/Cart/CalculateCartJob.php` (port `calcUnitPrice` + `getTotals` dari JS)
- [ ] `jobs/Stock/DeductStockJob.php` (`SELECT ... FOR UPDATE`)
- [ ] `jobs/Transaction/CreateTransactionJob.php` (DB transaction + jana `receipt_no`)
- [ ] `jobs/Transaction/ListTransactionsJob.php`, `GetReceiptJob.php`
- [ ] `api/` endpoint untuk semua di atas
- [ ] `cashier/index.php` + `cashier/js/` — pindah dari index.html, buang butang Variasi
- [ ] Sahkan dengan Playwright: buat jualan sebenar → semak baris dalam `transactions`,
      `transaction_items`, `stock_movements`; refresh browser → stok kekal berkurang

**Hujung Session 1: POS boleh diguna sebenar. Admin urus produk melalui phpMyAdmin buat sementara.**

---

## Session 2 — Cetakan + Bahagian Admin

### Fasa 4 — Resit termal

> **Fasa ini tukar pendekatan cetak, bukan tampal CSS.** Baca sebab di bawah
> sebelum mula — kalau tidak, mudah tersilap sangka kerja ini kecil.

**Kenapa cara sekarang tidak boleh dikekalkan**

Blok `@media print` dalam `css/style.css` guna helah `visibility: hidden`.
Untuk A4 ia menjadi. Untuk printer termal ia gagal atas tiga sebab:

1. **Tiada `@page size`** — driver andaikan A4, jadi resit 58mm dicetak di sudut
   kertas maya A4. Pada gulungan termal, kertas keluar panjang berjela.
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
- Admin guna halaman yang sama untuk cetak semula di Fasa 6 — tidak ditulis dua kali

Juruwang tekan Cetak → JS muatkan halaman ini dalam `iframe` tersembunyi →
`iframe.contentWindow.print()`. Skrin POS tidak berkelip, tiada tetingkap
baharu, tiada masalah popup blocker.

**Senarai kerja**

- [ ] `print/receipt.php` — dijana pelayan melalui `GetReceiptJob`
- [ ] `css/receipt-58mm.css` — `@page { size: 58mm auto; margin: 0 }`, 9pt monospace
- [ ] `css/receipt-80mm.css` — sama, 80mm, 10pt
- [ ] `cashier/js/print.js` — cetak melalui iframe tersembunyi
- [ ] Luaskan `GetReceiptJob` — tambah nama kedai, alamat, juruwang, kaunter,
      footer (semua dari `settings`, bukan pemalar dalam kod)
- [ ] Tandaan resit: **SALINAN** / **BATAL** / **PEMULANGAN**
- [ ] **Buang** blok `@media print` lama dari `css/style.css` — jangan tinggal
      dua mekanisme cetak yang bersaing
- [ ] Dokumen langkah tetapan printer Windows untuk Sufi

> Fail `.css` berasingan, bukan `style="..."` — peraturan "jangan inline CSS"
> dalam CLAUDE.md masih dipatuhi. Bootstrap memang tidak menyediakan
> `@page size`; fail sendiri satu-satunya jalan.

**Bentuk resit selepas Fasa 4**

Sekarang nama kedai ditulis terus dalam `js/app.js` (`KEDAI POS`). Selepas ini
semuanya dari DB, dan tiga baris baharu ditambah kerana wujudnya syif dan
kaunter dinamik:

```
        {shop_name}              <- settings
       {shop_address}            <- settings
-----------------------------
No. Resit : K1-20260824-0042     <- BAHARU (dulu Date.now)
Tarikh    : 24/08/2026 14:32
Juruwang  : Ali bin Abu          <- BAHARU (perlu, sebab ada syif)
Kaunter   : Kaunter 1            <- BAHARU (perlu, sebab kaunter dinamik)
-----------------------------
Nasi Lemak x2            18.60
  Rendang daging, Extra pedas
Teh Tarik x1              3.00
  Besar, Ais
-----------------------------
Subjumlah                21.60
Cukai (6%)                1.30   <- kadar dari settings
Diskaun                  -0.00
JUMLAH                   22.90
Tunai                    25.00
Baki                      2.10
-----------------------------
      {receipt_footer}           <- settings
```

**Tandaan SALINAN adalah keperluan audit, bukan hiasan.** Tanpa label,
juruwang boleh cetak resit kedua dan serahkan sebagai asal. Transaksi yang
dibatalkan mesti tercetak **BATAL** dengan jelas.

**Cara pengesahan**

Boleh disahkan sendiri dengan Playwright:

- [ ] `page.emulateMedia({ media: 'print' })` → ukur lebar sebenar `body`.
      Mesti 58mm (~219px pada 96dpi), bukan lebih
- [ ] Tiada limpahan mendatar — teks tidak terpotong di tepi
- [ ] **Kes terburuk dari data sebenar**: `Nasi Lemak` +
      `Rendang daging, Extra pedas, Telur mata, Sambal extra` — 48 aksara pada
      lebar 32 aksara. Mesti membalut ke baris baharu, bukan terpotong
- [ ] Cetak ke PDF → bilangan halaman = 1, tiada halaman kosong di hujung
- [ ] Ulang untuk 58mm dan 80mm

**Sufi kena sahkan sekali dengan printer sebenar.** Tiada jalan lain — kod
boleh dipastikan betul, tetapi hanya kertas sebenar membuktikan driver
berkelakuan seperti dijangka.

**Tiga perangkap yang dijangka**

1. **Saiz kertas dalam Printer Properties Windows.** `@page { size: 58mm auto }`
   hanyalah cadangan; sesetengah driver abaikan dan ikut tetapan printer.
   Sufi mungkin perlu set saiz kertas 58mm sekali sahaja dalam Windows. Ini
   **langkah pemasangan, bukan pepijat kod**.
2. **Margin dialog cetak Chrome.** Lalai "Default" tambah ~10mm. Perlu tukar ke
   "None". Kalau menyusahkan pada mesin kaunter sebenar, lancarkan Chrome
   dengan `--kiosk-printing` — dialog hilang, resit terus keluar.
3. **Emoji pada resit termal.** Ikon selalunya keluar sebagai kotak hitam pada
   driver termal murah. Cadangan: **buang emoji dari resit bercetak, kekalkan
   pada skrin**. Skrin dan kertas ada keperluan berbeza.

**Dua keputusan diperlukan dari Sufi sebelum Fasa 4 bermula**

- [ ] **Lebar lalai — 58mm atau 80mm?** 58mm lebih murah dan biasa untuk kedai
      makan; 80mm lebih lega untuk nama produk panjang. Kedua-dua akan dibina,
      cuma perlu tahu yang mana jadi lalai dalam `settings`
- [ ] **Emoji pada resit bercetak — buang atau kekal?** Cadangan: buang. Kalau
      Sufi nak kekalkan, jadikan tetapan hidup/mati supaya boleh diuji dengan
      printer sebenar

### Fasa 5 — Admin: katalog
- [ ] Rangka `admin/` — login, sidebar, semak peranan pada setiap halaman
- [ ] `admin/index.php` — dashboard (jualan hari ini, transaksi, top produk, stok rendah)
- [ ] `admin/products.php` — CRUD + muat naik gambar (`core/Uploader.php`)
- [ ] `admin/categories.php`
- [ ] `admin/variations.php` — pindah editor dari js/admin.js jadi halaman penuh
- [ ] `assets/img/product-default.png` + `uploads/.htaccess`
- [ ] Sahkan: muat naik gambar, gambar muncul di skrin juruwang, jatuh balik ke emoji berfungsi

### Fasa 6 — Admin: stok & transaksi
- [ ] `admin/stock.php` — baki, terima stok, pelarasan, log pergerakan
- [ ] `admin/transactions.php` — tapis tarikh/juruwang/kaunter/kaedah
- [ ] `jobs/Transaction/VoidTransactionJob.php` — pulang stok penuh
- [ ] `jobs/Transaction/RefundTransactionJob.php` — refund separa, transaksi negatif
- [ ] Sahkan: void pulangkan stok betul; refund separa hanya pulangkan item dipilih

---

## Session 3 — Laporan, Tetapan & Dokumentasi

### Fasa 7 — Laporan
- [ ] `admin/reports.php` — harian, bulanan, ikut kaedah bayaran, ikut juruwang, top produk
- [ ] Laporan tutup syif (Z-report)
- [ ] Eksport CSV
- [ ] Sahkan: jumlah laporan = jumlah dalam DB, refund ditolak dengan betul

### Fasa 8 — Pentadbiran
- [ ] `admin/users.php` — juruwang/admin, reset kata laluan
- [ ] `admin/terminals.php` — vendor tambah kaunter baharu
- [ ] `admin/payment-methods.php`
- [ ] `admin/settings.php` — nama kedai, kadar cukai, footer resit, lebar kertas
- [ ] `admin/logs.php` — log aktiviti
- [ ] Sahkan: tukar kadar cukai dalam tetapan → jualan baharu guna kadar baharu

### Fasa 9 — Dokumentasi
- [ ] Kemas kini `docs/panduan-pengguna.md` — screenshot baharu (skill `user-manual-auto`)
- [ ] Panduan admin baharu
- [ ] Kemas kini `docs/variasi/` — editor variasi kini halaman penuh
- [ ] `README` pemasangan: import schema, cipta pos_user, tetapan config

---

## Perkara tertangguh (bukan sebahagian 9 fasa)

- **ESC/POS mentah + buka laci wang** — tunggu Sufi tahu jenama printer termal
- Import sejarah lama dari localStorage — diputuskan buang
- Pelanggan / program kesetiaan — tidak dibincangkan
- Cukai berbilang kadar — sekarang satu kadar sahaja

## Log keputusan yang berubah di tengah jalan

> Kalau ada keputusan dalam PELAN.md yang terpaksa diubah semasa kerja,
> catat di sini dengan sebabnya supaya session seterusnya tidak keliru.

| Tarikh | Apa yang berubah | Sebab |
|---|---|---|
| — | — | — |
