# Playbook Screenshot dengan Playwright MCP

Rujukan ini untuk situasi yang lebih rumit daripada "buka halaman dan rakam". Baca
bahagian yang berkaitan sahaja.

## Kandungan

1. [Tetapan asas yang mesti sama sepanjang sesi](#1-tetapan-asas)
2. [Kitaran kerja bagi setiap langkah](#2-kitaran-kerja)
3. [Merakam modal, dropdown dan menu](#3-modal-dropdown-dan-menu)
4. [Merakam elemen tunggal, bukan seluruh skrin](#4-elemen-tunggal)
5. [Menyediakan data supaya gambar kelihatan kemas](#5-menyediakan-data)
6. [Keadaan yang selalu terlupa dirakam](#6-keadaan-yang-selalu-terlupa)
7. [Masalah lazim dan penyelesaian](#7-masalah-lazim)

---

## 1. Tetapan asas

Jalankan sekali di permulaan sesi:

```
browser_resize → width: 1440, height: 900
browser_navigate → url: <URL sistem>
```

Kenapa 1440×900: cukup lebar untuk susun atur desktop dua panel tanpa menjadi terlalu
lebar sehingga teks mengecil apabila gambar dimuatkan ke halaman A4. Jika sistem yang
didokumentasikan adalah untuk telefon, guna 390×844 dan kekal dengan saiz itu.

Saiz mesti kekal sama untuk semua screenshot. Gambar yang berbeza saiz akan dipaparkan
pada skala berbeza dalam PDF, dan manual nampak seperti disiapkan tergesa-gesa.

## 2. Kitaran kerja

Untuk setiap langkah, ulang tiga perkara ini:

```
1. browser_snapshot              → dapatkan rujukan elemen sebenar
2. browser_click / browser_type  → lakukan tindakan
3. browser_take_screenshot       → filename: "docs/images/NN-nama.png", scale: "css"
```

Sentiasa ambil `browser_snapshot` sebelum bertindak, bukan meneka selector. Selector yang
diteka akan gagal secara senyap atau menekan elemen yang salah, dan anda hanya perasan
selepas melihat gambar yang tidak masuk akal.

`filename` menerima laluan relatif dari akar projek, jadi `docs/images/03-cari-produk.png`
terus jatuh di tempat yang betul.

Selepas siap: `browser_close`, kemudian buang folder `.playwright-mcp/` di akar projek.

## 3. Modal, dropdown dan menu

Modal dan menu tertutup apabila fokus hilang, jadi susunan tindakan penting:

- Klik pemicu → terus ambil screenshot. **Jangan** ambil `browser_snapshot` tambahan yang
  tidak perlu di antaranya jika sistem menutup menu pada klik luar.
- Jika modal ada animasi masuk, guna `browser_wait_for` dengan teks yang muncul dalam
  modal itu sebelum merakam. Merakam terlalu awal menghasilkan gambar modal separuh lut
  sinar yang kelihatan rosak.
- Untuk dropdown asli `<select>`, senarai pilihannya dilukis oleh sistem pengendalian dan
  **tidak akan muncul** dalam screenshot. Rakam keadaan selepas pilihan dibuat, dan
  terangkan pilihan yang ada dalam bentuk jadual di dalam teks manual.
- Untuk modal yang panjang melebihi skrin, pertimbangkan dua screenshot: bahagian atas
  dan bahagian bawah selepas skrol — lebih terbaca daripada satu gambar `fullPage`.

## 4. Elemen tunggal

Apabila langkah hanya melibatkan satu kawasan kecil (contoh: satu kad produk, satu baris
troli, satu bar carian), rakam elemen itu sahaja:

```
browser_take_screenshot → target: <ref dari snapshot>, filename: "docs/images/NN-nama.png"
```

Gambar elemen tunggal jauh lebih berkesan untuk langkah terperinci, kerana pembaca tidak
perlu mencari kawasan yang dimaksudkan dalam skrin penuh. Guna screenshot skrin penuh
untuk langkah yang menunjukkan orientasi atau perubahan pada dua panel serentak.

## 5. Menyediakan data

Screenshot mewarisi keadaan data sistem, jadi data yang kemas menghasilkan manual yang
kemas. Sebelum merakam:

- Pastikan senarai tidak kosong dan tidak juga penuh sesak. Tiga hingga enam item dalam
  troli/senarai adalah paling mudah difahami.
- Guna nama dan nilai yang bermakna. `Nasi Lemak — RM 6.50` mengajar pembaca; `Test 1 — RM 0.00`
  tidak mengajar apa-apa dan nampak seperti sistem belum siap.
- Bersihkan keadaan sebelum aliran baharu bermula. Jika sistem menyimpan data dalam
  `localStorage`, guna `browser_evaluate` untuk mengosongkannya, kemudian muat semula.
- Elakkan data peribadi sebenar (nama penuh pelanggan, nombor telefon, e-mel, alamat).
  Manual ini akan diedarkan; gantikan dengan data contoh.

## 6. Keadaan yang selalu terlupa

Manual yang baik merakam bukan sahaja laluan berjaya, tetapi juga keadaan yang pengguna
akan temui pada hari sebenar:

- **Keadaan kosong** — troli kosong, senarai tiada rekod, carian tiada padanan
- **Butang dilumpuhkan** — dan sebab ia dilumpuhkan
- **Mesej ralat pengesahan** — medan wajib tidak diisi, nilai tidak sah
- **Keadaan tidak tersedia** — stok habis, rekod terkunci
- **Mesej kejayaan** — apa yang pengguna nampak selepas tindakan berjaya
- **Hasil akhir** — resit, laporan, dokumen tercetak

Keadaan-keadaan inilah yang paling kerap menjadi punca pengguna menelefon meminta
bantuan, jadi ia memberi nilai paling tinggi dalam manual.

## 7. Masalah lazim

| Masalah | Sebab | Penyelesaian |
|---|---|---|
| Gambar kosong atau putih | Rakaman berlaku sebelum halaman siap | `browser_wait_for` pada teks yang sepatutnya muncul, kemudian rakam |
| Modal tiada dalam gambar | Modal tertutup akibat klik/tindakan lain | Rakam terus selepas klik pemicu |
| Teks terlalu kecil dalam PDF | Guna `fullPage` pada halaman panjang | Guna screenshot viewport, atau pecahkan kepada beberapa gambar |
| Gambar berbeza saiz | `browser_resize` dipanggil di tengah sesi | Tetapkan saiz sekali di permulaan sahaja |
| Klik tiada kesan | Selector diteka, bukan dari snapshot | Ambil `browser_snapshot` dahulu dan guna `ref` sebenar |
| Fail tidak dijumpai selepas rakaman | Nama fail mutlak atau bermula dengan `./` | Guna laluan relatif seperti `docs/images/01-nama.png` |
