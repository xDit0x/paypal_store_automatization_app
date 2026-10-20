#!/usr/bin/env bash
#
# Regenera todos los iconos de la app Restock.
#
#   1. flutter_launcher_icons genera los iconos de cada plataforma a partir
#      de assets/images/restock_logo.png.
#   2. build_app_icons.py rehace las capas del icono adaptativo de Android y
#      los iconos maskable de web, que flutter_launcher_icons no deja en la
#      zona segura.
#
# Uso: bash tool/generate_app_icons.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Iconos de cada plataforma (flutter_launcher_icons)"
dart run flutter_launcher_icons

echo "==> Capas adaptativas e iconos maskable (build_app_icons.py)"
python3 tool/build_app_icons.py

echo "==> Listo"
