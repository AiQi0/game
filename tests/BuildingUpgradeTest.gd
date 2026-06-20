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
		_test_upgrade_data(game_data_script.new())
	if build_manager_script != null:
		_test_city_hall_upgrade(build_manager_script)
		_test_building_upgrade_unlock(build_manager_script)
		_test_info_panel_level_text(build_manager_script)
		_test_info_panel_keyboard_upgrade_and_close(build_manager_script)

	if failures == 0:
		print("BuildingUpgradeTest: PASS")
	else:
		push_error("BuildingUpgradeTest: %d failure(s)" % failures)

	quit(failures)


func _test_upgrade_data(data) -> void:
	_assert_equal(data.building_upgrade_cost("cityhall", 2), 50, "city hall level 2 costs 50 gold")
	_assert_equal(data.building_upgrade_cost("cityhall", 3), 100, "city hall level 3 costs 100 gold")
	_assert_equal(data.building_upgrade_cost("cityhall", 4), 180, "city hall level 4 costs 180 gold")
	_assert_equal(data.building_upgrade_cost("blacksmith", 2), 20, "blacksmith level 2 costs 20 gold")
	_assert_equal(data.building_upgrade_cost("blacksmith", 3), 40, "blacksmith level 3 costs 40 gold")
	_assert_equal(data.building_upgrade_cost("wall", 2), 15, "wall level 2 costs 15 gold")
	_assert_equal(data.building_upgrade_cost("farm", 2), 15, "farm level 2 costs 15 gold")
	_assert_equal(data.building_upgrade_cost("lumberyard", 2), 30, "lumberyard level 2 costs 30 gold")
	_assert_equal(data.building_upgrade_requirements("blacksmith", 2), {"cityhall": 2, "quarry": 1}, "blacksmith level 2 requires city hall level 2 and a quarry")
	_assert_equal(data.building_upgrade_requirements("blacksmith", 3), {"cityhall": 3, "iron_mine": 1}, "blacksmith level 3 requires city hall level 3 and an iron mine")
	_assert_false(data.has_building_upgrade("tavern", 2), "tavern has no level 2 upgrade yet")


func _test_city_hall_upgrade(build_manager_script) -> void:
	var setup := _create_manager_with_city_hall(build_manager_script)
	var manager = setup.manager

	_assert_true(manager.has_method("upgrade_building"), "BuildManager exposes upgrade_building")
	_assert_true(manager.has_method("can_upgrade_entity"), "BuildManager exposes can_upgrade_entity")
	_assert_true(manager.has_method("upgrade_cost_for_entity_index"), "BuildManager exposes upgrade cost lookup")

	manager.gold = 49
	_assert_equal(manager.upgrade_cost_for_entity_index(0), 50, "city hall upgrade cost is available")
	_assert_false(manager.can_upgrade_entity(0), "city hall cannot upgrade without enough gold")
	_assert_false(manager.upgrade_building(0), "city hall upgrade fails without enough gold")
	_assert_equal(manager.placed_buildings[0].get("level"), 1, "failed upgrade leaves city hall at level 1")

	manager.gold = 50
	_assert_true(manager.can_upgrade_entity(0), "city hall can upgrade with enough gold")
	_assert_true(manager.upgrade_building(0), "city hall upgrades to level 2")
	_assert_equal(manager.gold, 0, "city hall upgrade spends 50 gold")
	_assert_equal(manager.placed_buildings[0].get("level"), 2, "city hall stores level 2")

	setup.root.free()


