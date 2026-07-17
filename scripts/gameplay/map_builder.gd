extends RefCounted
class_name MapBuilder

const TILE_SIZE := Vector2i(64, 64)
const MAP_OBSTACLE_COLLISION_LAYER := 1 << 3
const RANGED_ATTACK_BLOCKER_LAYER := 1 << 4
const WATER_TEXTURE := preload("res://assets/tiny_swords_free_pack/Terrain/Tileset/Water Background color.png")
const GRASS_TEXTURE := preload("res://assets/tiny_swords_free_pack/Terrain/Tileset/Tilemap_color1.png")
const LIGHT_MEADOW_TEXTURE := preload("res://assets/tiny_swords_free_pack/Terrain/Tileset/Tilemap_color2.png")
const DARK_MEADOW_TEXTURE := preload("res://assets/tiny_swords_free_pack/Terrain/Tileset/Tilemap_color5.png")

const BUSH_PATHS := [
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Bushes/Bushe1.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Bushes/Bushe2.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Bushes/Bushe3.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Bushes/Bushe4.png",
]
const BUILDING_DATA := [
	["res://assets/tiny_swords_free_pack/Buildings/Blue Buildings/Castle.png", Vector2(320, 256), Vector2(-735, -350), Vector2(0.54, 0.54)],
	["res://assets/tiny_swords_free_pack/Buildings/Blue Buildings/Tower.png", Vector2(128, 256), Vector2(-790, 305), Vector2(0.68, 0.68)],
	["res://assets/tiny_swords_free_pack/Buildings/Blue Buildings/House1.png", Vector2(128, 192), Vector2(705, -300), Vector2(0.68, 0.68)],
	["res://assets/tiny_swords_free_pack/Buildings/Blue Buildings/House2.png", Vector2(128, 192), Vector2(805, -155), Vector2(0.66, 0.66)],
	["res://assets/tiny_swords_free_pack/Buildings/Blue Buildings/House3.png", Vector2(128, 192), Vector2(710, 35), Vector2(0.66, 0.66)],
	["res://assets/tiny_swords_free_pack/Buildings/Blue Buildings/Barracks.png", Vector2(192, 256), Vector2(755, 310), Vector2(0.58, 0.58)],
]

var game

func _init(game_root) -> void:
	game = game_root

func build() -> void:
	_build_water()
	_build_grass_island()
	_build_ground_variation()
	_build_buildings()
	_build_soft_obstacles()
	_build_boundary_props()
	_build_bush_clusters()
	_build_corner_props()

func _build_water() -> void:
	var water := TextureRect.new()
	water.name = "WaterBase"
	water.position = game.ARENA_BOUNDS.position - Vector2(256, 256)
	water.size = game.ARENA_BOUNDS.size + Vector2(512, 512)
	water.texture = WATER_TEXTURE
	water.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	water.stretch_mode = TextureRect.STRETCH_TILE
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water.z_index = -120
	game.map_root.add_child(water)

func _build_grass_island() -> void:
	var filled: Dictionary = {}
	for y in range(-9, 9):
		for x in range(-15, 15):
			filled[Vector2i(x, y)] = true
	for x in range(-7, 6):
		filled[Vector2i(x, -10)] = true
	for x in range(2, 11):
		filled[Vector2i(x, 9)] = true
	for y in range(-3, 3):
		filled[Vector2i(-16, y)] = true
	for y in range(-6, -1):
		filled[Vector2i(15, y)] = true
	var island := _build_tile_layer("GrassIsland", GRASS_TEXTURE, filled, -110)
	game.map_root.add_child(island)

