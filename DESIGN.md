# MotorQu — Design System & UI Specification

Dokumen ini adalah spesifikasi desain antarmuka (*UI/UX Design Specification*) untuk aplikasi **MotorQu**. Dokumen ini dirancang sebagai acuan tunggal untuk mendesain di **Figma** maupun diimpor/di-*prompt* ke **Google Stitch**.

---

## 1. Panduan & Prinsip Desain (*Design Philosophy*)

* **Target Pengguna**: Pemilik motor perorangan dan keluarga yang berbagi motor.
* **Karakter Desain**:
  * **Bersih & Fungsional**: Bebas dari elemen yang tidak perlu (*distraction-free*).
  * **Informatif & Jelas**: Status oli motor langsung terbaca dalam 1 detik (Aman vs Melewati Batas).
  * **Material 3 Modern**: Menggunakan sudut membulat (*rounded corners* 16–20px), elevasi halus (*subtle shadows*), dan hierarki warna kontras.
* **Ukuran Frame Rekomendasi (Mobile Canvas)**:
  * Lebar: `390 px` (atau `360 px` standar Android)
  * Tinggi: `844 px` (atau `800 px`)

---

## 2. Design Tokens (Warna, Tipografi, Spacing)

### A. Palet Warna (*Color Palette*)

| Token | Nilai Hex | Penggunaan |
|---|---|---|
| **Primary (Blue)** | `#1976D2` | Warna utama, tombol aktif, ikon utama |
| **Primary Gradient Start** | `#1E88E5` | Gradien tombol tambah `+`, header card |
| **Primary Gradient End** | `#1565C0` | Ujung gradien biru-indigo |
| **Success (Green)** | `#2E7D32` | Badge "Aman", badge "Grup", status oli baik |
| **Success Background** | `#E8F5E9` | Latar badge hijau muda |
| **Warning (Amber)** | `#F57C00` | Perlu cek oli segera, tombol aksi Catat Oli |
| **Warning Background** | `#FFF3E0` | Latar badge oranye muda |
| **Danger (Red)** | `#D32F2F` | Status melewati target KM, tombol Hapus/Keluar |
| **Danger Background** | `#FFEBEE` | Latar peringatan merah muda |
| **Surface (Background)** | `#F8FAFC` | Latar belakang layar aplikasi |
| **Card / Surface White** | `#FFFFFF` | Latar belakang kartu, form, dan dialog |
| **Text Primary** | `#0F172A` | Teks judul, nilai angka KM, teks tebal |
| **Text Secondary** | `#64748B` | Teks keterangan, subtitle, placeholder |
| **Border / Divider** | `#E2E8F0` | Garis pemisah, outline form |

### B. Tipografi (*Typography* - Font: Roboto / Inter)

| Gaya | Ukuran | Bobot (*Weight*) | Penggunaan |
|---|---|---|---|
| **Display / App Title** | 24 px | Bold (700) | Judul "MotorQu" di header |
| **Heading 1** | 20 px | Bold (700) | Judul layar, nama motor di detail |
| **Heading 2** | 16 px | SemiBold (600) | Judul kartu, judul seksi |
| **Body Bold** | 14 px | SemiBold (600) | Nilai KM, label tombol, teks penting |
| **Body Regular** | 14 px | Regular (400) | Teks isi form, deskripsi |
| **Caption / Subtitle** | 12 px | Regular (400) | Keterangan tanggal, plat nomor |
| **Badge / Micro** | 10–11 px | Bold (700) | Teks chip status ("Pribadi", "Grup", "Owner") |

### C. Radius & Shadows
* **Card Radius**: `16 px`
* **Button Radius**: `12 px` (Full pill `24 px` untuk chip/filter)
* **Dialog / BottomSheet Radius**: `24 px` (sudut atas)
* **Card Shadow**: `Y: 2, Blur: 8, Color: rgba(0, 0, 0, 0.06)`
* **Floating Button Shadow**: `Y: 4, Blur: 12, Color: rgba(25, 118, 210, 0.35)`

---

## 3. Komponen Global (*Global Components*)

