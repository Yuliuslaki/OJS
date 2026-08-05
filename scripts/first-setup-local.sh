#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DUMP_FILE="$ROOT_DIR/restore/database.sql.gz"
URL="http://localhost:8081/SCO/id"

EXPECTED_TABLES=132
DB_CONTAINER="ojs-sco-local-db"
OJS_CONTAINER="ojs-sco-local-app"

BODY_FILE=""
COOKIE_FILE=""

log() {
    printf '%s\n' "$*"
}

cleanup() {
    if [ -n "$BODY_FILE" ]; then
        rm -f "$BODY_FILE"
    fi

    if [ -n "$COOKIE_FILE" ]; then
        rm -f "$COOKIE_FILE"
    fi
}

show_ojs_logs() {
    echo
    echo "=== Log OJS terbaru ==="

    docker compose logs \
        --tail=120 \
        ojs 2>/dev/null || true
}

fail() {
    trap - ERR

    echo
    echo "PERSIAPAN GAGAL: $*"
    echo "Folder proyek lama tidak disentuh."

    exit 1
}

on_error() {
    local line="$1"

    trap - ERR

    echo
    echo "Terjadi kesalahan pada tahap persiapan."
    echo "Lokasi perkiraan: baris $line"

    show_ojs_logs

    echo
    echo "PERSIAPAN GAGAL."
    echo "Folder proyek lama tidak disentuh."

    exit 1
}

trap cleanup EXIT
trap 'on_error "$LINENO"' ERR

echo "============================================"
echo " Persiapan lingkungan lokal ScientiCO"
echo "============================================"
echo "Folder proyek : $ROOT_DIR"
echo "Alamat web    : $URL"
echo

# ============================================================
# 1. Pemeriksaan awal
# ============================================================

log "[1/8] Memeriksa Docker dan berkas proyek..."

command -v docker >/dev/null 2>&1 ||
    fail "Docker belum tersedia di WSL."

docker info >/dev/null 2>&1 ||
    fail "Docker Desktop belum berjalan atau integrasi WSL belum aktif."

command -v curl >/dev/null 2>&1 ||
    fail "curl belum tersedia di WSL."

command -v python3 >/dev/null 2>&1 ||
    fail "python3 belum tersedia di WSL."

command -v gzip >/dev/null 2>&1 ||
    fail "gzip belum tersedia di WSL."

[ -f .env ] ||
    fail "File .env tidak ditemukan."

[ -f config.inc.php ] ||
    fail "config.inc.php tidak ditemukan."

[ -f "$DUMP_FILE" ] ||
    fail "Backup database tidak ditemukan."

[ -f docker-compose.yml ] ||
    fail "docker-compose.yml tidak ditemukan."

gzip -t "$DUMP_FILE" ||
    fail "Backup database rusak."

docker compose config --quiet ||
    fail "Konfigurasi Docker tidak valid."

# ============================================================
# 2. Pemeriksaan konfigurasi
# ============================================================

log "[2/8] Memeriksa kesesuaian konfigurasi tanpa menampilkan rahasia..."

python3 - <<'PY'
from pathlib import Path
import re


env_path = Path(".env")
config_path = Path("config.inc.php")


def fail(message: str) -> None:
    print(f"PERSIAPAN GAGAL: {message}")
    raise SystemExit(1)


env = {}

for raw_line in env_path.read_text(encoding="utf-8").splitlines():
    line = raw_line.strip()

    if not line or line.startswith("#") or "=" not in line:
        continue

    key, value = line.split("=", 1)

    env[key.strip()] = (
        value.strip()
        .strip('"')
        .strip("'")
    )


config_text = config_path.read_text(encoding="utf-8")


def get_section(name: str) -> str:
    match = re.search(
        rf"(?ms)^\[{re.escape(name)}\][ \t]*\n"
        rf"(?P<body>.*?)(?=^\[|\Z)",
        config_text,
    )

    if not match:
        fail(
            f"Bagian [{name}] tidak ditemukan "
            "pada config.inc.php."
        )

    return match.group("body")


def get_value(section_name: str, key: str) -> str:
    body = get_section(section_name)

    match = re.search(
        rf"(?m)^[ \t]*{re.escape(key)}"
        rf"[ \t]*=[ \t]*(.*?)\s*$",
        body,
    )

    if not match:
        fail(
            f"Parameter {key} pada "
            f"[{section_name}] tidak ditemukan."
        )

    return (
        match.group(1)
        .strip()
        .strip('"')
        .strip("'")
    )


required_env = (
    "MARIADB_DATABASE",
    "MARIADB_USER",
    "MARIADB_PASSWORD",
    "MARIADB_ROOT_PASSWORD",
)

for key in required_env:
    if not env.get(key):
        fail(
            f"{key} pada .env kosong "
            "atau tidak tersedia."
        )


