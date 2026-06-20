extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if build_manager_script != null:
		_test_stone_shows_quarry_preview(build_manager_script)
		_test_mother_tree_shows_lumberyard_preview(build_manager_script)
		_test_bridge_shows_farm_preview_and_clears_when_leaving(build_manager_script)

	if failures == 0:
		print("ResourceBuildPreviewTest: PASS")
	else:
		push_error("ResourceBuildPreviewTest: %d failure(s)" % failures)

	quit(failures)


func _test_stone_shows_quarry_preview(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager
	var player: CharacterBody2D = setup.player

	manager._seed_existing_buildings()
	_set_building_level(manager, "cityhall", 2)
	var stone: Node2D = manager._spawn_stone_at(Vector2(4300, 472))
	player.global_position = stone.global_position
	manager.selected_index = -1
	manager.gold = 20
	manager._update_preview()

	_assert_true(manager.preview != null, "standing on a stone creates a quarry build preview")
	if manager.preview != null:
		_assert_equal(manager.preview.global_position, stone.global_position, "quarry preview is positioned on the stone")
		_assert_true(_is_green_preview(manager.preview), "quarry preview is green when city hall and gold requirements are met")

	manager.gold = 0
	manager._update_preview()
	_assert_true(manager.preview != null, "stone preview remains visible when quarry is unaffordable")
	if manager.preview != null:
		_assert_true(_is_red_preview(manager.preview), "quarry preview turns red when gold is insufficient")

	setup.root.free()


func _test_mother_tree_shows_lumberyard_preview(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager
	var player: CharacterBody2D = setup.player

	var mother_tree: Node2D = manager._spawn_mother_tree_at(Vector2(3300, 472))
	player.global_position = mother_tree.global_position
	manager.selected_index = -1
	manager.gold = 10
	manager._update_preview()

	_assert_true(manager.preview != null, "standing on a mother tree creates a lumberyard build preview")
	if manager.preview != null:
		_assert_equal(manager.preview.global_position, mother_tree.global_position, "lumberyard preview is positioned on the mother tree")
		_assert_true(_is_green_preview(manager.preview), "lumberyard preview is green when the mother tree is unused")

	var mother_tree_index: int = int(manager._mother_tree_entity_index_containing_point(player.global_position))
	var mother_tree_entity: Dictionary = manager.placed_buildings[mother_tree_index]
	mother_tree_entity.has_lumberyard = true
	manager.placed_buildings[mother_tree_index] = mother_tree_entity
	manager._update_preview()
	_assert_equal(manager.preview, null, "occupied mother tree does not show a red lumberyard preview")

	setup.root.free()


func _test_bridge_shows_farm_preview_and_clears_when_leaving(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager
	var player: CharacterBody2D = setup.player

	var bridge: Node2D = manager._spawn_bridge_at(Vector2(5700, 472))
	player.global_position = bridge.global_position
	manager.selected_index = -1
	manager.gold = 5
	manager._update_preview()

	_assert_true(manager.preview != null, "standing on a bridge creates a farm build preview")
	if manager.preview != null:
		_assert_equal(manager.preview.global_position, bridge.global_position, "farm preview is positioned on the bridge")
		_assert_true(_is_green_preview(manager.preview), "farm preview is green when the bridge is unused")

	var bridge_index: int = int(manager._bridge_entity_index_containing_point(player.global_position))
	var bridge_entity: Dictionary = manager.placed_buildings[bridge_index]
	bridge_entity.farm_built = true
	manager.placed_buildings[bridge_index] = bridge_entity
	manager._update_preview()
	_assert_equal(manager.preview, null, "occupied bridge does not show a red farm preview")

	player.global_position = Vector2(4800, 472)
	manager._update_preview()
	_assert_equal(manager.preview, null, "resource build preview clears after the player leaves the bridge")

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

	var status_label := Label.new()
	root.add_child(status_label)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.player = player
	manager.buildings_container = buildings
	manager.status_label = status_label

	return {
		"root": root,
		"manager": manager,
		"player": player,
	}


func _set_building_level(manager: Node2D, building_id: String, level: int) -> void:
	for i in range(manager.placed_buildings.size()):
		var entity: Dictionary = manager.placed_buildings[i]
		if entity.get("building_id", "") != building_id:
			continue
		entity.level = level
		manager.placed_buildings[i] = entity
		return


func _is_green_preview(preview: Node2D) -> bool:
	return preview.modulate.g > preview.modulate.r


func _is_red_preview(preview: Node2D) -> bool:
	return preview.modulate.r > preview.modulate.g


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
