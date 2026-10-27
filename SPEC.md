# SPEC v2 â€” MotorQu (Aplikasi Pencatatan Oli Motor)

> Status: Revisi v2 (disederhanakan sesuai arahan user)  
> Project Firebase: `motorqu-e81dd` Â· Package Android: `com.motorqu.app` Â· Region: asia-southeast2 (Jakarta)  
> Dokumen ini adalah acuan tunggal implementasi aplikasi.

---

## 1. PERUBAHAN UTAMA DARI v1 KE v2 (CHANGELOG)

| Bagian | v1 (Sebelumnya) | v2 (Revisi Sekarang) | Alasan |
|---|---|---|---|
| **Navigasi bawah** | 4 tab (Motor, Riwayat, Grup, Profil) | **3 item: [Motor] [ + ] [Profil]** | Lebih simpel, navigasi bersih |
| **Tab Riwayat** | Tab terpisah | **Dihapus**; riwayat langsung ada di dalam detail motor | Konteks motor & riwayat menyatu |
| **Tab Grup** | Tab terpisah | **Pindah ke dalam Profil** | Jarang dibuka setelah setup awal |
| **Input ganti oli** | Banyak field (merk, volume, filter, bengkel, biaya) | **Hanya Tanggal + KM** (catatan opsional dihapus dulu) | Fokus 100% pada fungsi inti |
| **Data motor** | Tahun wajib | **Tahun jadi opsional** | Fleksibel |
| **Storage / Foto** | Butuh aktivasi manual di console | **Ditunda ke v2** | Menghilangkan 1 blocker manual |
| **Export CSV** | Direncanakan di v1 | **Dihapus dari v2** | Fokus MVP |
| **Pengingat (Reminder)** | Belum spesifik | **Fitur baru**: interval KM per motor (di Detail Motor), notifikasi lokal bulanan, toggle global di Profil | Sesuai request user & best practice |
| **Manajemen Grup** | 1 grup statis | **Multi-Grup**: Dukungan banyak grup, owner bisa kick anggota & angkat anggota jadi owner baru, ubah nama grup | Sesuai kebutuhan keluarga besar |
| **Sinkronisasi Notifikasi** | Manual per motor | **Sinkronisasi Otomatis**: Semua motor pribadi & grup otomatis terjadwal pengingat saat app dibuka | Pengingat aktif untuk seluruh motor |

---

## 2. PENDAPAT & BEST PRACTICE FITUR PENGINGAT (REMINDER)

### A. Format & Waktu Pemicu Notifikasi
- **Waktu:** Berjalan lokal di HP secara otomatis setiap **30 hari sekali** terhitung sejak tanggal penggantian oli terakhir.
- **Teks Notifikasi:**
  > ðŸ”” **Pengingat Servis MotorQu**  
  > *Jika KM motor [Nama Motor] sudah lebih dari [Target KM]KM, jangan lupa ganti oli yaa*  
  > *(Contoh nyata: "Jika KM motor Beat sudah lebih dari 26.500KM, jangan lupa ganti oli yaa")*
- **Aksi saat di-tap:** Notifikasi langsung membuka form **"Catat Ganti Oli"** dengan motor tersebut sudah otomatis terpilih.

---

### B. Best Practice: Di Mana Setting Pengingat Diletakkan?

**Kesimpulan Best Practice: Pemisahan Konfigurasi Spesifik vs Global.**

1. **Setting Interval KM (Spesifik per Motor) â†’ Di [Detail Motor] / Form [Tambah Motor]:**
   - **Kenapa di Detail Motor?** Setiap motor memiliki karakter dan rekomendasi pabrikan yang berbeda.
     - Motor matic (BeAT, Vario, Mio): biasanya 1.500 â€“ 2.000 km.
     - Motor bebek / sport (Supra, Vixion, CBR): biasanya 2.500 â€“ 3.000 km.
     - Motor tua vs motor baru bisa memiliki interval servis yang berbeda.
   - Oleh karena itu, interval KM **wajib melekat pada data motor masing-masing**, bukan disamaratakan.
   - Lokasi:
     - Diisi pertama kali saat **Tambah Motor** (default: `2000 km`).
     - Bisa diubah sewaktu-waktu di layar **Detail Motor â†’ Edit Motor**.

