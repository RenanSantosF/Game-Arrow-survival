# Arrow Survival — próximos passos

Lista do que o dono do jogo pediu para fazer **depois que o jogo estiver publicado
oficialmente na Play Store**. Quem for ajudar (pessoa ou Claude): comece por aqui.

## 1. Liberar os anúncios reais (AdMob)
- [ ] AdMob → Apps → Arrow Survival → Configurações do app → **vincular à Google Play**
      (`com.renansantos.arrowsurvival`). O app está como "Requer revisão"; a revisão só
      começa depois do vínculo (1 a 3 dias). Até aprovar, os anúncios reais ficam limitados.
- [ ] Conferir dados de pagamento/impostos no AdMob.

## 2. Anunciar o jogo dentro de outros jogos (campanha paga)
- [ ] **Google Ads → Campanha de app → Instalações** (Android, Arrow Survival). O Google
      mostra o jogo em outros jogos/apps (rede do AdMob), no YouTube e na Play Store.
      Começar com orçamento pequeno (ex.: R$ 20–30/dia por 1–2 semanas) e acompanhar o
      custo por instalação antes de aumentar.
- [ ] Recursos da campanha: textos curtos (pt/en/es), as capturas de `store/`, o ícone,
      a imagem de destaque e, se possível, um vídeo curto de gameplay (15–30 s).

## 3. "Mini versão" que leva para a Google Play
Duas formas — o dono do jogo quer as duas, se possível:
- [ ] **Anúncio jogável (playable ad):** mini jogo em HTML5 de 15–30 s (puxar o arco, acertar
      1–2 inimigos, chefe aparece) que termina com o botão **"Baixar na Google Play"**.
      Regras do Google Ads: ZIP de até 5 MB, vertical, sem som antes do primeiro toque.
      O export web do Godot é grande demais: fazer uma versão leve em HTML5/JS puro,
      com o mesmo visual de stickman. Serve também para Unity Ads, AppLovin e Mintegral.
- [ ] **Demo na web:** a mesma mini versão publicada numa página (GitHub Pages em
      `docs/`), com o botão para a Play Store, para divulgar em redes sociais.

## 4. Divulgação grátis
- [ ] Vídeos curtos (TikTok/Shorts/Reels): corpo partido ao meio, chefes, membros arrancados.
- [ ] Pedir avaliações na loja para os primeiros jogadores.
- [ ] Depois: publicar também na **Samsung Galaxy Store** (mesmo jogo, AdMob funciona).

## Situação em 27/10/2026
- Teste interno e teste fechado enviados no Play Console (versões 15/16; a 19 tem a tela
  "CONTINUAR?", música e a correção da mira — enviar ao teste fechado).
- Teste fechado: 12+ testadores por 14 dias seguidos, depois pedir acesso à produção.
