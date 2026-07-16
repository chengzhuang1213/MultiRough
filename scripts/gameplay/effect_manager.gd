extends RefCounted
class_name EffectManager

var game

func _init(game_root) -> void:
	game = game_root

func spawn_effect(origin: Vector2, radius: float, color: Color, lifetime: float = 0.08) -> void:
	var effect := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	effect.polygon = points
	effect.position = origin
	effect.color = color
	game.effect_root.add_child(effect)
	game.get_tree().create_timer(lifetime).timeout.connect(Callable(effect, "queue_free"))

func add_textured_effect(root: Node2D, texture: Texture2D, diameter: float, position: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE, node_name: String = "TexturedEffect") -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.modulate = tint
	sprite.scale = Vector2.ONE * (diameter / maxf(float(texture.get_width()), 1.0))
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = material
	root.add_child(sprite)
	return sprite

func spawn_textured_effect(origin: Vector2, texture: Texture2D, diameter: float, lifetime: float, node_name: String = "TexturedEffect") -> void:
	var sprite := add_textured_effect(game.effect_root, texture, diameter, origin, Color.WHITE, node_name)
	var final_scale := sprite.scale * 1.12
	sprite.scale *= 0.72
	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", final_scale, lifetime)
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.finished.connect(Callable(sprite, "queue_free"))

func animate_effect_rotation(sprite: Sprite2D, duration: float, clockwise: bool) -> void:
	var tween := sprite.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(sprite, "rotation", TAU if clockwise else -TAU, maxf(duration, 0.05)).from(0.0)

func animate_effect_pulse(sprite: Sprite2D, minimum_alpha: float, maximum_alpha: float, duration: float) -> void:
	sprite.modulate.a = maximum_alpha
	var tween := sprite.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate:a", minimum_alpha, maxf(duration * 0.5, 0.05))
	tween.tween_property(sprite, "modulate:a", maximum_alpha, maxf(duration * 0.5, 0.05))

func spawn_inward_streaks(origin: Vector2, radius: float, color: Color, count: int, lifetime: float) -> void:
	var root := Node2D.new()
	root.name = "WarriorQInwardStreaks"
	game.effect_root.add_child(root)
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1))
		var direction := Vector2(cos(angle), sin(angle))
		var streak := Line2D.new()
		streak.width = 3.0
		streak.default_color = color
		streak.position = origin + direction * radius
		streak.points = PackedVector2Array([-direction * 16.0, direction * 4.0])
		root.add_child(streak)
		var tween := streak.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(streak, "position", origin + direction * 10.0, lifetime)
		tween.tween_property(streak, "modulate:a", 0.0, lifetime)
	game.get_tree().create_timer(lifetime).timeout.connect(Callable(root, "queue_free"))

func spawn_spark_burst(origin: Vector2, color: Color, count: int, distance: float, lifetime: float) -> void:
	var root := Node2D.new()
	root.name = "SparkBurst"
	game.effect_root.add_child(root)
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1)) + randf_range(-0.16, 0.16)
		var direction := Vector2(cos(angle), sin(angle))
		var spark := Line2D.new()
		spark.width = randf_range(2.0, 4.0)
		spark.default_color = color
		spark.position = origin
		spark.points = PackedVector2Array([Vector2.ZERO, direction * randf_range(7.0, 14.0)])
		root.add_child(spark)
		var tween := spark.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "position", origin + direction * randf_range(distance * 0.72, distance), lifetime)
		tween.tween_property(spark, "modulate:a", 0.0, lifetime)
	game.get_tree().create_timer(lifetime).timeout.connect(Callable(root, "queue_free"))

func spawn_area_visual(root: Node2D, origin: Vector2, radius: float, color: Color) -> void:
	var area := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(36):
		var angle := TAU * float(index) / 36.0
		points.append(origin + Vector2(cos(angle), sin(angle)) * radius)
	area.polygon = points
	area.color = color
	root.add_child(area)

