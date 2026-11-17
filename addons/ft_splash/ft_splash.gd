extends CanvasLayer
## ABERTURA "FT" — arquivo único, sem imagens nem dependências (Godot 4.x).
##
## COMO USAR EM QUALQUER JOGO GODOT 4:
##   1. Copie este arquivo para o projeto (ex.: res://addons/ft_splash/ft_splash.gd).
##   2. Projeto > Configurações do Projeto > Globais (Autoload): adicione este
##      arquivo com o nome FTSplash. Pronto: a abertura toca sozinha ao abrir
##      o jogo, por cima de tudo, e não dá para pular.
##   3. (Opcional) Para a tela de início do motor combinar com a abertura:
##      Configurações > Aplicação > Boot Splash: Show Image = desligado e
##      Bg Color = #FFE27F.
##   4. (Opcional) Para o jogo esperar a abertura antes de carregar coisas
##      pesadas (fica mais liso):  if FTSplash.playing: await FTSplash.finished
##
## Duração total: 1,8 s (sem pular). Funciona em retrato e paisagem.

signal finished

const DURATION := 1.8
const BG := Color("ffe27f")
const LINE := Color(0.82, 0.66, 0.2, 0.28)
const NAVY := Color("1b2d4f")
const ORANGE := Color("f39a2e")
const RED := Color("e8543a")

var playing := true
var _t := 0.0
var _canvas: Control


func _ready() -> void:
	layer = 128  # por cima de tudo
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = _Draw.new()
	_canvas.owner_splash = self
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP  # segura todos os toques: não dá para pular
	add_child(_canvas)


func _process(delta: float) -> void:
	if not playing:
		return
	# limita o passo: se um quadro travar (jogo carregando) a animação não "pula"
	_t += minf(delta, 1.0 / 30.0)
	_canvas.queue_redraw()
	if _t >= DURATION:
		playing = false
		finished.emit()
		queue_free()


func _input(event: InputEvent) -> void:
	# teclado/controle também não passam enquanto toca
	if playing:
		get_viewport().set_input_as_handled()


