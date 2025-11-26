# **INTERNLINK**

> ⚠️ **DICARI MAINTAINER BARU** — Proyek ini mencari maintainer baru. Syarat: minimal 3 PR di-merge. Lihat [MAINTAINER_WANTED.md](MAINTAINER_WANTED.md)

## **Deskripsi Singkat**
Internlink adalah platform manajemen magang berbasis web yang dibangun menggunakan framework Laravel. Aplikasi ini bertujuan untuk menghubungkan dan memfasilitasi interaksi antara siswa, sekolah/institusi pendidikan, perusahaan, dan supervisor. Sistem ini mencakup fitur untuk pendaftaran magang, pemantauan (monitoring), autentikasi pengguna, serta manajemen peran untuk admin, staf, dan pengembang.

## **Arsitektur/Diagram Sistem**

### Class Diagram (Entity Relationship)

```mermaid
classDiagram
    direction TB

    class User {
        +bigint id
        +string name
        +string email
        +string password
        +string phone
        +enum role
        +bigint school_id
        +student()
        +school()
    }

    class School {
        +bigint id
        +string code
        +string name
        +string address
        +string city
        +string phone
        +string email
        +users()
        +students()
        +supervisors()
        +institutions()
        +applications()
        +internships()
    }

    class Student {
        +bigint id
        +bigint user_id
        +bigint school_id
        +string student_number
        +string national_sn
        +bigint major_id
        +string class
        +string batch
        +user()
        +school()
        +major()
    }

    class Supervisor {
        +bigint id
        +bigint user_id
        +bigint school_id
        +string supervisor_number
        +bigint department_id
        +user()
        +school()
        +department()
    }

    class Institution {
        +bigint id
        +bigint school_id
        +string name
        +string address
        +string city
        +bigint industry_for
        +contacts()
        +quotas()
        +school()
    }

    class InstitutionContact {
        +bigint id
        +bigint institution_id
        +string name
        +string email
        +string phone
        +boolean is_primary
    }

    class InstitutionQuota {
        +bigint id
        +bigint institution_id
        +bigint period_id
        +bigint school_id
        +int quota
        +int used
    }

    class Period {
        +bigint id
        +int year
        +smallint term
        +bigint school_id
    }

    class Application {
        +bigint id
        +bigint student_id
        +bigint institution_id
        +bigint period_id
        +bigint school_id
        +enum status
        +date planned_start_date
        +date planned_end_date
        +student()
        +institution()
        +period()
    }

    class Internship {
        +bigint id
        +bigint application_id
        +bigint student_id
        +bigint institution_id
        +bigint period_id
        +bigint school_id
        +date start_date
        +date end_date
        +enum status
    }

    class MonitoringLog {
        +bigint id
        +bigint internship_id
        +bigint supervisor_id
        +bigint school_id
        +date log_date
        +string title
        +text content
        +enum type
    }

    class SchoolMajor {
        +bigint id
        +bigint school_id
        +string name
        +string slug
        +boolean is_active
    }

    class MajorStaffAssignment {
        +bigint id
        +bigint school_id
        +bigint supervisor_id
        +bigint major_id
    }

    User "1" --> "0..1" Student : has
    User "1" --> "0..1" Supervisor : has
    User "*" --> "1" School : belongs to

    School "1" --> "*" Student : has many
    School "1" --> "*" Supervisor : has many
    School "1" --> "*" Institution : has many
    School "1" --> "*" Period : has many
    School "1" --> "*" Application : has many
    School "1" --> "*" Internship : has many
    School "1" --> "*" SchoolMajor : has many

    Student "*" --> "1" SchoolMajor : belongs to
    Student "1" --> "*" Application : has many

    Supervisor "*" --> "1" SchoolMajor : department

    Institution "1" --> "*" InstitutionContact : has many
    Institution "1" --> "*" InstitutionQuota : has many
    Institution "*" --> "1" SchoolMajor : industry_for

    Application "*" --> "1" Student : belongs to
    Application "*" --> "1" Institution : belongs to
    Application "*" --> "1" Period : belongs to
    Application "1" --> "0..1" Internship : creates

    Internship "1" --> "*" MonitoringLog : has many
    Internship "*" --> "*" Supervisor : supervised by

    MajorStaffAssignment "*" --> "1" Supervisor : assigned to
    MajorStaffAssignment "*" --> "1" SchoolMajor : for major
```