func spawn_lancer_sweep_effect(origin: Vector2, direction: Vector2, length: float, half_width: float, texture: Texture2D) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side_axis := Vector2(-forward.y, forward.x)
	var root := Node2D.new()
	root.name = "LancerSweep"
	game.effect_root.add_child(root)
	var slash := add_textured_effect(root, texture, maxf(length * 1.65, half_width * 1.75), origin + forward * length * 0.44, Color.WHITE, "LancerSweepTexture")
	slash.rotation = forward.angle() - 0.72
	var slash_scale := slash.scale
	slash.scale *= 0.72
	var slash_tween := slash.create_tween().set_parallel(true)
	slash_tween.set_trans(Tween.TRANS_QUAD)
	slash_tween.set_ease(Tween.EASE_OUT)
	slash_tween.tween_property(slash, "scale", slash_scale * 1.08, 0.18)
	slash_tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	for side in [-1.0, 0.0, 1.0]:
		var line := Line2D.new()
		line.position = origin
		line.width = 5.0
		line.default_color = Color(0.65, 0.92, 1.0, 0.48)
		line.points = PackedVector2Array([side_axis * half_width * side * 0.45, forward * length + side_axis * half_width * side])
		root.add_child(line)
		line.create_tween().tween_property(line, "modulate:a", 0.0, 0.14)
	game.get_tree().create_timer(0.19).timeout.connect(Callable(root, "queue_free"))
	spawn_spark_burst(origin + forward * length * 0.72, Color(0.70, 0.96, 1.0, 0.92), 9, half_width * 0.72, 0.16)

func spawn_line_skill_effect(origin: Vector2, direction: Vector2, length: float, color: Color = Color(1.0, 0.86, 0.32, 0.55), lifetime: float = 0.09) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var line := Line2D.new()
	line.position = origin
	line.width = 4.0
	line.default_color = color
	line.points = PackedVector2Array([Vector2.ZERO, forward * length])
	game.effect_root.add_child(line)
	game.get_tree().create_timer(lifetime).timeout.connect(Callable(line, "queue_free"))

func spawn_ring_effect(origin: Vector2, radius: float, color: Color, lifetime: float = 0.18) -> void:
	var ring := Line2D.new()
	ring.position = origin
	ring.width = 4.0
	ring.closed = true
	ring.default_color = color
	var points := PackedVector2Array()
	for index in range(37):
		var angle := TAU * float(index) / 36.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	game.effect_root.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.12, 1.12), lifetime)
	tween.tween_property(ring, "modulate:a", 0.0, lifetime)
	tween.finished.connect(Callable(ring, "queue_free"))

func spawn_link_effect(start: Vector2, end: Vector2, color: Color, lifetime: float = 0.14) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = color
	line.points = PackedVector2Array([start, end])
	game.effect_root.add_child(line)
	game.get_tree().create_timer(lifetime).timeout.connect(Callable(line, "queue_free"))

func spawn_damage_number(origin: Vector2, amount: float, color: Color) -> void:
	var label := Label.new()
	label.text = "%d" % roundi(amount)
	label.position = origin
	label.modulate = color
	label.add_theme_font_size_override("font_size", 18)
	game.effect_root.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", origin + Vector2(0.0, -26.0), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(Callable(label, "queue_free"))

func spawn_cooldown_bubble(target_player: PlayerController, text: String) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var bubble := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.08, 0.78)
	style.border_color = Color(0.95, 0.95, 0.95, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	bubble.add_theme_stylebox_override("panel", style)
	bubble.position = target_player.global_position + Vector2(-46.0, -88.0)
	bubble.custom_minimum_size = Vector2(92.0, 28.0)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	bubble.add_child(label)
	game.effect_root.add_child(bubble)
	var tween := bubble.create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position", bubble.position + Vector2(0.0, -10.0), 0.5)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
	tween.finished.connect(Callable(bubble, "queue_free"))
