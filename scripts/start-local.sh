#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
docker compose up -d
URL="http://localhost:8081/SCO/id"
for _ in $(seq 1 40); do
    HTTP="$(curl -sS -L -o /dev/null -w '%{http_code}' "$URL" 2>/dev/null || true)"
    [ "$HTTP" = "200" ] && break
    sleep 2
done
if command -v explorer.exe >/dev/null 2>&1; then explorer.exe "$URL" >/dev/null 2>&1 || true; fi
docker compose ps