checks = [
    (
        get_value("general", "installed").lower() == "on",
        "installed pada config.inc.php harus bernilai On.",
    ),
    (
        get_value("general", "base_url")
        == "http://localhost:8081",
        "base_url harus http://localhost:8081.",
    ),
    (
        bool(get_value("general", "app_key")),
        "app_key tidak boleh kosong.",
    ),
    (
        get_value("database", "host") == "db",
        "host database harus bernilai db.",
    ),
    (
        get_value("database", "name")
        == env["MARIADB_DATABASE"],
        (
            "Nama database pada config.inc.php "
            "dan .env tidak sama."
        ),
    ),
    (
        get_value("database", "username")
        == env["MARIADB_USER"],
        (
            "Pengguna database pada config.inc.php "
            "dan .env tidak sama."
        ),
    ),
    (
        get_value("database", "password")
        == env["MARIADB_PASSWORD"],
        (
            "Password database pada config.inc.php "
            "dan .env tidak sama."
        ),
    ),
    (
        get_value("files", "files_dir")
        == "/var/www/files",
        "files_dir harus /var/www/files.",
    ),
]


for passed, message in checks:
    if not passed:
        fail(message)


print("Konfigurasi OJS dan .env konsisten.")
PY

# ============================================================
# 3. Pemeriksaan port lokal
# ============================================================

log "[3/8] Memeriksa penggunaan port 8081..."

PORT_OWNER="$(
    docker ps \
        --format '{{.Names}} {{.Ports}}' |
    awk '
        /127\.0\.0\.1:8081->80\/tcp/ {
            print $1
            exit
        }
    '
)"

if [ -n "$PORT_OWNER" ] &&
   [ "$PORT_OWNER" != "$OJS_CONTAINER" ]; then

    fail \
        "Port 8081 sedang dipakai container lain: $PORT_OWNER"
fi

# ============================================================
# 4. Izin folder
# ============================================================

log "[4/8] Menyiapkan izin folder lokal..."

echo "Linux mungkin meminta password pengguna acer."
echo "Saat password diketik, karakter memang tidak ditampilkan."
echo

sudo -v ||
    fail "Hak administrator Linux tidak diperoleh."

mkdir -p \
    ojs-files \
    ojs-public \
    ojs-runtime-public

# Pengguna acer tetap menjadi pemilik.
# Grup 33 adalah grup www-data pada container OJS.
sudo chown -R \
    "$(id -u):33" \
    ojs-files \
    ojs-public \
    ojs-runtime-public

# Setgid menjaga agar file dan folder baru tetap memakai grup 33.
sudo find \
    ojs-files \
    ojs-public \
    ojs-runtime-public \
    -type d \
    -exec chmod 2770 {} +

sudo find \
    ojs-files \
    ojs-public \
    ojs-runtime-public \
    -type f \
    -exec chmod 660 {} +

chmod 600 .env

sudo chown \
    "$(id -u):33" \
    config.inc.php

chmod 640 config.inc.php

# ============================================================
# 5. Menjalankan MariaDB
# ============================================================

log "[5/8] Menjalankan MariaDB lokal..."

docker compose up -d db

READY=0

for attempt in $(seq 1 45); do
    STATUS="$(
        docker inspect \
            --format \
            '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$DB_CONTAINER" 2>/dev/null ||
        true
    )"

    printf \
        '  Pemeriksaan database %02d/45: %s\n' \
        "$attempt" \
        "${STATUS:-belum tersedia}"

    if [ "$STATUS" = "healthy" ]; then
        READY=1
        break
    fi

    if [ "$STATUS" = "exited" ] ||
       [ "$STATUS" = "dead" ]; then

        docker compose logs \
            --tail=100 \
            db || true

        fail "Container MariaDB berhenti."
    fi

    sleep 2
done

if [ "$READY" -ne 1 ]; then
    docker compose logs \
        --tail=100 \
        db || true

    fail "MariaDB tidak menjadi sehat dalam batas waktu."
fi

# ============================================================
# 6. Restore dan validasi database
# ============================================================

log "[6/8] Memeriksa dan memulihkan database ScientiCO..."

TABLE_COUNT="$(
    docker compose exec -T db sh -lc '
    exec mariadb \
      --user="$MARIADB_USER" \
      --password="$MARIADB_PASSWORD" \
      --batch \
      --skip-column-names \
      -e "
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = \"$MARIADB_DATABASE\";
      "
    ' |
    tr -d '\r[:space:]'
)"

case "$TABLE_COUNT" in
    ''|*[!0-9]*)
        fail "Jumlah tabel database tidak dapat dibaca."
        ;;
esac

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo "Database masih kosong."
    echo "Memulihkan backup ScientiCO..."

    gzip -dc "$DUMP_FILE" |
    docker compose exec -T db sh -lc '
    exec mariadb \
      --user="$MARIADB_USER" \
      --password="$MARIADB_PASSWORD" \
      "$MARIADB_DATABASE"
    '
