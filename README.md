# ScientiCO OJS Local

Lingkungan pengembangan lokal untuk menjalankan **Open Journal Systems (OJS) 3.5.0-4** menggunakan Docker.

Repository ini digunakan untuk menyimpan konfigurasi contoh, skrip operasional, plugin, terjemahan, dan kustomisasi antarmuka ScientiCO yang aman untuk dipublikasikan.

> Repository ini tidak menyimpan database, password, file unggahan pengguna, konfigurasi aktif, atau data privat.

---

## Tentang Proyek

ScientiCO OJS Local merupakan lingkungan lokal untuk pengembangan dan pengujian situs jurnal ScientiCO.

Lingkungan ini memungkinkan OJS dijalankan menggunakan Docker tanpa harus memasang Apache, PHP, MariaDB, dan dependensi OJS secara manual pada sistem operasi utama.

Proyek ini digunakan untuk:

- menjalankan OJS secara lokal;
- menguji perubahan tampilan;
- mengembangkan plugin OJS;
- memperbaiki terjemahan Bahasa Indonesia;
- menguji konfigurasi sebelum diterapkan ke server;
- menjalankan proses backup dan pemeriksaan sistem;
- mengembangkan tampilan dashboard yang responsif pada perangkat seluler.

---

## Teknologi

Proyek ini menggunakan:

- Open Journal Systems 3.5.0-4;
- Docker;
- Docker Compose;
- MariaDB 10.6;
- Apache;
- PHP;
- Bash;
- Windows Command Script;
- Generic Plugin OJS;
- CSS;
- JavaScript;
- locale Bahasa Indonesia.

---

## Alamat OJS Lokal

Setelah container berhasil dijalankan, halaman jurnal dapat diakses melalui:

```text
http://localhost:8081/SCO/id
```

Halaman utama lokal juga dapat diakses melalui:

```text
http://localhost:8081
```

Port yang digunakan pada lingkungan lokal adalah:

```text
8081
```

---

## Struktur Proyek

Struktur utama repository:

```text
.
├── apache/
├── ojs-plugins/
│   └── scienticoAdminMobile/
│       ├── js/
│       │   └── admin-mobile.js
│       ├── styles/
│       │   └── admin-mobile.css
│       ├── ScienticoAdminMobilePlugin.php
│       └── version.xml
├── ojs-public/
├── ojs-runtime-public/
├── ojs-theme/
│   └── default/
│       ├── styles/
│       │   └── custom.css
│       └── DefaultThemePlugin.php
├── php-ini/
├── pkp-locale/
│   └── id/
│       ├── invitation.po
│       └── userAccess.po
├── scripts/
│   ├── backup-ojs.sh
│   ├── first-setup-local.sh
│   ├── start-local.sh
│   ├── status-local.sh
│   └── stop-local.sh
├── .env.example
├── .gitignore
├── config.example.inc.php
├── docker-compose.example.yml
├── FIRST-SETUP-SCO.cmd
├── PETUNJUK-LOKAL.txt
├── README.md
├── START-SCO.cmd
├── STATUS-SCO.cmd
└── STOP-SCO.cmd
```

Beberapa direktori dapat dibuat otomatis ketika lingkungan lokal dijalankan.

---

## Komponen Utama

### 1. Docker Compose

Docker Compose digunakan untuk menjalankan:

- container aplikasi OJS;
- container database MariaDB;
- volume database;
- file publik OJS;
- konfigurasi Apache;
- konfigurasi PHP;
- tema;
- locale;
- plugin tambahan.

File konfigurasi yang aktif tidak disimpan dalam repository.

File contoh yang tersedia:

```text
docker-compose.example.yml
```

Untuk digunakan secara lokal, file tersebut harus disalin menjadi:

```text
docker-compose.yml
```

---

### 2. Konfigurasi OJS

File konfigurasi contoh OJS berada pada:

```text
config.example.inc.php
```

Salin file tersebut menjadi:

```text
config.inc.php
```

Kemudian sesuaikan pengaturan database, URL lokal, direktori file, dan konfigurasi lain sesuai lingkungan masing-masing.

