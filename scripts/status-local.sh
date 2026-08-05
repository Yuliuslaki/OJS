#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
docker compose ps
echo
curl -sS -L -o /dev/null -w 'ScientiCO HTTP %{http_code}\n' http://localhost:8081/SCO/id 2>/dev/null || echo 'ScientiCO belum aktif.'
