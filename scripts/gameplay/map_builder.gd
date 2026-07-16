extends RefCounted
class_name MapBuilder

var game

func _init(game_root) -> void:
	game = game_root

func build() -> void:
	_build_ground_tiles()
	_build_soft_obstacles()
	_build_boundary_props()
	_build_corner_props()

func _build_ground_tiles() -> void:
	var background := ColorRect.new()
	background.name = "GrassBase"
	background.position = game.ARENA_BOUNDS.position
	background.size = game.ARENA_BOUNDS.size
	background.color = Color(0.31, 0.52, 0.31)
	background.z_index = -100
	game.map_root.add_child(background)

func _build_soft_obstacles() -> void:
	var positions: Array[Vector2] = [
		Vector2(-360.0, -150.0),
		Vector2(320.0, -120.0),
		Vector2(-220.0, 190.0),
		Vector2(430.0, 210.0),
		Vector2(40.0, -260.0),
	]
	for index in range(positions.size()):
		var path: String = game.ROCK_PATHS[index % game.ROCK_PATHS.size()]
		var prop := _make_sprite(path, Vector2(64, 64), positions[index], Vector2(0.65, 0.65))
		prop.name = "SoftObstacle"
		prop.z_index = -35
		game.map_root.add_child(prop)

func _build_boundary_props() -> void:
	var gap_width := 420.0
	var step := 300.0
	var top_y: float = game.ARENA_BOUNDS.position.y - 48.0
	var bottom_y: float = game.ARENA_BOUNDS.end.y + 44.0
	var left_x: float = game.ARENA_BOUNDS.position.x - 44.0
	var right_x: float = game.ARENA_BOUNDS.end.x + 44.0

	for x in range(int(game.ARENA_BOUNDS.position.x), int(game.ARENA_BOUNDS.end.x) + 1, int(step)):
		if abs(float(x)) > gap_width * 0.5:
			_add_boundary_prop(Vector2(float(x), top_y), x)
			_add_boundary_prop(Vector2(float(x), bottom_y), x + 13)

	for y in range(int(game.ARENA_BOUNDS.position.y), int(game.ARENA_BOUNDS.end.y) + 1, int(step)):
		if abs(float(y)) > gap_width * 0.5:
			_add_boundary_prop(Vector2(left_x, float(y)), y + 29)
			_add_boundary_prop(Vector2(right_x, float(y)), y + 47)

func _add_boundary_prop(position: Vector2, seed_value: int) -> void:
	var sprite: Sprite2D
	var selector: int = abs(seed_value) % 3
	if selector == 0:
		sprite = _make_sprite(game.TREE_PATHS[abs(seed_value) % game.TREE_PATHS.size()], Vector2(256, 256), position, Vector2(0.32, 0.32))
	else:
		sprite = _make_sprite(game.ROCK_PATHS[abs(seed_value) % game.ROCK_PATHS.size()], Vector2(64, 64), position, Vector2(0.55, 0.55))
	sprite.name = "BoundaryProp"
	sprite.z_index = -40
	game.map_root.add_child(sprite)

func _build_corner_props() -> void:
	var corner_positions: Array[Vector2] = [
		Vector2(game.ARENA_BOUNDS.position.x + 130.0, game.ARENA_BOUNDS.position.y + 110.0),
		Vector2(game.ARENA_BOUNDS.end.x - 140.0, game.ARENA_BOUNDS.position.y + 120.0),
		Vector2(game.ARENA_BOUNDS.position.x + 150.0, game.ARENA_BOUNDS.end.y - 120.0),
		Vector2(game.ARENA_BOUNDS.end.x - 130.0, game.ARENA_BOUNDS.end.y - 110.0),
	]
	for index in range(corner_positions.size()):
		var prop_path: String = game.CORNER_PROP_PATHS[index % game.CORNER_PROP_PATHS.size()]
		var frame_size := Vector2(192, 256) if prop_path.contains("Stump") else Vector2(64, 64)
		var prop := _make_sprite(prop_path, frame_size, corner_positions[index], Vector2(0.45, 0.45))
		prop.name = "CornerProp"
		prop.z_index = -30
		game.map_root.add_child(prop)

func _make_sprite(path: String, frame_size: Vector2, position: Vector2, sprite_scale: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.position = position
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, frame_size)
	sprite.scale = sprite_scale
	return sprite
