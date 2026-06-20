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

	if game_data_script != null:
		_test_bridge_and_farm_data(game_data_script.new())
	if catalog_script != null:
		_test_farm_removed_from_build_bar(catalog_script.new())
	if build_manager_script != null:
		_test_bridge_spawn_and_farm_build(build_manager_script)

	if failures == 0:
		print("BridgeFarmBuildTest: PASS")
	else:
		push_error("BridgeFarmBuildTest: %d failure(s)" % failures)

	quit(failures)


func _test_bridge_and_farm_data(data) -> void:
	_assert_equal(data.world_value("bridge_count"), 5, "world data defines five short bridges")
	_assert_equal(data.world_value("bridge_size"), Vector2(260, 16), "bridge deck is long and shallow enough to sit flush in ground")
	_assert_equal(data.world_value("bridge_water_size"), Vector2(220, 56), "bridge water keeps a shorter span than the deck")
	_assert_equal(data.world_value("city_hall_resource_inner_radius"), 1000.0, "bridge inner city hall radius is data-driven")
	_assert_equal(data.world_value("city_hall_resource_outer_radius"), 2000.0, "bridge outer city hall radius is data-driven")
	_assert_equal(data.economy_value("bridge_farm_cost"), 5, "bridge farm cost is data-driven")
	_assert_true(data.has_method("farm_definition"), "GameData exposes farm definition outside build bar")
	if data.has_method("farm_definition"):
		var farm: Dictionary = data.farm_definition()
		_assert_equal(farm.get("id", ""), "farm", "farm definition keeps farm id")
		_assert_equal(farm.get("cost", 0), 5, "farm built on bridge costs five gold")
		_assert_equal(farm.get("size", Vector2.ZERO), Vector2(440, 120), "farm footprint is doubled outside the build bar")


func _test_farm_removed_from_build_bar(catalog) -> void:
	var ids := []
	for definition in catalog.get_buildings():
		ids.append(str(definition.get("id", "")))

	_assert_false(ids.has("farm"), "farm is not selectable from the bottom build bar")


func _test_bridge_spawn_and_farm_build(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	var city_hall: Node2D = setup.city_hall
	var player: CharacterBody2D = setup.player

	_assert_true(manager.has_method("_spawn_bridges"), "BuildManager can spawn bridge entities")
	_assert_true(manager.has_method("_try_build_farm_at_player_bridge"), "BuildManager can build farms on bridges")
	if not manager.has_method("_spawn_bridges") or not manager.has_method("_try_build_farm_at_player_bridge"):
		setup.root.free()
		return

	manager._seed_existing_buildings()
	manager._spawn_bridges()
	var bridge_entities := _entities_for_kind(manager, "bridge")
	_assert_equal(bridge_entities.size(), 5, "world spawns five bridge entities")

	var city_hall_distances := []
	var bridge_size: Vector2 = manager.game_data.world_value("bridge_size")
	var city_hall_inner_radius: float = manager.game_data.world_value("city_hall_resource_inner_radius", 1000.0)
	var city_hall_outer_radius: float = manager.game_data.world_value("city_hall_resource_outer_radius", 2000.0)
	for entity in bridge_entities:
		var node: Node2D = entity.node
		if is_instance_valid(node):
			city_hall_distances.append(absf(node.global_position.x - city_hall.global_position.x))
			var water := node.get_node_or_null("Water") as Polygon2D
			var deck := node.get_node_or_null("Deck") as Polygon2D
			_assert_true(water != null, "bridge has water below it")
			_assert_true(deck != null, "bridge has a deck visual")
			if water != null and deck != null:
				var water_bounds := _polygon_bounds(water)
				var deck_bounds := _polygon_bounds(deck)
				_assert_true(deck_bounds.size.x >= water_bounds.size.x, "bridge deck spans across the whole water gap")
				_assert_equal(deck_bounds.position.y, 0.0, "bridge deck starts at ground level after being lowered")
				_assert_equal(deck_bounds.position.y + deck_bounds.size.y, bridge_size.y, "bridge deck is lowered by exactly one deck thickness")
				_assert_equal(water_bounds.position.y, bridge_size.y, "bridge water starts below the lowered deck")
	city_hall_distances.sort()
	_assert_equal(_distance_count(city_hall_distances, 0.0, city_hall_inner_radius), 0, "no bridge spawns within 1000 of city hall")
	_assert_equal(_distance_count(city_hall_distances, city_hall_inner_radius, city_hall_outer_radius), 1, "one bridge spawns between 1000 and 2000 of city hall")

	var bridge_entity: Dictionary = bridge_entities[0]
	var bridge_node: Node2D = bridge_entity.node
	player.global_position = bridge_node.global_position
	manager.gold = 5
	manager.selected_index = -1
	var built: bool = manager._try_build_farm_at_player_bridge()
	_assert_true(built, "pressing E on an unused bridge handles farm building")
	_assert_equal(manager.gold, 0, "building bridge farm spends five gold")
	_assert_equal(_building_count(manager, "farm"), 1, "bridge farm creates a farm building")
	_assert_equal(_work_site_count(manager, "farm"), 1, "bridge farm is a worker site")

	var duplicate: bool = manager._try_build_farm_at_player_bridge()
	_assert_false(duplicate, "already used bridge no longer intercepts E")
	_assert_equal(_building_count(manager, "farm"), 1, "same bridge cannot build a second farm")

	setup.root.free()


func _create_world(build_manager_script) -> Dictionary:
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

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.player = player
	manager.buildings_container = buildings

	return {
		"root": root,
		"manager": manager,
		"buildings": buildings,
		"city_hall": city_hall,
		"player": player,
	}


func _entities_for_kind(manager: Node2D, entity_kind: String) -> Array:
	var entities := []
	for entity in manager.placed_buildings:
		if entity.get("entity_kind", "") == entity_kind:
			entities.append(entity)
	return entities


func _building_count(manager: Node2D, building_id: String) -> int:
	var count := 0
	for entity in manager.placed_buildings:
		if entity.get("building_id", "") == building_id:
			count += 1
	return count


func _work_site_count(manager: Node2D, building_id: String) -> int:
	var count := 0
	for site in manager.get_work_sites():
		if site.get("building_id", "") == building_id:
			count += 1
	return count


func _polygon_bounds(polygon: Polygon2D) -> Rect2:
	if polygon.polygon.is_empty():
		return Rect2()

	var min_x := polygon.polygon[0].x
	var max_x := polygon.polygon[0].x
	var min_y := polygon.polygon[0].y
	var max_y := polygon.polygon[0].y
	for point in polygon.polygon:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _distance_count(distances: Array, min_distance: float, max_distance: float) -> int:
	var count := 0
	for distance in distances:
		if distance > min_distance and distance <= max_distance:
			count += 1
	return count


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