### 1. Bottom Navigation Bar (3 Item)
* **Struktur Frame**: Tinggi 64 px, latar putih `#FFFFFF`, border atas `#E2E8F0`.
* **Elemen**:
  * **Kiri**: Ikon Motor + label `"Motor"` (Aktif: `#1976D2`, Inaktif: `#64748B`).
  * **Tengah**: Tombol bulat mengapung diameter `52 px`, gradien biru-indigo, ikon `+` warna putih `32 px`.
  * **Kanan**: Ikon Orang + label `"Profil"`.

### 2. Status Badge / Pill
* **Badge Pribadi**: Latar `#E3F2FD`, Teks & Ikon Orang `#1976D2`.
* **Badge Grup**: Latar `#E8F5E9`, Teks & Ikon Grup `#2E7D32`.
* **Pill Kondisi Aman**: Latar `#E8F5E9`, Ikon Centang Hijau, teks `"Kondisi aman (sisa ~X KM)"`.
* **Pill Kondisi Bahaya**: Latar `#FFEBEE`, Ikon Tanda Seru Merah, teks `"Sudah melewati target! Segera ganti oli."`.

---

## 4. Rincian Desain Layar demi Layar (*Screen Specifications*)

### Layar 1: Login Screen (`/login`)
* **Tujuan**: Autentikasi Google satu ketukan (*one-tap sign-in*).
* **Elemen**:
  * Logo MotorQu di tengah (ukuran 96x96 px).
  * Teks Judul: `"MotorQu"` (28 px, Bold).
  * Teks Tagline: `"Aplikasi Pencatatan Oli Motor Keluarga"` (14 px, warna abu-abu).
  * Tombol Utama: Outlined / Filled Button `"Masuk dengan Google"` dengan logo Google di sisi kiri.
  * Footer: Teks copyright / informasi versi.

---

### Layar 2: Beranda Motor / Dashboard (`/home` - Tab 0)
* **Header**:
  * Salam personal: `"Halo, [Nama]! 👋"` (14 px, Text Secondary).
  * Judul: `"MotorQu"` (24 px, Bold).
  * Avatar foto profil Google di kanan atas (diameter 44 px).
* **Overview Card (Ringkasan Status)**:
  * Kartu gradien biru gelap-indigo (`#1976D2` ke `#1565C0`), radius 16 px.
  * 3 Kolom metrik yang dipisah garis tipis:
    1. **Total Motor**: [Jumlah] motor (ikon motor putih).
    2. **Oli Aman**: [Jumlah] (ikon centang hijau muda).
    3. **Perlu Dicek**: [Jumlah] (ikon warning kuning/merah).
* **Filter Chips**:
  * Baris horizontal tombol filter pill:
    * `[ Semua (3) ]` (Aktif: border & teks biru muda)
    * `[ Pribadi (1) ]`
    * `[ Grup (2) ]`
* **Daftar Kartu Motor**:
  * Setiap kartu motor menampilkan:
    * Ikon motor di kotak membulat (biru untuk pribadi, hijau untuk grup).
    * Nama motor: misal `"Vario 160"` (Bold 16 px).
    * Subtitle: `"Honda Vario • B 1234 XYZ"`.
    * Badge kanan atas: `[ Pribadi ]` atau `[ Grup ]`.
    * Baris Info: `"Oli Terakhir: 12.000 KM"` & `"Target: 14.000 KM"`.
    * Status Pill di bawah: Hijau jika aman, Merah jika melewati batas.
* **Empty State (Jika belum ada motor)**:
  * Ilustrasi ikon motor besar abu-abu.
  * Teks: `"Belum Ada Motor"`.
  * Tombol: `"Tambah Motor Sekarang"`.

---