File `config.inc.php` aktif tidak disimpan ke GitHub karena dapat memuat informasi sensitif.

---

### 3. Environment Variables

File contoh environment tersedia pada:

```text
.env.example
```

Salin file tersebut menjadi:

```text
.env
```

File `.env` digunakan untuk menyimpan pengaturan lokal seperti:

- nama database;
- pengguna database;
- password database;
- nama container;
- port aplikasi;
- zona waktu;
- pengaturan lain yang dibutuhkan Docker Compose.

File `.env` aktif tidak dimasukkan ke repository.

---

### 4. Plugin ScientiCO Admin Mobile

Plugin khusus tersedia pada:

```text
ojs-plugins/scienticoAdminMobile/
```

Plugin ini digunakan untuk memperbaiki tampilan dashboard OJS pada perangkat HP dan tablet.

Fungsi utama plugin:

- menambahkan tombol hamburger pada header dashboard;
- mengubah sidebar backend menjadi drawer;
- membuka sidebar dari sisi kiri;
- menutup sidebar melalui backdrop;
- menutup sidebar dengan tombol `Escape`;
- menyesuaikan atribut aksesibilitas;
- mencegah sidebar memenuhi bagian atas halaman;
- mempertahankan tampilan desktop OJS;
- membuat konten backend lebih responsif.

File utama plugin:

```text
ojs-plugins/scienticoAdminMobile/
├── ScienticoAdminMobilePlugin.php
├── version.xml
├── styles/
│   └── admin-mobile.css
└── js/
    └── admin-mobile.js
```

Setelah OJS berjalan, plugin perlu diaktifkan melalui halaman:

```text
Pengaturan → Situs Web → Plugin → Plugin Terinstal
```

Nama plugin:

```text
ScientiCO Admin Mobile
```

---

### 5. Kustomisasi Tema

Kustomisasi tema publik OJS berada pada:

```text
ojs-theme/default/styles/custom.css
```

File tersebut digunakan untuk memperbaiki dan menyesuaikan tampilan jurnal, termasuk tampilan responsif pada perangkat seluler.

File plugin tema yang digunakan:

```text
ojs-theme/default/DefaultThemePlugin.php
```

Repository tidak menyimpan seluruh isi tema bawaan OJS. Hanya file yang dikustomisasi yang disimpan.

---

### 6. Locale Bahasa Indonesia

Perbaikan locale Bahasa Indonesia berada pada:

```text
pkp-locale/id/invitation.po
pkp-locale/id/userAccess.po
```

File tersebut digunakan untuk memperbaiki teks yang sebelumnya dapat muncul sebagai kode locale mentah pada antarmuka OJS.

Contoh masalah yang diperbaiki:

- teks undangan pengguna;
- akses pengguna;
- proses penerimaan undangan;
- pesan antarmuka yang belum diterjemahkan.

Locale tersebut dipasang ke direktori PKP di dalam container melalui Docker volume mount.

---

### 7. Konfigurasi Apache

Konfigurasi tambahan Apache berada pada:

```text
apache/
```

Direktori ini digunakan untuk menyimpan konfigurasi yang dibutuhkan oleh lingkungan OJS lokal.

Konfigurasi Apache dapat mencakup:

- pengaturan virtual host;
- pengaturan rewrite;
- izin direktori;
- konfigurasi header;
- konfigurasi akses lokal.

---

### 8. Konfigurasi PHP

Konfigurasi tambahan PHP berada pada:

```text
php-ini/
```

Pengaturan ini dapat digunakan untuk menyesuaikan:

- batas unggahan;
- batas ukuran request;
- waktu eksekusi;
- batas memori;
- zona waktu;
- pengaturan PHP lain yang diperlukan OJS.

---

## Persyaratan Sistem

Sebelum menjalankan proyek, pastikan perangkat telah memiliki:

### Untuk Linux atau WSL

- Docker Engine;
- Docker Compose Plugin;
- Git;
- Bash;
- akses terminal.

### Untuk Windows

- Docker Desktop;
- Windows Subsystem for Linux atau terminal yang mendukung Docker;
- Git;
- virtualisasi aktif.

Periksa Docker dengan perintah:

