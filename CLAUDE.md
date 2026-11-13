Sila guna bahasa melayu bukan indonesia ketika menjawab
Sila guna bahasa melayu untuk display perkataan dalam sistem atau website
Sila guna bahasa inggeris untuk filename dan coding

Jangan pakai inline CSS, pakai Bootstrap sahaja. Tambahan yang dibenarkan:
- `css/theme.css` — tema "Pandan & Kunyit" (pemboleh ubah Bootstrap + kelas `kp-*`).
  Guna saiz standard di situ (`--kp-control*`, `--kp-text-*`), jangan cipta saiz baharu
- Ikon: **Font Awesome 6 Free** dari `vendor/fontawesome/` — bukan emoji untuk ikon antara muka
- Fon: Figtree + Bricolage Grotesque dari `vendor/fonts/` — jangan pautkan Google Fonts

Sentiasa pakai job class, jangan pakai God Controller

Untuk bahasa pengaturcara PHP sila gunakan vanila code untuk senang faham, jangan guna laravel struktur

## Kerja sedang berjalan — KedaiPOS SaaS

Sistem ini sedang dibina semula sebagai SaaS multi-tenant: satu kod, satu
pangkalan data, banyak vendor. Sebelum menulis sebarang kod berkaitan, baca
dua fail ini dahulu:

- `docs/migrasi-mysql/PELAN.md` — keputusan reka bentuk & skema 39 jadual (rujukan tetap)
- `docs/migrasi-mysql/PROGRES.md` — fasa mana sudah siap, mana seterusnya

**Peraturan paling penting:** `vendor_id` datang dari sesi, tidak pernah dari
`$_POST` atau `$_GET`. Setiap pertanyaan menapis `vendor_id`. Butirannya dalam
PELAN.md bahagian 3. `outlet_id` pula skop perniagaan — boleh dari input,
tetapi mesti disahkan milik vendor semasa.

Pangkalan data projek ini ialah `pos_saas`. Pangkalan data `tuisyen` pada
pelayan MySQL yang sama milik projek lain — jangan sentuh.