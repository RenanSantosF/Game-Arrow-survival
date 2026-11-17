extends Node
## TELAS GRANDES (tablets, dobráveis, Chromebooks) — exigência da Google Play.
##
## A Play Console pede para o app NÃO travar orientação nem tamanho no manifesto
## (no Android 16 essas travas são ignoradas em telas grandes). Por isso o projeto
## usa orientação "Sensor" (o manifesto sai como fullUser, sem trava) e este
## autoload faz o resto:
##   * Celular (lado menor < 600 dp): trava na orientação do jogo em tempo de
##     execução (retrato ou paisagem, conforme o tamanho da tela do projeto).
##   * Tela grande: o jogo gira livre; se a janela ficar na orientação "errada",
##     a imagem é encaixada inteira com faixas nas laterais (nada fica cortado
##     nem esticado). Na orientação certa o jogo fica igual ao do celular.
##
## Uso: Autoload com o nome ScreenFit (depois do FTSplash).

var _portrait_game := true
var _orig_aspect: int = Window.CONTENT_SCALE_ASPECT_EXPAND


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var w := int(ProjectSettings.get_setting("display/window/size/viewport_width", 720))
	var h := int(ProjectSettings.get_setting("display/window/size/viewport_height", 1280))
	_portrait_game = h >= w
	var root := get_tree().root
	_orig_aspect = root.content_scale_aspect
	if OS.has_feature("mobile") and is_phone():
		DisplayServer.screen_set_orientation(
			DisplayServer.SCREEN_SENSOR_PORTRAIT if _portrait_game else DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	root.size_changed.connect(_refit)
	_refit()


## true em celulares (menor lado da tela abaixo de 600 dp).
static func is_phone() -> bool:
	var px := DisplayServer.screen_get_size()
	var density := maxf(float(DisplayServer.screen_get_dpi()) / 160.0, 0.5)
	return minf(px.x, px.y) / density < 600.0


func _refit() -> void:
	var root := get_tree().root
	var s := root.size
	if s.x <= 0 or s.y <= 0:
		return
	var portrait_window := s.y >= s.x
	var want: int = _orig_aspect if portrait_window == _portrait_game else Window.CONTENT_SCALE_ASPECT_KEEP
	if root.content_scale_aspect != want:
		root.content_scale_aspect = want