```bash
docker --version
```

Periksa Docker Compose dengan:

```bash
docker compose version
```

Periksa Git dengan:

```bash
git --version
```

---

## Instalasi Repository

Clone repository:

```bash
git clone https://github.com/Yuliuslaki/OJS.git
```

Masuk ke direktori proyek:

```bash
cd OJS
```

Apabila proyek disimpan menggunakan nama folder lain, masuk ke folder tersebut.

Contoh:

```bash
cd ~/ojs-sco-local
```

---

## Persiapan Konfigurasi

Salin file konfigurasi contoh:

```bash
cp .env.example .env
cp config.example.inc.php config.inc.php
cp docker-compose.example.yml docker-compose.yml
```

Setelah itu, sesuaikan isi:

```text
.env
config.inc.php
docker-compose.yml
```

Jangan memasukkan password atau data produksi ke file contoh.

---

## Menjalankan OJS

### Linux atau WSL

Berikan izin eksekusi kepada script:

```bash
chmod +x scripts/*.sh
```

Jalankan OJS:

```bash
./scripts/start-local.sh
```

Alternatif menggunakan Docker Compose secara langsung:

```bash
docker compose up -d
```

---

### Windows

Jalankan:

```text
START-SCO.cmd
```

File tersebut digunakan untuk menjalankan container OJS melalui perintah yang telah disiapkan.

---

## Pengaturan Pertama

Untuk menjalankan proses pengaturan awal pada Linux atau WSL:

```bash
./scripts/first-setup-local.sh
```

Pada Windows:

```text
FIRST-SETUP-SCO.cmd
```

Script pengaturan awal dapat digunakan untuk:

- memeriksa Docker;
- membuat file atau direktori yang diperlukan;
- memastikan permission dasar;
- menjalankan container;
- membantu menyiapkan lingkungan lokal.

---

## Melihat Status Container

### Linux atau WSL

```bash
./scripts/status-local.sh
```

### Windows

```text
STATUS-SCO.cmd
```

Alternatif menggunakan Docker Compose:

```bash
docker compose ps
```

Untuk melihat status kesehatan container aplikasi:

```bash
docker inspect \
  --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
  ojs-sco-local-app
```

Status yang diharapkan:

```text
healthy
```

---

## Menghentikan OJS

### Linux atau WSL

```bash
./scripts/stop-local.sh
```

### Windows

```text
STOP-SCO.cmd
```

Alternatif menggunakan Docker Compose:

```bash
docker compose down
```

Perintah tersebut menghentikan container tanpa menghapus volume database.

---

## Memulai Ulang OJS

Untuk memulai ulang seluruh layanan:

```bash
docker compose restart
```

Untuk memulai ulang aplikasi OJS saja:

```bash
docker compose restart ojs
```

Setelah restart, tunggu sampai container kembali berstatus:

```text
healthy
```

---

## Melihat Log

Log aplikasi OJS:

```bash
docker compose logs -f ojs
```

Log database:

```bash
docker compose logs -f db
```

Log seluruh layanan:

```bash
docker compose logs -f
```

Tutup tampilan log dengan:

```text
Ctrl + C
```

---

## Pemeriksaan Sintaks PHP

Untuk memeriksa file PHP plugin:

```bash
docker compose exec -T ojs php -l \
/var/www/html/plugins/generic/scienticoAdminMobile/ScienticoAdminMobilePlugin.php
```

Hasil yang benar:

```text
No syntax errors detected
```

---

## Pemeriksaan Plugin Mobile

Pastikan file JavaScript dapat diakses:

```text
http://localhost:8081/plugins/generic/scienticoAdminMobile/js/admin-mobile.js
```

Pastikan file CSS dapat diakses:

```text
http://localhost:8081/plugins/generic/scienticoAdminMobile/styles/admin-mobile.css
```

Pada Console browser, keberadaan JavaScript dapat diperiksa menggunakan:

```javascript
document.querySelector('script[src*="admin-mobile.js"]')?.src;
```

Keberadaan CSS dapat diperiksa menggunakan:

```javascript
document.querySelector('link[href*="admin-mobile.css"]')?.href;
```

