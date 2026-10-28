# SPEC v2 — MotorQu (Aplikasi Pencatatan Oli Motor)

> Status: Revisi v2 (disederhanakan sesuai arahan user)  
> Project Firebase: `motorqu-e81dd` · Package Android: `com.motorqu.app` · Region: asia-southeast2 (Jakarta)  
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
| **Manajemen Grup** | 1 grup statis | **Multi-Grup & Multi-Owner**: Dukungan banyak grup, sistem banyak owner/admin (seperti WhatsApp), hak owner menurunkan owner lain & mengeluarkan anggota, serta hak owner mengeluarkan motor anggota lain dari grup | Sesuai kebutuhan keluarga besar |
| **Sinkronisasi Notifikasi** | Manual per motor | **Sinkronisasi Otomatis**: Semua motor pribadi & grup otomatis terjadwal pengingat saat app dibuka | Pengingat aktif untuk seluruh motor |

---

## 2. PENDAPAT & BEST PRACTICE FITUR PENGINGAT (REMINDER)

### A. Format & Waktu Pemicu Notifikasi
- **Waktu:** Berjalan lokal di HP secara otomatis setiap **30 hari sekali** terhitung sejak tanggal penggantian oli terakhir.
- **Teks Notifikasi:**
  > 🔔 **Pengingat Servis MotorQu**  
  > *Jika KM motor [Nama Motor] sudah lebih dari [Target KM]KM, jangan lupa ganti oli yaa*  
  > *(Contoh nyata: "Jika KM motor Beat sudah lebih dari 26.500KM, jangan lupa ganti oli yaa")*
- **Aksi saat di-tap:** Notifikasi langsung membuka form **"Catat Ganti Oli"** dengan motor tersebut sudah otomatis terpilih.

---

### B. Best Practice: Di Mana Setting Pengingat Diletakkan?

**Kesimpulan Best Practice: Pemisahan Konfigurasi Spesifik vs Global.**

1. **Setting Interval KM (Spesifik per Motor) → Di [Detail Motor] / Form [Tambah Motor]:**
   - **Kenapa di Detail Motor?** Setiap motor memiliki karakter dan rekomendasi pabrikan yang berbeda.
     - Motor matic (BeAT, Vario, Mio): biasanya 1.500 – 2.000 km.
     - Motor bebek / sport (Supra, Vixion, CBR): biasanya 2.500 – 3.000 km.
     - Motor tua vs motor baru bisa memiliki interval servis yang berbeda.
   - Oleh karena itu, interval KM **wajib melekat pada data motor masing-masing**, bukan disamaratakan.
   - Lokasi:
     - Diisi pertama kali saat **Tambah Motor** (default: `2000 km`).
     - Bisa diubah sewaktu-waktu di layar **Detail Motor → Edit Motor**.

2. **Master Switch (On / Off Global) → Di [Profil]:**
   - Di tab Profil ditaruh switch: `Izinkan Notifikasi Pengingat (Aktif/Nonaktif)`.
   - Fungsinya jika user sedang tidak ingin diganggu notifikasi tanpa harus mengubah setelan interval motor satu per satu.

---

## 3. STRUKTUR NAVIGASI (HANYA 3 ITEM)

