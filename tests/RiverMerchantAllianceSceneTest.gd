extends SceneTree

const NPC_SCRIPT_PATH := "res://scripts/NPC.gd"
const RIVER_NPC_DIRECTOR_SCRIPT_PATH := "res://scripts/RiverMerchantAllianceNPCDirector.gd"
const RIVER_SCENE_SCRIPT_PATH := "res://scripts/RiverMerchantAlliance.gd"

var failures := 0


func _init() -> void:
	var packed_scene: PackedScene = load("res://scenes/RiverMerchantAlliance.tscn")
	_assert_true(packed_scene != null, "river merchant alliance scene loads")
	if packed_scene == null:
		quit(failures)
		return

	var scene := packed_scene.instantiate()
	if scene.has_method("_ready"):
		scene._ready()
	_assert_equal(scene.name, "RiverMerchantAlliance", "scene root is RiverMerchantAlliance")
	_test_world_size(scene)
	_test_air_walls(scene)
	_test_player(scene)
	_test_scene_art_layers(scene)
	_test_dock_placeholders_hidden(scene)
	_test_return_to_main_world(scene)
	_test_removed_original_buildings(scene)
	_test_city_buildings(scene)
	_test_non_cityhall_building_scale(scene)
	_test_dynamic_npcs(scene)
	scene.free()

	if failures == 0:
		print("RiverMerchantAllianceSceneTest: PASS")
	else:
		push_error("RiverMerchantAllianceSceneTest: %d failure(s)" % failures)

	quit(failures)


func _test_world_size(scene: Node) -> void:
	var ground: Node2D = scene.get_node_or_null("Ground")
	_assert_true(ground != null, "river scene has ground")
	if ground == null:
		return

	_assert_equal(ground.position, Vector2(4800, 496), "river scene ground matches main world position")
	var collision: CollisionShape2D = ground.get_node_or_null("GroundCollision")
	_assert_true(collision != null, "river scene ground has collision")
	if collision == null:
		return

	var shape := collision.shape as RectangleShape2D
	_assert_true(shape != null, "river scene ground collision uses rectangle shape")
	if shape != null:
		_assert_equal(shape.size, Vector2(9600, 48), "river scene ground matches main world width")


func _test_scene_art_layers(scene: Node) -> void:
	var sky := scene.get_node_or_null("Sky") as CanvasItem
	_assert_true(sky != null, "river scene keeps fallback sky node")
	if sky != null:
		_assert_false(sky.visible, "river scene hides color sky behind generated background")

	var water := scene.get_node_or_null("Water") as CanvasItem
	_assert_true(water != null, "river scene keeps fallback water node")
	if water != null:
		_assert_false(water.visible, "river scene hides polygon water behind generated foreground water")

	var ground_visual := scene.get_node_or_null("Ground/GroundVisual") as CanvasItem
	_assert_true(ground_visual != null, "river scene keeps fallback ground visual")
	if ground_visual != null:
		_assert_false(ground_visual.visible, "river scene hides polygon ground behind generated ground strip")

	var scene_art := scene.get_node_or_null("SceneArt") as Node2D
	_assert_true(scene_art != null, "river scene has generated scene art root")
	if scene_art == null:
		return
	_assert_equal(scene_art.z_index, -50, "generated scene art stays behind gameplay entities")
	_assert_scene_art_tiles(
		scene_art,
		"BackgroundTiles",
		"BackgroundTile",
		"res://assets/medieval_pixel_pack_v3_no_outline/environment/river_background.png",
		0.0,
		"river background"
	)
	_assert_scene_art_tiles(
		scene_art,
		"GroundTiles",
		"GroundTile",
		"res://assets/medieval_pixel_pack_v3_no_outline/environment/river_ground.png",
		424.0,
		"river ground"
	)
	_assert_scene_art_tiles(
		scene_art,
		"ForegroundWaterTiles",
		"ForegroundWaterTile",
		"res://assets/medieval_pixel_pack_v3_no_outline/environment/foreground_water.png",
		520.0,
		"foreground water"
	)
	var foreground_tiles := scene_art.get_node_or_null("ForegroundWaterTiles") as CanvasItem
	if foreground_tiles != null:
		_assert_false(foreground_tiles.visible, "legacy 2D foreground water is hidden after mirror water is created")
	_assert_mirror_water_surface(scene_art)


