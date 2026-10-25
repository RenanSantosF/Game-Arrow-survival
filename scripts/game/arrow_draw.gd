class_name ArrowDraw
extends RefCounted
## Desenho da flecha. A PONTA fica na origem (0, 0) e o corpo segue para -X.

const LENGTH := 54.0


static func draw_arrow(canvas: CanvasItem, def: Dictionary, mod := Color.WHITE) -> void:
	var shaft: Color = def["shaft"] * mod
	var head: Color = def["head"] * mod
	var fletch: Color = def["fletch"] * mod
	canvas.draw_line(Vector2(-LENGTH, 0), Vector2(-8, 0), shaft, 3.5, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(5, 0), Vector2(-10, -6), Vector2(-7, 0), Vector2(-10, 6)
	]), head)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-LENGTH + 14, 0), Vector2(-LENGTH - 3, -8), Vector2(-LENGTH + 2, 0), Vector2(-LENGTH - 3, 8)
	]), fletch)
	match def["id"]:
		"explosive":
			canvas.draw_circle(Vector2(-16, 0), 5.5, Color(0.9, 0.15, 0.1) * mod)
			canvas.draw_line(Vector2(-16, -5), Vector2(-20, -10), Color(1, 0.8, 0.2) * mod, 2.0)
		"poison":
			canvas.draw_circle(Vector2(-14, 0), 3.5, Color(0.4, 1.0, 0.3) * mod)
		"ice":
			canvas.draw_line(Vector2(-4, -7), Vector2(-4, 7), Color(0.85, 1, 1) * mod, 2.0)
		"fire":
			canvas.draw_circle(Vector2(-12, 0), 4.0, Color(1, 0.7, 0.1, 0.9) * mod)
