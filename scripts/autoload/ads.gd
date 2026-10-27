extends Node
## Anúncios (Google AdMob) com regras para não incomodar o jogador:
##
## - Nunca há anúncio ao abrir o app, e nenhum anúncio obrigatório na 1ª sessão
##   (a primeira vez que o jogo é aberto depois de instalado).
## - Intersticial só entre partidas (ao tocar em "Jogar de novo" ou "Menu"),
##   no máximo a cada INTERSTITIAL_EVERY partidas e com intervalo mínimo de tempo.
## - Anúncio premiado é sempre opcional: o jogador escolhe assistir para ganhar algo
##   (continuar de onde parou, dobrar as moedas da partida, moedas grátis no Arsenal).
## - Sem banners durante o jogo.
##
## Os IDs abaixo são os IDs DE TESTE oficiais do Google. Antes de publicar,
## troque pelos IDs da sua conta AdMob (veja o README).

signal ad_closed

const INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

const INTERSTITIAL_EVERY := 3          ## Partidas entre intersticiais.
const MIN_SECONDS_BETWEEN := 150.0     ## Intervalo mínimo entre intersticiais.
const MIN_GAME_SECONDS := 25.0         ## Partidas muito curtas não contam.

var _enabled := false
var _interstitial: InterstitialAd = null
var _rewarded: RewardedAd = null
var _games_since_ad := 0
var _last_ad_time := -1000.0
var _reward_pending := false
var _on_reward := Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob")
	if not _enabled:
		return
	MobileAds.initialize()
	# Carrega com um pequeno atraso para não pesar na abertura do jogo.
	get_tree().create_timer(4.0).timeout.connect(_load_all)


func _load_all() -> void:
	_load_interstitial()
	_load_rewarded()


## Anúncios só existem no celular (Android com o plugin AdMob).
func is_available() -> bool:
	return _enabled


func is_rewarded_ready() -> bool:
	return _enabled and _rewarded != null


## Chamado ao fim de cada partida (antes de mostrar a tela de derrota).
func register_game_end(game_seconds: float) -> void:
	if game_seconds >= MIN_GAME_SECONDS:
		_games_since_ad += 1


## Mostra um intersticial se as regras permitirem. Chama "done" quando terminar.
func maybe_show_interstitial(done: Callable) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var allowed := (
		_enabled
		and _interstitial != null
		and GameData.sessions >= 2
		and _games_since_ad >= INTERSTITIAL_EVERY
		and now - _last_ad_time >= MIN_SECONDS_BETWEEN
	)
	if not allowed:
		done.call()
		return
	_games_since_ad = 0
	_last_ad_time = now
	var ad := _interstitial
	_interstitial = null
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_after_ad()
		done.call()
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_after_ad()
		done.call()
	ad.full_screen_content_callback = callback
	_before_ad()
	ad.show()


## Mostra o anúncio premiado. Chama "on_reward" se o jogador assistir até o fim.
func show_rewarded(on_reward: Callable) -> void:
	if not is_rewarded_ready():
		return
	_reward_pending = false
	_on_reward = on_reward
	_last_ad_time = Time.get_ticks_msec() / 1000.0
	_games_since_ad = 0
	var ad := _rewarded
	_rewarded = null
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_after_ad()
		if _reward_pending and _on_reward.is_valid():
			_on_reward.call()
		_on_reward = Callable()
		ad_closed.emit()
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_after_ad()
		_on_reward = Callable()
		ad_closed.emit()
	ad.full_screen_content_callback = callback
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_reward_pending = true
	_before_ad()
	ad.show(listener)


func _before_ad() -> void:
	AudioServer.set_bus_mute(0, true)


func _after_ad() -> void:
	AudioServer.set_bus_mute(0, not GameData.sound_enabled)
	# Já deixa o próximo anúncio carregado.
	get_tree().create_timer(2.0).timeout.connect(_load_all)


func _load_interstitial() -> void:
	if _interstitial != null:
		return
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
	cb.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		get_tree().create_timer(60.0).timeout.connect(_load_interstitial)
	InterstitialAdLoader.new().load(INTERSTITIAL_ID, AdRequest.new(), cb)


func _load_rewarded() -> void:
	if _rewarded != null:
		return
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
	cb.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		get_tree().create_timer(60.0).timeout.connect(_load_rewarded)
	RewardedAdLoader.new().load(REWARDED_ID, AdRequest.new(), cb)