func _test_dock_placeholders_hidden(scene: Node) -> void:
	var docks := scene.get_node_or_null("Docks") as CanvasItem
	_assert_true(docks != null, "river scene keeps fallback dock placeholder container")
	if docks == null:
		return
	_assert_false(docks.visible, "river scene hides old dock color-strip placeholders")

	for dock_path in ["Docks/CentralDock", "Docks/LeftDock", "Docks/RightDock"]:
		var dock := scene.get_node_or_null(dock_path) as CanvasItem
		_assert_true(dock != null, "%s exists as fallback dock placeholder" % dock_path)
		if dock != null:
			_assert_false(dock.visible, "%s is hidden and cannot appear in water reflection" % dock_path)


func _test_air_walls(scene: Node) -> void:
	var air_walls := scene.get_node_or_null("AirWalls")
	_assert_true(air_walls != null, "river scene has air wall container")
	if air_walls == null:
		return

	_assert_air_wall(air_walls, "LeftAirWall", "LeftAirWallCollision", Vector2(-48, 0))
	_assert_air_wall(air_walls, "RightAirWall", "RightAirWallCollision", Vector2(9648, 0))


func _assert_air_wall(air_walls: Node, wall_name: String, collision_name: String, expected_position: Vector2) -> void:
	var wall: StaticBody2D = air_walls.get_node_or_null(wall_name)
	_assert_true(wall != null, "%s exists" % wall_name)
	if wall == null:
		return

	_assert_equal(wall.position, expected_position, "%s matches main world position" % wall_name)
	var collision: CollisionShape2D = wall.get_node_or_null(collision_name)
	_assert_true(collision != null, "%s has collision" % wall_name)
	if collision == null:
		return

	var shape := collision.shape as RectangleShape2D
	_assert_true(shape != null, "%s collision uses rectangle shape" % wall_name)
	if shape != null:
		_assert_equal(shape.size, Vector2(96, 1000), "%s matches main world wall thickness" % wall_name)


func _test_player(scene: Node) -> void:
	var player: CharacterBody2D = scene.get_node_or_null("Player")
	_assert_true(player != null, "river scene has player")
	var post_station: Node2D = scene.get_node_or_null("PostStation")
	_assert_true(post_station != null, "river scene has post station for player spawn")
	if player != null and post_station != null:
		_assert_equal(player.position, post_station.position, "player starts at the post station")


func _test_return_to_main_world(scene: Node) -> void:
	var scene_script := load(RIVER_SCENE_SCRIPT_PATH)
	_assert_true(scene_script != null, "river scene script loads")
	_assert_true(scene.get_script() == scene_script, "river scene root uses return-travel script")
	_assert_true(scene.has_method("main_world_scene_path"), "river scene exposes main world route")
	_assert_true(scene.has_method("can_return_to_main_world"), "river scene checks post station return interaction")
	_assert_true(scene.has_method("return_to_main_world"), "river scene can request return to main world")
	if not scene.has_method("main_world_scene_path"):
		return

	_assert_equal(scene.main_world_scene_path(), "res://scenes/Main.tscn", "post station return targets main world")
	var player: Node2D = scene.get_node_or_null("Player")
	var post_station: Node2D = scene.get_node_or_null("PostStation")
	if player != null and post_station != null and scene.has_method("can_return_to_main_world"):
		player.global_position = post_station.global_position
		_assert_true(scene.can_return_to_main_world(), "player can return while standing at post station")


func _test_removed_original_buildings(scene: Node) -> void:
	for node_name in [
		"RiverTradeHall",
		"RiverPort",
		"MarketStalls",
		"Warehouse",
		"MerchantHouse",
	]:
		_assert_true(scene.get_node_or_null(node_name) == null, "original river scene building %s is removed" % node_name)


