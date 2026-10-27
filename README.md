# Arrow Survival

Jogo 2D de sobrevivência infinita com arco e flecha e personagens stickman,
feito em **Godot 4.3** (GDScript) para **Android**, na vertical.

Os arqueiros ficam em **ilhotas flutuantes**. Quem morre cai da plataforma
(com ragdoll, sangue estilizado e, às vezes, desmembramento ou partido ao meio).
Os inimigos vêm em **ondas** e **eras** cada vez mais fortes, com mini-chefes e
**chefes** gigantes; as moedas ganhas compram **melhorias** para o personagem.

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
| Trocar de flecha | Toque nos ícones na barra de baixo (só aparecem as flechas **equipadas**). |
| Recuperar vida | Acerte a **maçã vermelha** que sobe do fundo da tela. |
| Recuperar estamina | Acerte a **fruta-estrela amarela**. |
| Pausar | Botão **II** no canto (ou o botão Voltar do Android). |

- **Vida:** o jogador tem 150 (mais com melhorias); os inimigos começam com ~42.
- **Dano por região:** cabeça ×3 (×2 no jogador; elmo/coroa reduzem para ×2),
  **barriga ×2,5** (×1,5 no jogador), peito ×1, pernas ×0,7, braço ×0,6. As flechas inimigas tiram de 10 a 19 de vida (sobe com as ondas).
- **Estamina:** cada flecha tem um custo (número abaixo do ícone) que vale para o arco
  **totalmente puxado**; tiros mais fracos gastam menos (até 40% do custo). Segurar o arco
  puxado cansa. Cansado, o personagem ofega, a mira treme e o tiro sai fraco.
  **Acertar recupera estamina:** +18 na cabeça, +10 na barriga, +4 no peito, +2 em braço/perna.
- **Mira:** dá para mirar quase na vertical, para cima ou para baixo.
- **Desmembramento:** tiros fortes no tronco (principalmente na barriga) podem **partir o
  corpo ao meio**; o Arpão e as explosões partem com mais facilidade.
- **Membros quebrados (inimigo vivo):** dano acumulado num braço ou perna **quebra** o
  membro (braço quebrado: mira bem pior; perna quebrada: mais lento e torto). Mais dano
  **arranca** o membro: sem o braço do arco o inimigo não atira mais e sangra até morrer.
  O Arpão pode quebrar ou arrancar de uma vez.
- **Pontos:** 10 por abate (+5 por era), 40+ mini-chefe, 150+ chefe, **+15 na cabeça**,
  bônus de **combo** para abates seguidos em até 2,5 s, +5 por fruta.
- **Recorde**, **melhor onda** e **moedas** ficam salvos no aparelho.

### Ondas, eras e chefes
A partida é infinita, mas dividida em **ondas** (`game.gd`). Ao limpar uma onda você
recupera 12% da vida, um pouco de estamina e ganha moedas. A cada **5 ondas** começa uma
nova **era**: inimigos com novas cores, acessórios e proteções, e o céu muda de cor.

| Era | Ondas | Inimigos | Proteção | Chefe (onda 5) |
|---|---|---|---|---|
| 1 Recrutas | 1–5 | Stickmen simples, cores neutras | — | Grandalhão |
| 2 Bandidos | 6–10 | Vermelho/laranja, chapéus e bandanas | — | Barão Bandido (rajada de 2) |
| 3 Caçadores da Floresta | 11–15 | Capuzes verdes/roxos | Escudos de madeira (20%) | Rainha da Floresta (rajada de 3) |
| 4 Cavaleiros de Ferro | 16–20 | Aço e elmos | Escudos de ferro (40%) | Colosso de Ferro (escudo enorme) |
| 5 Guarda Real | 21–25 | Azul real, marfim e ouro | Escudos reais (45%) | Rei Arqueiro (coroa, rajada de 3) |
| 6 Sombras | 26–30 | Violeta e ciano, olhos brilhantes | Escudos sombrios (35%) | Senhor das Sombras (rajada de 4) |

- A **onda 3** de cada era termina com um **mini-chefe** (maior, 2,6× vida, barra de vida).
- A **onda 5** é a do **chefe**: bem maior, barra de vida no topo, às vezes com escudo e
  atirando várias flechas de uma vez. Vencer dá 35% de vida e um bônus de moedas.
- **Escudos** bloqueiam flechas até quebrar (veja as rachaduras). Mire na cabeça ou use
  Explosiva, Arpão ou Perfurante.
- Depois da era 6 as eras voltam (“Bandidos +1”…) com inimigos cada vez mais fortes.
- Precisão e velocidade dos inimigos chegam ao máximo na onda 29; depois disso vida e
  dano continuam subindo devagar.

### Arsenal (menu → MELHORIAS ou FLECHAS, ou na tela de derrota)
Uma tela só, com duas abas: **ARQUEIRO** (melhorias do personagem) e **FLECHAS**
(equipar, melhorar e comprar flechas). Toda compra mostra o que muda (“190 » 210”).

Melhorar **não é só pagar**:
- **Flechas** precisam de **experiência**, que só se ganha usando a flecha nas partidas
  (acerto = 1, cabeça/barriga = 3, abate = +2). Por nível: 12, 30, 60, 100 e 160 XP.
  No nível máximo a flecha vira **MESTRE**: +10% de dano extra, brilho e rastro dourados
  e coroa no ícone.
- **Melhorias do arqueiro** exigem ter chegado a certas ondas: nível 2 = onda 3,
  nível 3 = onda 6, nível 4 = onda 10, nível 5 = onda 15, nível 6 = onda 20.

