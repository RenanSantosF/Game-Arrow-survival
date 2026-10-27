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
## IDs: a versão da Play Store (AAB) usa os blocos reais da conta AdMob. O APK do
## GitHub é exportado com a marca "test_ads" e mostra os anúncios DE TESTE do Google,
## para quem testa nunca clicar num anúncio real (o AdMob bane contas por isso).
## O App ID real fica em project.godot, seção [admob].

signal ad_closed

const INTERSTITIAL_ID := "ca-app-pub-4311255826061303/4140344880"
const REWARDED_ID := "ca-app-pub-4311255826061303/7794976879"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

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
var _initialized := false
var _rewarded_loading := false
## Mensagem do último erro do premiado (aparece no Arsenal para diagnóstico).
var rewarded_error_message := ""
## Último erro ao carregar o anúncio premiado (código do AdMob, -1 = nenhum).
## 3 = sem anúncio disponível (comum em conta/app novos), 2 = sem internet,
## 1 = pedido inválido (ID errado), 0 = erro interno.
var rewarded_error_code := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob")
	if not _enabled:
		return
	# Só pede anúncios depois que o SDK do Google terminar de iniciar
	# (pedir antes pode falhar com erro de rede, código 2).
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_initialized = true
		_load_all()
	MobileAds.initialize(listener)
	# Garantia: se o aviso de "pronto" não chegar, tenta mesmo assim depois de um tempo.
	get_tree().create_timer(12.0).timeout.connect(func() -> void:
		if not _initialized:
			_initialized = true
			_load_all())


func _load_all() -> void:
	_load_interstitial()
	_load_rewarded()


## Anúncios só existem no celular (Android com o plugin AdMob).
func is_available() -> bool:
	return _enabled


## Pede um anúncio premiado agora, se ainda não tiver um carregado (ou carregando).
func request_rewarded() -> void:
	if _enabled and _initialized:
		_load_rewarded()


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
	cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("AdMob intersticial não carregou: %s" % (error.message if error else "?"))
		get_tree().create_timer(60.0).timeout.connect(_load_interstitial)
	InterstitialAdLoader.new().load(TEST_INTERSTITIAL_ID if _test_ads() else INTERSTITIAL_ID, AdRequest.new(), cb)


func _load_rewarded() -> void:
	if _rewarded != null or _rewarded_loading:
		return
	_rewarded_loading = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
		_rewarded_loading = false
		rewarded_error_code = -1
	cb.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_loading = false
		rewarded_error_code = error.code if error else 0
		rewarded_error_message = error.message if error else ""
		push_warning("AdMob premiado não carregou: %s" % (error.message if error else "?"))
		# Erro de rede: tenta de novo logo; outros erros: espera 1 minuto.
		get_tree().create_timer(15.0 if rewarded_error_code == 2 else 60.0).timeout.connect(_load_rewarded)
	RewardedAdLoader.new().load(TEST_REWARDED_ID if _test_ads() else REWARDED_ID, AdRequest.new(), cb)


## Anúncios de teste: APK de testes do GitHub (marca "test_ads") ou build de depuração.
func _test_ads() -> bool:
	return OS.has_feature("test_ads") or OS.is_debug_build()
