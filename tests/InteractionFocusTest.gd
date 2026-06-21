extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	var npc_factory_script := load("res://scripts/NPCFactory.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")
	if npc_factory_script == null:
		_fail("NPCFactory.gd should load")

	if build_manager_script != null and npc_manager_script != null and npc_factory_script != null:
		_test_interaction_focus_defaults_to_homeless(build_manager_script, npc_manager_script, npc_factory_script.new())
		_test_tab_cycles_to_resource_build(build_manager_script, npc_manager_script, npc_factory_script.new())
		_test_mouse_wheel_cycles_interactions(build_manager_script, npc_manager_script, npc_factory_script.new())
		_test_selected_build_slot_blocks_other_e_interactions(build_manager_script, npc_manager_script, npc_factory_script.new())

	if failures == 0:
		print("InteractionFocusTest: PASS")
	else:
		push_error("InteractionFocusTest: %d failure(s)" % failures)

	quit(failures)


func _test_interaction_focus_defaults_to_homeless(build_manager_script: Script, npc_manager_script: Script, factory) -> void:
	var setup := _create_conflict_world(build_manager_script, npc_manager_script, factory)
	var manager: Node2D = setup.build_manager
	var homeless: Node2D = setup.homeless
	if not _require_interaction_focus_api(manager):
		setup.root.free()
		return

	var candidates: Array = manager._interaction_candidates()
	_assert_equal(candidates.size(), 2, "stone plus homeless creates two E interaction candidates")
	_assert_equal(candidates[0].get("id", ""), "recruit_homeless", "homeless recruitment is the default focused interaction")

	_assert_true(manager._execute_focused_interaction(), "E executes focused interaction")
	_assert_equal(str(homeless.get("npc_type")), "villager", "default E recruits homeless")
	_assert_equal(_building_count(manager, "quarry"), 0, "default E does not also build quarry")

	setup.root.free()


func _test_tab_cycles_to_resource_build(build_manager_script: Script, npc_manager_script: Script, factory) -> void:
	var setup := _create_conflict_world(build_manager_script, npc_manager_script, factory)
	var manager: Node2D = setup.build_manager
	var homeless: Node2D = setup.homeless
	if not _require_interaction_focus_api(manager):
		setup.root.free()
		return

	manager._unhandled_input(_key_event(KEY_TAB))
	_assert_equal(manager._focused_interaction_candidate().get("id", ""), "build_quarry", "Tab focuses quarry build")

	manager._unhandled_input(_key_event(KEY_E))
	_assert_equal(_building_count(manager, "quarry"), 1, "cycled E builds quarry")
	_assert_equal(str(homeless.get("npc_type")), "homeless", "cycled E does not recruit homeless")

	setup.root.free()


func _test_mouse_wheel_cycles_interactions(build_manager_script: Script, npc_manager_script: Script, factory) -> void:
	var setup := _create_conflict_world(build_manager_script, npc_manager_script, factory)
	var manager: Node2D = setup.build_manager
	if not _require_interaction_focus_api(manager):
		setup.root.free()
		return

	manager._unhandled_input(_mouse_event(MOUSE_BUTTON_WHEEL_DOWN))
	_assert_equal(manager._focused_interaction_candidate().get("id", ""), "build_quarry", "mouse wheel down focuses next interaction")
	manager._unhandled_input(_mouse_event(MOUSE_BUTTON_WHEEL_UP))
	_assert_equal(manager._focused_interaction_candidate().get("id", ""), "recruit_homeless", "mouse wheel up focuses previous interaction")

	setup.root.free()


