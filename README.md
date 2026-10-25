# Arrow Survival

Jogo 2D de sobrevivência infinita com arco e flecha e personagens stickman,
feito em **Godot 4.3** (GDScript) para **Android**, na vertical e offline.

> **Etapa atual: 1 — Protótipo básico** (cenário, jogador, um inimigo, mira por toque,
> flechas com física e colisões). As próximas etapas serão adicionadas aos poucos.

---

## 1. Preparar o celular (sem computador)

### 1.1 Instalar o Godot 4.3 para Android
A versão da Google Play é atualizada automaticamente para versões mais novas.
Como o projeto usa a **4.3**, instale o APK oficial dessa versão:

1. No navegador do celular, abra:
   `https://github.com/godotengine/godot/releases/tag/4.3-stable`
2. Em **Assets**, toque em **`Godot_v4.3-stable_android_editor.apk`** (~200 MB).
3. Abra o arquivo baixado. Se o Android pedir, permita **"Instalar apps desconhecidos"**
   para o navegador (ou para o app de arquivos).
4. Abra o **Godot Editor** e aceite a permissão de **acesso a todos os arquivos**
   (o editor precisa dela para ler e salvar o projeto).

> Dica: um teclado Bluetooth e um mouse ajudam muito, mas não são obrigatórios.
> No editor, use dois dedos para dar zoom e arrastar a visão.

### 1.2 Baixar o projeto
1. No navegador, abra a página deste repositório no GitHub e escolha o branch do projeto.
2. Toque em **Code → Download ZIP** (se o botão não aparecer, ative "Site para computador" no navegador).
3. Abra o app **Arquivos** (por exemplo, *Files by Google*), toque no ZIP e escolha **Extrair**.
4. Mova a pasta extraída para `Armazenamento interno/Documents/Godot/ArrowSurvival`
   (evite a pasta `Android/data`, que o editor não consegue acessar).

### 1.3 Abrir o projeto no Godot
1. No Godot, na tela **Gerenciador de Projetos**, toque em **Importar**.
2. Navegue até `Documents/Godot/ArrowSurvival` e selecione o arquivo **`project.godot`**.
3. Toque em **Importar e Editar**. Na primeira vez, o Godot cria a pasta oculta `.godot`
   (cache); isso pode levar alguns segundos.

### 1.4 Executar o jogo
- Toque no botão **▶ (Executar Projeto)** no canto superior direito do editor.
- O jogo abre em uma janela própria. Use o botão **Voltar** do Android
  (ou o botão de parar ■ no editor) para retornar ao editor.

### 1.5 Atualizar para uma nova etapa
Quando novas etapas forem publicadas, baixe o ZIP novamente e substitua os arquivos
na mesma pasta (pode apagar a pasta `.godot` se o editor reclamar de cache).

---

## 2. Como jogar (Etapa 1)

- **Toque** em qualquer lugar da tela, **arraste o dedo para trás** (para longe do inimigo)
  e **solte** para atirar — como um estilingue.
- Quanto mais longe você arrastar, mais forte é o disparo (até ~260 pixels).
- Os pontinhos brancos mostram o começo da trajetória prevista.
- Arrastes muito curtos cancelam o tiro.
- O contador **Acertos** aumenta quando a flecha atinge o inimigo. A flecha fica presa
  no corpo, o personagem pisca e balança, e depois a flecha some.

---

## 3. Estrutura do projeto

```
project.godot          Configurações (720x1280, vertical, renderizador Compatibility)
scenes/
  main.tscn            Cena principal: cenário, chão, jogador, inimigo, flechas e HUD
  player.tscn          Jogador stickman (azul, bandana)
  enemy.tscn           Inimigo stickman (vermelho, chapéu)
  arrow.tscn           Flecha
scripts/
  main.gd              Cria flechas, limita a quantidade e conta acertos
  stickman.gd          Desenho, animação e reação a impacto de qualquer stickman
  player.gd            Mira por toque e disparo (herda de stickman.gd)
  aim_guide.gd         Desenha a mira e a trajetória prevista
  arrow.gd             Física da flecha (gravidade + raio de colisão) e fixação no alvo
  background.gd        Céu, sol, morros e chão desenhados por código
assets/
  images/, sounds/     Reservado para imagens e sons futuros
```

Nenhuma imagem externa é usada: tudo é desenhado com `_draw()` (linhas, círculos e
polígonos), o que deixa o jogo leve.

### 3.1 Árvore de nós de cada cena