2. **Master Switch (On / Off Global) â†’ Di [Profil]:**
   - Di tab Profil ditaruh switch: `Izinkan Notifikasi Pengingat (Aktif/Nonaktif)`.
   - Fungsinya jika user sedang tidak ingin diganggu notifikasi tanpa harus mengubah setelan interval motor satu per satu.

---

## 3. STRUKTUR NAVIGASI (HANYA 3 ITEM)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                  LAYAR UTAMA                 â”‚
â”‚                                              â”‚
â”‚                                              â”‚
â”‚                                              â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚     ðŸï¸ Motor      â”‚     âž•       â”‚ ðŸ‘¤ Profil â”‚
â”‚    (Home/Semua)   â”‚ (Quick Actionâ”‚ (Akun &   â”‚
â”‚                   â”‚ Bottom Sheet)â”‚  Grup)    â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## 4. RINCIAN LAYAR & ALUR PENGGUNA

### A. Layar 1: Tab [Motor] (Home)
- Menampilkan **semua motor sekaligus** dalam bentuk daftar kartu (card list).
- Motor milik sendiri dan motor dari grup keluarga **berada di satu tempat**.
- Yang membedakan hanya **badge keterangan** di kartu:
  - `[ Motor Saya ]` (badge biru)
  - `[ Motor Grup Keluarga ]` (badge oranye/hijau)
- **Isi setiap kartu:**
  - Nama panggilan motor (misal: "Beat Kakak")
  - Plat nomor (misal: "B 1234 XYZ") & Merk/Tipe ("Honda BeAT")
  - Odometer ganti oli terakhir (misal: "24.500 km") & tanggal
  - Status servis: "Target ganti: 26.500 km (+2.000 km)"
- **Aksi:**
  - Tap salah satu kartu motor â†’ Membuka **Layar Detail Motor**.

---

### B. Layar 2: Detail Motor (Muncul saat kartu motor di-tap)
Struktur vertikal dari atas ke bawah:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ â† [Kembali]           Detail Motor    [Edit] â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ Beat Kakak                                   â”‚
â”‚ [ Motor Grup Keluarga ]                      â”‚
â”‚ B 1234 XYZ Â· Honda BeAT                      â”‚
â”‚                                              â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚ â”‚          [ âž• Update Ganti Oli ]          â”‚ â”‚ â† Tombol cepat
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ ðŸ“œ RIWAYAT OLI                               â”‚
â”‚                                              â”‚
â”‚   â—  18 Okt 2026 â€” 24.500 km                 â”‚
â”‚   â”‚  (Jarak pemakaian: 2.020 km)             â”‚ â† Garis penghubung
â”‚   â—  15 Agu 2026 â€” 22.480 km                 â”‚   vertikal
â”‚   â”‚  (Jarak pemakaian: 1.980 km)             â”‚
â”‚   â—  10 Jun 2026 â€” 20.500 km                 â”‚
â”‚      (Catatan awal)                          â”‚
â”‚                                              â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ â„¹ï¸ INFORMASI MOTOR                           â”‚
â”‚ â€¢ Merk / Tipe  : Honda BeAT                  â”‚
â”‚ â€¢ Plat Nomor   : B 1234 XYZ                  â”‚
â”‚ â€¢ Tahun        : 2021 (opsional)             â”‚
â”‚ â€¢ Warna        : Hitam (opsional)            â”‚
â”‚ â€¢ Pengingat    : Per 2.000 km                â”‚
â”‚ â€¢ Dibuat oleh  : Kakak (ridlo... / nama)     â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

- **Tombol [Edit]** di pojok kanan atas: untuk mengedit plat, merk, nama, tahun, atau setelan pengingat KM.
- **Tombol [âž• Update Ganti Oli]**: langsung membuka popup catat tanggal & KM untuk motor ini.
- **Timeline Riwayat**: garis penghubung otomatis menghitung selisih KM antar pencatatan:
  $$\Delta KM = KM_{sekarang} - KM_{sebelumnya}$$

---