func _test_selected_build_slot_blocks_other_e_interactions(build_manager_script: Script, npc_manager_script: Script, factory) -> void:
	var setup := _create_conflict_world(build_manager_script, npc_manager_script, factory)
	var manager: Node2D = setup.build_manager
	var homeless: Node2D = setup.homeless
	if not _require_interaction_focus_api(manager):
		setup.root.free()
		return

	manager._refresh_building_choices()
	manager._unhandled_input(_key_event(KEY_1))
	_assert_true(manager.selected_index != -1, "number key selects a build bar slot")
	var selected_candidates: Array = manager._interaction_candidates()
	_assert_equal(selected_candidates.size(), 1, "selected build slot hides non-build E interactions")
	_assert_equal(selected_candidates[0].get("id", ""), "build_selected", "selected build slot keeps only build interaction")
	_assert_true(not str(manager.status_label.text).contains("采石场"), "selected build slot hides resource interaction prompt")
	_assert_true(not str(manager.status_label.text).contains("招募"), "selected build slot hides homeless interaction prompt")

	manager._unhandled_input(_key_event(KEY_E))
	_assert_equal(str(homeless.get("npc_type")), "homeless", "E with selected build slot does not recruit homeless")
	_assert_equal(_building_count(manager, "quarry"), 0, "E with selected build slot does not build resource building")

	manager._unhandled_input(_key_event(KEY_1))
	_assert_equal(manager.selected_index, -1, "pressing selected number again cancels build slot selection")
	var restored_candidates: Array = manager._interaction_candidates()
	var restored_ids := _candidate_ids(restored_candidates)
	_assert_true(restored_ids.has("recruit_homeless"), "canceling build selection restores homeless interaction")
	_assert_true(restored_ids.has("build_quarry"), "canceling build selection restores resource build interaction")

	setup.root.free()


func _create_conflict_world(build_manager_script: Script, npc_manager_script: Script, factory) -> Dictionary:
	var root := Node2D.new()

	var city_hall := Node2D.new()
	city_hall.name = "CityHall"
	city_hall.global_position = Vector2(4800, 472)
	root.add_child(city_hall)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var npcs := Node2D.new()
	npcs.name = "NPCs"
	root.add_child(npcs)

	var player := CharacterBody2D.new()
	player.name = "Player"
	root.add_child(player)

	var status_label := Label.new()
	status_label.name = "BuildStatus"
	root.add_child(status_label)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	root.add_child(build_manager)
	build_manager.player = player
	build_manager.buildings_container = buildings
	build_manager.status_label = status_label
	build_manager.gold = 20
	build_manager.selected_index = -1
	build_manager._seed_existing_buildings()
	_set_building_level(build_manager, "cityhall", 2)

	var npc_manager: Node2D = npc_manager_script.new()
	npc_manager.name = "NPCManager"
	root.add_child(npc_manager)
	npc_manager.player = player
	npc_manager.npc_container = npcs

	var stone: Node2D = build_manager._spawn_stone_at(Vector2(4300, 472))
	player.global_position = stone.global_position
	var homeless: Node2D = factory.create_homeless(player.global_position + Vector2(16, 0), Vector2(4800, 472))
	homeless.name = "Homeless_Test"
	npcs.add_child(homeless)

	return {
		"root": root,
		"build_manager": build_manager,
		"npc_manager": npc_manager,
		"player": player,
		"stone": stone,
		"homeless": homeless,
	}


func _set_building_level(manager: Node2D, building_id: String, level: int) -> void:
	for i in range(manager.placed_buildings.size()):
		var entity: Dictionary = manager.placed_buildings[i]
		if entity.get("building_id", "") != building_id:
			continue
		entity.level = level
		manager.placed_buildings[i] = entity
		return


func _building_count(manager: Node2D, building_id: String) -> int:
	var count := 0
	for entity in manager.placed_buildings:
		if str(entity.get("building_id", "")) == building_id:
			count += 1
	return count


func _candidate_ids(candidates: Array) -> Array:
	var ids := []
	for candidate in candidates:
		if candidate is Dictionary:
			ids.append(str((candidate as Dictionary).get("id", "")))
	return ids


func _require_interaction_focus_api(manager: Node2D) -> bool:
	var ok := true
	for method_name in ["_interaction_candidates", "_focused_interaction_candidate", "_cycle_interaction_focus", "_execute_focused_interaction"]:
		if not manager.has_method(method_name):
			_fail("BuildManager should expose %s" % method_name)
			ok = false
	return ok


func _mouse_event(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	return event


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
