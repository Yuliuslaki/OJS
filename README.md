# OJS Docker

Proyek Open Journal Systems yang dijalankan menggunakan Docker Compose.

## Komponen

- OJS 3.5.0-4
- MariaDB 10.6
- Default Theme dengan CSS kustom
- PHP dan Apache dari image OJS

## Persyaratan

- Docker
- Docker Compose
- Git

## Menjalankan secara lokal

Salin file konfigurasi contoh:

```bash
cp docker-compose.example.yml docker-compose.yml
cp .env.example .env
cp config.example.inc.php config.inc.php
```

Buat password acak:

```bash
openssl rand -hex 24
```

Edit file `.env`:

```bash
nano .env
```

Contoh:

```ini
MARIADB_ROOT_PASSWORD=GANTI_PASSWORD_ROOT
MARIADB_DATABASE=db_jurnal
MARIADB_USER=ojs
MARIADB_PASSWORD=GANTI_PASSWORD_OJS
```

Nilai `MARIADB_PASSWORD` harus sama dengan password database dalam
`config.inc.php`:

```ini
[database]

host = db
username = ojs
password = "GANTI_PASSWORD_OJS"
name = db_jurnal
```

Untuk penggunaan lokal:

```ini
base_url = "http://localhost:8080"
allowed_hosts = '["localhost", "127.0.0.1"]'
force_ssl = Off
force_login_ssl = Off
```

Buat folder penyimpanan:

```bash
mkdir -p ojs-files ojs-public
```

Jalankan container:

```bash
docker compose up -d
```

Periksa status:

```bash
docker compose ps
```

MariaDB seharusnya berstatus `healthy`.

Buka OJS melalui browser:

```text
http://localhost:8080/SCO/id
```

## Perintah Docker

Menjalankan container:

```bash
docker compose up -d
```

Menghentikan container:

```bash
docker compose stop
```

Menjalankan kembali:

```bash
docker compose start
```

Melihat log OJS:

```bash
docker compose logs -f ojs
```

Melihat log database:

```bash
docker compose logs -f db
```

Membuat ulang container OJS:

```bash
docker compose up -d --force-recreate ojs
```

Jangan menjalankan `docker compose down -v` tanpa backup karena opsi
`-v` dapat menghapus volume database.

## Data persisten

Data penting disimpan pada:

- Volume `db-data`: database MariaDB
- `ojs-files/`: file artikel dan file privat
- `ojs-public/`: logo, cover, dan file publik
- `config.inc.php`: konfigurasi aktif OJS
- `.env`: password dan environment lokal

File `.env` dan `config.inc.php` tidak boleh dimasukkan ke Git.

## Tema

Proyek hanya memasang file tema yang dimodifikasi:

```text
ojs-theme/default/DefaultThemePlugin.php
ojs-theme/default/styles/custom.css
```

File tema bawaan lainnya tetap berasal dari image OJS.

## Konfigurasi production

Sebelum deployment, ganti domain dan aktifkan HTTPS:

```ini
base_url = "https://journal.example.org"
allowed_hosts = '["journal.example.org"]'
force_ssl = On
force_login_ssl = On
```

Ganti `journal.example.org` dengan domain yang sebenarnya.

Gunakan reverse proxy HTTPS seperti Nginx, Apache, atau Caddy.

## Backup

Sebelum upgrade atau deployment, backup:

1. Database MariaDB
2. Folder `ojs-files`
3. Folder `ojs-public`
4. File `config.inc.php`
5. File `.env`

Contoh backup database:

```bash
docker compose exec -T db sh -lc \
'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' \
> backup-ojs.sql
```

Simpan backup di lokasi privat dan jangan commit ke Git.

## Pemeriksaan layanan

Periksa database:

```bash
docker inspect ojs-sco-db --format \
'Status={{.State.Status}} Health={{.State.Health.Status}}'
```

Periksa koneksi hostname database:

```bash
docker compose exec -T ojs php -r \
'echo gethostbyname("db"), PHP_EOL;'
```

Periksa halaman OJS:

```bash
curl -sS \
  -c /tmp/ojs-cookie.txt \
  -b /tmp/ojs-cookie.txt \
  -L \
  -o /dev/null \
  -w "HTTP %{http_code}\n" \
  http://localhost:8080/SCO/id
```

Hasil normal adalah `HTTP 200`.
