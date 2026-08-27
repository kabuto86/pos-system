# Prompt untuk Setiap Session

Salin blok yang berkenaan sebagai **mesej pertama** dalam session baharu.
Prompt ini sengaja pendek — konteks sebenar ada dalam PELAN.md dan PROGRES.md,
dan itu yang perlu dibaca dahulu.

**19 fasa merentas 6 session.**

| Session | Fasa | Hasil |
|---|---|---|
| 1 | 1–3 | Jualan kaunter berfungsi, dua vendor terasing |
| 2 | 4–6 | Kedai runcit siap sepenuhnya |
| 3 | 7–9 | Kedai makan siap sepenuhnya |
| 4 | 10–13 | Promosi, operasi & admin kedai penuh |
| 5 | 14–16 | Platform SaaS, kedai berbilang & bil |
| 6 | 17–19 | Bahasa, audit kebocoran, dokumentasi |

---

## Session 1 — Teras Multi-Tenant (Fasa 1–3)

```
Kita bina KedaiPOS sebagai SaaS: satu kod, satu DB, banyak vendor.
Asalnya sistem localStorage — sekarang dipindahkan ke MySQL + PHP vanila.

Baca dulu, ikut susunan:
1. CLAUDE.md — konvensyen projek
2. docs/migrasi-mysql/PELAN.md — beri perhatian penuh pada bahagian 3
   (peraturan multi-tenant). Itu bahagian yang menentukan sistem ini
   selamat atau bocor.
3. docs/migrasi-mysql/PROGRES.md — status semasa

Buat Fasa 1, 2 dan 3 sahaja. Jangan mula Fasa 4.

Peraturan multi-tenant (paling penting):
- vendor_id datang dari SESI, tidak pernah dari $_POST atau $_GET.
  Kalau endpoint terima vendor_id dari browser, vendor A boleh tukar satu
  nombor dan baca data vendor B.
- Setiap pertanyaan menapis vendor_id. Tiada pengecualian.
- Tiada SQL mentah dalam api/. Semua dalam job class.
- Seed WAJIB ada dua vendor: KEDAI01 (retail) dan KEDAI02 (restaurant).
  Dengan satu vendor sahaja, kebocoran mustahil dikesan.
- Setiap UNIQUE jadi unik per vendor (PELAN.md 3.5). Setiap indeks bermula
  dengan vendor_id (PELAN.md 3.6).

Peraturan lain:
- Ikut skema 34 jadual dalam PELAN.md. Kalau ada yang tak masuk akal semasa
  kerja, beritahu aku dulu sebelum ubah, dan catat dalam log keputusan
  di hujung PROGRES.md.
- Semua jualan lalui jadual orders, termasuk jualan kaunter biasa
  (order_type = counter). Ini keputusan 7.1 PELAN.md — jangan tulis terus
  ke transactions, kalau tidak Fasa 9 kena tulis semula fasa ini.
- business_day dikira dari settings.day_cutoff_time, BUKAN CURDATE().
- Jadual promosi dicipta sekarang walaupun UI dibina di Fasa 10, dan
  CalculateCartJob mesti sudah ada titik masuk penilaian promosi mengikut
  susunan PELAN.md 7.5. ApplyPromotionsJob boleh pulangkan kosong buat masa
  ini — yang penting susunan pengiraan betul sekarang, bukan ditampal nanti.
  Sebabnya sama seperti keputusan orders: CalculateCartJob mengira setiap sen
  dalam sistem ini, jadi ia tidak boleh ditulis semula selepas diuji.
- Import seed.sql WAJIB guna --default-character-set=utf8mb4. mysql.exe di
  Windows lalai cp850 dan akan merosakkan setiap emoji tanpa amaran.
  Baca PELAN.md 15.1, dan sahkan dengan HEX() selepas import.
- Guna pengguna MySQL pos_user, bukan root. Jangan sentuh database tuisyen.
- Port calcUnitPrice(), makeLineId(), getTotals() dari JS sedia ada.
- Empat peranan: superadmin, admin, cashier, waiter. Waiter tiada akses
  bayaran, disemak di dalam endpoint, bukan sekadar sorok butang.

Model tiga lapisan (PELAN.md 1.1 dan 3.8):
- vendor (syarikat yang melanggan) -> outlet (kedai) -> users (kakitangan).
  Satu vendor boleh ada banyak kedai. Stok, kaunter, syif, pesanan dan
  jualan milik OUTLET, bukan vendor.
- vendor_id = sempadan KESELAMATAN, dari sesi sahaja, ada pada SETIAP jadual.
  outlet_id = skop PERNIAGAAN, boleh dari input TAPI mesti disahkan milik
  vendor semasa melalui ValidateOutletJob. Jangan campurkan dua ini.
- Produk di peringkat vendor (katalog dikongsi). Stok dan harga per kedai
  dalam product_outlets. price_override NULL bermakna guna products.price.
- Seed: KEDAI01 satu kedai, KEDAI02 DUA kedai — supaya isu kedai berbilang
  terserlah awal, sama sebabnya seperti dua vendor.

Log masuk dan kata laluan (baca PELAN.md 4 habis):
- DUA laluan berbeza. E-mel + kata laluan untuk superadmin/tauke/admin.
  Nama + PIN untuk juruwang dan waiter, pada peranti yang sudah didaftarkan
  ke satu kedai. Waiter log masuk 20-30 kali sehari — kalau dipaksa menaip
  e-mel, mereka akan berkongsi satu akaun dan sistem hilang jejak siapa
  buat apa.
- users.email unik GLOBAL tetapi NULLABLE — wajib untuk admin, kosong untuk
  waiter yang hanya guna PIN. vendor_id diperoleh dari baris pengguna
  selepas pengesahan, tidak pernah dari borang.
- PIN di-hash dengan Argon2id yang sama. Jangan simpan teks biasa.
  PIN hanya sah pada peranti berdaftar. 3 cubaan gagal -> dikunci.
- Argon2id dengan memory_cost 19456, time_cost 2, threads 1. JANGAN guna
  lalai PHP (64MB, t=4) — sudah diukur, 801ms, terlalu perlahan.
  password_hash VARCHAR(255).
- password_needs_rehash() pada setiap log masuk berjaya.
- Mesej ralat sama untuk e-mel tidak wujud dan kata laluan salah.
- Kunci akaun 15 minit selepas 5 cubaan gagal, rekod cubaan + IP.

Dwibahasa:
- core/Lang.php dan helper t() WAJIB wujud sejak Fasa 1, dan setiap rentetan
  yang dipapar dari Fasa 2 ke hadapan melaluinya. Modul pentadbiran
  terjemahan dibina di Fasa 16 — tetapi kalau titik masuk tidak ada sekarang,
  setiap paparan kena dibuka semula nanti dan setiap rentetan yang terlepas
  jadi pepijat senyap. Baca PELAN.md 7.9 hingga 7.11.
- Jangan cantum serpihan yang diterjemah. Guna placeholder:
  t('stok_tidak_cukup', ['produk' => $nama]), bukan t('stok') . $nama.
- Kunci hilang pulangkan kunci itu sendiri, jangan sekali-kali kosong.
- Bahasa lalai Melayu. Nama produk TIDAK diterjemah.

Ujian wajib setiap fasa:
- Log masuk KEDAI01, cipta data. Log masuk KEDAI02, sahkan data KEDAI01
  tidak kelihatan.
- Ambil id rekod KEDAI01, cuba capai melalui API sebagai KEDAI02 —
  mesti 404 atau 403, bukan data.

Commit berasingan setiap fasa. Kemas kini PROGRES.md sebelum commit terakhir.
```

