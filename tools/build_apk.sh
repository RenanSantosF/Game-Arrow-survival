#!/usr/bin/env bash
# Gera build/ArrowSurvival.apk a partir do projeto (usado pelo GitHub Actions).
# Requer: Godot 4.3 no PATH (variável GODOT), export templates 4.3 e Android SDK configurado.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
VERSION_CODE="${VERSION_CODE:-1}"

# Chave de assinatura do APK de teste (sempre a mesma, para o Android aceitar atualizações).
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/keystore/arrow_survival.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="arrowsurvival"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="arrowsurvival"

# O número de versão precisa crescer a cada build para o Android instalar por cima.
cp export_presets.cfg /tmp/export_presets.cfg.bak
trap 'cp /tmp/export_presets.cfg.bak export_presets.cfg' EXIT
sed -i "s/^version\/code=.*/version\/code=${VERSION_CODE}/" export_presets.cfg

# Instala o "Android Build Template" (necessário para a compilação Gradle e o plugin AdMob).
if [ ! -f android/build/build.gradle ]; then
  TEMPLATES="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/4.3.stable}"
  mkdir -p android/build
  unzip -q -o "$TEMPLATES/android_source.zip" -d android/build
  printf "4.3.stable" > android/.build_version
  touch android/build/.gdignore
  # O plugin AdMob exige compilar contra o Android SDK 36 (o template do Godot 4.3 usa 34).
  sed -i "s/compileSdk         : 34,/compileSdk         : 36,/" android/build/config.gradle
  printf "\nandroid.suppressUnsupportedCompileSdk=36\n" >> android/build/gradle.properties
fi

mkdir -p build
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Android" build/ArrowSurvival.apk
ls -lh build/ArrowSurvival.apk
