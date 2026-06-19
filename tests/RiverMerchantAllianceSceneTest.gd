extends SceneTree

var failures := 0


func _init() -> void:
	var packed_scene: PackedScene = load("res://scenes/RiverMerchantAlliance.tscn")
	_assert_true(packed_scene != null, "river merchant alliance scene loads")
	if packed_scene == null:
		quit(failures)
		return

	var scene := packed_scene.instantiate()
	_assert_equal(scene.name, "RiverMerchantAlliance", "scene root is RiverMerchantAlliance")
	_test_world_size(scene)
	_test_air_walls(scene)
	_test_player(scene)
	_test_removed_original_buildings(scene)
	_test_city_buildings(scene)
	_test_static_npcs(scene)
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
	_assert_sprite_texture_path(scene, "CityHall", "res://assets/river_merchant_alliance/buildings/cityhall.png")
	_assert_sprite_texture_path(scene, "PostStation", "res://assets/river_merchant_alliance/buildings/post_station.png")
	_assert_sprite_texture_path(scene, "LeftWall", "res://assets/river_merchant_alliance/buildings/wall.png")
	_assert_sprite_texture_path(scene, "RightWall", "res://assets/river_merchant_alliance/buildings/wall.png")
	_assert_reused_sprite_texture(scene, "Farms", "Farm_", 5, "res://assets/river_merchant_alliance/buildings/farm.png")
	_assert_reused_sprite_texture(scene, "Lumberyards", "Lumberyard_", 3, "res://assets/river_merchant_alliance/buildings/lumberyard.png")
	_assert_reused_sprite_texture(scene, "Quarries", "Quarry_", 3, "res://assets/river_merchant_alliance/buildings/quarry.png")
	_assert_reused_sprite_texture(scene, "Blacksmiths", "Blacksmith_", 2, "res://assets/river_merchant_alliance/buildings/blacksmith.png")


func _assert_reused_sprite_texture(scene: Node, container_name: String, prefix: String, expected_count: int, expected_path: String) -> void:
	for i in range(expected_count):
		var child_name := "%s/%s%02d" % [container_name, prefix, i + 1]
		_assert_sprite_texture_path(scene, child_name, expected_path)


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


func _test_static_npcs(scene: Node) -> void:
	var npcs := scene.get_node_or_null("StaticNPCs")
	_assert_true(npcs != null, "river scene has static NPC container")
	if npcs == null:
		return

	_assert_count(npcs, "Farmers", 5)
	_assert_count(npcs, "Lumberjacks", 3)
	_assert_count(npcs, "Miners", 3)
	_assert_count(npcs, "SmithVillagers", 2)
	_assert_count(npcs, "Warriors", 10)
	_assert_count(npcs, "Archers", 6)


func _assert_count(parent: Node, child_name: String, expected_count: int) -> void:
	var child := parent.get_node_or_null(child_name)
	_assert_true(child != null, "static NPCs include %s" % child_name)
	if child != null:
		_assert_equal(child.get_child_count(), expected_count, "%s has expected NPC count" % child_name)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