func _build_ground_variation() -> void:
	var light_cells: Dictionary = {}
	_add_zone_row(light_cells, -7, -13, -7)
	_add_zone_row(light_cells, -6, -13, -5)
	_add_zone_row(light_cells, -5, -12, -5)
	_add_zone_row(light_cells, -4, -11, -6)
	for x in range(-10, 11):
		light_cells[Vector2i(x, 0)] = true
		if x % 4 != 0:
			light_cells[Vector2i(x, 1)] = true

	var dark_cells: Dictionary = {}
	_add_zone_row(dark_cells, 3, 7, 12)
	_add_zone_row(dark_cells, 4, 6, 13)
	_add_zone_row(dark_cells, 5, 6, 13)
	_add_zone_row(dark_cells, 6, 8, 12)
	var light_layer := _build_center_tile_layer("LightMeadowZone", LIGHT_MEADOW_TEXTURE, light_cells, -105)
	var dark_layer := _build_center_tile_layer("DarkMeadowZone", DARK_MEADOW_TEXTURE, dark_cells, -104)
	game.map_root.add_child(light_layer)
	game.map_root.add_child(dark_layer)

func _add_zone_row(cells: Dictionary, y: int, min_x: int, max_x: int) -> void:
	for x in range(min_x, max_x + 1):
		cells[Vector2i(x, y)] = true

func _build_center_tile_layer(layer_name: String, texture: Texture2D, cells: Dictionary, layer_z: int) -> TileMapLayer:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = TILE_SIZE
	source.create_tile(Vector2i(1, 1))
	tile_set.add_source(source, 0)
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.z_index = layer_z
	for cell_value in cells.keys():
		layer.set_cell(cell_value as Vector2i, 0, Vector2i(1, 1))
	return layer

func _build_tile_layer(layer_name: String, texture: Texture2D, filled: Dictionary, layer_z: int) -> TileMapLayer:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = TILE_SIZE
	for atlas_y in range(3):
		for atlas_x in range(3):
			source.create_tile(Vector2i(atlas_x, atlas_y))
	tile_set.add_source(source, 0)

	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.z_index = layer_z
	for cell_value in filled.keys():
		var cell := cell_value as Vector2i
		layer.set_cell(cell, 0, _atlas_tile_for_cell(cell, filled))
	return layer

func _atlas_tile_for_cell(cell: Vector2i, filled: Dictionary) -> Vector2i:
	var has_left := filled.has(cell + Vector2i.LEFT)
	var has_right := filled.has(cell + Vector2i.RIGHT)
	var has_top := filled.has(cell + Vector2i.UP)
	var has_bottom := filled.has(cell + Vector2i.DOWN)
	if not has_top and not has_left:
		return Vector2i(0, 0)
	if not has_top and not has_right:
		return Vector2i(2, 0)
	if not has_bottom and not has_left:
		return Vector2i(0, 2)
	if not has_bottom and not has_right:
		return Vector2i(2, 2)
	if not has_top:
		return Vector2i(1, 0)
	if not has_bottom:
		return Vector2i(1, 2)
	if not has_left:
		return Vector2i(0, 1)
	if not has_right:
		return Vector2i(2, 1)
	return Vector2i(1, 1)

func _build_buildings() -> void:
	for index in range(BUILDING_DATA.size()):
		var data: Array = BUILDING_DATA[index]
		var building := _make_sprite(str(data[0]), data[1] as Vector2, data[2] as Vector2, data[3] as Vector2)
		building.name = "BoundaryBuilding%d" % (index + 1)
		building.z_index = -28
		_add_static_collision(building, Vector2(0.82, 0.78), 0.06, true)
		game.map_root.add_child(building)

func _build_soft_obstacles() -> void:
	var positions: Array[Vector2] = [
		Vector2(-820, -120), Vector2(-700, 70), Vector2(-610, 285),
		Vector2(720, -470), Vector2(760, 170), Vector2(700, 470),
		Vector2(-350, -300), Vector2(330, -340),
		Vector2(-390, 440), Vector2(340, 430),
	]
	for index in range(positions.size()):
		var path: String = game.ROCK_PATHS[index % game.ROCK_PATHS.size()]
		var prop := _make_sprite(path, Vector2(64, 64), positions[index], Vector2(0.72, 0.72))
		prop.name = "SoftObstacle%d" % (index + 1)
		prop.z_index = -34
		_add_static_collision(prop, Vector2(0.78, 0.72), 0.0)
		game.map_root.add_child(prop)

