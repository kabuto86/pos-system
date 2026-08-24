Sila guna bahasa melayu bukan indonesia ketika menjawab
Sila guna bahasa melayu untuk display perkataan dalam sistem atau website
Sila guna bahasa inggeris untuk filename dan coding

Jangan pakai inline CSS, pakai Bootstrap sahaja

Sentiasa pakai job class, jangan pakai God Controller

Untuk bahasa pengaturcara PHP sila gunakan vanila code untuk senang faham, jangan guna laravel struktur

## Kerja sedang berjalan — migrasi ke MySQL

Sistem ini sedang dimigrasikan dari localStorage ke MySQL + PHP vanila.
Sebelum menulis sebarang kod berkaitan, baca dua fail ini dahulu:

- `docs/migrasi-mysql/PELAN.md` — keputusan reka bentuk & skema 14 jadual (rujukan tetap)
- `docs/migrasi-mysql/PROGRES.md` — fasa mana sudah siap, mana seterusnya

Pangkalan data projek ini ialah `pos_system`. Pangkalan data `tuisyen` pada
pelayan MySQL yang sama milik projek lain — jangan sentuh.