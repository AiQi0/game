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
		_test_mother_tree_data(game_data_script.new())
	if catalog_script != null:
		_test_lumberyard_removed_from_build_bar(catalog_script.new())
	if build_manager_script != null:
		_test_mother_tree_spawn_and_lumberyard_build(build_manager_script)

	if failures == 0:
		print("MotherTreeLumberyardBuildTest: PASS")
	else:
		push_error("MotherTreeLumberyardBuildTest: %d failure(s)" % failures)

	quit(failures)


func _test_mother_tree_data(data) -> void:
	_assert_equal(data.world_value("mother_tree_count"), 3, "world data defines three mother trees")
	_assert_true(data.has_method("lumberyard_definition"), "GameData exposes lumberyard definition outside build bar")
	if data.has_method("lumberyard_definition"):
		var lumberyard: Dictionary = data.lumberyard_definition()
		_assert_equal(lumberyard.get("id", ""), "lumberyard", "lumberyard definition keeps id")
		_assert_equal(lumberyard.get("cost", 0), 10, "lumberyard built on mother tree costs ten gold")
		_assert_equal(lumberyard.get("size", Vector2.ZERO), Vector2(400, 260), "lumberyard footprint is doubled outside the build bar")


func _test_lumberyard_removed_from_build_bar(catalog) -> void:
	var ids := []
	for definition in catalog.get_buildings():
		ids.append(str(definition.get("id", "")))

	_assert_false(ids.has("lumberyard"), "lumberyard is not selectable from the bottom build bar")


func _test_mother_tree_spawn_and_lumberyard_build(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var player: CharacterBody2D = setup.player

	_assert_true(manager.has_method("_spawn_mother_trees"), "BuildManager can spawn mother trees")
	_assert_true(manager.has_method("_try_build_lumberyard_at_player_mother_tree"), "BuildManager can build lumberyards at mother trees")
	if not manager.has_method("_spawn_mother_trees") or not manager.has_method("_try_build_lumberyard_at_player_mother_tree"):
		setup.root.free()
		return

	manager._seed_existing_buildings()
	manager._spawn_mother_trees()
	var mother_trees := _entities_for_kind(manager, "mother_tree")
	_assert_equal(mother_trees.size(), 3, "world spawns three mother tree entities")
	for entity in mother_trees:
		var node: Node2D = entity.node
		if is_instance_valid(node):
			_assert_true(node.get_node_or_null("MotherTrunk") != null, "mother tree has a huge trunk visual")
			_assert_true(node.get_node_or_null("MotherCanopy") != null, "mother tree has a huge canopy visual")

	var mother_entity: Dictionary = mother_trees[0]
	var mother_node: Node2D = mother_entity.node
	player.global_position = mother_node.global_position
	manager.gold = 10
	manager.selected_index = -1
	var built: bool = manager._try_build_lumberyard_at_player_mother_tree()
	_assert_true(built, "pressing E on a mother tree handles lumberyard building")
	_assert_equal(manager.gold, 0, "building mother-tree lumberyard spends ten gold")
	_assert_equal(_building_count(manager, "lumberyard"), 1, "mother tree creates one lumberyard")
	_assert_equal(_work_site_count(manager, "lumberyard"), 1, "mother-tree lumberyard is a work site")

	var duplicate: bool = manager._try_build_lumberyard_at_player_mother_tree()
	_assert_false(duplicate, "already used mother tree no longer intercepts E")
	_assert_equal(_building_count(manager, "lumberyard"), 1, "same mother tree cannot build a second lumberyard")

	var lumberyard_index := _entity_index_for_building(manager, "lumberyard")
	_assert_true(lumberyard_index != -1, "built lumberyard can be found")
	if lumberyard_index != -1:
		var lumberyard_entity: Dictionary = manager.placed_buildings[lumberyard_index]
		var lumberyard_node: Node2D = lumberyard_entity.node
		if is_instance_valid(lumberyard_node):
			lumberyard_node.global_position += Vector2(800, 0)
		var before := _resource_count(manager, "tree")
		manager._update_lumberyards(120.0)
		_assert_equal(_resource_count(manager, "tree"), before, "mother-tree lumberyard no longer grows external trees")
		_assert_equal(manager.tree_chop_tasks.size(), 0, "mother-tree lumberyard no longer creates external chop tasks")
		_assert_equal(manager.game_data.building_interior_value("lumberyard", "resource_kind"), "tree", "lumberyard interior still owns tree production")
		_assert_equal(manager.game_data.building_interior_value("lumberyard", "spawn_count"), 3, "lumberyard interior grows three trees per batch")

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


func _entity_index_for_building(manager: Node2D, building_id: String) -> int:
	for i in range(manager.placed_buildings.size()):
		if manager.placed_buildings[i].get("building_id", "") == building_id:
			return i
	return -1


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


func _resource_count(manager: Node2D, resource_kind: String) -> int:
	var count := 0
	for entity in manager.placed_buildings:
		if entity.get("resource_kind", "") == resource_kind:
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