else
    echo \
        "Database sudah berisi $TABLE_COUNT tabel. " \
        "Impor tidak diulang."
fi

DB_CHECK="$(
    docker compose exec -T db sh -lc '
    exec mariadb \
      --user="$MARIADB_USER" \
      --password="$MARIADB_PASSWORD" \
      --batch \
      --skip-column-names \
      "$MARIADB_DATABASE" <<'"'"'SQL'"'"'

SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = DATABASE();

SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = DATABASE()
AND table_name IN (
    "users",
    "journals",
    "submissions",
    "publications",
    "issues"
);

SELECT COUNT(*)
FROM journals
WHERE path = "SCO";

SQL
    ' |
    tr -d '\r'
)"

mapfile -t DB_VALUES <<< "$DB_CHECK"

FINAL_TABLE_COUNT="${DB_VALUES[0]:-}"
CORE_TABLE_COUNT="${DB_VALUES[1]:-}"
SCO_COUNT="${DB_VALUES[2]:-}"

case "$FINAL_TABLE_COUNT" in
    ''|*[!0-9]*)
        fail "Jumlah tabel hasil restore tidak valid."
        ;;
esac

if [ "$FINAL_TABLE_COUNT" -lt 120 ]; then
    fail \
        "Database tampak tidak lengkap: " \
        "hanya $FINAL_TABLE_COUNT tabel."
fi

if [ "$CORE_TABLE_COUNT" != "5" ]; then
    fail \
        "Tabel inti OJS tidak lengkap " \
        "($CORE_TABLE_COUNT dari 5)."
fi

if [ "$SCO_COUNT" != "1" ]; then
    fail \
        "Jurnal SCO tidak ditemukan " \
        "secara tepat satu kali."
fi

if [ "$FINAL_TABLE_COUNT" -ne "$EXPECTED_TABLES" ]; then
    echo
    echo \
        "Catatan: jumlah tabel saat ini " \
        "$FINAL_TABLE_COUNT."

    echo \
        "Backup awal memiliki " \
        "$EXPECTED_TABLES tabel."

    echo \
        "Tabel inti tetap lengkap, " \
        "sehingga proses dilanjutkan."
fi

echo \
    "Validasi database berhasil: " \
    "$FINAL_TABLE_COUNT tabel, jurnal SCO tersedia."

# ============================================================
# 7. Menjalankan dan memeriksa OJS
# ============================================================

log "[7/8] Menjalankan OJS..."

docker compose up -d ojs

HTTP="000"
FINAL_URL=""

BODY_FILE="$(mktemp)"
COOKIE_FILE="$(mktemp)"

for attempt in $(seq 1 60); do
    RESULT="$(
        curl \
            -sS \
            -L \
            --max-redirs 5 \
            --connect-timeout 5 \
            --max-time 20 \
            --cookie "$COOKIE_FILE" \
            --cookie-jar "$COOKIE_FILE" \
            -o "$BODY_FILE" \
            -w '%{http_code}|%{url_effective}' \
            "$URL" 2>/dev/null ||
        true
    )"

    HTTP="${RESULT%%|*}"
    FINAL_URL="${RESULT#*|}"

    printf \
        '  Pemeriksaan web %02d/60: HTTP %s\n' \
        "$attempt" \
        "${HTTP:-000}"

    if [ "$HTTP" = "200" ]; then
        break
    fi

    sleep 3
done

if [ "$HTTP" != "200" ]; then
    show_ojs_logs

    fail \
        "ScientiCO belum dapat dibuka " \
        "(HTTP $HTTP)."
fi

case "$FINAL_URL" in
    http://localhost:8081/*)
        ;;
    http://127.0.0.1:8081/*)
        ;;
    *)
        show_ojs_logs

        fail \
            "OJS mengarahkan ke alamat " \
            "yang tidak sesuai: $FINAL_URL"
        ;;
esac

if grep -Eqi \
    'Installation of Open Journal Systems|Instalasi Open Journal Systems' \
    "$BODY_FILE"; then

    show_ojs_logs

    fail \
        "Yang tampil adalah halaman instalasi, " \
        "bukan jurnal SCO yang sudah dipulihkan."
fi

if [ ! -s "$BODY_FILE" ]; then
    show_ojs_logs

    fail \
        "Halaman OJS memberikan HTTP 200, " \
        "tetapi isi halaman kosong."
fi

# ============================================================
# 8. Status akhir
# ============================================================

log "[8/8] Memeriksa status akhir..."

docker compose ps

echo
echo "============================================"
echo " PERSIAPAN BERHASIL"
echo "============================================"
echo "ScientiCO aktif di: $URL"
echo "Database dan jurnal SCO berhasil divalidasi."
echo "Folder proyek lama tidak disentuh."

if command -v explorer.exe >/dev/null 2>&1; then
    explorer.exe "$URL" >/dev/null 2>&1 || true
fi