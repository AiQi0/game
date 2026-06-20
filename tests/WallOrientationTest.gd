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
		_test_wall_orientation_data(game_data_script.new())
	if build_manager_script != null:
		_test_runtime_wall_orientation(build_manager_script)
		_test_restored_wall_orientation(build_manager_script)

	if failures == 0:
		print("WallOrientationTest: PASS")
	else:
		push_error("WallOrientationTest: %d failure(s)" % failures)

	quit(failures)


func _test_wall_orientation_data(data) -> void:
	_assert_true(data.has_method("building_orientation_rule"), "GameData exposes building orientation rules")
	if not data.has_method("building_orientation_rule"):
		return

	var rule: Dictionary = data.building_orientation_rule("wall")
	_assert_true(bool(rule.get("mirror_right_of_cityhall", false)), "wall mirrors when built right of city hall")


func _test_runtime_wall_orientation(build_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager
	var player: CharacterBody2D = setup.player

	manager.gold = 99
	_build_wall_near_player(manager, player, 4300.0)
	var left_wall := _latest_wall(manager)
	_assert_true(left_wall != null, "left-side wall is built")
	if left_wall != null:
		_assert_true(left_wall.global_position.x < 4800.0, "left-side wall is left of city hall")
		_assert_true(left_wall.scale.x > 0.0, "wall built left of city hall keeps normal facing")

	_build_wall_near_player(manager, player, 5124.0)
	var right_wall := _latest_wall(manager)
	_assert_true(right_wall != null, "right-side wall is built")
	if right_wall != null:
		_assert_true(right_wall.global_position.x > 4800.0, "right-side wall is right of city hall")
		_assert_true(right_wall.scale.x < 0.0, "wall built right of city hall is horizontally flipped")
		_assert_true(right_wall.scale.y > 0.0, "flipped wall keeps positive vertical scale")

	setup.root.free()


func _test_restored_wall_orientation(build_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script)
	var manager: Node2D = setup.manager

	manager._restore_building_snapshot({
		"node_name": "wall_loaded_right",
		"building_id": "wall",
		"entity_kind": "building",
		"display_name": "wall",
		"level": 1,
		"damaged": false,
		"demolishable": true,
		"is_workplace": true,
		"position": [5300.0, 472.0],
		"footprint_position": [5180.0, 272.0],
		"footprint_size": [240.0, 200.0],
	})

	var restored_wall := setup.buildings.get_node_or_null("wall_loaded_right") as Node2D
	_assert_true(restored_wall != null, "restored wall exists")
	if restored_wall != null:
		_assert_true(restored_wall.scale.x < 0.0, "restored right-side wall is horizontally flipped")

	setup.root.free()


func _build_wall_near_player(manager: Node2D, player: CharacterBody2D, player_x: float) -> void:
	player.global_position = Vector2(player_x, 472.0)
	manager.selected_index = _wall_building_index(manager)
	manager._recreate_preview()
	manager._try_build()


func _wall_building_index(manager: Node2D) -> int:
	for i in range(manager.buildings.size()):
		if manager.buildings[i].get("id", "") == "wall":
			return i
	return -1


func _latest_wall(manager: Node2D) -> Node2D:
	for i in range(manager.placed_buildings.size() - 1, -1, -1):
		var entity: Dictionary = manager.placed_buildings[i]
		if entity.get("building_id", "") == "wall":
			return entity.get("node", null) as Node2D
	return null


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


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