### Layar 3: Detail Motor (`/motor`)
* **Header / AppBar**: Tombol Back `←`, Judul: `[Nama Motor]`, Tombol Edit `✏️` di kanan atas.
* **Tombol Aksi Utama**: Tombol lebar penuh `"Catat Ganti Oli"` warna kuning-oranye/biru (tinggi 48 px).
* **Seksi Timeline Riwayat Oli**:
  * Judul: `"Riwayat Oli"`.
  * Komponen Timeline Vertikal:
    * Titik bulat biru (lingkaran 24 px dengan ikon centang).
    * Garis vertikal penghubung biru muda (tebal 2 px) ke catatan berikutnya.
    * Kartu Catatan di kanan garis:
      * Angka KM: `"14.500 KM"` (Bold 16 px).
      * Tanggal: `"20 Okt 2026"` • Nama pencatat: `"Ridlo FW"`.
      * Tombol Hapus (ikon tong sampah merah di sisi kanan kartu).
* **Seksi Info Motor**:
  * Kartu spesifikasi teknis motor:
    * Merk, Model, Plat Nomor, Tahun, Warna.
    * KM Terakhir, Target Berikutnya, Interval Pengingat (misal `2.000 KM`).
    * Kepemilikan: `Pribadi` / `Grup Keluarga`.
* **Tombol Bawah**: Tombol Outlined merah `"Hapus Motor"`.

---

### Layar 4: Form Catat Ganti Oli (`/addOil`)
* **AppBar**: Tombol Back `←`, Judul: `"Catat Ganti Oli"`.
* **Form Inputs**:
  1. **Dropdown Pilih Motor** *(Wajib)*:
     * Menampilkan nama motor + merk (contoh: `"Vario 160 (Honda Vario)"`).
  2. **Tanggal Ganti Oli** *(Wajib)*:
     * Tombol pemilih tanggal kalender (format: `20 Oktober 2026`).
  3. **KM Saat Ini** *(Wajib)*:
     * Input angka (contoh: `14500`), suffix `"KM"`.
     * Helper text: harus lebih besar atau sama dengan KM terakhir.
* **Tombol Simpan**: Tombol penuh di bawah `"Simpan Catatan Oli"` (tinggi 48 px).

---

### Layar 5: Form Tambah / Edit Motor (`/addMotor`)
* **AppBar**: Judul `"Tambah Motor"` atau `"Edit Motor"`.
* **Form Fields**:
  1. Nama Panggilan Motor *(Wajib)*: `contoh: Beat Merah`
  2. Merk *(Wajib)*: `Honda, Yamaha, Suzuki, dll`
  3. Model *(Wajib)*: `Beat CBS, Vario 160, NMax`
  4. Plat Nomor *(Opsional)*: `B 1234 XYZ`
  5. Tahun Pembuatan *(Opsional)*: `2022`
  6. Warna Motor *(Opsional)*: `Hitam Glossy`
  7. KM Saat Ini / Awal *(Hanya saat Tambah Motor)*: `contoh: 12000`
  8. Interval Pengingat Oli *(Wajib)*: `2000 KM` (default)
* **Seksi Kepemilikan (Radio List)**:
  * Radio 1: `Motor Pribadi` (Hanya terlihat di akun Anda).
  * Radio 2: `Bagikan ke Grup Keluarga`.
  * *(Jika memilih grup dan user punya banyak grup)*: Muncul dropdown pilih grup target.
* **Tombol Simpan**: `"Simpan Motor"`.

---

### Layar 6: Kelola Grup Keluarga (`/group`)
* **AppBar**: Judul `"Kelola Grup Keluarga"`, tombol menu titik tiga `⋮` (Buat Grup Baru / Gabung Kode).
* **Group Switcher (Jika punya > 1 grup)**:
  * Kartu dropdown pemilih grup aktif di bagian atas (contoh: `"Grup: Keluarga Ridlo ▼"`).
* **Kartu Info Grup Aktif**:
  * Avatar ikon grup.
  * Nama Grup + Ikon Pensil `✏️` untuk ubah nama grup langsung.
  * Status: `"Anda adalah Pemilik Grup"` atau `"Anggota"`.
  * Tombol: `"Undang Anggota"` (membuka popup kode 6 digit).
* **Seksi "Motor di Grup Ini"**:
  * Header seksi + tombol teks `"+ Tambah Motor"`.
  * Daftar motor yang sedang dibagikan di grup ini.
  * Tombol ikon minus/keluarkan untuk motor milik sendiri.