class _Draw extends Control:
	var owner_splash: Node

	func _draw() -> void:
		var t: float = owner_splash._t
		var sz := size
		var fade := 1.0 - _seg(t, 1.5, 1.8)  # some no fim
		draw_rect(Rect2(Vector2.ZERO, sz), Color(BG, fade))
		if fade <= 0.0:
			return
		var u := minf(sz.x, sz.y)  # escala: funciona em retrato e paisagem
		# linhas diagonais de fundo que se desenham (circuito)
		var lines := [
			[Vector2(0.0, 0.22), Vector2(0.2, 0.1)], [Vector2(0.2, 0.1), Vector2(0.2, 0.0)],
			[Vector2(0.3, 0.17), Vector2(0.37, 0.13)], [Vector2(0.37, 0.13), Vector2(0.37, 0.0)],
			[Vector2(0.63, 0.1), Vector2(0.82, 0.0)], [Vector2(0.0, 0.36), Vector2(0.13, 0.29)],
			[Vector2(0.86, 0.34), Vector2(1.0, 0.26)], [Vector2(0.92, 0.33), Vector2(1.0, 0.29)],
			[Vector2(0.0, 0.8), Vector2(0.17, 0.71)], [Vector2(0.0, 0.89), Vector2(0.13, 0.82)],
			[Vector2(0.57, 1.0), Vector2(0.78, 0.88)], [Vector2(0.78, 0.88), Vector2(0.78, 1.0)],
			[Vector2(0.91, 0.8), Vector2(1.0, 0.75)],
		]
		var lp := FTSplashMath.ease_out(_seg(t, 0.0, 0.55))
		for i in lines.size():
			var a: Vector2 = lines[i][0] * sz
			var b: Vector2 = lines[i][1] * sz
			draw_line(a, a.lerp(b, lp), Color(LINE, LINE.a * fade), maxf(u * 0.0018, 1.0), true)
		var dots := [Vector2(0.61, 0.11), Vector2(0.86, 0.125), Vector2(0.15, 0.28), Vector2(0.84, 0.355),
			Vector2(0.19, 0.7), Vector2(0.89, 0.7), Vector2(0.89, 0.93)]
		for i in dots.size():
			var k := FTSplashMath.back(_seg(t, 0.1 + i * 0.04, 0.45 + i * 0.04))
			var r := u * (0.009 if i % 3 == 0 else 0.0045) * k
			if r > 0.2:
				draw_circle(dots[i] * sz, r, Color(LINE.r, LINE.g, LINE.b, 0.45 * fade))
		# logo FT (desenhado em vetor; caixa de 200 x 125 unidades)
		var s := u * 0.00105  # tamanho do logo (~20% do lado menor da tela)
		var pop := FTSplashMath.back(_seg(t, 0.12, 0.6))
		var center := sz * 0.5
		var scale := s * lerpf(0.6, 1.0, pop)
		var origin := center - Vector2(100, 62) * scale
		var col := Color(NAVY, fade * clampf(pop * 2.0, 0.0, 1.0))
		var xf := func(p: Vector2) -> Vector2: return origin + p * scale
		var poly := func(pts: Array, c: Color) -> void:
			var arr := PackedVector2Array()
			for p in pts:
				arr.append(xf.call(p))
			draw_colored_polygon(arr, c)
		# F: haste sobe, barras entram da esquerda
		var fh := FTSplashMath.ease_out(_seg(t, 0.12, 0.5))
		poly.call([Vector2(0, 124 - 124 * fh), Vector2(30, 124 - 124 * fh), Vector2(30, 124), Vector2(0, 124)], col)
		var fb := FTSplashMath.ease_out(_seg(t, 0.3, 0.65))
		poly.call([Vector2(30, 0), Vector2(30 + 66 * fb, 0), Vector2(30 + 66 * fb - 8, 30), Vector2(30, 30)], col)
		var fm := FTSplashMath.ease_out(_seg(t, 0.38, 0.72))
		poly.call([Vector2(30, 50), Vector2(30 + 38 * fm, 50), Vector2(30 + 38 * fm, 76), Vector2(30, 76)], col)
		# riscos laranja e vermelho: entram de cima, um depois do outro
		var o1 := FTSplashMath.back(_seg(t, 0.5, 0.8))
		var o2 := FTSplashMath.back(_seg(t, 0.58, 0.88))
		var dy1 := -40.0 * (1.0 - o1)
		var dy2 := -40.0 * (1.0 - o2)
		poly.call([Vector2(101, dy1), Vector2(112, dy1), Vector2(103, 26 + dy1), Vector2(92, 26 + dy1)], Color(ORANGE, fade * clampf(o1 * 3.0, 0.0, 1.0)))
		poly.call([Vector2(115, dy2), Vector2(126, dy2), Vector2(117, 26 + dy2), Vector2(106, 26 + dy2)], Color(RED, fade * clampf(o2 * 3.0, 0.0, 1.0)))
		# T: cai de cima com mola
		var tt := FTSplashMath.back(_seg(t, 0.62, 1.0))
		var dyt := -60.0 * (1.0 - tt)
		var tcol := Color(NAVY, fade * clampf(tt * 3.0, 0.0, 1.0))
		poly.call([Vector2(129, dyt), Vector2(190, dyt), Vector2(196, 3 + dyt), Vector2(199, 9 + dyt), Vector2(197, 16 + dyt),
			Vector2(192, 30 + dyt), Vector2(120, 30 + dyt)], tcol)
		poly.call([Vector2(134, 30 + dyt), Vector2(162, 30 + dyt), Vector2(162, 124 + dyt), Vector2(134, 124 + dyt)], tcol)
		# brilho que passa pelo logo
		var sh := _seg(t, 1.0, 1.4)
		if sh > 0.0 and sh < 1.0:
			var x := lerpf(10.0, 230.0, sh)
			var x0 := clampf(x - 40.0, 0.0, 200.0)
			var x1 := clampf(x + 18.0, 0.0, 200.0)
			if x1 - x0 > 1.0:
				var band := PackedVector2Array([xf.call(Vector2(minf(x0 + 40.0, x1), 0)), xf.call(Vector2(x1, 0)), xf.call(Vector2(maxf(x1 - 40.0, x0), 124)), xf.call(Vector2(x0, 124))])
				draw_colored_polygon(band, Color(1, 1, 1, 0.22 * fade))

	static func _seg(t: float, a: float, b: float) -> float:
		return clampf((t - a) / (b - a), 0.0, 1.0)


class FTSplashMath:
	static func ease_out(x: float) -> float:
		x = clampf(x, 0.0, 1.0)
		return 1.0 - pow(1.0 - x, 3.0)

	static func back(x: float) -> float:
		x = clampf(x, 0.0, 1.0)
		var c := 1.9
		return 1.0 + (c + 1.0) * pow(x - 1.0, 3.0) + c * pow(x - 1.0, 2.0)
