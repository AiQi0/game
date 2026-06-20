extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")

	if game_data_script == null:
		_fail("GameData.gd should load")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if game_data_script != null:
		_test_city_hall_radius_data(game_data_script.new())
	if build_manager_script != null:
		_test_city_hall_resource_spawn_radii(build_manager_script)

	if failures == 0:
		print("CityHallSpawnRadiusTest: PASS")
	else:
		push_error("CityHallSpawnRadiusTest: %d failure(s)" % failures)

	quit(failures)


func _test_city_hall_radius_data(data) -> void:
	_assert_equal(data.world_value("city_hall_resource_inner_radius"), 1000.0, "inner city hall resource radius is data-driven")
	_assert_equal(data.world_value("city_hall_resource_outer_radius"), 2000.0, "outer city hall resource radius is data-driven")


func _test_city_hall_resource_spawn_radii(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var city_hall: Node2D = setup.city_hall

	manager._seed_existing_buildings()
	manager._spawn_bridges()
	manager._spawn_mother_trees()
	manager._spawn_stones()
	manager._spawn_trees()

	var inner_radius := float(manager.game_data.world_value("city_hall_resource_inner_radius", 1000.0))
	var outer_radius := float(manager.game_data.world_value("city_hall_resource_outer_radius", 2000.0))
	for resource_kind in ["bridge", "mother_tree", "stone"]:
		var distances := _resource_distances_from_city_hall(manager, city_hall, resource_kind)
		var inner_count := _distance_count(distances, 0.0, inner_radius)
		var ring_count := _distance_count(distances, inner_radius, outer_radius)
		_assert_equal(inner_count, 0, "%s does not spawn within 1000 of city hall" % resource_kind)
		_assert_equal(ring_count, 1, "%s has exactly one spawn between 1000 and 2000 of city hall" % resource_kind)

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

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.buildings_container = buildings

	return {
		"root": root,
		"manager": manager,
		"city_hall": city_hall,
	}


func _resource_distances_from_city_hall(manager: Node2D, city_hall: Node2D, resource_kind: String) -> Array:
	var distances := []
	for entity in manager.placed_buildings:
		if entity.get("resource_kind", "") != resource_kind:
			continue

		var node: Node2D = entity.node
		if is_instance_valid(node):
			distances.append(absf(node.global_position.x - city_hall.global_position.x))
	return distances


func _distance_count(distances: Array, min_distance: float, max_distance: float) -> int:
	var count := 0
	for distance in distances:
		if distance > min_distance and distance <= max_distance:
			count += 1
	return count


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
