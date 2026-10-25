# Arrow Survival

Jogo 2D de sobrevivência infinita com arco e flecha e personagens stickman,
feito em **Godot 4.3** (GDScript) para **Android**, na vertical.

Os arqueiros ficam em **ilhotas flutuantes**. Quem morre cai da plataforma
(com ragdoll, sangue estilizado e, às vezes, desmembramento). Os inimigos são
substituídos por novos, cada vez mais rápidos, precisos e numerosos.

---

## 1. Instalar o jogo no celular (sem computador)

O APK é **compilado automaticamente** pelo GitHub a cada atualização da branch `main`
(arquivo `.github/workflows/build-apk.yml`). Basta baixar e instalar:

1. No navegador do celular (logado no GitHub), abra a página do repositório.
2. Toque em **Releases** → **"Arrow Survival — APK mais recente"**.
3. Em **Assets**, toque em **`ArrowSurvival.apk`**.
4. Abra o arquivo baixado e instale. Se o Android pedir, permita
   **"Instalar apps desconhecidos"**. Se o Play Protect avisar, toque em
   **"Instalar mesmo assim"** (acontece com qualquer APK fora da Play Store).

**Atualizações:** instale o APK novo por cima, sem desinstalar. Todas as versões usam
a mesma assinatura de teste (`keystore/`) e um número de versão crescente.

---

## 2. Como jogar

| Ação | Como |
|---|---|
| Mirar e atirar | Toque, **arraste o dedo para trás** (como um estilingue) e solte. Quanto mais puxar, mais forte. |
| Trocar de flecha | Toque nos ícones na barra de baixo (ou em **FLECHAS** no menu). |
| Recuperar vida | Acerte a **maçã vermelha** que sobe do fundo da tela. |
| Recuperar estamina | Acerte a **fruta-estrela amarela**. |
| Pausar | Botão **II** no canto (ou o botão Voltar do Android). |

- **Vida:** o jogador tem 150; os inimigos começam com 40 (aumenta aos poucos).
- **Dano por região:** cabeça ×3 (×2,5 no jogador; elmo reduz para ×2), tronco ×1,
  pernas ×0,7, braço ×0,6.
- **Estamina:** cada flecha gasta estamina (número abaixo do ícone) e segurar o arco
  puxado cansa. Cansado, o personagem ofega, a mira treme e o tiro sai fraco.
  Ela se recupera sozinha quando você não está mirando.
- **Pontos:** 10 por abate (15 caçador, 25 elite), **+15 na cabeça**, bônus de
  **combo** para abates seguidos em até 2,5 s, +5 por fruta.
- **Recorde** e **maior sequência** ficam salvos no aparelho.

### Flechas desbloqueáveis (abates seguidos, sem morrer)

| Flecha | Abates | Efeito | Estamina |
|---|---:|---|---:|
| Comum | 0 | — | 12 |
| Veneno | 10 | Dano contínuo por 4 s | 14 |
| Fogo | 20 | Queima por 3 s | 16 |
| Gelo | 35 | Congela o inimigo (não atira) por 3 s | 16 |
| Explosiva | 50 | Explosão em área | 24 |
| Tripla | 75 | Três flechas de uma vez | 26 |

Os valores ficam em `scripts/autoload/game_data.gd` (constante `ARROWS`).

### Dificuldade infinita
O nível cresce com os abates e com o tempo (`game.gd → difficulty_level()`):
1 inimigo no começo → até 4 ao mesmo tempo; mira mais rápida e precisa; menos tempo
entre tiros; mais vida; inimigos **caçadores** (capuz) e **elite** (elmo) aparecem depois.
Os inimigos surgem só dentro de uma **área limite** à direita (`ENEMY_AREA`) e sempre
afastados uns dos outros (`MIN_ENEMY_DISTANCE`).

---

## 3. Anúncios (AdMob)

Implementados com o plugin **Poing Studios Godot AdMob v5.0.0** (`addons/admob`).
Regras para não incomodar (`scripts/autoload/ads.gd`):

- **Nunca** há anúncio ao abrir o app, nem anúncio obrigatório na **primeira sessão**
  (a primeira vez que o jogo é aberto depois de instalado).
- **Intersticial** só entre partidas (ao tocar em "Jogar de novo" ou "Menu"), no máximo
  **a cada 3 partidas** e com pelo menos **150 s** entre um e outro. Partidas com menos
  de 25 s não contam.
- **Premiado (opcional):** na tela de derrota, "Continuar (ver anúncio)" revive o
  jogador uma vez por partida, com 60% da vida, mantendo a sequência de abates.
- **Sem banners.**

