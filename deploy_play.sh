#!/bin/zsh
# Deploy de TinyMont a Google Play (track de prueba interna).
# Uso: ./deploy_play.sh            -> tests + export AAB + subida a prueba interna
#      ./deploy_play.sh --solo-subir  -> sube el AAB ya exportado sin re-exportar
set -euo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT_BIN:-godot}"
AAB="builds/android/TinyMont.aab"

if [[ "${1:-}" != "--solo-subir" ]]; then
  echo "==> Tests"
  "$GODOT" --headless --path . res://tests/test_misiones.tscn > /dev/null

  echo "==> Export AAB (release firmado)"
  "$GODOT" --headless --export-release "Android" "$AAB" --quit > /tmp/tinymont_aab.log 2>&1
  if rg -qi 'ERROR' /tmp/tinymont_aab.log; then
    echo "Export con errores; ver /tmp/tinymont_aab.log" >&2
    exit 1
  fi
fi

[[ -f "$AAB" ]] || { echo "No existe $AAB" >&2; exit 1; }

echo "==> Subida a Google Play (prueba interna)"
fastlane android internal

echo "==> Listo. Promover a produccion: fastlane android promote (o desde Play Console)."
