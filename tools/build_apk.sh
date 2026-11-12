#!/usr/bin/env bash
# Gera build/ArrowSurvival.apk e build/ArrowSurvival.aab (usado pelo GitHub Actions).
# Requer: Godot 4.7.2 (variável GODOT), export templates 4.7.2 e Android SDK configurado.
#
# Assinatura:
# - APK de teste: sempre a chave de teste do repositório (keystore/), para o
#   Android aceitar instalar por cima das versões anteriores.
# - AAB: chave de upload da Play Store se as variáveis UPLOAD_KEYSTORE_PATH,
#   UPLOAD_KEYSTORE_PASSWORD e UPLOAD_KEY_ALIAS existirem; senão, a de teste
#   (nesse caso o AAB precisa ser reassinado com a chave de upload antes de enviar).
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
VERSION_CODE="${VERSION_CODE:-1}"
TEMPLATE_VERSION="4.7.2.stable"
TEMPLATES="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/$TEMPLATE_VERSION}"

# O número de versão precisa crescer a cada build para o Android instalar por cima.
cp export_presets.cfg /tmp/export_presets.cfg.bak
trap 'cp /tmp/export_presets.cfg.bak export_presets.cfg' EXIT
sed -i "s/^version\/code=.*/version\/code=${VERSION_CODE}/" export_presets.cfg

# "Android Build Template" (compilação Gradle, necessária para o plugin AdMob),
# com os ajustes para os avisos da Play Console.
if [ ! -f android/build/build.gradle ] || [ "$(cat android/.build_version 2>/dev/null)" != "$TEMPLATE_VERSION" ]; then
  rm -rf android
  mkdir -p android/build
  unzip -q -o "$TEMPLATES/android_source.zip" -d android/build
  printf "%s" "$TEMPLATE_VERSION" > android/.build_version
  touch android/build/.gdignore
  bash ci/android_play_compat.sh android/build
fi

mkdir -p build
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/keystore/arrow_survival.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="arrowsurvival"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="arrowsurvival"
"$GODOT" --headless --path . --export-release "Android" build/ArrowSurvival.apk
ls -lh build/ArrowSurvival.apk

if [ -n "${UPLOAD_KEYSTORE_PATH:-}" ] && [ -n "${UPLOAD_KEYSTORE_PASSWORD:-}" ] && [ -n "${UPLOAD_KEY_ALIAS:-}" ]; then
  export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$UPLOAD_KEYSTORE_PATH"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$UPLOAD_KEY_ALIAS"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$UPLOAD_KEYSTORE_PASSWORD"
  echo "AAB assinado com a chave de upload."
else
  echo "AAB assinado com a chave de TESTE (reassine com a chave de upload antes de enviar à Play Store)."
fi
"$GODOT" --headless --path . --export-release "Android AAB" build/ArrowSurvival.aab
ls -lh build/ArrowSurvival.aab
