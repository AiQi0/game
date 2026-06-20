extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var catalog_script := load("res://scripts/BuildingCatalog.gd")

	if game_data_script == null:
		_fail("GameData.gd should load")
	if catalog_script == null:
		_fail("BuildingCatalog.gd should load")

	if game_data_script != null:
		var data = game_data_script.new()
		_test_direct_building_definitions_scale(data)
		_test_terrain_building_definitions_scale(data)
		_test_city_hall_size_stays_unchanged(data)
		_test_resource_sizes_scale(data)

	if catalog_script != null:
		_test_catalog_building_definitions_scale(catalog_script.new())

	if failures == 0:
		print("BuildingScaleTest: PASS")
	else:
		push_error("BuildingScaleTest: %d failure(s)" % failures)

	quit(failures)


func _test_catalog_building_definitions_scale(catalog) -> void:
	var buildings: Array = catalog.get_buildings()
	_assert_equal(_definition_size(buildings, "blacksmith"), Vector2(360, 280), "blacksmith footprint is doubled")
	_assert_equal(_definition_size(buildings, "wall"), Vector2(240, 200), "wall footprint is doubled")
	_assert_equal(_definition_size(buildings, "tavern"), Vector2(380, 300), "tavern footprint is doubled")
	_assert_equal(_definition_size(buildings, "post_station"), Vector2(380, 260), "post station footprint is doubled")
	_assert_equal(_definition_size(buildings, "barracks"), Vector2(440, 300), "barracks footprint is doubled")


func _test_direct_building_definitions_scale(data) -> void:
	_assert_equal(data.farm_definition().get("size"), Vector2(440, 120), "bridge farm footprint is doubled")
	_assert_equal(data.lumberyard_definition().get("size"), Vector2(400, 260), "mother-tree lumberyard footprint is doubled")
	_assert_equal(data.quarry_definition().get("size"), Vector2(360, 240), "stone quarry footprint is doubled")


func _test_terrain_building_definitions_scale(data) -> void:
	var terrain_buildings: Array = data.terrain_building_definitions()
	_assert_equal(_definition_size(terrain_buildings, "river_port"), Vector2(440, 260), "river port footprint is doubled")
	_assert_equal(_definition_size(terrain_buildings, "beacon_tower"), Vector2(220, 380), "beacon tower footprint is doubled")
	_assert_equal(_definition_size(terrain_buildings, "iron_mine"), Vector2(380, 260), "iron mine footprint is doubled")
	_assert_equal(_definition_size(terrain_buildings, "cliff_fort"), Vector2(420, 340), "cliff fort footprint is doubled")


func _test_city_hall_size_stays_unchanged(data) -> void:
	_assert_equal(data.world_value("city_hall_size"), Vector2(400, 334), "city hall size stays unchanged")


func _test_resource_sizes_scale(data) -> void:
	_assert_equal(data.world_value("tree_size"), Vector2(128, 240), "tree world size is doubled")
	_assert_equal(data.world_value("stone_size"), Vector2(144, 144), "stone world size is doubled")
	_assert_equal(data.world_value("mother_tree_size"), Vector2(340, 520), "mother tree world size is doubled")
	_assert_equal(data.resource_value("tree", "size"), Vector2(128, 240), "tree resource size is doubled")
	_assert_equal(data.resource_value("stone", "size"), Vector2(144, 144), "stone resource size is doubled")
	_assert_equal(data.resource_value("mother_tree", "size"), Vector2(340, 520), "mother tree resource size is doubled")


func _definition_size(definitions: Array, building_id: String) -> Vector2:
	for definition in definitions:
		if definition.get("id", "") == building_id:
			return definition.get("size", Vector2.ZERO)
	return Vector2.ZERO


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