---

## Session 2 — Kedai Runcit Siap (Fasa 4–6)

```
Sambung pembinaan KedaiPOS SaaS.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — bahagian 3 (peraturan multi-tenant)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-3 sepatutnya sudah bertanda siap

Sebelum tulis kod baharu, sahkan Fasa 1-3 masih berfungsi: log masuk
KEDAI01, buat satu jualan ujian, pastikan ia masuk DB dengan vendor_id betul.

Buat Fasa 4, 5 dan 6 sahaja.

Peraturan:
- Barcode: pengimbas USB berkelakuan sebagai papan kekunci — ia menaip digit
  dan tekan Enter. Tiada driver, tiada library. Jangan cari penyelesaian
  yang lebih rumit daripada itu. Barcode unik PER VENDOR, bukan global —
  dua kedai memang jual barang sama.
- Fasa 5 (resit termal) menukar pendekatan cetak sepenuhnya, bukan tampal
  CSS. Baca bahagian Fasa 5 dalam PROGRES.md habis dulu — ada tiga sebab
  cara lama gagal dan tiga perangkap driver yang dijangka.
- print/receipt.php terima id dalam URL, jadi ia sasaran kebocoran paling
  jelas dalam sistem. Semak vendor_id sebelum papar apa-apa.
- Buang blok @media print lama dari css/style.css. Jangan tinggal dua
  mekanisme cetak yang bersaing.
- Ada dua keputusan menunggu aku dalam bahagian Fasa 5 (lebar kertas lalai,
  emoji pada resit). Tanya bila sampai situ.
- Muat naik gambar ke uploads/products/{vendor_id}/. Sahkan jenis fail
  dengan finfo, had 2MB, nama fail jadi hash, .htaccess halang PHP.
- Bahagian admin kedai BERASINGAN di /admin/ dengan sidebar sendiri.
  Butang Variasi di navbar juruwang sudah dibuang dalam Fasa 3 — jangan
  masukkan semula.

Ujian kebocoran setiap fasa seperti biasa. Commit berasingan setiap fasa.
Kemas kini PROGRES.md.
```

