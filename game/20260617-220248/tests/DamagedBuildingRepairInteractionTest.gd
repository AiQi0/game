extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if build_manager_script != null:
		_test_damaged_building_repairs_from_e_without_panel(build_manager_script)

	if failures == 0:
		print("DamagedBuildingRepairInteractionTest: PASS")
	else:
		push_error("DamagedBuildingRepairInteractionTest: %d failure(s)" % failures)

	quit(failures)


func _test_damaged_building_repairs_from_e_without_panel(build_manager_script: Script) -> void:
	var root := Node2D.new()
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(4200, 472)
	root.add_child(player)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.player = player
	manager.buildings_container = buildings
	var status_label := Label.new()
	status_label.name = "BuildStatus"
	manager.add_child(status_label)
	manager.status_label = status_label
	manager.gold = 99

	var farm := Node2D.new()
	farm.name = "farm_damaged"
	farm.global_position = Vector2(4200, 472)
	buildings.add_child(farm)
	manager._track_placed_entity(
		farm,
		Rect2(Vector2(4090, 412), Vector2(220, 60)),
		true,
		"farm",
		"building",
		true,
		"farm"
	)

	var entity: Dictionary = manager.placed_buildings[0]
	entity.damaged = true
	manager.placed_buildings[0] = entity
	var repair_cost: int = manager.repair_cost_for_entity_index(0)
	manager._update_preview()
	_assert_equal(manager.status_label.text, "E 修复 %d金" % repair_cost, "standing under damaged building shows repair prompt and price")
	manager.gold = repair_cost - 1
	manager._update_preview()
	_assert_equal(manager.status_label.text, "金币不足，修复需要 %d金" % repair_cost, "repair prompt shows price when gold is insufficient")

	manager.gold = 99
	_assert_true(manager._try_toggle_building_info_panel(), "pressing E on damaged building is handled")
	_assert_true(manager.info_panel == null, "damaged building does not open info panel")
	_assert_false(manager.placed_buildings[0].get("damaged", true), "pressing E repairs damaged building")
	_assert_equal(manager.gold, 99 - repair_cost, "pressing E spends repair cost")

	entity = manager.placed_buildings[0]
	entity.damaged = true
	manager.placed_buildings[0] = entity
	manager.gold = 99
	manager.selected_index = 0
	_assert_true(manager._try_repair_damaged_building_at_player(), "damaged repair has priority over selected building")
	_assert_false(manager.placed_buildings[0].get("damaged", true), "priority repair clears damaged state")

	entity = manager.placed_buildings[0]
	entity.damaged = true
	manager.placed_buildings[0] = entity
	manager._show_building_info_panel(0)
	_assert_true(manager.info_panel == null, "damaged building cannot be opened by panel API")

	root.free()


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