func _test_building_upgrade_unlock(build_manager_script) -> void:
	var setup := _create_manager_with_city_hall(build_manager_script)
	var manager = setup.manager
	var buildings_container: Node2D = setup.buildings_container

	_track_building(manager, buildings_container, "blacksmith_1", "blacksmith", Vector2(5200, 472), Vector2(180, 140), 1)

	manager.gold = 100
	_assert_false(manager.can_upgrade_entity(1), "blacksmith level 2 is locked before city hall level 2")
	_assert_false(manager.upgrade_building(1), "locked blacksmith upgrade fails")
	_assert_equal(manager.placed_buildings[1].get("level"), 1, "locked blacksmith stays level 1")

	_assert_true(manager.upgrade_building(0), "city hall upgrade unlocks building level 2")
	_assert_false(manager.can_upgrade_entity(1), "blacksmith level 2 still needs a quarry after city hall reaches level 2")
	_assert_false(manager.upgrade_building(1), "blacksmith level 2 upgrade fails without a quarry")
	_assert_equal(manager.placed_buildings[1].get("level"), 1, "blacksmith stays level 1 without a quarry")

	_track_building(manager, buildings_container, "quarry_1", "quarry", Vector2(5600, 472), Vector2(220, 150), 1)
	_assert_true(manager.can_upgrade_entity(1), "blacksmith can upgrade after city hall reaches level 2 and a quarry exists")
	_assert_true(manager.upgrade_building(1), "blacksmith upgrades after unlock")
	_assert_equal(manager.gold, 30, "city hall and blacksmith upgrades spend 70 gold total")
	_assert_equal(manager.placed_buildings[1].get("level"), 2, "blacksmith stores level 2")
	_assert_false(manager.can_upgrade_entity(1), "blacksmith level 3 is locked before city hall level 3")

	manager.gold = 140
	_assert_true(manager.upgrade_building(0), "city hall level 3 unlocks iron-era blacksmith upgrade")
	_assert_false(manager.can_upgrade_entity(1), "blacksmith level 3 still needs an iron mine after city hall reaches level 3")
	_assert_false(manager.upgrade_building(1), "blacksmith level 3 upgrade fails without an iron mine")
	_assert_equal(manager.placed_buildings[1].get("level"), 2, "blacksmith stays level 2 without an iron mine")

	_track_building(manager, buildings_container, "iron_mine_1", "iron_mine", Vector2(6000, 472), Vector2(240, 180), 1)
	_assert_true(manager.can_upgrade_entity(1), "blacksmith can upgrade after city hall reaches level 3 and an iron mine exists")
	_assert_true(manager.upgrade_building(1), "blacksmith upgrades to level 3")
	_assert_equal(manager.gold, 0, "city hall level 3 and blacksmith level 3 spend 140 gold")
	_assert_equal(manager.placed_buildings[1].get("level"), 3, "blacksmith stores level 3")

	setup.root.free()


func _test_info_panel_level_text(build_manager_script) -> void:
	var setup := _create_manager_with_city_hall(build_manager_script)
	var manager = setup.manager

	manager.gold = 50
	_assert_true(manager.upgrade_building(0), "city hall upgrades for info panel test")
	manager._show_building_info_panel(0)
	_assert_true(_panel_has_text(manager.info_panel, "等级: 2"), "info panel shows the upgraded level")

	setup.root.free()


func _test_info_panel_keyboard_upgrade_and_close(build_manager_script) -> void:
	var setup := _create_manager_with_city_hall(build_manager_script)
	var manager = setup.manager

	manager.gold = 50
	manager._show_building_info_panel(0)
	_assert_true(manager.info_panel != null, "info panel opens before shortcut test")
	_assert_true(manager._handle_info_panel_input(KEY_E), "E is handled while building panel is open")
	_assert_equal(manager.placed_buildings[0].get("level"), 2, "E upgrades the open building panel target")
	_assert_equal(manager.gold, 0, "E upgrade spends the upgrade cost")
	_assert_true(manager.info_panel != null, "E upgrade keeps the building panel open")
	_assert_true(manager._handle_info_panel_input(KEY_Q), "Q is handled while building panel is open")
	_assert_equal(manager.info_panel, null, "Q closes the building panel")

	setup.root.free()


func _create_manager_with_city_hall(build_manager_script) -> Dictionary:
	var root := Node2D.new()
	var buildings_container := Node2D.new()
	buildings_container.name = "Buildings"
	root.add_child(buildings_container)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.buildings_container = buildings_container

	var city_hall := Node2D.new()
	city_hall.name = "CityHall"
	city_hall.global_position = Vector2(4800, 472)
	root.add_child(city_hall)
	manager._track_placed_entity(
		city_hall,
		Rect2(Vector2(4600, 138), Vector2(400, 334)),
		false,
		"City Hall",
		"cityhall",
		false,
		"cityhall"
	)

	return {
		"root": root,
		"manager": manager,
		"buildings_container": buildings_container,
	}


func _track_building(
	manager: Node2D,
	buildings_container: Node2D,
	node_name: String,
	building_id: String,
	position: Vector2,
	size: Vector2,
	level: int
) -> Node2D:
	var building := Node2D.new()
	building.name = node_name
	building.global_position = position
	buildings_container.add_child(building)
	manager._track_placed_entity(
		building,
		Rect2(position - Vector2(size.x * 0.5, size.y), size),
		true,
		building_id.capitalize(),
		"building",
		true,
		building_id
	)
	var entity_index: int = int(manager.placed_buildings.size()) - 1
	var entity: Dictionary = manager.placed_buildings[entity_index]
	entity.level = level
	manager.placed_buildings[entity_index] = entity
	return building


func _panel_has_text(node: Node, needle: String) -> bool:
	if node == null:
		return false
	if node is Label and (node as Label).text.find(needle) != -1:
		return true

	for child in node.get_children():
		if _panel_has_text(child, needle):
			return true

	return false


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