---

## Session 3 — Kedai Makan: Pesanan (Fasa 7–9)

```
Sambung pembinaan KedaiPOS SaaS — bahagian kedai makan.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — bahagian 3 (multi-tenant), 7 (tiga
   keputusan seni bina) dan 8 (aliran kerja setiap mod)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-6 sepatutnya sudah bertanda siap

Uji sebagai vendor KEDAI02 (restaurant).

Buat Fasa 7, 8 dan 9.

Peraturan:
- orders dan transactions adalah DUA benda berbeza. orders = apa yang
  dipesan (boleh berubah). transactions = apa yang dibayar (kekal).
  Gabung bil: banyak order -> satu transaction. Pecah bil: satu order ->
  banyak transaction.
- Stok ditolak SEMASA PESANAN DIBUAT, bukan semasa bayaran. Kalau tunggu
  bayaran, dua meja boleh pesan ikan terakhir yang sama. Batal pesanan
  mesti pulangkan stok.
- Nombor take-away unik per vendor + business_day, reset harian.
  business_day dikira dari day_cutoff_time — uji pada jam 01:00, ia mesti
  ikut hari semalam. Dua vendor boleh ada take-away 001 pada hari sama.
- Pecah bil mesti kemas kini order_items.paid_qty dalam DB transaction yang
  sama. Kalau tidak, item sama boleh dibayar dua kali. Ini kena diuji
  secara khusus.
- Mustahil gabung pesanan merentas vendor — uji ini.
- Waiter TIADA akses bayaran. Uji dengan curl, bukan sekadar tengok UI —
  panggil endpoint bayaran guna sesi waiter dan pastikan ditolak 403.
- Aplikasi waiter mobile-first. Uji pada viewport 390x844.

Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 4 — Promosi, Operasi & Admin Kedai (Fasa 10–13)

```
Sambung pembinaan KedaiPOS SaaS.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-9 sepatutnya sudah bertanda siap

Buat Fasa 10, 11, 12 dan 13.

Peraturan:
- Fasa 10 (promosi): baca PELAN.md 7.4 hingga 7.8 habis dulu. Empat peraturan
  di sana sudah aku putuskan dan tidak boleh diubah sambil lalu:
  priority tertinggi menang dan tidak bertindan kecuali is_stackable;
  discount_tax_mode ialah tetapan vendor yang disimpan pada setiap transaksi;
  julat tarikh ikut business_day tetapi happy hour ikut jam dinding;
  diskaun manual juruwang kekal dan dikenakan selepas promosi.
- Promosi peringkat item SENTIASA menjejaskan cukai dalam kedua-dua mod,
  kerana ia betul-betul mengubah harga jualan. discount_tax_mode mengawal
  diskaun peringkat bil sahaja. Ini bukan pepijat — jangan "betulkan".
- promotions.used_count dinaikkan dalam DB transaction yang sama dengan
  jualan, kalau tidak max_uses boleh dilanggar bila dua kaunter bayar serentak.
- Nama promosi disalin ke transaksi. Vendor sunting promosi bulan depan tidak
  boleh mengubah resit bulan ini.
- Void dan refund adalah dua perkara berbeza. Void = silap juruwang, tanda
  status void, stok pulang penuh. Refund = pelanggan pulang barang kemudian,
  jadi rekod baharu bernilai negatif berpaut pada resit asal.
- Laporan mesti tolak refund dan kecualikan transaksi void. Sahkan jumlah
  dalam laporan sama dengan jumlah dikira terus dari DB melalui SQL —
  jangan percaya paparan sahaja.
- Laporan paling mudah bocor sebab ia mengagregat. Sahkan jumlah KEDAI01
  tidak termasuk sebarang jualan KEDAI02.
