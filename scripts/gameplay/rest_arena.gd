extends Node2D
class_name RestArena

const BOUNDS := Rect2(Vector2(-420.0, -250.0), Vector2(840.0, 500.0))
const GRID_SIZE := 70.0

func _ready() -> void:
	z_index = -90
	queue_redraw()

func _draw() -> void:
	draw_rect(BOUNDS.grow(28.0), Color(0.035, 0.075, 0.065, 1.0), true)
	draw_rect(BOUNDS, Color(0.12, 0.24, 0.18, 1.0), true)
	var x := BOUNDS.position.x
	while x <= BOUNDS.end.x:
		draw_line(Vector2(x, BOUNDS.position.y), Vector2(x, BOUNDS.end.y), Color(0.32, 0.48, 0.36, 0.20), 1.0)
		x += GRID_SIZE
	var y := BOUNDS.position.y
	while y <= BOUNDS.end.y:
		draw_line(Vector2(BOUNDS.position.x, y), Vector2(BOUNDS.end.x, y), Color(0.32, 0.48, 0.36, 0.20), 1.0)
		y += GRID_SIZE
	draw_rect(BOUNDS, Color(0.58, 0.78, 0.58, 0.90), false, 5.0)
	draw_circle(Vector2(-180.0, -20.0), 54.0, Color(0.52, 0.34, 0.18, 0.18))
	draw_circle(Vector2(180.0, -20.0), 54.0, Color(0.52, 0.34, 0.18, 0.18))