```
┌──────────────────────────────────────────────┐
│                  LAYAR UTAMA                 │
│                                              │
│                                              │
│                                              │
├───────────────────┬──────────────┬───────────┤
│     🏍️ Motor      │     ➕       │ 👤 Profil │
│    (Home/Semua)   │ (Quick Action│ (Akun &   │
│                   │ Bottom Sheet)│  Grup)    │
└───────────────────┴──────────────┴───────────┘
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
  - Tap salah satu kartu motor → Membuka **Layar Detail Motor**.

---

### B. Layar 2: Detail Motor (Muncul saat kartu motor di-tap)
Struktur vertikal dari atas ke bawah:

```
┌──────────────────────────────────────────────┐
│ ← [Kembali]           Detail Motor    [Edit] │
├──────────────────────────────────────────────┤
│ Beat Kakak                                   │
│ [ Motor Grup Keluarga ]                      │
│ B 1234 XYZ · Honda BeAT                      │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │          [ ➕ Update Ganti Oli ]          │ │ ← Tombol cepat
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ 📜 RIWAYAT OLI                               │
│                                              │
│   ●   18 Okt 2026 — 24.500 km                 │
│   │  (Jarak pemakaian: 2.020 km)             │ ← Garis penghubung
│   ●   15 Agu 2026 — 22.480 km                 │   vertikal
│   │  (Jarak pemakaian: 1.980 km)             │
│   ●   10 Jun 2026 — 20.500 km                 │
│      (Catatan awal)                          │
│                                              │
├──────────────────────────────────────────────┤
│ ℹ️ INFORMASI MOTOR                           │
│ • Merk / Tipe  : Honda BeAT                  │
│ • Plat Nomor   : B 1234 XYZ                  │
│ • Tahun        : 2021 (opsional)             │
│ • Warna        : Hitam (opsional)            │
│ • Pengingat    : Per 2.000 km                │
│ • Dibuat oleh  : Kakak (ridlo... / nama)     │
└──────────────────────────────────────────────┘
```

- **Tombol [Edit]** di pojok kanan atas: untuk mengedit plat, merk, nama, tahun, atau setelan pengingat KM.
- **Tombol [➕ Update Ganti Oli]**: langsung membuka popup catat tanggal & KM untuk motor ini.
- **Timeline Riwayat**: garis penghubung otomatis menghitung selisih KM antar pencatatan:
  $$\Delta KM = KM_{sekarang} - KM_{sebelumnya}$$

---

### C. Navigasi Tengah [ ➕ ] (Action Modal)
Saat ikon `+` di navigasi bawah ditekan, muncul **Bottom Sheet** dengan 4 pilihan aksi:

```
┌──────────────────────────────────────────────┐
│  PILIH AKSI                                  │
├──────────────────────────────────────────────┤
│  🛢️   Catat Ganti Oli                         │
│      Update KM dan tanggal oli motor         │
├──────────────────────────────────────────────┤
│  🏍️   Tambah Motor Baru                       │
│      Daftarkan motor sendiri / motor grup    │
├──────────────────────────────────────────────┤
│  👥  Buat Grup Keluarga                      │
│      Buat grup baru & dapatkan kode undangan │
├──────────────────────────────────────────────┤
│  🔑  Masuk Grup                              │
│      Gabung ke grup keluarga lewat kode unik │
└──────────────────────────────────────────────┘
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
   - Tahun (opsional — sesuai permintaan user)
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
  - Jika **sudah punya grup**: Menampilkan nama grup (misal: "Keluarga Ridlo"), jumlah anggota, dan tombol `[ Kelola Grup → ]`.
  - Jika **belum punya grup**: Menampilkan kartu ajakan dengan tombol `[ Buat Grup Baru ]` atau `[ Masuk dengan Kode ]`.
- **Pengaturan Aplikasi:**
  - Switch: `Izinkan Notifikasi Pengingat (Aktif/Nonaktif)`
  - Tombol: `Cek Pembaruan Versi Aplikasi` (Auto-update APK)
- **Tombol:** `Keluar Akun (Sign Out)`

---

#### 2. Layar Khusus: [Kelola Grup Keluarga] (Terbuka saat kartu grup di Profil di-tap)

```
┌──────────────────────────────────────────────┐
│ ← [Kembali]           Kelola Grup    [Simpan]│
├──────────────────────────────────────────────┤
│ 🏷️  NAMA GRUP                                │
│ [ Keluarga Ridlo & Kakak              ] ✏️    │ ← Bisa diedit owner
├──────────────────────────────────────────────┤
│ 🔑  KODE UNDANGAN ANGGOTA                    │
│ ┌──────────────────────────────────────────┐ │
│ │                  MTR789                  │ │ ← Kode 6 digit
│ └──────────────────────────────────────────┘ │
│ [ 📋 Salin Kode ]      [ 📱 Bagikan ke WA ]  │
│ (Kode berlaku 7 hari, siap dikirim ke kakak) │
├──────────────────────────────────────────────┤
│ 👥  ANGGOTA GRUP (2 Orang)                   │
│ • Ridlo (ridlo...@gmail.com)       👑 Owner  │
│ • Kakak (kakak...@gmail.com)       Anggota   │
│                                              │
├──────────────────────────────────────────────┤
│ 🏍️  MOTOR DI GRUP INI (2 Motor)              │
│ • Beat Kakak (B 1234 XYZ)                    │
│ • Vario Ridlo (B 5678 ABC)                   │
│ *(Untuk tambah/pindah motor, lewat Edit Motor)*│
├──────────────────────────────────────────────┤
│ [ 🚪 Keluar dari Grup ]                      │ ← Jika Member
│ [ 🗑️ Bubarkan Grup ]                          │ ← Jika Owner
└──────────────────────────────────────────────┘
```

---

#### 3. Mekanisme Memasukkan Motor ke Dalam Grup (*Sangat Simpel & Praktis*)

Memasukkan atau mengeluarkan motor dari grup **TIDAK PERLU** menu yang rumit. Cukup dilakukan lewat **Form Motor** (saat Tambah Motor atau saat Edit Motor di halaman Detail Motor):

- Di form motor ada pilihan switch/radio:
  - `( ) Motor Pribadi` → Hanya muncul di akun pemiliknya saja.
  - `(●) Bagikan ke Grup Keluarga` → Otomatis seketika muncul di layar HP semua anggota grup (bisa dilihat dan dicatat olinya bersama-sama).
- **Contoh Kasus Nyata:**
  - Kamu baru beli motor Vario, saat kamu tambah motor, kamu pilih `Bagikan ke Grup Keluarga`. Seketika motor itu juga muncul di HP kakakmu.
  - Jika suatu saat motor itu dijual atau tidak ingin dibagikan lagi, kamu tinggal buka motor itu → tekan **Edit** → ubah kembali ke `Motor Pribadi`.

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