Keberadaan tombol hamburger dapat diperiksa menggunakan:

```javascript
document.querySelector("#scientico-admin-nav-toggle");
```

Ketika drawer terbuka, elemen `body` akan memiliki class:

```text
scienticoAdminNavOpen
```

Pemeriksaan:

```javascript
document.body.classList.contains("scienticoAdminNavOpen");
```

---

## Backup

Script backup berada pada:

```text
scripts/backup-ojs.sh
```

Jalankan backup dengan:

```bash
./scripts/backup-ojs.sh
```

Backup dapat mencakup:

- database MariaDB;
- konfigurasi lokal;
- file publik;
- file unggahan OJS;
- data penting lain sesuai konfigurasi script.

File hasil backup tidak dimasukkan ke GitHub.

Ekstensi berikut diabaikan oleh Git:

```text
.sql
.sql.gz
.dump
.tar
.tar.gz
.tgz
.zip
.7z
```

---

## Data Runtime

Data runtime tidak disimpan pada repository.

Contoh data runtime:

```text
ojs-files/
ojs-runtime-public/
restore/
```

Direktori tersebut dapat berisi:

- file unggahan artikel;
- file galley;
- gambar jurnal;
- cache;
- file hasil proses;
- data restore;
- database backup;
- file privat pengguna.

---

## Keamanan Repository

Repository ini tidak boleh menyimpan:

- password database;
- username database privat;
- token akses;
- Personal Access Token GitHub;
- secret key;
- file `.env` aktif;
- `config.inc.php` aktif;
- `docker-compose.yml` aktif;
- database SQL;
- arsip backup;
- file unggahan pengguna;
- data jurnal privat;
- alamat email pengguna;
- data reviewer;
- data penulis;
- file produksi;
- dokumentasi privat.

File yang diabaikan oleh Git antara lain:

```text
.env
config.inc.php
docker-compose.yml
restore/
ojs-files/
PETUNJUK-PRIVAT.txt
SUMBER-BACKUP.txt
settings.json
```

Sebelum melakukan commit, selalu periksa:

```bash
git status
```

Periksa file yang akan masuk commit:

```bash
git diff --cached --stat
```

Periksa isi perubahan:

```bash
git diff --cached
```

---

## File Contoh

Repository menyediakan file contoh berikut:

```text
.env.example
config.example.inc.php
docker-compose.example.yml
```

File contoh tidak boleh memuat password asli.

Gunakan nilai placeholder seperti:

```text
CHANGE_ME
your_password_here
example_password
```

---

## Perintah Git Dasar

Periksa perubahan:

```bash
git status
```

Tambahkan file tertentu:

```bash
git add nama-file
```

Tambahkan direktori tertentu:

```bash
git add nama-direktori/
```

Buat commit:

```bash
git commit -m "Deskripsi perubahan"
```

Kirim ke GitHub:

```bash
git push origin main
```

Sebelum melakukan `git add .`, pastikan `.gitignore` sudah benar dan tidak terdapat file sensitif.

---

## Kustomisasi yang Telah Diterapkan

Fitur dan perbaikan yang telah diterapkan meliputi:

- OJS 3.5.0-4 berjalan melalui Docker;
- database menggunakan MariaDB 10.6;
- healthcheck untuk container aplikasi dan database;
- konfigurasi URL lokal;
- dukungan journal path `SCO`;
- konfigurasi zona waktu;
- perbaikan menu publik pada perangkat seluler;
- kustomisasi tema default OJS;
- perbaikan locale Bahasa Indonesia;
- plugin dashboard mobile;
- tombol hamburger pada backend;
- sidebar backend berbentuk drawer;
- backdrop untuk menutup drawer;
- dukungan tombol `Escape`;
- penyesuaian tabel pada layar kecil;
- penyesuaian formulir dan panel;
- script start;
- script stop;
- script status;
- script first setup;
- script backup;
- log rotation container;
- mekanisme backup locking;
- retensi backup;
- pengujian restore OJS.

---

## Catatan Pengembangan

Perubahan pada file CSS dan JavaScript plugin sebaiknya diikuti dengan peningkatan versi query aset.

