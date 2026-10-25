class_name TitleLogo
extends Control
## Título "ARROW SURVIVAL" animado: as letras caem quicando, depois ondulam,
## e uma flecha atravessa a tela e crava no título.

const LINE1 := "ARROW"
const LINE2 := "SURVIVAL"
const SIZE1 := 104
const SIZE2 := 78
const LETTER_DELAY := 0.07

var _time := 0.0
var _font: Font
var _arrow_x := -200.0
var _arrow_hit := false
var _shake := 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(700, 250)


func _process(delta: float) -> void:
	_time += delta
	_shake = maxf(_shake - delta * 30.0, 0.0)
	var arrow_start := (LINE1.length() + LINE2.length()) * LETTER_DELAY + 0.5
	if _time > arrow_start and not _arrow_hit:
		_arrow_x += delta * 2400.0
		if _arrow_x >= size.x * 0.5 + 250.0:
			_arrow_x = size.x * 0.5 + 250.0
			_arrow_hit = true
			_shake = 10.0
			Sfx.play("wood")
	queue_redraw()


func _draw() -> void:
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	_draw_line_of_letters(LINE1, SIZE1, Vector2(0, 100) + shake, 0, Color(1.0, 0.86, 0.3), Color(1.0, 0.6, 0.15))
	_draw_line_of_letters(LINE2, SIZE2, Vector2(0, 200) + shake, LINE1.length(), Color(1, 1, 1), Color(0.7, 0.85, 1.0))

	if _time > (LINE1.length() + LINE2.length()) * LETTER_DELAY + 0.5:
		var y := 125.0
		draw_set_transform(Vector2(_arrow_x, y) + shake, 0.0, Vector2(1.8, 1.8))
		ArrowDraw.draw_arrow(self, GameData.get_arrow("fire"))
		draw_set_transform(Vector2.ZERO)


func _draw_line_of_letters(text: String, font_size: int, base: Vector2, index_offset: int, top_color: Color, wave_color: Color) -> void:
	var total_w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + (text.length() - 1) * 4.0
	var x := (size.x - total_w) / 2.0
	for i in text.length():
		var ch := text[i]
		var w := _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var t := _time - (i + index_offset) * LETTER_DELAY
		var y := base.y
		var alpha := 1.0
		if t < 0.0:
			alpha = 0.0
		elif t < 0.55:
			# Queda com quique (ease out bounce simplificado).
			var k := t / 0.55
			y -= (1.0 - k) * 260.0 * absf(cos(k * PI * 1.5)) * (1.0 - k)
		else:
			y += sin(_time * 3.0 + i * 0.6) * 5.0
		var col := top_color.lerp(wave_color, 0.5 + 0.5 * sin(_time * 2.0 + i * 0.5))
		col.a = alpha
		var pos := Vector2(x + base.x, y)
		draw_string_outline(_font, pos + Vector2(0, 6), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, Color(0, 0, 0, 0.35 * alpha))
		draw_string_outline(_font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, Color(0.08, 0.1, 0.18, alpha))
		draw_string(_font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
		x += w + 4.0