func _build_boundary_props() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(-575, -430), Vector2(-440, -465), Vector2(-295, -445), Vector2(-150, -470),
		Vector2(235, -465), Vector2(380, -445), Vector2(515, -455), Vector2(625, -410),
		Vector2(-665, -250), Vector2(-825, 5), Vector2(-680, 190),
		Vector2(-610, 415), Vector2(-470, 455), Vector2(-315, 430), Vector2(-150, 465),
		Vector2(115, 450), Vector2(260, 465), Vector2(420, 445), Vector2(555, 420),
		Vector2(880, -360), Vector2(885, 80), Vector2(875, 385),
	]
	for index in range(tree_positions.size()):
		var tree_path: String = game.TREE_PATHS[index % game.TREE_PATHS.size()]
		var frame_size := _tree_frame_size(tree_path)
		var tree_scale := Vector2(0.50, 0.50) if frame_size.y <= 192.0 else Vector2(0.44, 0.44)
		var tree := _make_sprite(tree_path, frame_size, tree_positions[index], tree_scale)
		tree.name = "BoundaryTree%d" % (index + 1)
		tree.z_index = -30
		_add_static_collision(tree, Vector2(0.72, 0.78), 0.02, true)
		game.map_root.add_child(tree)

func _build_bush_clusters() -> void:
	var positions: Array[Vector2] = [
		Vector2(-570, -355), Vector2(-430, -385), Vector2(-285, -375),
		Vector2(485, -375), Vector2(605, -345), Vector2(835, -290),
		Vector2(-590, 345), Vector2(-455, 385), Vector2(-300, 365),
		Vector2(455, 380), Vector2(590, 340), Vector2(840, 275),
		Vector2(-845, -210), Vector2(-835, 170), Vector2(855, -35), Vector2(845, 155),
	]
	for index in range(positions.size()):
		var bush := _make_sprite(BUSH_PATHS[index % BUSH_PATHS.size()], Vector2(128, 128), positions[index], Vector2(0.48, 0.48))
		bush.name = "BoundaryBush%d" % (index + 1)
		bush.z_index = -32
		game.map_root.add_child(bush)

func _build_corner_props() -> void:
	var corner_positions: Array[Vector2] = [
		Vector2(-870, -430), Vector2(870, -420),
		Vector2(-860, 425), Vector2(860, 420),
	]
	for index in range(corner_positions.size()):
		var prop_path: String = game.CORNER_PROP_PATHS[index % game.CORNER_PROP_PATHS.size()]
		var frame_size := Vector2(192, 256) if prop_path.contains("Stump") else Vector2(64, 64)
		var prop := _make_sprite(prop_path, frame_size, corner_positions[index], Vector2(0.50, 0.50))
		prop.name = "CornerProp%d" % (index + 1)
		prop.z_index = -27
		var footprint_ratio := Vector2(0.72, 0.75) if prop_path.contains("Stump") else Vector2(0.78, 0.72)
		var footprint_y_ratio := 0.03 if prop_path.contains("Stump") else 0.0
		_add_static_collision(prop, footprint_ratio, footprint_y_ratio)
		game.map_root.add_child(prop)

func _tree_frame_size(path: String) -> Vector2:
	var texture := load(path) as Texture2D
	return Vector2(texture.get_width() / 8.0, texture.get_height())

func _add_static_collision(sprite: Sprite2D, size_ratio: Vector2, y_offset_ratio: float, blocks_ranged_attacks: bool = false) -> void:
	var body := StaticBody2D.new()
	body.name = "MapObstacleBody"
	body.collision_layer = MAP_OBSTACLE_COLLISION_LAYER | (RANGED_ATTACK_BLOCKER_LAYER if blocks_ranged_attacks else 0)
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = sprite.region_rect.size * size_ratio
	collision.position = Vector2(0.0, sprite.region_rect.size.y * y_offset_ratio)
	collision.shape = rectangle
	body.add_child(collision)
	sprite.add_child(body)

func _make_sprite(path: String, frame_size: Vector2, position: Vector2, sprite_scale: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.position = position
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, frame_size)
	sprite.scale = sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite
