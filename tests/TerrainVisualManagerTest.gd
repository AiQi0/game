extends SceneTree

const TERRAIN_ROOT := "res://assets/world_terrain_v1"

var failures := 0
const EXPECTED_GROUND_MIN_X := -4000.0
const EXPECTED_GROUND_MAX_X := 13600.0
const EXPECTED_GROUND_WIDTH := EXPECTED_GROUND_MAX_X - EXPECTED_GROUND_MIN_X
const EXPECTED_AIR_WALL_WIDTH := 96.0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var terrain_manager_script := load("res://scripts/TerrainVisualManager.gd")

	_assert_true(game_data_script != null, "GameData.gd should load")
	_assert_true(terrain_manager_script != null, "TerrainVisualManager.gd should load")

	if game_data_script != null:
		_test_terrain_data(game_data_script.new())
	if terrain_manager_script != null:
		_test_visual_manager_nodes(terrain_manager_script)
		_test_main_scene_wiring()

	if failures == 0:
		print("TerrainVisualManagerTest: PASS")
	else:
		push_error("TerrainVisualManagerTest: %d failure(s)" % failures)

	quit(failures)


func _test_terrain_data(game_data) -> void:
	_assert_equal(game_data.terrain_asset_root(), TERRAIN_ROOT, "terrain asset root is data-driven")
	_assert_equal(game_data.terrain_tile_size(), Vector2(256, 64), "terrain tile size is data-driven")
	_assert_equal(game_data.visual_chunk_width(), 1920.0, "visual chunk width is data-driven")
	_assert_equal(game_data.world_value("terrain_tile_size"), Vector2(256, 64), "world data exposes terrain tile size")
	_assert_equal(game_data.world_value("visual_chunk_width"), 1920, "world data exposes visual chunk width")

	var terrain_set: Dictionary = game_data.terrain_set("main_grass")
	_assert_equal(terrain_set.get("ground_tiles", []).size(), 3, "main grass terrain has three ground tile variants")
	_assert_equal(terrain_set.get("background_layers", []).size(), 5, "main grass terrain has five background layers")
	var resource_variants: Dictionary = terrain_set.get("resource_variants", {})
	_assert_equal(resource_variants.get("tree", []).size(), 2, "terrain pack records tree variants")
	_assert_equal(resource_variants.get("mother_tree", []).size(), 2, "terrain pack records mother tree variants")
	_assert_equal(resource_variants.get("stone", []).size(), 2, "terrain pack records stone variants")

	_assert_asset(game_data, "grass_ground_tile", Vector2i(256, 64), true)
	_assert_asset(game_data, "grass_ground_variant_01", Vector2i(256, 64), true)
	_assert_asset(game_data, "grass_ground_variant_02", Vector2i(256, 64), true)
	_assert_asset(game_data, "ground_fill", Vector2i(256, 128), true)
	_assert_asset(game_data, "water_tile", Vector2i(256, 64), true)
	_assert_asset(game_data, "short_bridge_tile", Vector2i(256, 80), false)
	_assert_asset(game_data, "bridge_support", Vector2i(64, 80), false)
	_assert_asset(game_data, "sky_gradient", Vector2i(1920, 1080), true)
	_assert_asset(game_data, "far_hills_loop", Vector2i(1920, 360), true)
	_assert_asset(game_data, "far_forest_loop", Vector2i(1920, 300), true)
	_assert_asset(game_data, "cloud_loop_01", Vector2i(1920, 220), true)
	_assert_asset(game_data, "cloud_loop_02", Vector2i(1920, 220), true)


func _test_visual_manager_nodes(terrain_manager_script: Script) -> void:
	var world := Node2D.new()
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(4800, 472)
	world.add_child(player)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)

	var manager: Node2D = terrain_manager_script.new()
	manager.name = "TerrainVisualManager"
	world.add_child(manager)
	manager._ready()

	var expected_ground_tiles := int(ceil((EXPECTED_GROUND_WIDTH + 1920.0 * 2.0) / 256.0))
	var ground_tiles := manager.get_node_or_null("GroundTiles")
	var fill_tiles := manager.get_node_or_null("GroundFillTiles")
	var backgrounds := manager.get_node_or_null("Backgrounds")
	var water_tiles := manager.get_node_or_null("WaterTiles")

	_assert_true(ground_tiles != null, "terrain manager creates GroundTiles")
	_assert_true(fill_tiles != null, "terrain manager creates GroundFillTiles")
	_assert_true(backgrounds != null, "terrain manager creates Backgrounds")
	_assert_true(water_tiles != null, "terrain manager creates WaterTiles")
	if ground_tiles != null:
		_assert_equal(ground_tiles.get_child_count(), expected_ground_tiles, "ground visuals cover the full world plus one chunk on both sides")
		var first_tile := ground_tiles.get_child(0) as Sprite2D
		var last_tile := ground_tiles.get_child(ground_tiles.get_child_count() - 1) as Sprite2D
		_assert_true(first_tile.position.x <= EXPECTED_GROUND_MIN_X - 1920.0, "first ground tile starts before the left air wall")
		_assert_true(last_tile.position.x + 256.0 >= EXPECTED_GROUND_MAX_X + 1920.0, "last ground tile reaches past the right air wall")
	if fill_tiles != null:
		_assert_equal(fill_tiles.get_child_count(), expected_ground_tiles, "ground fill matches ground tile count")
	if backgrounds != null:
		_assert_true(backgrounds.get_node_or_null("SkyGradient") != null, "backgrounds include sky gradient")
		_assert_true(backgrounds.get_node_or_null("FarHills") != null, "backgrounds include far hills")
		_assert_true(backgrounds.get_node_or_null("FarForest") != null, "backgrounds include far forest")

	manager.set_water_spans([Rect2(Vector2(1024, 488), Vector2(512, 64))])
	water_tiles = manager.get_node_or_null("WaterTiles")
	if water_tiles != null:
		_assert_equal(water_tiles.get_child_count(), 2, "water span creates enough repeated water tiles")

	_assert_no_collision_nodes(manager, "terrain visual manager")
	world.free()


func _test_main_scene_wiring() -> void:
	var packed_scene := load("res://scenes/Main.tscn") as PackedScene
	_assert_true(packed_scene != null, "Main.tscn should load")
	if packed_scene == null:
		return

	var scene := packed_scene.instantiate()
	var manager := scene.get_node_or_null("TerrainVisualManager")
	_assert_true(manager != null, "main scene has TerrainVisualManager")
	if manager != null:
		manager._ready()
		_assert_true(manager.get_node_or_null("GroundTiles") != null, "main terrain manager can build ground tiles")
		_assert_no_collision_nodes(manager, "main terrain manager")

	var ground_visual := scene.get_node_or_null("Ground/GroundVisual") as CanvasItem
	_assert_true(ground_visual != null, "main scene keeps old GroundVisual node")
	if ground_visual != null:
		_assert_false(ground_visual.visible, "old polygon ground visual is hidden")

	var ground_collision := scene.get_node_or_null("Ground/GroundCollision") as CollisionShape2D
	_assert_true(ground_collision != null, "main scene keeps GroundCollision")
	if ground_collision != null and ground_collision.shape is RectangleShape2D:
		_assert_equal((ground_collision.shape as RectangleShape2D).size, Vector2(EXPECTED_GROUND_WIDTH, 48), "ground collision covers expanded main world")

	var left_wall := scene.get_node_or_null("AirWalls/LeftAirWall") as StaticBody2D
	var right_wall := scene.get_node_or_null("AirWalls/RightAirWall") as StaticBody2D
	_assert_true(left_wall != null, "left air wall remains")
	_assert_true(right_wall != null, "right air wall remains")
	if left_wall != null:
		_assert_equal(left_wall.position, Vector2(EXPECTED_GROUND_MIN_X - EXPECTED_AIR_WALL_WIDTH * 0.5, 0), "left air wall guards expanded left edge")
	if right_wall != null:
		_assert_equal(right_wall.position, Vector2(EXPECTED_GROUND_MAX_X + EXPECTED_AIR_WALL_WIDTH * 0.5, 0), "right air wall guards expanded right edge")
	_assert_true(scene.get_node_or_null("AirWalls/LeftAirWall/LeftAirWallCollision") != null, "left air wall collision remains")
	_assert_true(scene.get_node_or_null("AirWalls/RightAirWall/RightAirWallCollision") != null, "right air wall collision remains")
	scene.free()


func _assert_asset(game_data, asset_id: String, expected_size: Vector2i, should_tile: bool) -> void:
	var path: String = game_data.terrain_asset_path(asset_id)
	_assert_true(path.begins_with(TERRAIN_ROOT), "%s path is in world terrain pack" % asset_id)
	_assert_true(FileAccess.file_exists(path), "%s asset exists" % asset_id)
	var texture := load(path) as Texture2D
	_assert_true(texture != null, "%s asset loads as Texture2D" % asset_id)
	if texture == null:
		return
	_assert_equal(Vector2i(texture.get_width(), texture.get_height()), expected_size, "%s asset size matches spec" % asset_id)
	if should_tile:
		_assert_horizontal_seam_matches(texture, "%s has matching left and right edges" % asset_id)


func _assert_horizontal_seam_matches(texture: Texture2D, message: String) -> void:
	var image := texture.get_image()
	_assert_true(image != null, "%s image is readable" % message)
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	var right_x := image.get_width() - 1
	for y in range(image.get_height()):
		if not _colors_close(image.get_pixel(0, y), image.get_pixel(right_x, y)):
			_fail("%s at y=%d" % [message, y])
			return


func _assert_no_collision_nodes(node: Node, label: String) -> void:
	for child in node.get_children():
		if child is CollisionObject2D or child is CollisionShape2D or child is CollisionPolygon2D:
			_fail("%s should not create collision nodes, found %s" % [label, child.name])
		_assert_no_collision_nodes(child, label)


func _colors_close(a: Color, b: Color) -> bool:
	return (
		absf(a.r - b.r) < 0.001
		and absf(a.g - b.g) < 0.001
		and absf(a.b - b.b) < 0.001
		and absf(a.a - b.a) < 0.001
	)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