func _test_city_buildings(scene: Node) -> void:
	_assert_true(scene.get_node_or_null("CityHall") != null, "river scene has one city hall")
	_assert_true(scene.get_node_or_null("PostStation") != null, "river scene has one post station")
	_assert_true(scene.get_node_or_null("LeftWall") != null, "river scene has left wall")
	_assert_true(scene.get_node_or_null("RightWall") != null, "river scene has right wall")

	_assert_building_row(scene, "Farms", "Farm_", 5)
	_assert_building_row(scene, "Lumberyards", "Lumberyard_", 3)
	_assert_building_row(scene, "Quarries", "Quarry_", 3)
	_assert_building_row(scene, "Blacksmiths", "Blacksmith_", 2)
	_assert_existing_model_nodes(scene)
	_assert_generated_building_sprites(scene)


func _assert_existing_model_nodes(scene: Node) -> void:
	_assert_has_children(scene.get_node_or_null("CityHall"), ["BuildingBody", "Roof", "Dome", "LeftColumn", "CenterColumn", "RightColumn", "Door", "LeftWindow", "RightWindow"], "city hall uses main world model")
	_assert_has_children(scene.get_node_or_null("PostStation"), ["Body", "WindowMain"], "post station uses existing generic model")
	_assert_has_children(scene.get_node_or_null("LeftWall"), ["WallBody", "Crenel0", "Crenel1", "Crenel2", "Crenel3", "Gate", "WindowSlit"], "left wall uses existing wall model")
	_assert_has_children(scene.get_node_or_null("RightWall"), ["WallBody", "Crenel0", "Crenel1", "Crenel2", "Crenel3", "Gate", "WindowSlit"], "right wall uses existing wall model")
	_assert_has_children(scene.get_node_or_null("Farms/Farm_01"), ["Soil", "CropRow0", "CropRow1", "CropRow2", "CropRow3", "Fence", "WindowLantern"], "farm uses existing farm model")
	_assert_has_children(scene.get_node_or_null("Lumberyards/Lumberyard_01"), ["Body", "WindowMain"], "lumberyard uses existing generic model")
	_assert_has_children(scene.get_node_or_null("Quarries/Quarry_01"), ["RockPile", "CutFace", "WindowMain"], "quarry uses existing quarry model")
	_assert_has_children(scene.get_node_or_null("Blacksmiths/Blacksmith_01"), ["Body", "Roof", "Chimney", "Door", "WindowForge"], "blacksmith uses existing blacksmith model")


func _assert_generated_building_sprites(scene: Node) -> void:
	_assert_sprite_texture_path(scene, "CityHall", "res://assets/medieval_pixel_pack_v3_no_outline/buildings/cityhall.png")
	_assert_polygon_descendants_hidden(scene.get_node_or_null("CityHall"), "CityHall fallback polygons are hidden")
	_assert_sprite_texture_path(scene, "PostStation", "res://assets/medieval_pixel_pack_v3_no_outline/buildings/post_station.png")
	_assert_polygon_descendants_hidden(scene.get_node_or_null("PostStation"), "PostStation fallback polygons are hidden")
	_assert_sprite_texture_path(scene, "LeftWall", "res://assets/medieval_pixel_pack_v3_no_outline/buildings/wall.png")
	_assert_polygon_descendants_hidden(scene.get_node_or_null("LeftWall"), "LeftWall fallback polygons are hidden")
	_assert_sprite_texture_path(scene, "RightWall", "res://assets/medieval_pixel_pack_v3_no_outline/buildings/wall.png")
	_assert_polygon_descendants_hidden(scene.get_node_or_null("RightWall"), "RightWall fallback polygons are hidden")
	_assert_reused_sprite_texture(scene, "Farms", "Farm_", 5, "res://assets/medieval_pixel_pack_v3_no_outline/buildings/farm.png")
	_assert_reused_sprite_texture(scene, "Lumberyards", "Lumberyard_", 3, "res://assets/medieval_pixel_pack_v3_no_outline/buildings/lumberyard.png")
	_assert_reused_sprite_texture(scene, "Quarries", "Quarry_", 3, "res://assets/medieval_pixel_pack_v3_no_outline/buildings/quarry.png")
	_assert_reused_sprite_texture(scene, "Blacksmiths", "Blacksmith_", 2, "res://assets/medieval_pixel_pack_v3_no_outline/buildings/blacksmith.png")


