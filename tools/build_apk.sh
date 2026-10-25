#!/usr/bin/env bash
# Gera build/ArrowSurvival.apk a partir do projeto (usado pelo GitHub Actions).
# Requer: Godot 4.3 no PATH (variável GODOT), export templates 4.3 e Android SDK configurado.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
VERSION_CODE="${VERSION_CODE:-1}"

# Chave de assinatura do APK de teste (sempre a mesma, para o Android aceitar atualizações).
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/android/arrow_survival.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="arrowsurvival"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="arrowsurvival"

# O número de versão precisa crescer a cada build para o Android instalar por cima.
sed -i "s/^version\/code=.*/version\/code=${VERSION_CODE}/" export_presets.cfg

mkdir -p build
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Android" build/ArrowSurvival.apk
ls -lh build/ArrowSurvival.apk
