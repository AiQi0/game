extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if build_manager_script != null:
		var root := Node2D.new()
		var buildings_container := Node2D.new()
		buildings_container.name = "Buildings"
		root.add_child(buildings_container)

		var manager: Node2D = build_manager_script.new()
		manager.name = "BuildManager"
		root.add_child(manager)
		manager.buildings_container = buildings_container
		manager.gold = 20
		var player := CharacterBody2D.new()
		player.name = "Player"
		player.global_position = Vector2(3000, 400)
		root.add_child(player)
		manager.player = player

		var blacksmith := Node2D.new()
		blacksmith.name = "blacksmith_1"
		blacksmith.global_position = Vector2(3000, 472)
		buildings_container.add_child(blacksmith)
		manager._track_placed_entity(
			blacksmith,
			Rect2(Vector2(2910, 332), Vector2(180, 140)),
			true,
			"铁匠铺",
			"building",
			true,
			"blacksmith"
		)

		_assert_true(manager.has_method("_show_building_info_panel"), "BuildManager shows building info panels")
		_assert_true(manager.has_method("start_blacksmith_craft"), "BuildManager starts blacksmith tool crafting")
		_assert_true(manager.has_method("_update_blacksmith_crafting"), "BuildManager advances blacksmith crafting")
		_assert_true(manager.has_method("tool_count_for_building"), "BuildManager counts stored tools per building")
		_assert_true(manager.has_method("try_take_tool_for_role"), "BuildManager lets workers take matching tools")

		if manager.has_method("_show_building_info_panel"):
			manager._show_building_info_panel(0)
			_assert_true(manager.info_panel != null, "building info panel is created")
			_assert_equal(manager.info_panel.global_position, blacksmith.global_position + Vector2(80, -300), "building info panel is shifted left by two hundred pixels")
			_assert_true(_panel_has_text(manager.info_panel, "名字"), "panel shows building name field")
			_assert_true(_panel_has_text(manager.info_panel, "等级"), "panel shows level field")
			_assert_true(_panel_has_text(manager.info_panel, "人员"), "panel shows worker field")
			_assert_true(_panel_has_text(manager.info_panel, "功能"), "panel shows function field")
			_assert_true(_panel_has_text(manager.info_panel, "数值"), "panel shows values field")
			_assert_true(_panel_has_text(manager.info_panel, "制造"), "blacksmith panel shows crafting actions")

			player.global_position = Vector2(3200, 400)
			manager._process(0.0)
			_assert_equal(manager.info_panel, null, "building info panel closes when player leaves building footprint")
			player.global_position = Vector2(3000, 400)

		if manager.has_method("start_blacksmith_craft") and manager.has_method("_update_blacksmith_crafting"):
			_assert_true(manager.start_blacksmith_craft(0, "axe"), "blacksmith starts crafting an axe")
			_assert_equal(manager.gold, 17, "crafting costs three gold")
			manager._update_blacksmith_crafting(29.0)
			_assert_equal(manager.tool_count_for_building("blacksmith_1"), 0, "tool is not stored before thirty seconds")
			manager._update_blacksmith_crafting(1.0)
			_assert_equal(manager.tool_count_for_building("blacksmith_1"), 1, "tool is stored after thirty seconds")
			_assert_equal(_tool_count(buildings_container, "axe"), 1, "crafted axe is placed in front of blacksmith")

			manager.gold = 100
			for _i in range(4):
				_assert_true(manager.start_blacksmith_craft(0, "sword"), "blacksmith fills storage")
				manager._update_blacksmith_crafting(30.0)
			_assert_equal(manager.tool_count_for_building("blacksmith_1"), 5, "blacksmith storage caps at five tools")
			_assert_false(manager.start_blacksmith_craft(0, "sickle"), "blacksmith cannot craft past total storage limit")

			_assert_equal(manager.try_take_tool_for_role("lumberjack"), "axe", "lumberjack takes an axe")
			_assert_equal(manager.tool_count_for_building("blacksmith_1"), 4, "taking a tool frees one storage slot")

		root.free()

	if failures == 0:
		print("BuildingInfoAndToolCraftTest: PASS")
	else:
		push_error("BuildingInfoAndToolCraftTest: %d failure(s)" % failures)

	quit(failures)


func _panel_has_text(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.find(needle) != -1:
		return true

	for child in node.get_children():
		if _panel_has_text(child, needle):
			return true

	return false


func _tool_count(container: Node, tool_id: String) -> int:
	var count := 0
	for child in container.get_children():
		if child.get_meta("tool_id", "") == tool_id:
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
