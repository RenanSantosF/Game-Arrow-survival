#!/usr/bin/env bash
# Joga sozinho no emulador: abre, toca em JOGAR e atira sem parar (puxar e soltar)
# por ~3 minutos, tocando nos botões do fim de partida. Coleta logcat e capturas.
set -u
PKG=${PKG:-com.renansantos.arrowsurvival}
D=${DIAG:-diag}
mkdir -p "$D"
adb wait-for-device
adb shell settings put global window_animation_scale 0 || true
adb shell settings put secure immersive_mode_confirmations confirmed || true
adb install -r build/emu.apk
adb logcat -c

W=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | cut -dx -f1)
H=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | cut -dx -f2)
S=$(python3 -c "print($W/720)")
GH=$(python3 -c "print(round($H/($W/720)))")
echo "tela ${W}x${H}, escala $S, altura do jogo $GH"
px() { python3 -c "print(int($1*$S))"; }
tap() { adb shell input tap "$(px $1)" "$(px $2)"; sleep "${3:-0.6}"; }
swipe() { adb shell input swipe "$(px $1)" "$(px $2)" "$(px $3)" "$(px $4)" "${5:-350}"; }
shot() { adb exec-out screencap -p > "$D/$1.png"; }
CRASH=0
alive() {
  if adb shell pidof "$PKG" > /dev/null; then echo "[OK] app rodando: $1"
  else echo "[CRASH] app FECHOU em: $1"; CRASH=1; fi
}

adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 45   # abertura FT conta quadros; o emulador sem GPU é lento
alive "abertura"; shot 01_menu
tap 360 $((GH - 482)) 6     # JOGAR
alive "início da partida"; shot 02_partida

play_for() {  # play_for SEGUNDOS ETIQUETA
  local END=$((SECONDS + $1)); local n=0
  while [ $SECONDS -lt $END ] && [ $CRASH -eq 0 ]; do
    # puxa o dedo para trás (para baixo/esquerda) e solta: atira para cima/direita
    X=$((250 + RANDOM % 220)); Y=$((GH / 2 + RANDOM % 200))
    swipe $X $Y $((X - 80 - RANDOM % 160)) $((Y + 60 + RANDOM % 160)) 300
    n=$((n + 1))
    if [ $((n % 12)) -eq 0 ]; then
      alive "$2 tiro $n"
      # botões do fim de partida/continuar (toques no meio-baixo não atrapalham o jogo)
      tap 360 $((GH - 300)) 0.3
    fi
    [ $((n % 60)) -eq 0 ] && shot "03_$2_$n"
  done
}

play_for 120 parte1
alive "fim da parte 1"; shot 04_fim_parte1

# Fecha e abre de novo: o modo leve (ligado sozinho no emulador lento) agora
# começa já com a imagem em 720p.
adb shell am force-stop "$PKG"; sleep 2
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 45
alive "reabertura"; shot 05_menu_reaberto
tap 360 $((GH - 482)) 6
play_for 90 parte2
alive "fim"; shot 06_fim

adb logcat -d > "$D/logcat.txt"
echo "=== trechos importantes do logcat ==="
grep -E "FATAL|SIGSEGV|SIGABRT|backtrace|Abort message|#0[0-9] pc|godot.*(ERROR|SCRIPT)|E godot|USER ERROR|\[ARROW\]" "$D/logcat.txt" | head -150 || true
echo "=== fim ==="
[ $CRASH -eq 0 ] && echo "RESULTADO: SEM TRAVAMENTO" || echo "RESULTADO: TRAVOU"
exit 0
