# Senarai Semak Perubahan Staged

Rujukan ini dibaca semasa **Langkah 4 (semakan isu)**. Tujuannya bukan untuk ditanda satu
per satu dalam laporan, tetapi untuk memberi anda tempat mencari apabila diff kelihatan
"okey sahaja" — kebanyakan pepijat yang lolos ke commit datang daripada kategori di bawah.

Susunan mengikut kos: perkara di bahagian atas paling mahal untuk diperbaiki selepas
ia masuk ke sejarah repo.

---

## 1. Rahsia dan data sensitif (paling mahal)

Sekali rahsia masuk ke dalam commit, membuangnya bermakna menulis semula sejarah repo.
Jadi ini keutamaan pertama, walaupun ia jarang berlaku.

- Kata laluan, token, kunci API ditulis terus dalam kod
- Fail `.env`, `config.local.php`, sijil, kunci peribadi ter-stage tanpa sengaja
- Endpoint dalaman, IP pelayan pengeluaran, nama pangkalan data sebenar
- Data pelanggan sebenar dalam fail ujian atau seed (nama, no. telefon, no. IC)

Jika anda jumpa: laporkan sebagai **Kritikal**. Kemudian **semak sejarah fail itu sebelum
memberi nasihat pemulihan** — kerana nasihatnya berbeza sama sekali bergantung pada satu
fakta:

```bash
git log --all --oneline -- <laluan-fail>
```

- **Tiada output** — fail itu belum pernah masuk mana-mana commit. `git reset` untuk
  meng-unstage sudah memadai. Katakan begitu dengan jelas. Rahsia itu belum masuk sejarah,
  jadi tiada penulisan semula diperlukan, dan pengguna boleh bernafas lega.
- **Ada output** — rahsia itu sudah berada dalam sejarah repo. Unstage tidak membantu; ia
  kekal dalam commit lama. Nyatakan bahawa rahsia itu perlu ditukar (rotate) di tempat ia
  dikeluarkan, dan penulisan semula sejarah (`git filter-repo`) diperlukan jika repo sudah
  dikongsi.

Sebabnya penting: memberi amaran "kunci anda dah bocor selama-lamanya, kena rotate" kepada
seseorang yang sebenarnya cuma perlu menaip `git reset` adalah nasihat yang menakutkan
tanpa keperluan, dan ia menghakis kepercayaan terhadap laporan anda. Sebaliknya, gagal
memberi amaran itu apabila ia **memang** perlu adalah kegagalan yang jauh lebih teruk.
Semakan satu baris di atas membezakan kedua-duanya, jadi jalankan sahaja.

## 2. Fail yang tidak sepatutnya staged

Ini paling kerap berlaku selepas `git add -A` atau `git add .`:

- `node_modules/`, `vendor/` yang dimuat turun, folder `build/`, `dist/`
- Fail log, fail sementara, `*.bak`, output nyahpepijat
- Fail besar (imej mentah, PDF, arkib) yang membengkakkan repo selama-lamanya
- Fail konfigurasi peribadi editor

Bandingkan dengan `.gitignore`. Jika `.gitignore` sepatutnya menangkapnya tetapi tidak,
sebab biasanya fail itu sudah dijejak sebelum peraturan ditambah.

## 3. Perubahan tidak lengkap atau tidak berkaitan

- Fungsi dipanggil tetapi belum ditakrifkan, atau sebaliknya (kod mati)
- Satu bahagian penamaan semula dibuat, bahagian lain tertinggal — cari nama lama
  yang masih wujud dalam fail yang tidak disentuh
- Import/`require` ditambah tetapi tidak digunakan, atau dibuang sedangkan masih dipakai
- Dua perubahan yang tiada kaitan bercampur dalam satu commit — ini menyukarkan
  `git revert` kemudian hari, jadi cadangkan pecahkan kepada dua commit

## 4. Sisa kerja pembangunan

- `console.log`, `var_dump`, `print_r`, `dd()` yang tertinggal
- Kod yang dikomen keluar tanpa penjelasan (sejarah Git sudah menyimpannya — buang sahaja)
- `TODO`/`FIXME` baharu: terima jika ia menanda kerja masa depan yang jelas, persoalkan
  jika ia menanda sesuatu yang sepatutnya siap dalam perubahan ini sendiri
- Ujian yang difokuskan (`.only`, `fdescribe`) — ini senyap-senyap melangkau ujian lain
- Penanda konflik merge (`<<<<<<<`, `>>>>>>>`) belum dibersihkan

## 5. Ketepatan logik

Baca baris `+` sebagai kod baharu, bukan sebagai teks:

- Syarat terbalik, `>=` lawan `>`, `&&` lawan `||`
- Gelung bermula pada indeks salah, atau terlepas elemen terakhir
- Nilai `null`/`undefined` tidak diperiksa sebelum digunakan
- Pengiraan wang menggunakan nombor apungan tanpa pembundaran — untuk sistem jualan,
  ini menyebabkan baki tidak seimbang beberapa sen
- Ralat tidak ditangkap; janji (`promise`) tanpa `catch`
- Perubahan yang mengandaikan data sentiasa wujud (troli kosong, senarai kosong, 0 item)

## 6. Konvensyen projek

Jika repo mempunyai `CLAUDE.md`, `CONTRIBUTING.md`, `.editorconfig`, atau fail linter,
baca dan semak diff terhadap peraturan **sebenar** dalam fail tersebut. Jangan hafal
peraturan projek lain — setiap repo berbeza.

Contoh peraturan yang lazim wujud dan mudah dilanggar tanpa sedar:
- Larangan inline CSS (`style="..."`) apabila projek menetapkan Bootstrap sahaja
- Bahasa untuk teks paparan berbanding bahasa untuk nama fail dan pengecam kod
- Struktur kelas/modul tertentu yang mesti dipatuhi
- Konvensyen penamaan fail

Jika tiada fail konvensyen dalam repo, katakan begitu dan langkau bahagian ini —
lebih baik daripada mereka-reka peraturan.

## 7. Kesan kepada bahagian lain

- Perubahan tandatangan fungsi: siapa lagi memanggilnya? Cari dengan `grep`.
- Perubahan bentuk data yang disimpan (`localStorage`, skema DB): adakah data lama
  masih boleh dibaca? Perubahan begini memecahkan pengguna sedia ada secara senyap.
- Kelas atau ID CSS dibuang: adakah masih dirujuk dalam HTML atau JS?
- Teks paparan diubah: adakah ujian atau dokumentasi merujuk teks lama?

---

## Apa yang **tidak** perlu dilaporkan

Menahan diri di sini sama pentingnya dengan menemui isu. Laporan yang penuh
dengan bunyi latar akan diabaikan sepenuhnya, termasuk isu betul di dalamnya.

- Citarasa gaya yang tiada dalam peraturan projek (petik tunggal vs berganda, dsb.)
- Cadangan menulis semula kod yang berfungsi tanpa sebab konkrit
- Isu dalam kod yang **tidak** disentuh oleh diff ini — kecuali ia terus rosak
  disebabkan perubahan yang staged
- "Tambah lebih banyak ujian" atau "tambah komen" sebagai nasihat umum tanpa
  menunjuk kepada bahagian tertentu yang benar-benar mengelirukan
- Isu yang anda tidak dapat tunjukkan fail dan barisnya