func _assert_reused_sprite_texture(scene: Node, container_name: String, prefix: String, expected_count: int, expected_path: String) -> void:
	for i in range(expected_count):
		var child_name := "%s/%s%02d" % [container_name, prefix, i + 1]
		_assert_sprite_texture_path(scene, child_name, expected_path)
		_assert_polygon_descendants_hidden(scene.get_node_or_null(child_name), "%s fallback polygons are hidden" % child_name)


func _test_non_cityhall_building_scale(scene: Node) -> void:
	_assert_true(scene.has_method("apply_non_cityhall_building_scale"), "river scene can scale non-cityhall buildings")
	if scene.has_method("apply_non_cityhall_building_scale"):
		scene.apply_non_cityhall_building_scale()

	_assert_node_scale(scene, "CityHall", Vector2.ONE, "river city hall stays original size")
	_assert_node_scale(scene, "PostStation", Vector2(2, 2), "river post station is doubled")
	_assert_node_scale(scene, "LeftWall", Vector2(2, 2), "river left wall is doubled")
	_assert_node_scale(scene, "RightWall", Vector2(-2, 2), "river right wall is doubled and mirrored")
	_assert_node_scale(scene, "Farms/Farm_01", Vector2(2, 2), "river farms are doubled")
	_assert_node_scale(scene, "Lumberyards/Lumberyard_01", Vector2(2, 2), "river lumberyards are doubled")
	_assert_node_scale(scene, "Quarries/Quarry_01", Vector2(2, 2), "river quarries are doubled")
	_assert_node_scale(scene, "Blacksmiths/Blacksmith_01", Vector2(2, 2), "river blacksmiths are doubled")


func _assert_node_scale(scene: Node, node_path: String, expected_scale: Vector2, message: String) -> void:
	var node := scene.get_node_or_null(node_path) as Node2D
	_assert_true(node != null, "%s exists" % node_path)
	if node == null:
		return
	_assert_equal(node.scale, expected_scale, message)


func _assert_scene_art_tiles(scene_art: Node2D, container_name: String, tile_prefix: String, expected_path: String, expected_y: float, message: String) -> void:
	var container := scene_art.get_node_or_null(container_name)
	_assert_true(container != null, "%s tile container exists" % message)
	if container == null:
		return

	for i in range(5):
		var tile := container.get_node_or_null("%s%d" % [tile_prefix, i]) as Sprite2D
		_assert_true(tile != null, "%s tile %d exists" % [message, i])
		if tile == null:
			continue
		_assert_equal(tile.centered, false, "%s tile %d is top-left anchored" % [message, i])
		_assert_equal(tile.position, Vector2(1920.0 * i, expected_y), "%s tile %d is placed in world strip" % [message, i])
		_assert_true(tile.texture != null, "%s tile %d has texture" % [message, i])
		if tile.texture != null:
			_assert_equal(tile.texture.resource_path, expected_path, "%s tile %d uses generated texture" % [message, i])


func _assert_mirror_water_surface(scene_art: Node2D) -> void:
	_assert_true(scene_art.get_node_or_null("Water3D") == null, "river scene no longer creates 3D water root")

	var water_root := scene_art.get_node_or_null("WaterReflection") as Node2D
	_assert_true(water_root != null, "river scene creates mirror water root")
	if water_root == null:
		return
	_assert_equal(water_root.z_as_relative, false, "mirror water renders in world z order")
	_assert_equal(water_root.z_index, 4, "mirror water renders over the water strip")

	for i in range(5):
		var tile := water_root.get_node_or_null("WaterReflectionTile%d" % i) as ColorRect
		_assert_true(tile != null, "mirror water tile %d exists" % i)
		if tile == null:
			continue
		_assert_equal(tile.position, Vector2(1920.0 * i, 520.0), "mirror water tile %d starts 20px lower at the waterline" % i)
		_assert_equal(tile.size, Vector2(1920, 560), "mirror water tile %d covers the lowered foreground water area" % i)
		_assert_equal(tile.mouse_filter, Control.MOUSE_FILTER_IGNORE, "mirror water tile %d ignores mouse input" % i)

		var material := tile.material as ShaderMaterial
		_assert_true(material != null, "mirror water tile %d uses a shader material" % i)
		if material == null:
			continue
		_assert_equal(material.get_shader_parameter("ripple_amplitude_pixels"), 8.0, "mirror water tile %d has animated ripple amplitude" % i)
		_assert_equal(material.get_shader_parameter("ripple_speed"), 0.65, "mirror water tile %d has animated ripple speed" % i)
		_assert_equal(material.get_shader_parameter("shimmer_strength"), 0.08, "mirror water tile %d has subtle shimmer animation" % i)
		_assert_equal(material.get_shader_parameter("top_blur_fraction"), 0.25, "mirror water tile %d blurs the top quarter" % i)
		_assert_equal(material.get_shader_parameter("top_blur_radius_pixels"), 6.0, "mirror water tile %d has top blur radius" % i)
		_assert_true(material.shader != null, "mirror water tile %d has a shader" % i)
		if material.shader != null:
			_assert_equal(material.shader.resource_path, "res://shaders/river_mirror_water.gdshader", "mirror water tile %d uses mirror screen shader" % i)
			_assert_true(material.shader.code.find("hint_screen_texture") != -1, "mirror water shader copies the rendered screen")
			_assert_true(material.shader.code.find("UV.y * reflection_height_pixels") == -1, "mirror water shader does not stretch reflection by water rect height")
			_assert_true(material.shader.code.find("dFdy(SCREEN_UV.y) / dFdy(UV.y)") != -1, "mirror water shader measures the drawn tile in screen pixels")
			_assert_true(material.shader.code.find("waterline_screen_uv_y = SCREEN_UV.y - UV.y * rect_screen_height_uv") != -1, "mirror water shader finds the waterline in screen space")
			_assert_true(material.shader.code.find("waterline_screen_uv_y - reflection_offset_uv") != -1, "mirror water shader samples a one-to-one vertically flipped image")
			_assert_true(material.shader.code.find("TIME * ripple_speed") != -1, "mirror water shader animates ripple movement over time")
			_assert_true(material.shader.code.find("ripple_amplitude_pixels * SCREEN_PIXEL_SIZE.x") != -1, "mirror water shader distorts the reflection horizontally")
			_assert_true(material.shader.code.find("shimmer_strength") != -1, "mirror water shader animates soft brightness shimmer")
			_assert_true(material.shader.code.find("smoothstep(top_blur_fraction, 0.0, UV.y)") != -1, "mirror water shader fades blur through the top quarter")
			_assert_true(material.shader.code.find("top_blur_radius_pixels * SCREEN_PIXEL_SIZE") != -1, "mirror water shader samples a blur radius in screen pixels")
			_assert_true(material.shader.code.find("mix(reflected, blurred, top_blur_mask)") != -1, "mirror water shader blends blurred reflection gradually")

	_assert_water_grass(scene_art)


func _assert_water_grass(scene_art: Node2D) -> void:
	var grass_root := scene_art.get_node_or_null("WaterGrass") as Node2D
	_assert_true(grass_root != null, "river scene creates random water grass root")
	if grass_root == null:
		return
	_assert_equal(grass_root.z_as_relative, false, "water grass renders in world z order")
	_assert_equal(grass_root.z_index, 5, "water grass renders over mirror water")
	_assert_equal(grass_root.get_child_count(), 24, "river scene creates expected water grass count")

	for child in grass_root.get_children():
		var clump := child as Node2D
		_assert_true(clump != null, "water grass clump is Node2D")
		if clump == null:
			continue
		_assert_true(clump.position.x >= 160.0 and clump.position.x <= 9440.0, "%s x stays in river world" % clump.name)
		_assert_true(clump.position.y >= 560.0 and clump.position.y <= 1010.0, "%s y stays in water" % clump.name)
		_assert_true(_has_no_collision_descendants(clump), "%s has no collision nodes" % clump.name)
		_assert_true(clump.get_child_count() >= 3, "%s has several grass blades" % clump.name)
		for blade in clump.get_children():
			_assert_true(blade is Polygon2D, "%s blade is Polygon2D" % clump.name)