### C. Navigasi Tengah [ âž• ] (Action Modal)
Saat ikon `+` di navigasi bawah ditekan, muncul **Bottom Sheet** dengan 4 pilihan aksi:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  PILIH AKSI                                  â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚  ðŸ›¢ï¸  Catat Ganti Oli                         â”‚
â”‚      Update KM dan tanggal oli motor         â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚  ðŸï¸  Tambah Motor Baru                       â”‚
â”‚      Daftarkan motor sendiri / motor grup    â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚  ðŸ‘¥  Buat Grup Keluarga                      â”‚
â”‚      Buat grup baru & dapatkan kode undangan â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚  ðŸ”‘  Masuk Grup                              â”‚
â”‚      Gabung ke grup keluarga lewat kode unik â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

1. **Jika pilih "Catat Ganti Oli":**
   - Langkah 1: Pilih motor dari dropdown (berisi daftar semua motor).
   - Langkah 2: Masukkan **Tanggal** (otomatis default ke hari ini, bisa diganti lewat date picker).
   - Langkah 3: Masukkan **KM Saat Ganti** (input angka, wajib).
   - Tombol: `[ Simpan Catatan ]`.
   - *Semua field lain (merk oli, filter, bengkel, dll) TIDAK ADA.*

2. **Jika pilih "Tambah Motor Baru":**
   - Nama motor (wajib, misal: "Vario 125")
   - Merk & Tipe (wajib, misal: "Honda Vario")
   - Plat nomor (opsional)
   - Tahun (opsional â€” sesuai permintaan user)
   - Warna (opsional)
   - Simpan ke: `[ Motor Saya Pribadi ]` atau `[ Motor Grup Keluarga ]`
   - Setting Pengingat Interval: default 2.000 km (bisa diatur sesuai motor)
   - KM awal sekarang (wajib, sebagai titik nol)
   - Tombol: `[ Daftarkan Motor ]`.

3. **Jika pilih "Buat Grup Keluarga":**
   - Masukkan Nama Grup (misal: "Keluarga Ridlo")
   - Tombol: `[ Buat Grup & Salin Kode Undangan ]`
   - Kode 6 digit otomatis di-generate (misal: `MTR789`) dan siap di-share ke WhatsApp kakak/keluarga.

4. **Jika pilih "Masuk Grup":**
   - Masukkan Kode Undangan (input 6 digit karakter)
   - Tombol: `[ Gabung Grup ]`
   - Begitu berhasil, seluruh motor milik grup keluarga tersebut otomatis muncul di tab **Motor** user ini.

---

### D. Layar 3: Tab [Profil] & Pengelolaan Grup Keluarga

Tab Profil berfungsi sebagai pusat akun pengguna dan **Hub Utama Pengelolaan Grup**.

#### 1. Tampilan Layar Profil
- **Info Akun:** Foto profil Google, Nama Lengkap, Email.
- **Kartu Grup Keluarga:**
  - Jika **sudah punya grup**: Menampilkan nama grup (misal: "Keluarga Ridlo"), jumlah anggota, dan tombol `[ Kelola Grup â†’ ]`.
  - Jika **belum punya grup**: Menampilkan kartu ajakan dengan tombol `[ Buat Grup Baru ]` atau `[ Masuk dengan Kode ]`.
- **Pengaturan Aplikasi:**
  - Switch: `Izinkan Notifikasi Pengingat (Aktif/Nonaktif)`
  - Tombol: `Cek Pembaruan Versi Aplikasi` (Auto-update APK)
- **Tombol:** `Keluar Akun (Sign Out)`

---