* **Seksi "Anggota Grup"**:
  * Daftar foto profil, nama anggota, email, dan chip `"Owner"` / `"Anda"`.
* **Tombol Keluar Grup**: Tombol outlined merah `"Keluar dari Grup"`.

---

### Layar 7: Profil & Setelan (`/profile` - Tab 1)
* **Header Profil**:
  * Foto profil Google besar (radius 34 px).
  * Nama lengkap (Bold 18 px).
  * Email Google.
  * Badge hijau/biru: `"Akun Google Aktif"`.
* **Grup Menu 1: Grup Keluarga**:
  * Kartu menu `"Kelola Grup Keluarga"`, subtitle jumlah grup yang diikuti.
* **Grup Menu 2: Pengingat & Notifikasi**:
  * Baris Switch: `"Pengingat Ganti Oli"` (On / Off berkala 30 hari).
  * Sub-baris: `"Informasi & Tes Notifikasi"` (klik untuk membuka popup info + tombol tes notifikasi).
* **Grup Menu 3: Sistem & Pembaruan**:
  * Baris: `"Versi Aplikasi"` → teks subtitle `"v1.0.5 (Build 6)"`.
  * Tombol kanan: `"Cek Update"` (memicu pengecekan rilis otomatis).
* **Tombol Keluar**: Tombol bordered merah `"Keluar dari Akun"`.

---

## 5. Modal, Bottom Sheets, & Dialogs

### A. Bottom Sheet Aksi Cepat `+`
* Muncul saat tombol bulat tengah `+` ditekan.
* Menggunakan 4 kartu grid aksi cepat (2x2):
  1. 🛠️ **Catat Oli** (latar kuning muda) → Buka Form Catat Oli.
  2. 🏍️ **Tambah Motor** (latar biru muda) → Buka Form Tambah Motor.
  3. 👥 **Buat Grup** (latar hijau muda) → **Langsung muncul Dialog Buat Grup**.
  4. 🔑 **Masuk Grup** (latar ungu muda) → **Langsung muncul Dialog Masuk Kode**.

### B. Dialog Buat Grup
* Judul: `"Buat Grup Keluarga"`.
* Input: Nama grup baru.
* Tombol: `Batal` & `Buat Grup`.

### C. Dialog Masuk Grup (Kode Undangan)
* Judul: `"Masuk ke Grup"`.
* Input: Kode 6 huruf kapital/angka (autofocus, max 6 karakter).
* Tombol: `Batal` & `Gabung`.

### D. Dialog Progress Download Update
* Muncul saat menekan "Unduh & Install" di Cek Update.
* Tidak bisa ditutup manual (*barrierDismissible: false*).
* Menampilkan:
  * Progress Bar animasi biru.
  * Teks indikator MB riil: `"18.5 MB / 56.4 MB (32%)"`.
  * Status auto-resume jika sinyal sempat terputus: `"Melanjutkan unduhan (18.5 MB tersimpan)..."`.

---

## 6. Cara Menggunakan Dokumen Ini di Figma & Google Stitch

### Opsi A: Mendesain di Figma
1. Buat canvas baru di Figma.
2. Buat Frame ukuran Mobile (misal: **iPhone 14 / Android Large - 390x844 px**).
3. Buat 7 Frame utama sesuai nama layar di Bab 4.
4. Gunakan token warna dari Bab 2 (simpan sebagai *Color Styles* di Figma).
5. Buat komponen reusable dari Bab 3 (*BottomNavBar*, *MotorCard*, *StatusPill*).
6. Susun elemen tiap layar mengikuti daftar komponen di Bab 4.

### Opsi B: Menggunakan Google Stitch
1. Google Stitch dapat membaca file **`DESIGN.md`** ini secara langsung.
2. Unggah atau tempel isi file `DESIGN.md` ini ke Google Stitch untuk meng-generate *Design System* dan komponen visual secara otomatis.
3. Prompt perintah ke Stitch per layar, contoh:
   > *"Generate mobile screen for 'Beranda Motor' based on Section 4 Screen 2 in DESIGN.md, using Material 3 and our defined Blue/Green color tokens."*