> Por enquanto são usados os **IDs de TESTE** do Google (aparece "Test Ad").
> Antes de publicar: crie o app no AdMob e troque `INTERSTITIAL_ID` e `REWARDED_ID`
> em `ads.gd` e o **App ID** em `project.godot` (seção `[admob]`,
> `general/android/app_id`). Isso será feito na Etapa 6.

---

## 4. Estrutura do projeto

```
project.godot                 Configurações (720x1280 vertical, Compatibility, autoloads)
export_presets.cfg            Exportação Android (Gradle, arm64 + armv7)
scenes/
  menu.tscn                   Menu inicial
  game.tscn                   Partida
scripts/
  autoload/
    game_data.gd              Flechas, recorde, desbloqueios e opções salvos (user://save.cfg)
    sfx.gd                    Efeitos sonoros sintetizados por código (sem arquivos de áudio)
    ads.gd                    Anúncios e regras de frequência
  game/
    game.gd                   Partida: surgimento, dificuldade, frutas, pontos, derrota, reviver
    stickman.gd               Stickman: desenho, animação, zonas de acerto, status, morte
    player_archer.gd          Jogador: mira por toque, estamina
    enemy_archer.gd           Inimigo: IA que mira (balística) e atira
    ragdoll.gd                Corpo caindo (física Verlet) com desmembramento
    arrow.gd / arrow_draw.gd  Flecha: física, rastro, efeitos e desenho
    floating_platform.gd      Ilhota flutuante (entra, balança, desmorona)
    fruit.gd                  Frutas de vida e estamina
    fx.gd                     Partículas (sangue, suco, faíscas, explosão) e textos
    aim_guide.gd              Mira e trajetória prevista
    background.gd             Céu, sol, montanhas, névoa e nuvens animadas
  menu/
    menu.gd                   Menu com duelo de stickmen ao fundo
    title_logo.gd             Título animado
    arrow_select_panel.gd     Escolha de flechas
  ui/
    ui_kit.gd                 Botões, painéis e transições no mesmo estilo
    game_hud.gd               HUD da partida
    stat_bar.gd               Barras animadas de vida/estamina
    arrow_icon.gd             Ícone de cada flecha
    pause_panel.gd            Pausa
    game_over_panel.gd        Tela de derrota
addons/admob/                 Plugin AdMob (Poing Studios, licença MIT)
keystore/                     Chave de assinatura do APK de TESTE
tools/build_apk.sh            Script de compilação do APK (usado pelo GitHub)
.github/workflows/            Compilação automática do APK
```

Nenhuma imagem ou som externo: tudo é desenhado com `_draw()` e os sons são gerados
por código, o que deixa o jogo leve e 100% offline (exceto os anúncios).

### Camadas de física
| Camada | Valor | Uso |
|---:|---:|---|
| 1 | 1 | Plataformas (mundo) |
| 2 | 2 | Zonas de acerto do jogador |
| 3 | 4 | Zonas de acerto dos inimigos |
| 6 | 32 | Frutas |

---

## 5. Desempenho
- Flechas sem RigidBody: velocidade + gravidade e um raio por quadro (`intersect_ray`).
- Ragdoll em Verlet (sem física pesada), removido ao sair da tela ou após 6 s.
- Limites: 45 flechas, 420 partículas, 12 textos flutuantes; flechas presas somem em 4 s.
- Renderizador Compatibility (OpenGL), o mais leve para celulares modestos.

---

## 6. Compilar o APK manualmente (opcional)
`tools/build_apk.sh` gera `build/ArrowSurvival.apk` num Linux com Godot 4.3, export
templates 4.3, JDK 17 e Android SDK (plataforma 36). Ele instala o *Android Build
Template* em `android/build` e ajusta o `compileSdk` para 36, exigido pelo plugin AdMob.

---

## 7. Roteiro

- [x] **Etapa 1** — Protótipo: cenário, stickmen, mira por toque, flechas físicas
- [x] **Etapa 2** — Combate: inimigos que atiram, vida, dano e eliminação
- [x] **Etapa 3** — Impactos: zonas de acerto, sangue, reações, ragdoll e desmembramento
- [x] **Etapa 4** — Sobrevivência: pontos, recorde salvo, surgimento em área limite, dificuldade
- [x] **Etapa 5** — Menu animado, escolha de flechas, pausa, derrota, sons, frutas, estamina
- [x] Anúncios com IDs de teste (intersticial espaçado + premiado opcional)
- [ ] **Etapa 6** — Publicação: conta AdMob real, chave de envio privada, AAB, consentimento
      (UMP/LGPD/GDPR), ficha da Play Store e testes fechados
