#!/usr/bin/env bash
# Ajustes no modelo Gradle do Godot (android/build) para o aviso da Play Console
# "O app usa APIs ou parâmetros descontinuados para exibição de ponta a ponta"
# (Window.setStatusBarColor / setNavigationBarColor, descontinuados no Android 15).
#
# Quem chamava essas APIs era a atividade do modelo (GodotApp.java):
#   - EdgeToEdge.enable(this)               (androidx.activity, EdgeToEdgeApi23/26/29)
#   - SplashScreen.installSplashScreen(this) (androidx.core.splashscreen, Impl31)
# Troca por:
#   - WindowCompat.setDecorFitsSystemWindows(window, false): desenha de ponta a
#     ponta sem mexer na cor das barras (o próprio Godot já usa essa chamada);
#   - setTheme(GodotAppMainTheme): no Android 12+ a tela de abertura do sistema
#     continua vindo do tema (windowSplashScreen*), sem a biblioteca.
# E liga o R8 só para remover o código que ficou sem uso (sem ofuscar nem
# otimizar; todo o resto é mantido como está).
#
# A trava de orientação/tamanho (outro aviso) é resolvida no projeto:
# orientação Sensor + autoload ScreenFit.
# Uso: ci/android_play_compat.sh [pasta do android/build]
set -euo pipefail
B="${1:-android/build}"
APP="$B/src/main/java/com/godot/game/GodotApp.java"
test -f "$B/build.gradle"
test -f "$APP"

# 1) GodotApp.java sem EdgeToEdge.enable e sem installSplashScreen
python3 - "$APP" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "PLAY_COMPAT" not in s:
    s = s.replace("import androidx.activity.EdgeToEdge;\n", "")
    s = s.replace("import androidx.core.splashscreen.SplashScreen;\n", "import androidx.core.view.WindowCompat;\n")
    old = re.search(r"\tpublic void onCreate\(Bundle savedInstanceState\) \{\n.*?\n\t\}\n", s, re.S)
    assert old, "onCreate não encontrado em GodotApp.java"
    new = (
        "\tpublic void onCreate(Bundle savedInstanceState) {\n"
        "\t\t// PLAY_COMPAT: sem androidx EdgeToEdge nem biblioteca de splash (APIs descontinuadas no Android 15)\n"
        "\t\tsetTheme(R.style.GodotAppMainTheme);\n"
        "\t\tWindowCompat.setDecorFitsSystemWindows(getWindow(), false);\n"
        "\t\tsuper.onCreate(savedInstanceState);\n"
        "\t}\n"
    )
    s = s[:old.start()] + new + s[old.end():]
    open(p, "w", encoding="utf-8").write(s)
assert "androidx.activity.EdgeToEdge" not in s and "EdgeToEdge.enable(this)" not in s and "androidx.core.splashscreen" not in s and "SplashScreen.install" not in s
PY
grep -n -A6 "public void onCreate" "$APP"

# 2) R8 removendo apenas o que ficou sem uso
cat > "$B/play-compat-rules.pro" <<'EOF'
# Mantém TODO o código como está (o Godot chama Java por nome via JNI/reflexão),
# exceto EdgeToEdge (androidx.activity) e SplashScreen (androidx.core.splashscreen),
# que não são mais usados e chamam APIs descontinuadas no Android 15.
-dontobfuscate
-dontoptimize
-dontwarn **
-ignorewarnings
-keepattributes *
-keep class !androidx.activity.EdgeToEdge**,!androidx.core.splashscreen.**,** { *; }
EOF

if ! grep -q "play-compat-rules.pro" "$B/build.gradle"; then
  # adiciona minify no bloco "release {" de buildTypes
  awk '
    /buildTypes[[:space:]]*\{/ { inbt=1 }
    inbt && !done && /^[[:space:]]*release[[:space:]]*\{/ {
      print
      print "            minifyEnabled true"
      print "            shrinkResources false"
      print "            proguardFiles \"play-compat-rules.pro\""
      done=1; next
    }
    { print }
  ' "$B/build.gradle" > "$B/build.gradle.tmp" && mv "$B/build.gradle.tmp" "$B/build.gradle"
fi
grep -q "play-compat-rules.pro" "$B/build.gradle"
echo "android_play_compat: ok"
