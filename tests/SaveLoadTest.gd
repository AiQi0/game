extends SceneTree

const GameData = preload("res://scripts/GameData.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var save_manager_script := load("res://scripts/SaveGameManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if save_manager_script == null:
		_fail("SaveGameManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")

	if build_manager_script != null and save_manager_script != null:
		_test_apply_save_snapshot(build_manager_script, save_manager_script)
		_test_save_and_load_buildings_and_levels(build_manager_script, save_manager_script)
		_test_load_last_save_applies_snapshot(build_manager_script, save_manager_script)
		_test_escape_pause_menu_save_and_load(build_manager_script, save_manager_script)
		_test_return_to_main_menu_saves_manual(build_manager_script, save_manager_script)
	if build_manager_script != null and save_manager_script != null and npc_manager_script != null:
		_test_save_load_runtime_resources_npcs_and_quarry(build_manager_script, save_manager_script, npc_manager_script)

	if failures == 0:
		print("SaveLoadTest: PASS")
	else:
		push_error("SaveLoadTest: %d failure(s)" % failures)

	quit(failures)


func _test_apply_save_snapshot(build_manager_script: Script, save_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "apply_snapshot")
	var manager: Node2D = setup.manager

	var save_data := {
		"scene_path": "res://scenes/Main.tscn",
		"snapshot": {
			"gold": 135,
			"player_dead": false,
			"player_position": [3210.0, 472.0],
			"city_terrain": "mountain",
			"city_player_controlled": true,
			"horse_count": 2,
		},
	}
	_assert_true(manager.has_method("apply_save_data"), "BuildManager exposes save data application")
	if manager.has_method("apply_save_data"):
		_assert_true(manager.apply_save_data(save_data), "save snapshot applies")
	_assert_equal(manager.gold, 135, "save load restores gold")
	_assert_equal(setup.player.global_position, Vector2(3210, 472), "save load restores player position")
	_assert_equal(manager.get("city_terrain"), "mountain", "save load restores city terrain")
	_assert_true(manager.get("city_player_controlled"), "save load restores city ownership")
	_assert_equal(manager.get("horse_count"), 2, "save load restores horse count")

	_cleanup_save_root(setup.save_manager.save_root_path)
	setup.root.free()


func _test_save_and_load_buildings_and_levels(build_manager_script: Script, save_manager_script: Script) -> void:
	var source := _create_world(build_manager_script, save_manager_script, "buildings_source")
	var source_manager: Node2D = source.manager
	var source_save_manager = source.save_manager
	_track_building(source_manager, source.buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 2, false, "cityhall")
	_track_building(source_manager, source.buildings, "blacksmith_saved", "blacksmith", Vector2(4300, 472), Vector2(180, 140), 2)
	_track_building(source_manager, source.buildings, "wall_saved", "wall", Vector2(4550, 472), Vector2(120, 100), 1)

	_assert_true(source_manager.autosave_game("manual"), "manual save with buildings succeeds")
	var save_data: Dictionary = source_save_manager.read_last_save()
	var snapshot: Dictionary = save_data.get("snapshot", {})
	var saved_buildings: Array = snapshot.get("buildings", [])
	_assert_equal(saved_buildings.size(), 3, "snapshot stores cityhall and player buildings")
	_assert_equal(_saved_level_for(saved_buildings, "cityhall"), 2, "snapshot stores cityhall level")
	_assert_equal(_saved_level_for(saved_buildings, "blacksmith"), 2, "snapshot stores blacksmith level")

	var target := _create_world(build_manager_script, save_manager_script, "buildings_target")
	var target_manager: Node2D = target.manager
	_track_building(target_manager, target.buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 1, false, "cityhall")

	_assert_true(target_manager.apply_save_data(save_data), "save snapshot with buildings applies")
	_assert_equal(target_manager.building_level_for_id("cityhall"), 2, "load restores cityhall level")
	_assert_equal(target_manager.building_level_for_id("blacksmith"), 2, "load restores blacksmith level")
	_assert_equal(target_manager.building_level_for_id("wall"), 1, "load restores wall building")
	var blacksmith_entity := _entity_for_building_id(target_manager, "blacksmith")
	_assert_true(not blacksmith_entity.is_empty(), "load recreates blacksmith entity")
	if not blacksmith_entity.is_empty():
		var blacksmith_node: Node2D = blacksmith_entity.get("node")
		_assert_true(is_instance_valid(blacksmith_node), "load recreates blacksmith node")
		if is_instance_valid(blacksmith_node):
			_assert_equal(blacksmith_node.global_position, Vector2(4300, 472), "load restores blacksmith position")

	_cleanup_save_root(source_save_manager.save_root_path)
	source.root.free()
	_cleanup_save_root(target.save_manager.save_root_path)
	target.root.free()


func _test_load_last_save_applies_snapshot(build_manager_script: Script, save_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "load_last")
	var manager: Node2D = setup.manager
	var save_manager = setup.save_manager
	_assert_true(
		save_manager.record_autosave(
			"res://scenes/Main.tscn",
			{
				"gold": 82,
				"player_dead": false,
				"player_position": [5100.0, 472.0],
				"city_terrain": "",
				"city_player_controlled": true,
				"horse_count": 1,
			},
			"manual"
		),
		"test last save can be recorded"
	)

	manager.gold = 1
	_assert_true(manager.has_method("load_last_save"), "BuildManager exposes last save loading")
	if manager.has_method("load_last_save"):
		_assert_true(manager.load_last_save(), "last save loads")
	_assert_equal(manager.gold, 82, "last save load restores gold")
	_assert_equal(setup.player.global_position, Vector2(5100, 472), "last save load restores player position")

	_cleanup_save_root(save_manager.save_root_path)
	setup.root.free()


func _test_escape_pause_menu_save_and_load(build_manager_script: Script, save_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "pause_menu", true)
	var manager: Node2D = setup.manager
	var save_manager = setup.save_manager
	manager._create_ui()

	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true

	_assert_equal(manager.process_mode, Node.PROCESS_MODE_ALWAYS, "build manager keeps receiving escape while paused")
	manager._unhandled_input(event)

	_assert_true(manager.get_tree().paused, "escape pauses the game")
	_assert_true(manager.get("pause_panel") != null, "escape opens pause panel")
	manager._unhandled_input(event)
	_assert_false(manager.get_tree().paused, "second escape resumes the game")
	_assert_true(manager.get("pause_panel") == null, "second escape closes pause panel")
	manager._unhandled_input(event)
	_assert_true(manager.get_tree().paused, "escape can pause again after resume")
	_assert_true(_find_button(manager, "ResumeButton") != null, "pause menu has resume button")
	_assert_true(_find_button(manager, "LoadButton") != null, "pause menu has load button")
	_assert_true(_find_button(manager, "SaveButton") != null, "pause menu has save button")
	_assert_true(_find_button(manager, "PauseMainMenuButton") != null, "pause menu has main menu button")
	var main_menu_button := _find_button(manager, "PauseMainMenuButton")
	if main_menu_button != null:
		_assert_equal(main_menu_button.text, "保存并退出", "pause main menu button is save and exit")

	manager.gold = 44
	var save_button := _find_button(manager, "SaveButton")
	if save_button != null:
		save_button.emit_signal("pressed")
	var save_data: Dictionary = save_manager.read_last_save()
	_assert_equal(save_data.get("autosave_reason", ""), "manual", "pause save writes manual autosave")
	_assert_equal(save_data.get("snapshot", {}).get("gold", -1), 44, "pause save stores current gold")

	_assert_true(
		save_manager.record_autosave(
			"res://scenes/Main.tscn",
			{
				"gold": 73,
				"player_dead": false,
				"player_position": [6200.0, 472.0],
				"city_terrain": "",
				"city_player_controlled": true,
				"horse_count": 0,
			},
			"manual"
		),
		"test save can be replaced before pause load"
	)
	var load_button := _find_button(manager, "LoadButton")
	if load_button != null:
		load_button.emit_signal("pressed")
	_assert_false(manager.get_tree().paused, "pause load resumes the game")
	_assert_true(manager.get("pause_panel") == null, "pause load closes pause panel")
	_assert_equal(manager.gold, 73, "pause load restores saved gold")
	_assert_equal(setup.player.global_position, Vector2(6200, 472), "pause load restores saved position")

	_cleanup_save_root(save_manager.save_root_path)
	if manager.is_inside_tree():
		manager.get_tree().paused = false
	current_scene = null
	if setup.root.get_parent() != null:
		setup.root.get_parent().remove_child(setup.root)
	setup.root.free()


func _test_return_to_main_menu_saves_manual(build_manager_script: Script, save_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "save_exit")
	var manager: Node2D = setup.manager
	var save_manager = setup.save_manager

	manager.gold = 58
	manager._return_to_main_menu()
	_assert_true(save_manager.has_last_save(), "save and exit writes last save")
	var save_data: Dictionary = save_manager.read_last_save()
	_assert_equal(save_data.get("autosave_reason", ""), "manual", "save and exit records manual reason")
	_assert_equal(save_data.get("snapshot", {}).get("gold", -1), 58, "save and exit stores current gold")

	_cleanup_save_root(save_manager.save_root_path)
	setup.root.free()


func _test_save_load_runtime_resources_npcs_and_quarry(
	build_manager_script: Script,
	save_manager_script: Script,
	npc_manager_script: Script
) -> void:
	var source := _create_full_world(build_manager_script, save_manager_script, npc_manager_script, "runtime_state_source")
	var source_manager: Node2D = source.manager
	var source_save_manager = source.save_manager
	_assert_equal(_entity_count_for_kind(source_manager, "tree"), GameData.TREE_COUNT, "source world starts with default trees")

	var tree_index := _entity_index_for_kind(source_manager, "tree")
	_assert_true(tree_index != -1, "source has a tree to chop")
	var chopped_tree_name := _node_name_for_entity(source_manager.placed_buildings[tree_index]) if tree_index != -1 else ""
	if tree_index != -1:
		source_manager._start_tree_chop_task(tree_index)
		_assert_true(source_manager.advance_tree_chop(chopped_tree_name, 1.0, 1.0), "test tree chop completes")
	_assert_equal(_entity_count_for_kind(source_manager, "tree"), GameData.TREE_COUNT - 1, "source tree count drops after chop")

	_set_cityhall_level(source_manager, 2)
	var stone_index := _entity_index_for_kind(source_manager, "stone")
	_assert_true(stone_index != -1, "source has a stone for quarry")
	var source_game_data = GameData.new()
	var source_stone_name := _node_name_for_entity(source_manager.placed_buildings[stone_index]) if stone_index != -1 else ""
	if stone_index != -1:
		source_manager.gold = 99
		source_manager._build_quarry_on_stone(stone_index, source_game_data.quarry_definition())
	var quarry_entity := _entity_for_building_id(source_manager, "quarry")
	_assert_true(not quarry_entity.is_empty(), "source quarry exists before save")
	var quarry_name := _node_name_for_entity(quarry_entity)
	var source_stone_entity := _entity_for_node_name(source_manager, source_stone_name)
	_assert_true(bool(source_stone_entity.get("has_quarry", false)), "source stone records quarry occupation")

	var source_npc: Node2D = source.npcs.get_node_or_null("Villager_01")
	_assert_true(source_npc != null, "source has starting villager")
	if source_npc != null:
		source_npc.global_position = Vector2(3666.0, GameData.GROUND_TOP_Y)
		source_npc.become_miner()
		source_npc.equip_tool("stone_pickaxe")
		source_npc.set_workplace(Vector2(4200.0, GameData.GROUND_TOP_Y), "采石场", quarry_name)

	_assert_true(source_manager.autosave_game("manual"), "manual save with runtime world state succeeds")
	var save_data: Dictionary = source_save_manager.read_last_save()

	var target := _create_full_world(build_manager_script, save_manager_script, npc_manager_script, "runtime_state_target")
	var target_manager: Node2D = target.manager
	_assert_true(target_manager.apply_save_data(save_data), "runtime world snapshot applies")

	_assert_equal(_entity_count_for_kind(target_manager, "tree"), GameData.TREE_COUNT - 1, "load keeps chopped tree removed")
	_assert_true(_entity_for_node_name(target_manager, chopped_tree_name).is_empty(), "load does not recreate chopped tree node")
	var loaded_quarry := _entity_for_building_id(target_manager, "quarry")
	_assert_true(not loaded_quarry.is_empty(), "load restores quarry building")
	if not loaded_quarry.is_empty():
		_assert_equal(_node_name_for_entity(loaded_quarry), quarry_name, "load restores quarry node name")
	var loaded_stone := _entity_for_node_name(target_manager, source_stone_name)
	_assert_true(not loaded_stone.is_empty(), "load restores source stone")
	if not loaded_stone.is_empty():
		_assert_true(bool(loaded_stone.get("has_quarry", false)), "load keeps source stone occupied by quarry")
		_assert_equal(str(loaded_stone.get("quarry_node_name", "")), quarry_name, "load keeps source stone quarry link")
		var stone_node: Node2D = loaded_stone.get("node")
		if is_instance_valid(stone_node):
			_assert_false(stone_node.visible, "load keeps occupied source stone hidden")

	var loaded_npc: Node2D = target.npcs.get_node_or_null("Villager_01")
	_assert_true(loaded_npc != null, "load restores saved villager")
	if loaded_npc != null:
		_assert_equal(loaded_npc.global_position, Vector2(3666.0, GameData.GROUND_TOP_Y), "load restores NPC position")
		_assert_equal(str(loaded_npc.get("worker_role")), "miner", "load restores NPC worker role")
		_assert_equal(str(loaded_npc.get("carried_tool")), "stone_pickaxe", "load restores NPC carried tool")
		_assert_equal(str(loaded_npc.get("assigned_workplace_id")), quarry_name, "load restores NPC workplace")

	_cleanup_save_root(source_save_manager.save_root_path)
	if source.root.get_parent() != null:
		source.root.get_parent().remove_child(source.root)
	source.root.free()
	_cleanup_save_root(target.save_manager.save_root_path)
	if target.root.get_parent() != null:
		target.root.get_parent().remove_child(target.root)
	target.root.free()
	current_scene = null


func _create_world(build_manager_script: Script, save_manager_script: Script, label: String, add_to_tree := false) -> Dictionary:
	var root := Node2D.new()
	root.name = "SaveLoadRoot"
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(4800, 472)
	root.add_child(player)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.player = player
	manager.buildings_container = buildings

	var save_manager = save_manager_script.new()
	save_manager.save_root_path = _test_save_root(label)
	_cleanup_save_root(save_manager.save_root_path)
	manager.set("save_manager", save_manager)

	if add_to_tree:
		get_root().add_child(root)
		current_scene = root

	return {
		"root": root,
		"player": player,
		"buildings": buildings,
		"manager": manager,
		"save_manager": save_manager,
	}


func _create_full_world(build_manager_script: Script, save_manager_script: Script, npc_manager_script: Script, label: String) -> Dictionary:
	var root := Node2D.new()
	root.name = "SaveLoadFullRoot"
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(4800, GameData.GROUND_TOP_Y)
	root.add_child(player)

	var cityhall := Node2D.new()
	cityhall.name = "CityHall"
	cityhall.global_position = GameData.CITY_HALL_FRONT
	root.add_child(cityhall)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var npcs := Node2D.new()
	npcs.name = "NPCs"
	root.add_child(npcs)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	var save_manager = save_manager_script.new()
	save_manager.save_root_path = _test_save_root(label)
	_cleanup_save_root(save_manager.save_root_path)
	manager.set("save_manager", save_manager)
	root.add_child(manager)

	var npc_manager: Node2D = npc_manager_script.new()
	npc_manager.name = "NPCManager"
	root.add_child(npc_manager)

	get_root().add_child(root)
	current_scene = root

	return {
		"root": root,
		"player": player,
		"cityhall": cityhall,
		"buildings": buildings,
		"npcs": npcs,
		"manager": manager,
		"npc_manager": npc_manager,
		"save_manager": save_manager,
	}


func _track_building(
	manager: Node2D,
	buildings: Node2D,
	node_name: String,
	building_id: String,
	position: Vector2,
	size: Vector2,
	level: int,
	is_workplace := true,
	entity_kind := "building"
) -> Node2D:
	var building := Node2D.new()
	building.name = node_name
	building.global_position = position
	buildings.add_child(building)
	manager._track_placed_entity(
		building,
		Rect2(Vector2(position.x - size.x * 0.5, position.y - size.y), size),
		true,
		building_id,
		entity_kind,
		is_workplace,
		building_id
	)
	var index: int = manager.placed_buildings.size() - 1
	var entity: Dictionary = manager.placed_buildings[index]
	entity.level = level
	entity.demolishable = entity_kind != "cityhall"
	manager.placed_buildings[index] = entity
	return building


func _saved_level_for(saved_buildings: Array, building_id: String) -> int:
	for building in saved_buildings:
		if building is Dictionary and building.get("building_id", "") == building_id:
			return int(building.get("level", 0))
	return 0


func _entity_for_building_id(manager: Node2D, building_id: String) -> Dictionary:
	for entity in manager.placed_buildings:
		if entity.get("building_id", "") == building_id:
			return entity
	return {}


func _entity_index_for_kind(manager: Node2D, entity_kind: String) -> int:
	for i in range(manager.placed_buildings.size()):
		var entity: Dictionary = manager.placed_buildings[i]
		if str(entity.get("entity_kind", "")) == entity_kind:
			return i
	return -1


func _entity_count_for_kind(manager: Node2D, entity_kind: String) -> int:
	var count := 0
	for entity in manager.placed_buildings:
		if str(entity.get("entity_kind", "")) == entity_kind:
			count += 1
	return count


func _entity_for_node_name(manager: Node2D, node_name: String) -> Dictionary:
	for entity in manager.placed_buildings:
		if _node_name_for_entity(entity) == node_name:
			return entity
	return {}


func _node_name_for_entity(entity: Dictionary) -> String:
	var node: Node2D = entity.get("node")
	if is_instance_valid(node):
		return node.name
	return ""


func _set_cityhall_level(manager: Node2D, level: int) -> void:
	for i in range(manager.placed_buildings.size()):
		var entity: Dictionary = manager.placed_buildings[i]
		if entity.get("building_id", "") != "cityhall":
			continue
		entity.level = level
		manager.placed_buildings[i] = entity
		return


func _find_button(node: Node, button_name: String) -> Button:
	if node == null:
		return null
	if node is Button and node.name == button_name:
		return node as Button
	for child in node.get_children():
		var button := _find_button(child, button_name)
		if button != null:
			return button
	return null


func _test_save_root(label: String) -> String:
	return "user://save_load_test_%s_%d" % [label, Time.get_ticks_usec()]


func _cleanup_save_root(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				DirAccess.remove_absolute("%s/%s" % [path, file_name])
			file_name = dir.get_next()
		dir.list_dir_end()
	DirAccess.remove_absolute(path)


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