Contoh:

```php
$pluginUrl . '/styles/admin-mobile.css?v=1.3.0'
```

```php
$pluginUrl . '/js/admin-mobile.js?v=1.3.0'
```

Tujuannya agar browser tidak terus menggunakan cache file versi lama.

Setelah perubahan plugin:

```bash
docker compose restart ojs
```

Kemudian lakukan hard refresh pada browser:

```text
Ctrl + Shift + R
```

---

## Pemecahan Masalah

### Halaman tidak dapat dibuka

Periksa container:

```bash
docker compose ps
```

Periksa log aplikasi:

```bash
docker compose logs --tail=100 ojs
```

Periksa log database:

```bash
docker compose logs --tail=100 db
```

---

### Container belum sehat

Periksa status:

```bash
docker inspect \
  --format '{{json .State.Health}}' \
  ojs-sco-local-app
```

Tunggu beberapa saat setelah restart karena aplikasi membutuhkan waktu untuk melakukan inisialisasi.

---

### Plugin tidak muncul

Pastikan direktori plugin tersedia:

```bash
docker compose exec -T ojs ls -la \
/var/www/html/plugins/generic/scienticoAdminMobile
```

Pastikan file berikut tersedia:

```text
ScienticoAdminMobilePlugin.php
version.xml
styles/admin-mobile.css
js/admin-mobile.js
```

Periksa sintaks PHP:

```bash
docker compose exec -T ojs php -l \
/var/www/html/plugins/generic/scienticoAdminMobile/ScienticoAdminMobilePlugin.php
```

---

### JavaScript plugin tidak dimuat

Periksa melalui Console browser:

```javascript
document.querySelector('script[src*="admin-mobile.js"]')?.src;
```

Apabila hasilnya `undefined`, pastikan:

- plugin aktif;
- file PHP plugin telah diperbarui;
- fungsi `addJavaScript()` tersedia;
- container telah direstart;
- browser telah melakukan hard refresh.

---

### CSS lama masih digunakan

Naikkan versi file CSS pada plugin:

```php
admin-mobile.css?v=1.4.0
```

Kemudian restart aplikasi:

```bash
docker compose restart ojs
```

Lakukan hard refresh:

```text
Ctrl + Shift + R
```

---

### Sidebar tampil di atas konten

Pastikan CSS tidak lagi menggunakan:

```css
.app__body {
  flex-direction: column;
}
```

Sidebar mobile harus menggunakan class:

```text
scienticoAdminMobileNav
```

dan ditampilkan ketika `body` memiliki class:

```text
scienticoAdminNavOpen
```

---

## Kontribusi

Perubahan sebaiknya dilakukan melalui langkah berikut:

1. buat branch baru;
2. lakukan perubahan;
3. periksa file sensitif;
4. uji OJS;
5. periksa status container;
6. periksa tampilan desktop;
7. periksa tampilan mobile;
8. buat commit yang jelas;
9. push ke GitHub;
10. gabungkan perubahan setelah pengujian selesai.

Contoh membuat branch:

```bash
git switch -c nama-perubahan
```

Contoh commit:

```bash
git commit -m "Add responsive mobile admin drawer"
```

---

## Lisensi

OJS merupakan perangkat lunak open-source yang dikembangkan oleh Public Knowledge Project.

Kustomisasi pada repository ini digunakan untuk lingkungan pengembangan ScientiCO. Penggunaan OJS tetap mengikuti lisensi resmi dari proyek OJS dan Public Knowledge Project.

---

## Repository

Repository GitHub:

```text
https://github.com/Yuliuslaki/OJS
```

Branch utama:

```text
main
```

---

## Status

Lingkungan lokal telah mendukung:

- OJS lokal melalui Docker;
- database MariaDB;
- konfigurasi contoh yang aman;
- kustomisasi tema;
- locale Bahasa Indonesia;
- plugin dashboard mobile;
- script operasional;
- proses backup;
- pemeriksaan kesehatan container.

Pengembangan berikutnya dapat dilakukan dengan tetap menjaga agar data privat dan konfigurasi aktif tidak masuk ke repository publik.
