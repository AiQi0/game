extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var catalog_script := load("res://scripts/BuildingCatalog.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if game_data_script == null:
		_fail("GameData.gd should load")
	if catalog_script == null:
		_fail("BuildingCatalog.gd should load")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if game_data_script != null and catalog_script != null:
		var data = game_data_script.new()
		var catalog = catalog_script.new()
		_test_visible_rect_uses_opaque_pixels(data)
		_test_body_size_ignores_transparent_padding(data, catalog)
	if game_data_script != null and build_manager_script != null:
		var runtime_data = game_data_script.new()
		if runtime_data.has_method("building_body_size"):
			_test_runtime_build_uses_pixel_body_footprint(runtime_data, build_manager_script)
			_test_resource_build_uses_pixel_body_footprint(runtime_data, build_manager_script)

	if failures == 0:
		print("BuildingPixelFootprintTest: PASS")
	else:
		push_error("BuildingPixelFootprintTest: %d failure(s)" % failures)

	quit(failures)


func _test_visible_rect_uses_opaque_pixels(data) -> void:
	_assert_true(data.has_method("art_asset_visible_rect"), "GameData exposes visible asset bounds")
	if not data.has_method("art_asset_visible_rect"):
		return

	var wall_texture: Texture2D = data.art_asset_texture("buildings", "wall")
	var wall_rect: Rect2 = data.art_asset_visible_rect("buildings", "wall")
	_assert_true(wall_texture != null, "wall texture loads")
	if wall_texture != null:
		_assert_true(wall_rect.size.x < float(wall_texture.get_width()), "wall visible width excludes transparent pixels")
		_assert_true(wall_rect.size.y <= float(wall_texture.get_height()), "wall visible height fits the texture")


func _test_body_size_ignores_transparent_padding(data, catalog) -> void:
	_assert_true(data.has_method("building_body_size"), "GameData exposes building body size")
	if not data.has_method("building_body_size"):
		return

	var wall_definition: Dictionary = _definition_for_id(catalog.get_buildings(), "wall")
	var wall_body_size: Vector2 = data.building_body_size(wall_definition)
	var wall_definition_size: Vector2 = wall_definition.get("size", Vector2.ZERO)
	_assert_true(wall_body_size.x < wall_definition_size.x, "wall body footprint is narrower than transparent canvas footprint")
	_assert_vector_close(wall_body_size, Vector2(136.6667, 200.0), 0.01, "wall body size matches rendered opaque pixels")

	var farm_definition: Dictionary = data.farm_definition()
	var farm_body_size: Vector2 = data.building_body_size(farm_definition)
	var farm_definition_size: Vector2 = farm_definition.get("size", Vector2.ZERO)
	_assert_true(farm_body_size.x < farm_definition_size.x, "farm body footprint is narrower than transparent canvas footprint")
	_assert_vector_close(farm_body_size, Vector2(351.0, 94.5), 0.01, "farm body size matches rendered opaque pixels")


func _test_runtime_build_uses_pixel_body_footprint(data, build_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager
	var player: CharacterBody2D = setup.player

	player.global_position = Vector2(4200, 472)
	manager.gold = 99
	manager.selected_index = _building_index(manager, "wall")
	manager._recreate_preview()
	manager._try_build()

	var wall_entity := _entity_for_building(manager, "wall")
	_assert_true(not wall_entity.is_empty(), "runtime wall is built")
	if not wall_entity.is_empty():
		var wall_definition: Dictionary = _definition_for_id(manager.buildings, "wall")
		_assert_vector_close(
			wall_entity.get("footprint", Rect2()).size,
			data.building_body_size(wall_definition),
			0.01,
			"runtime wall footprint uses opaque pixel body size"
		)

	setup.root.free()


func _test_resource_build_uses_pixel_body_footprint(data, build_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager
	var player: CharacterBody2D = setup.player

	var bridge: Node2D = manager._spawn_bridge_at(Vector2(5700, 472))
	player.global_position = bridge.global_position
	manager.gold = 5
	manager.selected_index = -1
	_assert_true(manager._try_build_farm_at_player_bridge(), "bridge farm is built")

	var farm_entity := _entity_for_building(manager, "farm")
	_assert_true(not farm_entity.is_empty(), "resource farm entity exists")
	if not farm_entity.is_empty():
		_assert_vector_close(
			farm_entity.get("footprint", Rect2()).size,
			data.building_body_size(data.farm_definition()),
			0.01,
			"bridge farm footprint uses opaque pixel body size"
		)

	setup.root.free()


func _create_world(build_manager_script: Script) -> Dictionary:
	var root := Node2D.new()
	var city_hall := Node2D.new()
	city_hall.name = "CityHall"
	city_hall.global_position = Vector2(4800, 472)
	root.add_child(city_hall)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(4800, 472)
	root.add_child(player)

	var status_label := Label.new()
	root.add_child(status_label)
	var gold_label := Label.new()
	root.add_child(gold_label)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.player = player
	manager.buildings_container = buildings
	manager.status_label = status_label
	manager.gold_label = gold_label
	manager._refresh_building_choices()
	manager._track_placed_entity(
		city_hall,
		Rect2(Vector2(4600, 138), Vector2(400, 334)),
		false,
		"cityhall",
		"cityhall",
		false,
		"cityhall"
	)

	return {
		"root": root,
		"manager": manager,
		"player": player,
		"buildings": buildings,
	}


func _definition_for_id(definitions: Array, building_id: String) -> Dictionary:
	for definition in definitions:
		if definition.get("id", "") == building_id:
			return definition
	return {}


func _building_index(manager: Node2D, building_id: String) -> int:
	for i in range(manager.buildings.size()):
		if manager.buildings[i].get("id", "") == building_id:
			return i
	return -1


func _entity_for_building(manager: Node2D, building_id: String) -> Dictionary:
	for entity in manager.placed_buildings:
		if entity.get("building_id", "") == building_id:
			return entity
	return {}


func _assert_vector_close(actual: Vector2, expected: Vector2, tolerance: float, message: String) -> void:
	if actual.distance_to(expected) > tolerance:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