#### Melhorias do arqueiro
Moedas: 1+ por abate, +1 na cabeça, mini-chefe 5+, chefe 20+, bônus por onda vencida.
O visual do arqueiro evolui com as melhorias: Aprendiz (bandana) → Caçador (capuz) →
Cavaleiro (elmo) → Rei Arqueiro (coroa).

| Melhoria | Efeito por nível | Níveis |
|---|---|---:|
| Vida | +20 de vida máxima | 6 |
| Força | +10% de dano das flechas | 6 |
| Fôlego | +15 de estamina máxima | 5 |
| Recuperação | +20% de estamina por segundo | 5 |
| Armadura | −7% de dano recebido | 5 |
| Arco Longo | +6% de força do tiro | 4 |

Preços em `scripts/autoload/game_data.gd` (constante `UPGRADES`).

#### Espaços de flecha
Só as flechas **equipadas** vão para a partida. Você começa com **2 espaços** (a Comum,
fixa, + 1). Espaços extras custam caro: 3º = 400, 4º = 1000, 5º = 2200 moedas.
Flechas novas desbloqueadas são equipadas sozinhas se houver espaço livre.

#### Flechas
Desbloqueie com abates seguidos (sem morrer) **ou compre com moedas**. Cada flecha tem
**5 níveis de melhoria**: +12% de dano, −6% de estamina e +15% de efeito por nível
(veneno/fogo/gelo duram mais, explosão maior, Vampira cura mais, Teleguiada vira mais;
no nível 3 a Perfurante atravessa 3 inimigos e o Raio salta para 3).

| Flecha | Abates | Efeito | Estamina |
|---|---:|---|---:|
| Comum | 0 | — | 7 |
| Veneno | 8 | Dano contínuo por 4 s | 8 |
| Fogo | 16 | Queima por 3 s | 9 |
| Gelo | 25 | Congela o inimigo (não atira) por 3 s | 9 |
| Perfurante | 35 | Atravessa escudos e até 2 inimigos | 10 |
| Vampira | 45 | Recupera 35% do dano causado como vida | 10 |
| Explosiva | 55 | Explosão em área, quebra escudos | 14 |
| Raio | 70 | Salta para até 2 inimigos próximos | 12 |
| Tripla | 85 | Três flechas de uma vez | 15 |
| Teleguiada | 100 | Faz curva atrás do inimigo | 11 |
| Arpão | 120 | Dano enorme, parte corpos e escudos | 18 |

Os valores ficam em `scripts/autoload/game_data.gd` (constante `ARROWS`).

---

## 3. Anúncios (AdMob)

Implementados com o plugin **Poing Studios Godot AdMob v5.0.0** (`addons/admob`).
Regras para não incomodar (`scripts/autoload/ads.gd`):

- **Nunca** há anúncio ao abrir o app, nem anúncio obrigatório na **primeira sessão**
  (a primeira vez que o jogo é aberto depois de instalado).
- **Intersticial** só entre partidas (ao tocar em "Jogar de novo" ou "Menu"), no máximo
  **a cada partida** (as partidas são longas) e com pelo menos **60 s** entre um e outro. Partidas com menos
  de 25 s não contam.
- **Premiados (sempre opcionais):**
  - tela de derrota → **Continuar de onde parou** (uma vez por partida, 60% da vida,
    mesma onda e sequência de abates);
  - tela de derrota → **Dobrar moedas** da partida (uma vez por partida);
  - Arsenal → **+40 moedas grátis** (até 3 por dia).
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
    music.gd                  Música de fundo em loop, sintetizada por código (numa thread)
    lang.gd                   Idiomas (português, inglês e espanhol) e detecção do aparelho
    ads.gd                    Anúncios e regras de frequência
  game/
    game.gd                   Partida: ondas, eras, chefes, frutas, pontos, moedas, derrota, reviver
    stickman.gd               Stickman: desenho, animação, zonas de acerto, escudo, status, morte
    player_archer.gd          Jogador: mira por toque, estamina
    enemy_archer.gd           Inimigo: IA que mira (balística) e atira (chefes em rajadas)
    ragdoll.gd                Corpo caindo (física Verlet) com desmembramento
    limb_piece.gd             Membro arrancado em vida, voando e caindo
    arrow.gd / arrow_draw.gd  Flecha: física, rastro, efeitos e desenho
    floating_platform.gd      Ilhota flutuante (entra, balança, desmorona)
    fruit.gd                  Frutas de vida e estamina
    fx.gd                     Partículas (sangue, suco, faíscas, explosão) e textos
    aim_guide.gd              Mira e trajetória prevista
    background.gd             Céu, sol, montanhas, névoa e nuvens animadas
  menu/
    menu.gd                   Menu com duelo de stickmen ao fundo
    title_logo.gd             Título animado
    arsenal.gd                Arsenal: melhorias do arqueiro, espaços, equipar/melhorar/comprar flechas
  ui/
    ui_kit.gd                 Botões, painéis e transições no mesmo estilo
    game_hud.gd               HUD da partida
    stat_bar.gd               Barras animadas de vida/estamina
    arrow_icon.gd             Ícone de cada flecha
    pause_panel.gd            Pausa
    game_over_panel.gd        Tela de derrota
store/                        Ficha da Play Store: ícone, imagem de destaque, capturas e textos
docs/privacidade.html         Política de privacidade (publicada pelo GitHub Pages)
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
- [x] Ondas, eras com novos inimigos, mini-chefes, chefes com escudo, melhorias e 11 flechas
- [ ] **Etapa 6** — Publicação: conta AdMob real, chave de envio privada, AAB, consentimento
      (UMP/LGPD/GDPR), ficha da Play Store e testes fechados
