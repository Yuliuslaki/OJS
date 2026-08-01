#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/ojs-docker}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/ojs-private-backups}"
BACKUP_DIR="${1:-}"

TEMP_CONTAINER="ojs-restore-test-$(date +%s)-$$"
TEMP_DATABASE="ojs_restore_test"
TEMP_ROOT_PASSWORD="$(openssl rand -hex 24)"

cleanup() {
    if docker container inspect "$TEMP_CONTAINER" >/dev/null 2>&1; then
        echo
        echo "Menghapus container database sementara..."
        docker rm -f "$TEMP_CONTAINER" >/dev/null
    fi
}

trap cleanup EXIT

cd "$PROJECT_DIR"

echo "Memeriksa Docker..."
docker info >/dev/null
docker compose config --quiet

if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$(
        find "$BACKUP_ROOT" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -name 'full-backup-*' \
            -printf '%T@ %p\n' |
        sort -nr |
        head -n 1 |
        cut -d' ' -f2-
    )"
fi

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    echo "GAGAL: folder backup tidak ditemukan."
    exit 1
fi

DUMP_FILE="$BACKUP_DIR/database.sql.gz"
CHECKSUM_FILE="$BACKUP_DIR/SHA256SUMS"

if [ ! -f "$DUMP_FILE" ]; then
    echo "GAGAL: database.sql.gz tidak ditemukan di:"
    echo "$BACKUP_DIR"
    exit 1
fi

if [ ! -f "$CHECKSUM_FILE" ]; then
    echo "GAGAL: SHA256SUMS tidak ditemukan di:"
    echo "$BACKUP_DIR"
    exit 1
fi

DB_IMAGE="$(
    docker compose config --images |
    awk '/^mariadb:/{print; exit}'
)"

if [ -z "$DB_IMAGE" ]; then
    DB_IMAGE="mariadb:10.6"
fi

echo
echo "=== Konfigurasi pengujian ==="
echo "Backup          : $BACKUP_DIR"
echo "Dump database   : $DUMP_FILE"
echo "Image MariaDB   : $DB_IMAGE"
echo "Container uji   : $TEMP_CONTAINER"
echo "Database uji    : $TEMP_DATABASE"

echo
echo "Memverifikasi checksum backup..."

(
    cd "$BACKUP_DIR"
    sha256sum -c SHA256SUMS
)

echo
echo "Memeriksa struktur gzip..."
gzip -t "$DUMP_FILE"
echo "Struktur gzip: OK"

echo
echo "Menjalankan MariaDB sementara..."

docker run -d \
    --name "$TEMP_CONTAINER" \
    --env "MARIADB_ROOT_PASSWORD=$TEMP_ROOT_PASSWORD" \
    --env "MARIADB_DATABASE=$TEMP_DATABASE" \
    --env "TZ=Asia/Makassar" \
    "$DB_IMAGE" \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \
    >/dev/null

echo "Menunggu MariaDB siap..."

READY=0

for attempt in $(seq 1 30); do
    if docker exec "$TEMP_CONTAINER" \
        healthcheck.sh --connect --innodb_initialized \
        >/dev/null 2>&1; then
        READY=1
        echo "MariaDB sementara siap pada pemeriksaan ke-$attempt."
        break
    fi

    if ! docker container inspect "$TEMP_CONTAINER" \
        --format '{{.State.Running}}' 2>/dev/null |
        grep -qx true; then
        echo "GAGAL: container MariaDB sementara berhenti."
        docker logs "$TEMP_CONTAINER"
        exit 1
    fi

    sleep 2
done

if [ "$READY" -ne 1 ]; then
    echo "GAGAL: MariaDB sementara tidak siap dalam batas waktu."
    docker logs "$TEMP_CONTAINER"
    exit 1
fi

echo
echo "Mengimpor database ke container sementara..."

gzip -dc "$DUMP_FILE" |
docker exec -i "$TEMP_CONTAINER" sh -lc '
exec mariadb \
    --user=root \
    --password="$MARIADB_ROOT_PASSWORD" \
    "$MARIADB_DATABASE"
'

echo "Impor database: OK"

echo
echo "Memeriksa tabel inti OJS..."

TABLE_COUNT="$(
    printf '%s\n' \
        'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE();' |
    docker exec -i "$TEMP_CONTAINER" sh -lc '
    exec mariadb \
        --user=root \
        --password="$MARIADB_ROOT_PASSWORD" \
        --batch \
        --skip-column-names \
        "$MARIADB_DATABASE"
    '
)"

CORE_TABLE_COUNT="$(
    printf '%s\n' \
        "SELECT COUNT(*) FROM information_schema.tables
         WHERE table_schema = DATABASE()
         AND table_name IN (
             'users',
             'journals',
             'submissions',
             'publications',
             'issues'
         );" |
    docker exec -i "$TEMP_CONTAINER" sh -lc '
    exec mariadb \
        --user=root \
        --password="$MARIADB_ROOT_PASSWORD" \
        --batch \
        --skip-column-names \
        "$MARIADB_DATABASE"
    '
)"

if ! [[ "$TABLE_COUNT" =~ ^[0-9]+$ ]] || [ "$TABLE_COUNT" -eq 0 ]; then
    echo "GAGAL: tidak ada tabel yang berhasil dipulihkan."
    exit 1
fi

if [ "$CORE_TABLE_COUNT" -ne 5 ]; then
    echo "GAGAL: tabel inti OJS tidak lengkap."
    echo "Tabel inti ditemukan: $CORE_TABLE_COUNT dari 5"
    exit 1
fi

echo "Jumlah tabel       : $TABLE_COUNT"
echo "Tabel inti OJS     : $CORE_TABLE_COUNT dari 5"

echo
echo "=== Ringkasan data hasil restore ==="

cat <<'SQL' |
SELECT CONCAT('users=', COUNT(*)) FROM users;
SELECT CONCAT('journals=', COUNT(*)) FROM journals;
SELECT CONCAT('submissions=', COUNT(*)) FROM submissions;
SELECT CONCAT('publications=', COUNT(*)) FROM publications;
SELECT CONCAT('issues=', COUNT(*)) FROM issues;
SQL
docker exec -i "$TEMP_CONTAINER" sh -lc '
exec mariadb \
    --user=root \
    --password="$MARIADB_ROOT_PASSWORD" \
    --batch \
    --skip-column-names \
    "$MARIADB_DATABASE"
'

echo
echo "Memeriksa integritas seluruh tabel..."

docker exec "$TEMP_CONTAINER" sh -lc '
if command -v mariadb-check >/dev/null 2>&1; then
    exec mariadb-check \
        --user=root \
        --password="$MARIADB_ROOT_PASSWORD" \
        "$MARIADB_DATABASE"
else
    exec mysqlcheck \
        --user=root \
        --password="$MARIADB_ROOT_PASSWORD" \
        "$MARIADB_DATABASE"
fi
' >/dev/null

echo "Integritas tabel: OK"

echo
echo "=========================================="
echo "UJI RESTORE BERHASIL"
echo "Database aktif tidak disentuh."
echo "Backup: $BACKUP_DIR"
echo "Jumlah tabel dipulihkan: $TABLE_COUNT"
echo "=========================================="