**main.tscn**
```
Main (Node2D) ← scripts/main.gd   [arrow_scene = scenes/arrow.tscn]
├── Background (Node2D) ← scripts/background.gd   [z_index = -10]
├── Ground (StaticBody2D)   [position = (360, 1600), camada 1 "mundo"]
│   └── CollisionShape2D   [RectangleShape2D 4000 x 1200 → topo do chão em y = 1000]
├── Player (instância de player.tscn)   [position = (120, 1000)]
├── Enemy (instância de enemy.tscn)     [position = (600, 1000)]
├── Arrows (Node2D)   ← onde as flechas são criadas
└── HUD (CanvasLayer)
    ├── Title (Label)      "ARROW SURVIVAL"
    ├── HitsLabel (Label)  "Acertos: 0"
    └── HintLabel (Label)  instrução de como atirar
```

**player.tscn**
```
Player (Node2D) ← scripts/player.gd
├── Hurtbox (Area2D)   [collision_layer = 2 "jogador", mask = nenhuma, monitoring = desligado]
│   └── CollisionShape2D   [CapsuleShape2D raio 22, altura 172, position = (0, -86)]
└── AimGuide (Node2D) ← scripts/aim_guide.gd
```

**enemy.tscn**
```
Enemy (Node2D) ← scripts/stickman.gd   [facing_left = ligado, cor vermelha, accessory = HAT]
└── Hurtbox (Area2D)   [collision_layer = 3 "inimigo" (valor 4), mask = nenhuma]
    └── CollisionShape2D   [igual ao do jogador]
```

**arrow.tscn**
```
Arrow (Node2D) ← scripts/arrow.gd
```

### 3.2 Como criar uma cena/nó manualmente (para aprender)
Os arquivos já vêm prontos, mas é assim que se cria algo do zero no editor:
1. **Cena → Nova Cena**, escolha **Outro Nó** e procure o tipo (ex.: `Node2D`).
2. Para adicionar filhos, selecione o nó e toque em **+** (Adicionar Nó Filho).
3. Para anexar um script, selecione o nó e toque no ícone de **pergaminho** (Anexar Script),
   ou arraste o arquivo `.gd` do painel **Sistema de Arquivos** até o nó.
4. Propriedades (posição, camadas de colisão, formas) ficam no painel **Inspetor**.
5. Para usar uma cena dentro de outra (ex.: Player dentro de Main), use o ícone de
   **corrente** (Instanciar Cena Filha).
6. Salve com **Cena → Salvar Cena** na pasta `scenes/`.

### 3.3 Camadas de física
| Camada | Nome     | Quem usa                        |
|-------:|----------|---------------------------------|
| 1      | mundo    | chão (`Ground`)                 |
| 2      | jogador  | `Hurtbox` do jogador            |
| 3      | inimigo  | `Hurtbox` dos inimigos          |

As flechas do jogador usam a máscara `1 + 3` (valor 5): acertam o chão e os inimigos,
nunca o próprio jogador.

---

## 4. Decisões técnicas da Etapa 1

- **Flecha sem RigidBody:** a flecha calcula velocidade e gravidade por conta própria e,
  a cada quadro de física, usa `PhysicsDirectSpaceState2D.intersect_ray()` entre a posição
  anterior e a nova. Isso evita que flechas rápidas atravessem o alvo e é mais barato que
  corpos rígidos no celular.
- **Flecha presa:** ao acertar uma `Area2D` de personagem, a flecha vira filha dela
  (`reparent()`), então acompanha o corpo. Depois de 5 s ela desaparece gradualmente.
- **Limite de objetos:** no máximo 30 flechas ao mesmo tempo; as mais antigas são removidas.
- **Renderizador Compatibility (OpenGL):** o mais leve e compatível com celulares modestos.
- **Tela:** base 720 x 1280, `stretch = canvas_items`, `aspect = keep_width`
  (a largura é fixa; celulares mais altos mostram mais chão embaixo).
- **Teste no computador (opcional):** `emulate_touch_from_mouse` está ativado, então o mouse
  também funciona como dedo.

### Ajustes fáceis (no Inspetor do nó Player)
`min_speed`, `max_speed` (força do tiro), `max_drag` (quanto arrastar para força máxima),
`cooldown` (intervalo entre tiros), `min_angle`/`max_angle` (limites da mira).

---

## 5. Roteiro

- [x] **Etapa 1** — Protótipo: cenário, stickmen, mira por toque, flechas físicas, colisões
- [ ] **Etapa 2** — Combate: inimigos que atiram, vida, dano e eliminação
- [ ] **Etapa 3** — Impactos: cabeça/tronco/membros, sangue estilizado, reações, desmembramento
- [ ] **Etapa 4** — Sobrevivência: pontuação, recorde salvo, novos inimigos, dificuldade progressiva
- [ ] **Etapa 5** — Finalização: menu, tela de derrota, sons, otimização
- [ ] **Etapa 6** — Publicação: exportar APK/AAB e preparar para a Google Play