- Kadar cukai, caj perkhidmatan dan caj bungkus dibaca dari settings vendor,
  bukan pemalar dalam kod. Uji: tukar kadar KEDAI01, sahkan KEDAI02 tidak
  terjejas dan jualan lama tidak berubah.
- business_type TIADA dalam tetapan kedai — ia milik superadmin (Fasa 14).

Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 5 — Platform SaaS & Kedai Berbilang (Fasa 14–16)

```
Sambung pembinaan KedaiPOS SaaS — lapisan platform.

Baca dulu, ikut susunan:
1. CLAUDE.md
2. docs/migrasi-mysql/PELAN.md — bahagian 3, 5 (peranan) dan 9 (had pelan)
3. docs/migrasi-mysql/PROGRES.md — Fasa 1-13 sepatutnya sudah bertanda siap

Buat Fasa 14, 15 dan 16.

Peraturan:
- superadmin ada vendor_id NULL. Ia menguruskan vendor, TIDAK masuk POS
  mana-mana vendor. Uji kedua-dua arah: superadmin tak boleh masuk POS,
  admin vendor tak boleh capai /superadmin/.
- Had pelan dikuatkuasa dalam job simpan, bukan hanya butang disable di UI.
  Uji dengan panggil API terus melebihi had.
- Fasa 16 (kedai berbilang & bil): baca PELAN.md 9 habis. Harga kedai
  tambahan dikira dari plan_outlet_tiers, BUKAN nombor tetap dalam kod.
  Kedai dibuka pertengahan kitaran diprorata. invoice_lines simpan
  unit_price sendiri supaya menukar harga pelan tidak mengubah bil lama.
- ProvisionVendorJob mesti hasilkan vendor yang terus boleh berjualan —
  tetapan lalai, kaedah bayaran, kategori, akaun admin, kaunter pertama.
  Tiada langkah manual dalam DB selepas itu.
- Fasa 16 (bahasa): t() sudah wujud sejak Fasa 1 dan setiap rentetan sudah
  melaluinya. Fasa ini bina modul pentadbiran dan lengkapkan set Inggeris.
  Modul mesti benar-benar boleh tambah bahasa ketiga melalui UI — uji dengan
  menambah satu bahasa baharu, bukan sekadar menyokong ms dan en.
  Nama produk TIDAK diterjemah, dan resit ikut bahasa vendor bukan bahasa
  juruwang. Kedua-duanya betul — jangan "betulkan". Baca PELAN.md 7.10, 7.11.
- Fasa 17 ialah audit kebocoran menyeluruh. Ia bukan formaliti — senaraikan
  setiap pertanyaan SQL dalam jobs/ dan sahkan setiap satu menapis
  vendor_id. `grep -rn "vendor_id" api/` mesti kosong. Jalankan juga
  /security-review. Catat hasilnya dalam PROGRES.md.

Commit berasingan setiap fasa. Kemas kini PROGRES.md.
```

---

## Session 6 — Bahasa, Audit & Dokumentasi (Fasa 17–19)

```
Tiga fasa terakhir KedaiPOS SaaS.

Baca dulu:
1. CLAUDE.md
2. docs/migrasi-mysql/PROGRES.md — Fasa 1-16 sepatutnya sudah siap

Buat Fasa 17, 18 dan 19.

Peraturan:
- Empat panduan berasingan sebab empat peranan berbeza: juruwang, waiter,
  admin kedai, superadmin. Jangan campur jadi satu dokumen.
- Guna skill user-manual-auto untuk jana screenshot baharu.
- Panduan sedia ada dalam docs/panduan-pengguna.md merujuk skrin lama yang
  sudah tidak wujud — kena ganti, bukan tampal.
- docs/variasi/ juga perlu dikemas kini: editor variasi kini halaman penuh
  dalam admin, bukan modal.
- README pemasangan mesti termasuk cara provision vendor pertama.
- Hujung session: jalankan /code-review ke atas keseluruhan projek.
- Tandakan PROGRES.md siap sepenuhnya.
```

---

## Kalau session terputus di tengah fasa

```
Sambung kerja KedaiPOS SaaS yang terhenti.

Baca docs/migrasi-mysql/PROGRES.md dan docs/migrasi-mysql/PELAN.md.
Kemudian jalankan `git log --oneline -10` dan `git status` untuk lihat
di mana kerja sebenarnya terhenti.

Beritahu aku apa yang kau dapati dan apa langkah seterusnya SEBELUM
mula menulis kod.
```