### Sequence Diagram - Proses Pendaftaran Magang

```mermaid
sequenceDiagram
    autonumber
    participant S as Student
    participant UI as Web Interface
    participant AC as ApplicationController
    participant App as Application Model
    participant IQ as InstitutionQuota
    participant DB as Database

    S->>UI: Akses form pendaftaran magang
    UI->>AC: GET /applications/create
    AC->>DB: Query institutions, periods
    DB-->>AC: Data institutions & periods
    AC-->>UI: Render form

    S->>UI: Submit aplikasi magang
    UI->>AC: POST /applications
    AC->>AC: Validate input data
    
    AC->>IQ: Check quota availability
    IQ->>DB: SELECT quota, used FROM institution_quotas
    DB-->>IQ: Quota data
    IQ-->>AC: Quota status

    alt Quota tersedia
        AC->>App: Create new application
        App->>DB: INSERT INTO applications
        DB-->>App: Application created
        DB->>DB: Trigger: log_app_status_on_insert()
        DB->>DB: Trigger: bump_quota_used_active()
        App-->>AC: Success
        AC-->>UI: Redirect with success message
        UI-->>S: Tampilkan konfirmasi
    else Quota penuh
        AC-->>UI: Return error
        UI-->>S: Tampilkan pesan quota penuh
    end
```

### Sequence Diagram - Alur Penerimaan & Internship

```mermaid
sequenceDiagram
    autonumber
    participant Admin as Admin/Supervisor
    participant UI as Web Interface
    participant AppC as ApplicationController
    participant IntC as InternshipController
    participant App as Application
    participant Int as Internship
    participant DB as Database

    Admin->>UI: Update status aplikasi ke "accepted"
    UI->>AppC: PUT /applications/{id}
    AppC->>App: Update status = 'accepted'
    App->>DB: UPDATE applications SET status='accepted'
    DB->>DB: Trigger: log_app_status_change()
    DB-->>App: Updated
    App-->>AppC: Success
    AppC-->>UI: Redirect to application detail

    Admin->>UI: Buat internship dari aplikasi
    UI->>IntC: POST /internships
    IntC->>DB: Validate application status
    DB-->>IntC: Application is accepted
    
    IntC->>Int: Create internship
    Int->>DB: INSERT INTO internships
    DB->>DB: Trigger: enforce_internship_from_accepted_application()
    DB-->>Int: Internship created
    Int-->>IntC: Success
    IntC-->>UI: Redirect with success
    UI-->>Admin: Tampilkan detail internship
```

### Flowchart - Alur Utama Sistem

```mermaid
flowchart TD
    A[User Mengakses Sistem] --> B{Sudah Login?}
    B -->|Tidak| C[Halaman Login]
    C --> D{Punya Akun?}
    D -->|Tidak| E[Registrasi]
    E --> F[Pilih Role: Student/Supervisor]
    F --> G[Input Kode Sekolah]
    G --> H[Lengkapi Data Profil]
    H --> I[Akun Dibuat]
    I --> C
    D -->|Ya| J[Input Credentials]
    J --> K{Valid?}
    K -->|Tidak| C
    K -->|Ya| L{Cek Role User}
    
    B -->|Ya| L
    L -->|Developer| M[Dashboard Developer]
    L -->|Admin| N[Dashboard Admin Sekolah]
    L -->|Supervisor| O[Dashboard Supervisor]
    L -->|Student| P[Dashboard Student]

    M --> M1[Kelola Schools]
    M --> M2[Kelola Developers]

    N --> N1[Kelola Students]
    N --> N2[Kelola Supervisors]
    N --> N3[Kelola Institutions]
    N --> N4[Kelola Applications]
    N --> N5[Kelola Internships]
    N --> N6[Kelola Monitoring]

    O --> O1[Lihat Students]
    O --> O2[Kelola Applications]
    O --> O3[Monitoring Magang]
    O --> O4[Input Log Aktivitas]

    P --> P1[Lihat Profil]
    P --> P2[Lihat Status Aplikasi]
```

