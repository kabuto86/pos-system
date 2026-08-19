# Panduan Penulisan Manual dalam Bahasa Melayu

Rujukan gaya bahasa untuk manual yang dijana. Matlamatnya: pengguna yang tidak biasa
dengan komputer boleh ikut tanpa tersekat, dan pembaca yang biasa boleh imbas dengan
cepat.

## Guna Bahasa Melayu Malaysia, bukan Indonesia

Perbezaan ini kerap terlepas dan segera dirasakan janggal oleh pembaca Malaysia.

| Guna | Jangan guna |
|---|---|
| pelayar | peramban |
| but | tombol |
| tekan / klik | ketuk |
| perisian | piranti lunak |
| but butang **Bayar** | tekan tombol Bayar |
| muat naik / muat turun | unggah / unduh |
| kemas kini | pembaruan |
| tetapan | pengaturan |
| log masuk | masuk / login (dalam teks berterusan) |
| memaparkan | menampilkan |
| troli | keranjang |
| jadual | tabel |
| skrin | layar |
| fail | berkas |
| senarai | daftar |
| pilihan | opsi |
| kandungan | konten |

Nota: perkataan "butang" ialah istilah Malaysia yang betul untuk *button* — baris kedua
dalam jadual di atas merujuk kepada "tombol" sahaja sebagai bentuk Indonesia.

## Arahan ditulis sebagai kata kerja perintah

Manual memberi arahan, jadi tulis secara langsung. Pembaca sedang duduk di depan sistem
dan mahu tahu apa yang perlu dibuat sekarang.

| Baik | Lemah |
|---|---|
| Tekan butang **Bayar**. | Pengguna boleh menekan butang Bayar. |
| Taip nama produk dalam medan **Cari produk**. | Terdapat medan carian yang boleh digunakan. |
| Pilih kategori **Minuman** untuk menapis senarai. | Sistem menyediakan fungsi penapisan kategori. |
| Masukkan jumlah wang yang diterima daripada pelanggan. | Jumlah wang perlu dimasukkan. |

## Nama antara muka ditebalkan dan disalin tepat

Tulis `**Bayar**`, bukan `butang bayar` atau `butang untuk membayar`. Ejaan dan huruf
besar mesti sama persis dengan yang dipaparkan di skrin, termasuk jika sistem menggunakan
Bahasa Inggeris — kalau butang tertulis "Checkout", tulis **Checkout**, bukan
terjemahannya. Pembaca mencari perkataan itu dengan mata di skrin; terjemahan yang tidak
sepadan menyebabkan mereka tersekat.

## Setiap langkah ada contoh konkrit

Selepas menerangkan cara umum, berikan satu contoh sebenar daripada sistem:

> Contoh: menekan **Nasi Lemak** membuka tetingkap dengan tiga kumpulan pilihan —
> **Lauk**, **Kepedasan**, dan **Tambahan**.

Contoh konkrit mengesahkan kepada pembaca bahawa mereka berada di tempat yang betul,
kerana ia sepadan dengan apa yang mereka lihat pada gambar dan pada skrin mereka.

## Nota, petua dan amaran

Guna blockquote dalam Markdown dan `alert` Bootstrap dalam HTML:

```markdown
> **Nota:** Butang **Bayar** dilumpuhkan selagi troli kosong.

> **Petua:** Tekan kad produk yang sama berulang kali untuk menambah kuantiti.

> **Amaran:** Transaksi yang telah disahkan tidak boleh dibatalkan.
```

- **Nota** — maklumat yang menjelaskan kelakuan sistem
- **Petua** — jalan pintas yang menjimatkan masa
- **Amaran** — tindakan yang tidak boleh diundur atau boleh menyebabkan kehilangan data

Letakkan tepat di langkah berkaitan, bukan dikumpulkan di hujung dokumen. Amaran yang
dibaca selepas kesilapan berlaku tidak berguna.

## Istilah teknikal

Kekalkan istilah yang memang dipaparkan sistem dalam Bahasa Inggeris, tetapi terangkan
sekali pada penggunaan pertama:

> Sistem jualan (Point of Sale) untuk kedai makan.

Selepas itu guna istilah Melayu secara konsisten. Jangan bertukar-tukar antara "troli"
dan "cart" dalam dokumen yang sama.

## Tarikh dan nombor

- Tarikh: `17 Ogos 2026` — nama bulan penuh dalam Bahasa Melayu
- Mata wang: `RM 6.50` — dengan jarak selepas RM, dua tempat perpuluhan
- Peratus: `6%` — tanpa jarak
- Masa: `2:30 petang` atau `14:30`, pilih satu dan kekal dengannya

Bulan dalam Bahasa Melayu: Januari, Februari, Mac, April, Mei, Jun, Julai, Ogos,
September, Oktober, November, Disember.

## Ayat pendek

Satu ayat, satu idea. Ayat manual yang melebihi dua baris biasanya boleh dipecah tanpa
kehilangan apa-apa makna. Pembaca manual sedang mengimbas sambil bekerja, bukan membaca
esei.

| Baik | Lemah |
|---|---|
| Tekan **Bayar**. Tetingkap bayaran akan terbuka. | Selepas anda menekan butang Bayar, sistem kemudiannya akan memaparkan sebuah tetingkap bayaran di mana anda boleh memasukkan jumlah wang. |
