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
- [ ] `css/receipt-58mm.css`, `css/receipt-80mm.css`
- [ ] Halaman cetak resit berasingan (lebar ikut `settings.paper_width`)
- [ ] Cetak semula resit lama
- [ ] Sahkan: pratonton cetak betul pada kedua-dua lebar

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
