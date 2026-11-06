#!/usr/bin/env bash
# Incrementa APP_VERSION en index.html (patch: 40.0 -> 40.1).
# Uso: ./scripts/bump_version.sh
# Opcional (auto en cada push):
#   git config core.hooksPath .githooks

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index.html"

current=$(grep -oE "const APP_VERSION = '[0-9]+\.[0-9]+'" "$INDEX" | head -1 | grep -oE "[0-9]+\.[0-9]+")
if [[ -z "$current" ]]; then
  echo "No se encontró APP_VERSION en index.html" >&2
  exit 1
fi

major="${current%%.*}"
minor="${current##*.}"
next_minor=$((minor + 1))
next="${major}.${next_minor}"

sed -i '' "s/const APP_VERSION = '${current}'/const APP_VERSION = '${next}'/g" "$INDEX"
sed -i '' "s/CAPYM V${current}/CAPYM V${next}/g" "$INDEX"
sed -i '' "s/Capym V${current}/Capym V${next}/g" "$INDEX" 2>/dev/null || true

echo "Versión actualizada: ${current} -> ${next}"