func _has_no_collision_descendants(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D or child is StaticBody2D or child is Area2D:
			return false
		if not _has_no_collision_descendants(child):
			return false
	return true


func _assert_sprite_texture_path(scene: Node, node_path: String, expected_path: String) -> void:
	var building := scene.get_node_or_null(node_path)
	_assert_true(building != null, "%s exists for generated sprite" % node_path)
	if building == null:
		return

	var sprite: Sprite2D = building.get_node_or_null("GeneratedSprite")
	_assert_true(sprite != null, "%s has GeneratedSprite" % node_path)
	if sprite == null:
		return

	_assert_true(sprite.texture != null, "%s GeneratedSprite has texture" % node_path)
	if sprite.texture == null:
		return

	_assert_equal(sprite.texture.resource_path, expected_path, "%s GeneratedSprite reuses expected texture" % node_path)


func _assert_polygon_descendants_hidden(node: Node, message: String) -> void:
	if node == null:
		return
	for child in node.get_children():
		if child is Polygon2D:
			_assert_false(child.visible, "%s: %s" % [message, child.name])
		_assert_polygon_descendants_hidden(child, message)


func _assert_has_children(node: Node, child_names: Array, message: String) -> void:
	_assert_true(node != null, "%s root exists" % message)
	if node == null:
		return
	for child_name in child_names:
		_assert_true(node.get_node_or_null(str(child_name)) != null, "%s has %s" % [message, child_name])


func _assert_building_row(scene: Node, container_name: String, prefix: String, expected_count: int) -> void:
	var container := scene.get_node_or_null(container_name)
	_assert_true(container != null, "river scene has %s container" % container_name)
	if container == null:
		return

	_assert_equal(container.get_child_count(), expected_count, "%s has expected count" % container_name)
	var last_x := -INF
	var row_y := INF
	for i in range(expected_count):
		var child_name := "%s%02d" % [prefix, i + 1]
		var child: Node2D = container.get_node_or_null(child_name)
		_assert_true(child != null, "%s contains %s" % [container_name, child_name])
		if child == null:
			continue
		if i == 0:
			row_y = child.position.y
		else:
			_assert_equal(child.position.y, row_y, "%s buildings are placed in one row" % container_name)
		_assert_true(child.position.x > last_x, "%s buildings are placed side by side" % container_name)
		last_x = child.position.x


func _test_dynamic_npcs(scene: Node) -> void:
	var director_script := load(RIVER_NPC_DIRECTOR_SCRIPT_PATH)
	_assert_true(director_script != null, "river scene NPC director script loads")

	var director := scene.get_node_or_null("RiverNPCDirector")
	_assert_true(director != null, "river scene has NPC director")
	_assert_true(director != null and director.has_method("setup_scene_npcs"), "river NPC director can populate moving NPCs")

	var npcs := scene.get_node_or_null("NPCs")
	_assert_true(npcs != null, "river scene has dynamic NPC container")
	if npcs == null:
		return

	if director != null and director.has_method("setup_scene_npcs"):
		director.setup_scene_npcs()

	var static_npcs := scene.get_node_or_null("StaticNPCs")
	_assert_true(static_npcs != null, "river scene keeps static NPC fallback")
	if static_npcs != null:
		_assert_false(static_npcs.visible, "static NPC fallback is hidden after dynamic NPC setup")

	_assert_equal(npcs.get_child_count(), 29, "river scene has expected dynamic NPC count")
	_assert_scripted_npcs(npcs, 29)
	_assert_role_count(npcs, "farmer", 5)
	_assert_role_count(npcs, "lumberjack", 3)
	_assert_role_count(npcs, "miner", 3)
	_assert_role_count(npcs, "villager", 2)
	_assert_role_count(npcs, "warrior", 10)
	_assert_role_count(npcs, "archer", 6)
	_assert_npc_moves(npcs)
	_assert_workers_enter_buildings(npcs, director)


func _assert_count(parent: Node, child_name: String, expected_count: int) -> void:
	var child := parent.get_node_or_null(child_name)
	_assert_true(child != null, "static NPCs include %s" % child_name)
	if child != null:
		_assert_equal(child.get_child_count(), expected_count, "%s has expected NPC count" % child_name)


func _assert_scripted_npcs(npcs: Node, expected_count: int) -> void:
	var npc_script := load(NPC_SCRIPT_PATH)
	_assert_true(npc_script != null, "NPC.gd loads for river NPC assertions")
	if npc_script == null:
		return

	var scripted_count := 0
	for child in npcs.get_children():
		if child.get_script() == npc_script:
			scripted_count += 1
	_assert_equal(scripted_count, expected_count, "all river NPCs use the main NPC movement script")


func _assert_role_count(npcs: Node, role: String, expected_count: int) -> void:
	var count := 0
	for child in npcs.get_children():
		if str(child.get("worker_role")) == role:
			count += 1
	_assert_equal(count, expected_count, "river scene has %d %s NPCs" % [expected_count, role])


func _assert_npc_moves(npcs: Node) -> void:
	if npcs.get_child_count() == 0:
		_fail("river scene has a scripted NPC that can move: expected at least one NPC")
		return

	var npc := npcs.get_child(0)
	_assert_true(npc.has_method("_process"), "river NPC exposes NPC.gd process movement")
	if not npc.has_method("_process"):
		return

	var start_position: Vector2 = npc.global_position
	npc.set("target_position", start_position + Vector2(64, 0))
	npc._process(1.0)
	_assert_true(npc.global_position.x > start_position.x, "river scripted NPC moves toward its target")


func _assert_workers_enter_buildings(npcs: Node, director: Node) -> void:
	var worker_names := ["Farmer_01", "Lumberjack_01", "Miner_01", "SmithVillager_01"]
	for npc_name in worker_names:
		var npc: Node2D = npcs.get_node_or_null(npc_name)
		_assert_true(npc != null, "%s exists for river building entry" % npc_name)
		if npc == null:
			continue
		_assert_true(npc.get("is_traveling_to_workplace") == true, "%s travels to its assigned river building" % npc_name)
		var home_center: Vector2 = npc.get("home_center")
		npc.global_position = home_center
		npc.set("target_position", home_center)

	if director != null and director.has_method("_process"):
		director._process(0.1)

	for npc_name in worker_names:
		var npc: Node2D = npcs.get_node_or_null(npc_name)
		if npc == null:
			continue
		_assert_true(npc.get("is_inside_building") == true, "%s enters its river building after arriving" % npc_name)
		_assert_false(npc.visible, "%s hides while working inside river building" % npc_name)

	var duplicate_a: Node2D = npcs.get_node_or_null("Farmer_02")
	var duplicate_b: Node2D = npcs.get_node_or_null("Farmer_03")
	_assert_true(duplicate_a != null and duplicate_b != null, "river duplicate-entry test has two farmers")
	if duplicate_a == null or duplicate_b == null:
		return

	for duplicate in [duplicate_a, duplicate_b]:
		duplicate.set("is_inside_building", false)
		duplicate.set("is_traveling_to_workplace", true)
		duplicate.set("assigned_workplace_id", "farm_1")
		duplicate.set("assigned_workplace_name", "farm")
		duplicate.set("home_center", Vector2(1600, 472))
		duplicate.global_position = Vector2(1600, 472)
		duplicate.set("target_position", Vector2(1600, 472))
		duplicate.visible = true

	if director != null and director.has_method("_process"):
		director._process(0.1)

	var farm_1_inside_count := 0
	for child in npcs.get_children():
		if child.get("assigned_workplace_id") == "farm_1" and child.get("is_inside_building") == true:
			farm_1_inside_count += 1
	_assert_equal(farm_1_inside_count, 1, "river director allows only one NPC inside the same building")


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