### Flowchart - Proses Aplikasi Magang

```mermaid
flowchart TD
    Start([Student/Admin membuat aplikasi]) --> A[Input data aplikasi]
    A --> B{Validasi data}
    B -->|Gagal| C[Tampilkan error]
    C --> A
    B -->|Sukses| D{Cek kuota institusi}
    D -->|Penuh| E[Tolak aplikasi]
    E --> End1([Selesai])
    D -->|Tersedia| F{Cek max 3 aplikasi aktif per siswa}
    F -->|Melebihi| G[Tolak - limit tercapai]
    G --> End1
    F -->|OK| H[Simpan aplikasi - Status: Submitted]
    H --> I[Trigger: Log status history]
    I --> J[Trigger: Update used quota]
    J --> K[Aplikasi berhasil dibuat]
    K --> L{Review oleh Admin/Supervisor}
    
    L -->|Ditolak| M[Update status: Rejected]
    M --> N[Kurangi used quota]
    N --> End2([Aplikasi ditolak])
    
    L -->|Diterima| O[Update status: Accepted]
    O --> P[Buat record Internship]
    P --> Q{Validasi: Aplikasi sudah accepted?}
    Q -->|Tidak| R[Error: Tidak bisa buat internship]
    Q -->|Ya| S[Internship dibuat]
    S --> T[Assign Supervisor]
    T --> U[Monitoring dimulai]
    U --> End3([Magang berjalan])
```

### Arsitektur Teknologi

```mermaid
flowchart LR
    subgraph Client
        Browser[Web Browser]
    end

    subgraph Server["Laravel Application"]
        direction TB
        Routes[Routes/web.php]
        MW[Middleware]
        Controllers[Controllers]
        Models[Eloquent Models]
        Views[Blade Views]
    end

    subgraph Database["PostgreSQL"]
        direction TB
        CoreSchema[core schema]
        AppSchema[app schema]
        Triggers[Database Triggers]
        Functions[Stored Functions]
    end

    Browser <--> Routes
    Routes --> MW
    MW --> Controllers
    Controllers <--> Models
    Controllers --> Views
    Views --> Browser
    Models <--> AppSchema
    Models <--> CoreSchema
    AppSchema --> Triggers
    Triggers --> Functions
```

## **Instalasi & Setup**

### Prasyarat

Pastikan sistem Anda sudah memiliki:
- **PHP 8.1+** dengan ekstensi: `pdo_pgsql`, `pgsql`, `mbstring`, `openssl`, `zip`, `fileinfo`, `xml`, `curl`
- **PostgreSQL 14+**
- **Node.js 18 LTS+** & npm
- **Composer**
- **Git**
- **Chrome/Chromium** (untuk fitur export PDF)

---

### Langkah Instalasi

#### 1. Clone Repository

```bash
git clone https://github.com/crbsdndr/internlink.git
cd internlink
```

#### 2. Install Dependensi

```bash
# Install dependensi PHP
composer install

# Install dependensi Node.js
npm install

# Build assets frontend
npm run build
```

#### 3. Konfigurasi Environment

```bash
# Salin file environment
cp .env.example .env    # Linux/Mac
copy .env.example .env  # Windows
```

