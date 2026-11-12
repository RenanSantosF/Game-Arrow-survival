# Abertura FT (1,8 s, não dá para pular)

## Jogos feitos em Godot 4
1. Copie `ft_splash.gd` para o projeto (ex.: `res://addons/ft_splash/ft_splash.gd`).
2. Projeto > Configurações do Projeto > **Globais (Autoload)**: adicione o arquivo com o nome **FTSplash**
   e deixe-o como o **primeiro** da lista.
3. (Recomendado) Configurações do Projeto > Aplicação > **Boot Splash**: desligue *Show Image* e
   use **Bg Color = #FFE27F**. Assim a tela do motor já abre amarela e emenda na abertura.
4. (Opcional) Na primeira cena, antes de carregar coisas pesadas:
   ```gdscript
   if FTSplash.playing:
       await FTSplash.finished
   ```
Pronto: a abertura toca sozinha ao abrir o jogo, por cima de tudo, bloqueia toques/teclas
e some em 1,8 s. Funciona em retrato e paisagem (o logo se ajusta ao tamanho da tela).

## Jogos em outros motores (Unity, web, etc.)
Use os vídeos `abertura_ft_retrato.mp4` (1080x1920) ou `abertura_ft_paisagem.mp4` (1920x1080),
30 fps, 1,8 s, como vídeo de abertura sem botão de pular. Cor de fundo para combinar: #FFE27F.