#### 2. Layar Khusus: [Kelola Grup Keluarga] (Terbuka saat kartu grup di Profil di-tap)

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ â† [Kembali]           Kelola Grup    [Simpan]â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ ðŸ·ï¸  NAMA GRUP                                â”‚
â”‚ [ Keluarga Ridlo & Kakak              ] âœï¸   â”‚ â† Bisa diedit owner
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ ðŸ”‘  KODE UNDANGAN ANGGOTA                    â”‚
â”‚ â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚ â”‚                  MTR789                  â”‚ â”‚ â† Kode 6 digit
â”‚ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚ [ ðŸ“‹ Salin Kode ]      [ ðŸ“² Bagikan ke WA ]  â”‚
â”‚ (Kode berlaku 7 hari, siap dikirim ke kakak) â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ ðŸ‘¥  ANGGOTA GRUP (2 Orang)                   â”‚
â”‚ â€¢ Ridlo (ridlo...@gmail.com)       ðŸ‘‘ Owner  â”‚
â”‚ â€¢ Kakak (kakak...@gmail.com)       Anggota   â”‚
â”‚                                              â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ ðŸï¸  MOTOR DI GRUP INI (2 Motor)              â”‚
â”‚ â€¢ Beat Kakak (B 1234 XYZ)                    â”‚
â”‚ â€¢ Vario Ridlo (B 5678 ABC)                   â”‚
â”‚ *(Untuk tambah/pindah motor, lewat Edit Motor)*â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚ [ ðŸšª Keluar dari Grup ]                      â”‚ â† Jika Member
â”‚ [ ðŸ—‘ï¸ Bubarkan Grup ]                          â”‚ â† Jika Owner
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

#### 3. Mekanisme Memasukkan Motor ke Dalam Grup (*Sangat Simpel & Praktis*)

Memasukkan atau mengeluarkan motor dari grup **TIDAK PERLU** menu yang rumit. Cukup dilakukan lewat **Form Motor** (saat Tambah Motor atau saat Edit Motor di halaman Detail Motor):

- Di form motor ada pilihan switch/radio:
  - `( ) Motor Pribadi` â†’ Hanya muncul di akun pemiliknya saja.
  - `(â—) Bagikan ke Grup Keluarga` â†’ Otomatis seketika muncul di layar HP semua anggota grup (bisa dilihat dan dicatat olinya bersama-sama).
- **Contoh Kasus Nyata:**
  - Kamu baru beli motor Vario, saat kamu tambah motor, kamu pilih `Bagikan ke Grup Keluarga`. Seketika motor itu juga muncul di HP kakakmu.
  - Jika suatu saat motor itu dijual atau tidak ingin dibagikan lagi, kamu tinggal buka motor itu â†’ tekan **Edit** â†’ ubah kembali ke `Motor Pribadi`.

---

## 5. SKEMA DATA FIRESTORE (TERSEDERHANA)

### A. `groups/{groupId}`
```json
{
  "name": "Keluarga Ridlo",
  "ownerId": "UID_RIDLO",
  "memberUids": ["UID_RIDLO", "UID_KAKAK"],
  "createdAt": "2026-10-18T10:00:00Z"
}
```

### B. `invites/{code}` (Contoh: "MTR789")
```json
{
  "groupId": "groupId_keluarga",
  "createdBy": "UID_RIDLO",
  "expiresAt": "2026-10-25T10:00:00Z"
}
```

### C. `motorcycles/{motorcycleId}`
```json
{
  "name": "Beat Kakak",
  "brand": "Honda",
  "model": "BeAT",
  "plate": "B 1234 XYZ",
  "year": "2021",
  "color": "Hitam",
  "groupId": "groupId_keluarga",
  "isGroupMotor": true,
  "reminderIntervalKm": 2000,
  "lastOdometer": 24500,
  "lastServiceAt": "2026-10-18T05:00:00Z",
  "createdBy": "UID_KAKAK",
  "createdAt": "2026-10-18T05:00:00Z"
}
```

### D. `motorcycles/{motorcycleId}/records/{recordId}`
```json
{
  "motorcycleId": "moto_123",
  "performedAt": "2026-10-18T05:00:00Z",
  "odometer": 24500,
  "performedBy": "UID_RIDLO",
  "createdAt": "2026-10-18T05:30:00Z"
}
```

---

## 6. STATUS TEKNIS & PERSIAPAN KODE

1. **Backend Rules (Firestore):**
   - Rules verifikasi self-join via kode undangan sudah di-deploy live ke Firebase dan aktif.
2. **Kebutuhan Library Flutter:**
   - `firebase_core`, `firebase_auth`, `cloud_firestore`
   - `google_sign_in`
   - `flutter_local_notifications` (untuk reminder bulanan)
   - `package_info_plus`, `dio`, `open_file` (untuk mekanisme auto-update APK)

---

*Spesifikasi v2 ini telah disederhanakan secara maksimal untuk memastikan aplikasi cepat diselesaikan, ringan, dan langsung menjawab kebutuhan inti.*