Edit file `.env` dan sesuaikan konfigurasi database:
```env
APP_NAME=Internlink
APP_ENV=local
APP_DEBUG=true
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=internlink
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

#### 4. Setup Database

Buat database di PostgreSQL:
```sql
CREATE DATABASE internlink;
```

Kemudian jalankan migrasi:
```bash
# Generate application key
php artisan key:generate

# Jalankan migrasi
php artisan migrate

# (Opsional) Isi data contoh
php artisan db:seed
```

#### 5. Jalankan Aplikasi

```bash
php artisan serve
```

✅ Akses aplikasi di: **http://127.0.0.1:8000**

---

### Development Mode (Hot Reload)

Jalankan dua terminal secara bersamaan:

```bash
# Terminal 1 - Laravel Server
php artisan serve

# Terminal 2 - Vite Dev Server
npm run dev
```

---

### Akun Default (Setelah Seeding)

| Role | Email | Password |
|------|-------|----------|
| Developer | `dev@internlink.test` | `password` |

> ⚠️ **Penting:** Ubah password default setelah login pertama kali!

## **Fitur/Fungsi Utama**

### 🔐 Autentikasi & Otorisasi

| Fitur | Deskripsi |
|-------|-----------|
| **Multi-step Registration** | Pendaftaran akun untuk Student dan Supervisor dengan verifikasi kode sekolah |
| **Session-based Login** | Autentikasi berbasis session dengan redirect otomatis ke realm sekolah |
| **Role-based Access Control** | 4 level akses: Developer, Admin, Supervisor, Student |
| **Password Management** | Ubah password dengan validasi old/new/confirm |

### 🏫 Manajemen Sekolah (Developer Only)

| Fitur | Route | Deskripsi |
|-------|-------|-----------|
| **CRUD Sekolah** | `/schools` | Kelola data sekolah (nama, alamat, kontak, kepala sekolah) |
| **Realm System** | `/{school_code}/...` | Setiap sekolah memiliki kode unik sebagai prefix URL |
| **Jurusan/Departemen** | `/{school}/settings/environments` | Kelola daftar jurusan aktif per sekolah |

### 👥 Manajemen Pengguna

| Modul | Route | Akses | Fitur |
|-------|-------|-------|-------|
| **Students** | `/{school}/students` | Admin, Supervisor | CRUD siswa dengan NIS, NISN, jurusan, kelas, angkatan |
| **Supervisors** | `/{school}/supervisors` | Admin, Developer | CRUD pembimbing dengan nomor pegawai dan departemen |
| **Admins** | `/{school}/admins` | Developer | Kelola admin sekolah |
| **Major Contacts** | `/{school}/major-contacts` | Admin, Developer | Mapping jurusan ke supervisor sebagai contact person |

### 🏢 Manajemen Institusi Mitra

| Fitur | Deskripsi |
|-------|-----------|
| **Data Institusi** | Nama, alamat, kota, provinsi, website, industri |
| **Kontak Institusi** | Multiple contacts dengan penanda primary |
| **Kuota per Periode** | Kuota magang per semester dengan tracking penggunaan |
| **Industry Mapping** | Mapping institusi ke jurusan yang relevan |

### 📝 Aplikasi Magang

| Fitur | Deskripsi |
|-------|-----------|
| **Pengajuan Individual** | Siswa mengajukan magang ke institusi pilihan |
| **Bulk Application** | Admin/Supervisor dapat mengajukan untuk banyak siswa sekaligus |
| **Auto Period Detection** | Periode otomatis terdeteksi dari tanggal mulai |
| **Quota Validation** | Sistem memblokir pengajuan jika kuota penuh |
| **Status Workflow** | `draft` → `submitted` → `under_review` → `accepted` / `rejected` / `cancelled` |
| **PDF Export** | Generate surat pengajuan magang dalam format PDF |
| **Print All** | Cetak semua aplikasi sekaligus |

### 🎓 Manajemen Internship

| Fitur | Deskripsi |
|-------|-----------|
| **Create from Application** | Internship dibuat dari aplikasi yang sudah `accepted` |
| **Status Tracking** | `planned` → `ongoing` → `completed` / `terminated` |
| **Supervisor Assignment** | Assign pembimbing untuk setiap internship |
| **Schedule Management** | Kelola tanggal mulai dan selesai magang |

### 📊 Monitoring & Logging

| Fitur | Deskripsi |
|-------|-----------|
| **Activity Logs** | Catat aktivitas harian/mingguan siswa magang |
| **Log Types** | `weekly`, `issue`, `final`, `other` |
| **Bulk Monitoring** | Terapkan log ke semua siswa di institusi yang sama |
| **Progress Tracking** | Pantau perkembangan magang secara real-time |

### ⚙️ Settings & Konfigurasi

| Menu | Route | Deskripsi |
|------|-------|-----------|
| **Profile** | `/{school}/settings/profile` | Edit data profil sesuai role |
| **Security** | `/{school}/settings/security` | Ubah password dengan validasi |
| **Environments** | `/{school}/settings/environments` | Kelola jurusan (Admin/Developer) |

### 🔧 Fitur Teknis

| Fitur | Teknologi |
|-------|-----------|
| **PDF Generation** | Browsershot + Chromium untuk render PDF |
| **Dynamic Dropdowns** | Tom Select untuk autocomplete dan multi-select |
| **Database Triggers** | PostgreSQL triggers untuk audit trail dan validasi |
| **Multi-tenant** | Path-based tenancy dengan middleware `school` |
| **CSRF Protection** | Semua form mutation dilindungi CSRF token |

## **Pemecahan Masalah / FAQ**

### ❓ Bagaimana cara menambahkan sekolah baru ke sistem?

Hanya user dengan role **Developer** yang dapat menambahkan sekolah baru.

1. Login sebagai Developer
2. Akses menu **Schools** (`/schools`)
3. Klik tombol **Tambah Sekolah**
4. Isi data sekolah (nama, alamat, kontak, kepala sekolah)
5. Sistem akan otomatis generate **kode sekolah** unik
6. Kode sekolah ini yang akan digunakan user lain saat registrasi

> 💡 **Tips:** Setelah sekolah dibuat, buat minimal 1 akun Admin untuk sekolah tersebut via menu **Admins** (`/{school_code}/admins`).

---

### ❓ Mengapa saya tidak bisa login setelah registrasi?

Beberapa kemungkinan penyebab:

| Masalah | Solusi |
|---------|--------|
| **Kode sekolah salah** | Pastikan kode sekolah yang diinput saat registrasi sudah benar (case-insensitive) |
| **Email sudah terdaftar** | Gunakan email lain atau hubungi admin sekolah |
| **Password salah** | Gunakan fitur reset password atau hubungi admin |
| **Session expired** | Clear cookies browser dan coba login ulang |

Jika masih bermasalah, minta admin/developer untuk mengecek status akun Anda di database.

---

### ❓ Bagaimana cara mengatur kuota magang untuk institusi?

Kuota magang diatur per **institusi** dan per **periode** (semester).

1. Login sebagai Admin atau Supervisor
2. Akses menu **Institutions** (`/{school}/institutions`)
3. Pilih institusi yang ingin diatur kuotanya
4. Pada halaman detail, cari bagian **Kuota per Periode**
5. Klik **Tambah Kuota** atau edit kuota existing
6. Isi:
   - **Periode**: Pilih tahun dan semester (misal: 2025 Semester 1)
   - **Kuota**: Jumlah maksimal siswa yang bisa magang
7. Simpan

> ⚠️ **Penting:** Sistem akan otomatis menolak aplikasi baru jika `used >= quota`. Pastikan kuota sudah diatur sebelum periode magang dimulai.

---

### ❓ Kenapa PDF surat pengajuan tidak bisa di-generate / hasilnya kosong?

Fitur PDF menggunakan **Browsershot** yang membutuhkan Chrome/Chromium terinstall di server.

**Checklist troubleshooting:**

| Langkah | Perintah/Aksi |
|---------|---------------|
| 1. Pastikan Chromium terinstall | `which chromium` atau `which google-chrome` |
| 2. Cek path di config | Lihat `config/browsershot.php` atau `.env` |
| 3. Cek permission | `chmod +x /usr/bin/chromium` |
| 4. Test manual | `php artisan tinker` lalu jalankan Browsershot test |
| 5. Cek error log | `tail -f storage/logs/laravel.log` |

**Untuk environment tanpa GUI (server):**
```bash
# Install dependencies untuk headless Chrome
sudo apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libxcomposite1 libxrandr2 libxdamage1 libgbm1
```

**Set path di `.env` (jika perlu):**
```env
BROWSERSHOT_CHROME_PATH=/usr/bin/chromium
```

---

### ❓ Apa perbedaan role Admin, Supervisor, dan Student?

| Kemampuan | Developer | Admin | Supervisor | Student |
|-----------|:---------:|:-----:|:----------:|:-------:|
| Kelola Schools | ✅ | ❌ | ❌ | ❌ |
| Kelola Developers | ✅ | ❌ | ❌ | ❌ |
| Kelola Admins | ✅ | ❌ | ❌ | ❌ |
| Kelola Students | ✅ | ✅ | ✅ (view) | ❌ |
| Kelola Supervisors | ✅ | ✅ | ❌ | ❌ |
| Kelola Institutions | ✅ | ✅ | ✅ | ❌ |
| Kelola Applications | ✅ | ✅ | ✅ | 👁️ (view own) |
| Kelola Internships | ✅ | ✅ | ✅ | ❌ |
| Input Monitoring Log | ✅ | ✅ | ✅ | ❌ |
| Edit Profil Sendiri | ✅ | ✅ | ✅ | ✅ |
| Ubah Password | ✅ | ✅ | ✅ | ✅ |
| Kelola Jurusan | ✅ | ✅ | ❌ | ❌ |

**Ringkasan:**
- **Developer**: Super admin, akses penuh ke semua sekolah
- **Admin**: Mengelola semua aspek dalam 1 sekolah
- **Supervisor**: Pembimbing magang, fokus pada monitoring dan aplikasi
- **Student**: Hanya bisa melihat profil dan status aplikasi sendiri

## **Kontribusi**

### Cara Berkontribusi

1. Fork repository → Clone → Buat branch baru
2. Lakukan perubahan dengan format commit [Conventional Commits](https://www.conventionalcommits.org/)
3. Push → Buat Pull Request ke `main`

### Panduan Singkat

- **PHP**: PSR-12, jalankan `./vendor/bin/pint`
- **Testing**: `php artisan test`
- **Bug Report**: Buka issue di [GitHub Issues](https://github.com/crbsdndr/internlink/issues)

## **Informasi Kontak & Lisensi**

### Lisensi

**GNU General Public License v3.0** — Lihat [LICENSE](LICENSE)

### Kontak

| | |
|---|---|
| **Maintainer** | Dendra |
| **Email** | artrialazz@gmail.com.com |
| **Repository** | [github.com/crbsdndr/internlink](https://github.com/crbsdndr/internlink) |

### Acknowledgments

[Laravel](https://laravel.com/) • [PostgreSQL](https://www.postgresql.org/) • [Vite](https://vitejs.dev/) • [Bootstrap](https://getbootstrap.com/) • [Tom Select](https://tom-select.js.org/) • [Browsershot](https://github.com/spatie/browsershot)

---

<div align="center">

**Made with ❤️ for Indonesian Vocational Schools**

[⬆ Kembali ke Atas](#internlink)

</div>
