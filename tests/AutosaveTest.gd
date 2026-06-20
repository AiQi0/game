extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var save_manager_script := load("res://scripts/SaveGameManager.gd")
	var game_data_script := load("res://scripts/GameData.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if save_manager_script == null:
		_fail("SaveGameManager.gd should load")
	if game_data_script == null:
		_fail("GameData.gd should load")

	if build_manager_script != null and save_manager_script != null and game_data_script != null:
		_test_autosave_interval(build_manager_script, save_manager_script, game_data_script.new())
		_test_death_autosaves_immediately(build_manager_script, save_manager_script)
		_test_quit_autosaves_immediately(build_manager_script, save_manager_script)

	if failures == 0:
		print("AutosaveTest: PASS")
	else:
		push_error("AutosaveTest: %d failure(s)" % failures)

	quit(failures)


func _test_autosave_interval(build_manager_script: Script, save_manager_script: Script, game_data) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "interval")
	var manager: Node2D = setup.manager
	var save_manager = setup.save_manager

	_assert_equal(game_data.world_value("autosave_seconds"), 60.0, "autosave interval is data-driven")
	manager.gold = 88
	manager._process(59.0)
	_assert_false(save_manager.has_last_save(), "autosave does not run before one minute")
	manager._process(1.0)
	_assert_true(save_manager.has_last_save(), "autosave runs after one minute")

	var save_data: Dictionary = save_manager.read_last_save()
	_assert_equal(save_data.get("slot_id", ""), "autosave", "autosave overwrites the autosave slot")
	_assert_equal(save_data.get("autosave_reason", ""), "interval", "interval autosave records reason")
	var snapshot: Dictionary = save_data.get("snapshot", {})
	_assert_equal(snapshot.get("gold", -1), 88, "autosave snapshot stores current gold")
	_assert_equal(snapshot.get("player_position", []), [4800.0, 472.0], "autosave snapshot stores player position")

	manager.gold = 77
	manager._process(60.0)
	save_data = save_manager.read_last_save()
	snapshot = save_data.get("snapshot", {})
	_assert_equal(snapshot.get("gold", -1), 77, "next autosave overwrites original save")

	_cleanup_save_root(save_manager.save_root_path)
	setup.root.free()


func _test_death_autosaves_immediately(build_manager_script: Script, save_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "death")
	var manager: Node2D = setup.manager
	var save_manager = setup.save_manager

	manager.gold = 40
	var result: Dictionary = manager.apply_player_monster_hit()
	_assert_true(result.get("died", false), "player death can be triggered by monster hit")
	_assert_true(save_manager.has_last_save(), "death immediately writes autosave")

	var save_data: Dictionary = save_manager.read_last_save()
	_assert_equal(save_data.get("autosave_reason", ""), "death", "death autosave records reason")
	var snapshot: Dictionary = save_data.get("snapshot", {})
	_assert_equal(snapshot.get("gold", -1), 0, "death autosave stores post-death gold")
	_assert_equal(snapshot.get("player_dead", false), true, "death autosave stores player_dead")

	_cleanup_save_root(save_manager.save_root_path)
	setup.root.free()


func _test_quit_autosaves_immediately(build_manager_script: Script, save_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script, save_manager_script, "quit")
	var manager: Node2D = setup.manager
	var save_manager = setup.save_manager

	manager.gold = 66
	manager._quit_game()
	_assert_true(save_manager.has_last_save(), "quit immediately writes autosave")

	var save_data: Dictionary = save_manager.read_last_save()
	_assert_equal(save_data.get("autosave_reason", ""), "quit", "quit autosave records reason")
	var snapshot: Dictionary = save_data.get("snapshot", {})
	_assert_equal(snapshot.get("gold", -1), 66, "quit autosave stores current gold")

	_cleanup_save_root(save_manager.save_root_path)
	setup.root.free()


func _create_world(build_manager_script: Script, save_manager_script: Script, label: String) -> Dictionary:
	var root := Node2D.new()
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
	if manager.get("save_manager") == null:
		_fail("BuildManager exposes save_manager for autosave routing")
	else:
		manager.set("save_manager", save_manager)

	return {
		"root": root,
		"manager": manager,
		"save_manager": save_manager,
	}


func _test_save_root(label: String) -> String:
	return "user://autosave_test_%s_%d" % [label, Time.get_ticks_usec()]


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
