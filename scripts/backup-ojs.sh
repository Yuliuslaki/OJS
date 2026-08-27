#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/ojs-sco-local}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/ojs-private-backups}"
OJS_URL="${OJS_URL:-http://127.0.0.1:8081/SCO/id}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/full-backup-$TIMESTAMP"
COOKIE_FILE="$(mktemp)"
RETENTION_COUNT="${RETENTION_COUNT:-7}"
LOCK_FILE="${LOCK_FILE:-$BACKUP_ROOT/.backup-ojs.lock}"

OJS_STOPPED=0

cleanup() {
    rm -f "$COOKIE_FILE"

    if [ "$OJS_STOPPED" -eq 1 ]; then
        echo "Menjalankan kembali container OJS..."
        cd "$PROJECT_DIR"
        docker compose up -d ojs >/dev/null
    fi
}

apply_retention() {
    local backups=()
    local index
    local name
    local candidate

    mapfile -t backups < <(
        find "$BACKUP_ROOT"             -mindepth 1             -maxdepth 1             -type d             -name 'full-backup-*'             -printf '%f\n' |
        sort -r
    )

    echo
    echo "=== Retensi backup ==="
    echo "Backup yang dipertahankan: $RETENTION_COUNT"
    echo "Backup lengkap tersedia  : ${#backups[@]}"

    if [ "${#backups[@]}" -le "$RETENTION_COUNT" ]; then
        echo "Tidak ada backup lama yang perlu dihapus."
        return
    fi

    for ((index = RETENTION_COUNT; index < ${#backups[@]}; index++)); do
        name="${backups[$index]}"

        if ! [[ "$name" =~ ^full-backup-[0-9]{8}-[0-9]{6}$ ]]; then
            echo "Dilewati karena nama tidak valid: $name"
            continue
        fi

        candidate="$BACKUP_ROOT/$name"

        if [ "$candidate" = "$BACKUP_DIR" ]; then
            echo "Dilewati karena merupakan backup aktif: $candidate"
            continue
        fi

        echo "Menghapus backup lama: $candidate"
        rm -rf --one-file-system -- "$candidate"
    done
}

trap cleanup EXIT

cd "$PROJECT_DIR"

if ! [[ "$RETENTION_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "GAGAL: RETENTION_COUNT harus berupa angka bulat minimal 1."
    exit 1
fi

if ! command -v flock >/dev/null 2>&1; then
    echo "GAGAL: perintah flock tidak tersedia."
    exit 1
fi

mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"

exec 9>"$LOCK_FILE"
chmod 600 "$LOCK_FILE"

if ! flock -n 9; then
    echo "GAGAL: proses backup OJS lain sedang berjalan."
    echo "Lock file: $LOCK_FILE"
    exit 1
fi

echo "Lock backup berhasil diperoleh."

echo "Memeriksa Docker Compose..."
docker compose config --quiet

echo "Memeriksa status database..."
if ! docker compose ps --status running --services |
    grep -qx 'db'; then
    echo "GAGAL: container database tidak berjalan."
    exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
umask 077

echo "Backup akan dibuat di:"
echo "$BACKUP_DIR"
echo

{
    echo "Tanggal backup: $(date --iso-8601=seconds)"
    echo "Host: $(hostname)"
    echo "Project: $PROJECT_DIR"
    echo "Git branch: $(git branch --show-current)"
    echo "Git commit: $(git rev-parse HEAD)"
    echo
    echo "Status Git:"
    git status -sb
    echo
    echo "Status container sebelum backup:"
    docker compose ps
} > "$BACKUP_DIR/backup-info.txt"

echo "Menghentikan OJS sementara..."
docker compose stop ojs
OJS_STOPPED=1

echo "Membuat dump database..."
docker compose exec -T db sh -lc '
exec mariadb-dump \
    --user=root \
    --password="$MARIADB_ROOT_PASSWORD" \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    --events \
    --hex-blob \
    --default-character-set=utf8mb4 \
    "$MARIADB_DATABASE"
' | gzip -9 > "$BACKUP_DIR/database.sql.gz"

test -s "$BACKUP_DIR/database.sql.gz"

echo "Mengarsipkan file dan konfigurasi..."

ITEMS=(
    "ojs-files"
    "ojs-public"
    "ojs-runtime-public"
    "ojs-theme"
    "pkp-locale"
    "ojs-locale"
    "ojs-plugins"
    "pkp-classes"
    "apache"
    "php-ini"
    ".htaccess"
    ".env"
    ".env.example"
    "config.inc.php"
    "config.example.inc.php"
    "docker-compose.yml"
    "docker-compose.example.yml"
    ".gitignore"
    "README.md"
    "scripts"
)

EXISTING_ITEMS=()

for item in "${ITEMS[@]}"; do
    if [ -e "$item" ]; then
        EXISTING_ITEMS+=("$item")
    fi
done

sudo tar \
    --numeric-owner \
    -czf "$BACKUP_DIR/files-and-config.tar.gz" \
    "${EXISTING_ITEMS[@]}"

sudo chown -R "$USER:$USER" "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
chmod 600 "$BACKUP_DIR"/*

echo "Menjalankan kembali OJS..."
docker compose up -d ojs
OJS_STOPPED=0

sleep 12

echo "Memverifikasi arsip..."
gzip -t "$BACKUP_DIR/database.sql.gz"
tar -tzf "$BACKUP_DIR/files-and-config.tar.gz" >/dev/null

(
    cd "$BACKUP_DIR"

    sha256sum \
        database.sql.gz \
        files-and-config.tar.gz \
        backup-info.txt \
        > SHA256SUMS

    chmod 600 SHA256SUMS
    sha256sum -c SHA256SUMS
)

echo
echo "Memeriksa OJS..."

curl -sS \
    -c "$COOKIE_FILE" \
    -b "$COOKIE_FILE" \
    -L \
    --max-redirs 10 \
    -o /dev/null \
    -w "OJS HTTP %{http_code}\n" \
    "$OJS_URL" |
    grep -q 'OJS HTTP 200'

echo "OJS HTTP 200"

apply_retention

echo
echo "=== Hasil backup ==="
du -h "$BACKUP_DIR"/*

echo
echo "Backup selesai:"
echo "$BACKUP_DIR"

rm -f "$COOKIE_FILE"
trap - EXIT
