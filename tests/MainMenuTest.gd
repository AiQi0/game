extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager_script := load("res://scripts/SaveGameManager.gd")
	var main_menu_script := load("res://scripts/MainMenu.gd")
	var packed_scene: PackedScene = load("res://scenes/MainMenu.tscn")

	if save_manager_script == null:
		_fail("SaveGameManager.gd should load")
	if main_menu_script == null:
		_fail("MainMenu.gd should load")
	if packed_scene == null:
		_fail("MainMenu.tscn should load")

	if save_manager_script != null:
		_test_save_manager_last_save(save_manager_script)
	if save_manager_script != null and main_menu_script != null and packed_scene != null:
		_test_main_menu_scene(save_manager_script, main_menu_script, packed_scene)
		_test_continue_button_visibility(save_manager_script, packed_scene)
		_test_continue_uses_last_save(save_manager_script, packed_scene)
		_test_menu_panels(save_manager_script, packed_scene)
		_test_save_list_entry_loads_save(save_manager_script, packed_scene)

	if failures == 0:
		print("MainMenuTest: PASS")
	else:
		push_error("MainMenuTest: %d failure(s)" % failures)

	quit(failures)


func _test_save_manager_last_save(save_manager_script: Script) -> void:
	var manager = save_manager_script.new()
	manager.save_root_path = _test_save_root("save_manager")
	_cleanup_save_root(manager.save_root_path)
	_assert_false(manager.has_last_save(), "new save root has no last save")
	_assert_equal(manager.list_saves().size(), 0, "new save root has no save list entries")

	_assert_true(manager.record_last_played_save("slot_001", "测试存档", "res://scenes/Main.tscn"), "save manager records last played save")
	_assert_true(manager.has_last_save(), "save manager detects last save")
	_assert_equal(manager.last_played_scene_path(), "res://scenes/Main.tscn", "last save points to main scene")
	_assert_equal(manager.list_saves().size(), 1, "save list includes recorded last save")
	_cleanup_save_root(manager.save_root_path)


func _test_main_menu_scene(save_manager_script: Script, main_menu_script: Script, packed_scene: PackedScene) -> void:
	var manager = save_manager_script.new()
	manager.save_root_path = _test_save_root("scene")
	_cleanup_save_root(manager.save_root_path)

	var scene: Control = packed_scene.instantiate()
	scene.save_manager = manager
	get_root().add_child(scene)

	_assert_equal(scene.name, "MainMenu", "main menu scene root name")
	_assert_true(scene.get_script() == main_menu_script, "main menu scene uses MainMenu script")
	_assert_button(scene, "MenuPanel/MenuButtons/ContinueButton", "继续")
	_assert_button(scene, "MenuPanel/MenuButtons/NewGameButton", "新游戏")
	_assert_button(scene, "MenuPanel/MenuButtons/SavesButton", "查看存档")
	_assert_button(scene, "MenuPanel/MenuButtons/SettingsButton", "设置")
	_assert_button(scene, "MenuPanel/MenuButtons/QuitButton", "退出游戏")

	scene.free()
	_cleanup_save_root(manager.save_root_path)


func _test_continue_button_visibility(save_manager_script: Script, packed_scene: PackedScene) -> void:
	var manager = save_manager_script.new()
	manager.save_root_path = _test_save_root("continue_visibility")
	_cleanup_save_root(manager.save_root_path)

	var no_save_scene: Control = packed_scene.instantiate()
	no_save_scene.save_manager = manager
	get_root().add_child(no_save_scene)
	var continue_button := no_save_scene.get_node("MenuPanel/MenuButtons/ContinueButton") as Button
	_assert_false(continue_button.visible, "continue button is hidden without saves")
	no_save_scene.free()

	_assert_true(manager.record_last_played_save("slot_001", "测试存档", "res://scenes/Main.tscn"), "test save can be recorded")
	var save_scene: Control = packed_scene.instantiate()
	save_scene.save_manager = manager
	get_root().add_child(save_scene)
	continue_button = save_scene.get_node("MenuPanel/MenuButtons/ContinueButton") as Button
	_assert_true(continue_button.visible, "continue button is visible with a last save")
	save_scene.free()
	_cleanup_save_root(manager.save_root_path)


func _test_continue_uses_last_save(save_manager_script: Script, packed_scene: PackedScene) -> void:
	var manager = save_manager_script.new()
	manager.save_root_path = _test_save_root("continue_route")
	_cleanup_save_root(manager.save_root_path)
	_assert_true(manager.record_last_played_save("slot_001", "测试存档", "res://scenes/Main.tscn"), "test save can be recorded for continue route")

	var scene: Control = packed_scene.instantiate()
	scene.save_manager = manager
	get_root().add_child(scene)
	_assert_true(scene.continue_game(), "continue button action is handled when save exists")
	_assert_equal(scene.last_requested_scene_path, "res://scenes/Main.tscn", "continue requests last played save scene")
	scene.free()
	_cleanup_save_root(manager.save_root_path)


func _test_menu_panels(save_manager_script: Script, packed_scene: PackedScene) -> void:
	var manager = save_manager_script.new()
	manager.save_root_path = _test_save_root("panels")
	_cleanup_save_root(manager.save_root_path)

	var scene: Control = packed_scene.instantiate()
	scene.save_manager = manager
	get_root().add_child(scene)

	_assert_false(scene.get_node("SaveListPanel").visible, "save list panel starts hidden")
	_assert_true(scene.show_save_list(), "save list button action is handled")
	_assert_true(scene.get_node("SaveListPanel").visible, "save list panel opens")
	_assert_true(scene.get_node("SettingsPanel") != null, "settings panel exists")
	_assert_true(scene.show_settings(), "settings button action is handled")
	_assert_true(scene.get_node("SettingsPanel").visible, "settings panel opens")

	scene.free()
	_cleanup_save_root(manager.save_root_path)


func _test_save_list_entry_loads_save(save_manager_script: Script, packed_scene: PackedScene) -> void:
	var manager = save_manager_script.new()
	manager.save_root_path = _test_save_root("save_list_entry")
	_cleanup_save_root(manager.save_root_path)
	_assert_true(
		manager.record_autosave("res://scenes/Main.tscn", {"gold": 123}, "manual"),
		"test save can be recorded for save list entry"
	)

	var scene: Control = packed_scene.instantiate()
	scene.save_manager = manager
	get_root().add_child(scene)
	_assert_true(scene.show_save_list(), "save list can be shown")

	var save_entry := scene.get_node_or_null("SaveListPanel/Panel/ListScroll/SaveListItems/Save_01")
	_assert_true(save_entry is Button, "save list entry is clickable")
	if save_entry is Button:
		(save_entry as Button).emit_signal("pressed")
	_assert_equal(scene.last_requested_scene_path, "res://scenes/Main.tscn", "clicking save entry requests saved scene")

	scene.free()
	_cleanup_save_root(manager.save_root_path)


func _test_save_root(label: String) -> String:
	return "user://main_menu_test_%s_%d" % [label, Time.get_ticks_usec()]


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


func _assert_button(scene: Node, node_path: String, expected_text: String) -> void:
	var button := scene.get_node_or_null(node_path) as Button
	_assert_true(button != null, "%s exists" % node_path)
	if button != null:
		_assert_equal(button.text, expected_text, "%s text" % node_path)


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
