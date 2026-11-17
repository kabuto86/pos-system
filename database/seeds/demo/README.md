# Data demo

Dijana oleh `php database/migrate.php fresh --demo`. Hanya untuk mesin
pembangunan (`env = local`); pelari menolak seed demo di pelayan lain.
Harga pelan ialah **harga contoh**. Sufi tetapkan harga sebenar melalui
panel superadmin.

## Log masuk e-mel

Kata laluan semua akaun: `demo12345`

| Akaun | E-mel | Vendor |
|---|---|---|
| Superadmin | `superadmin@kedaipos.test` | (platform) |
| Admin | `ahmad@majujaya.test` | KEDAI01 Kedai Runcit Maju Jaya |
| Admin | `pakmat@selera.test` | KEDAI02 Restoran Selera Kampung |
| Admin | `kakani@dapurkakani.test` | KEDAI03 Dapur Kak Ani |

## Kakitangan PIN

PIN hanya berfungsi pada peranti yang didaftarkan ke kedai itu (PELAN.md 4.3).

| Vendor | Kedai | Nama | Peranan | PIN |
|---|---|---|---|---|
| KEDAI01 | HQ Kedai Utama | Ali | juruwang | 1111 |
| KEDAI02 | BGI Cawangan Bangi | Ali | juruwang | 1111 |
| KEDAI02 | BGI Cawangan Bangi | Aisyah | juruwang | 2222 |
| KEDAI02 | BGI Cawangan Bangi | Kumar | waiter | 3333 |
| KEDAI02 | BGI Cawangan Bangi | Mei Ling | waiter | 4444 |
| KEDAI02 | KJG Cawangan Kajang | Hafiz | juruwang | 1111 |
| KEDAI02 | KJG Cawangan Kajang | Siti | waiter | 2222 |
| KEDAI03 | RUMAH Dapur Kak Ani | Kak Ani | juruwang | 1234 |

## Apa yang sengaja disediakan untuk diuji

| Perkara | Di mana | Untuk menguji |
|---|---|---|
| Dua vendor, 18 produk sama, **barcode sama** | KEDAI01, KEDAI02 | Kebocoran antara vendor; `UNIQUE(vendor_id, barcode)` |
| Pelan Asas (`pos` sahaja) lawan Pro (10 modul) | KEDAI01, KEDAI02 | Sekatan modul dan 403 |
| Dua kedai | KEDAI02 Bangi & Kajang | Isu kedai berbilang |
| `paper_width` 80 ditindih | KEDAI02 Kajang | Lebar resit per kedai (Fasa 5) |
| Harga Nasi Lemak RM 5.00 ditindih | KEDAI02 Kajang | `price_override` |
| Pesanan QR hidup, bayar kaunter atau online | KEDAI02 Bangi, meja M1 hingga M8 | `qr_token`, `qr_payment_options` |
| Peranti dapur dengan cetak automatik | KEDAI02 Bangi, D1 | Modul dapur (Fasa 9C) |
| Kedai online `s/kak-ani`, tiada meja | KEDAI03 | Ambil sendiri (Fasa 9E) |
| Gerbang sandbox, kunci kosong | KEDAI02 ToyyibPay, KEDAI03 Billplz | Isi kunci dari akaun ujian gerbang (Fasa 9D) |
| Air Mineral dikecualikan cukai | KEDAI01, KEDAI02 | `is_tax_exempt` |
| Milkshake & Aiskrim stok 0 | KEDAI01, KEDAI02 | Paparan "Habis" |
| Sejarah 7 hari, satu void, satu syif kurang RM 2.00 | Setiap kedai | Dashboard, laporan, sejarah, beza tunai |

Hari ini sengaja **kosong** dan tiada syif terbuka, supaya aliran buka syif
boleh diuji dari awal.

## Nota

- `seed --demo` boleh dijalankan semula tanpa menggandakan data. Sejarah
  jualan dijana semula dengan benih rawak tetap, jadi angkanya sama.
- `qr_token` meja dijana sekali sahaja. Seed semula tidak menukarnya, tetapi
  `fresh` memadam semua, jadi QR lama tidak sah lagi selepas `fresh`.
- Peranti belum didaftarkan (`device_token_hash` kosong). Pendaftaran
  dibina di Fasa 2.
