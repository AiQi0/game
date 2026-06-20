extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_script := load("res://scripts/GameSession.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var river_scene_script := load("res://scripts/RiverMerchantAlliance.gd")
	var save_manager_script := load("res://scripts/SaveGameManager.gd")
	if session_script == null:
		_fail("GameSession.gd should load")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if river_scene_script == null:
		_fail("RiverMerchantAlliance.gd should load")
	if save_manager_script == null:
		_fail("SaveGameManager.gd should load")

	if session_script != null and build_manager_script != null and river_scene_script != null:
		_test_cached_main_scene_restores_same_runtime_state(session_script, build_manager_script)
		_test_build_manager_travel_caches_current_main(session_script, build_manager_script)
		_test_river_return_uses_cached_main_scene(session_script, river_scene_script, build_manager_script)
		_test_river_e_input_return_does_not_use_detached_viewport(session_script, river_scene_script, build_manager_script)
		_test_river_travel_return_keeps_main_city_controlled(session_script, build_manager_script)
	if session_script != null and build_manager_script != null and save_manager_script != null:
		_test_cached_main_scene_autosaves_before_quit(session_script, build_manager_script, save_manager_script)
	if session_script != null and build_manager_script != null and river_scene_script != null and save_manager_script != null:
		_test_river_escape_pause_saves_active_scene(session_script, river_scene_script, build_manager_script, save_manager_script)
		_test_river_pause_load_rebuilds_non_dead_cached_main(session_script, river_scene_script, build_manager_script, save_manager_script)

	if failures == 0:
		print("TravelStatePersistenceTest: PASS")
	else:
		push_error("TravelStatePersistenceTest: %d failure(s)" % failures)

	quit(failures)


func _test_cached_main_scene_restores_same_runtime_state(session_script: Script, build_manager_script: Script) -> void:
	var session: Node = session_script.new()
	var main := _make_main_scene(build_manager_script, 42)
	_assert_true(session.has_method("cache_main_scene"), "session can cache main scene")
	_assert_true(session.has_method("take_cached_main_scene"), "session can return cached main scene")
	if not session.has_method("cache_main_scene") or not session.has_method("take_cached_main_scene"):
		main.free()
		session.free()
		return

	_assert_true(session.cache_main_scene(main), "session caches main scene")
	var restored: Node = session.take_cached_main_scene()
	_assert_true(restored == main, "session returns the same main scene instance")
	_assert_equal(restored.get_node("BuildManager").get("gold"), 42, "cached main scene keeps runtime gold")
	main.free()
	session.free()


func _test_build_manager_travel_caches_current_main(session_script: Script, build_manager_script: Script) -> void:
	var session := get_root().get_node_or_null("GameSession")
	var owns_session := false
	if session == null:
		session = session_script.new()
		session.name = "GameSession"
		get_root().add_child(session)
		owns_session = true
	elif session.has_method("take_cached_main_scene"):
		session.take_cached_main_scene()

	var main := _make_main_scene(build_manager_script, 63)
	get_root().add_child(main)
	current_scene = main
	var manager := main.get_node("BuildManager")
	manager._request_travel_scene_change("res://scenes/RiverMerchantAlliance.tscn")

	_assert_true(session.has_cached_main_scene(), "travel caches the current main scene")
	_assert_false(current_scene == main, "travel switches away from the cached main scene")
	var cached_main: Node = session.take_cached_main_scene()
	_assert_true(cached_main == main, "travel cache keeps the same main scene instance")
	_assert_equal(cached_main.get_node("BuildManager").get("gold"), 63, "travel cache keeps main scene gold")

	var active_scene := current_scene
	if active_scene != null and active_scene != main:
		if active_scene.get_parent() != null:
			active_scene.get_parent().remove_child(active_scene)
		active_scene.free()
	current_scene = null
	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.free()
	if owns_session:
		session.free()


func _test_river_return_uses_cached_main_scene(
	session_script: Script,
	river_scene_script: Script,
	build_manager_script: Script
) -> void:
	var session := get_root().get_node_or_null("GameSession")
	var owns_session := false
	if session == null:
		session = session_script.new()
		session.name = "GameSession"
		get_root().add_child(session)
		owns_session = true
	elif session.has_method("take_cached_main_scene"):
		session.take_cached_main_scene()

	var main := _make_main_scene(build_manager_script, 57)
	get_root().add_child(main)
	current_scene = main
	_assert_true(session.cache_main_scene(main), "main scene can be cached before river travel")
	get_root().remove_child(main)

	var river := Node2D.new()
	river.name = "RiverMerchantAlliance"
	river.set_script(river_scene_script)
	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(5350, 472)
	river.add_child(player)
	var post_station := Node2D.new()
	post_station.name = "PostStation"
	post_station.global_position = Vector2(5350, 472)
	river.add_child(post_station)
	get_root().add_child(river)
	current_scene = river

	_assert_equal(river.main_world_scene_path(), "res://scenes/Main.tscn", "minimal river scene resolves main route")
	_assert_true(river.can_return_to_main_world(), "minimal river scene can return at post station")
	_assert_true(session.has_cached_main_scene(), "main scene is cached before river return")
	_assert_true(river.return_to_main_world(), "river return restores cached main scene")
	_assert_false(session.has_cached_main_scene(), "river return consumes cached main scene")
	_assert_true(current_scene == main, "current scene is the original main scene after return")
	_assert_equal(current_scene.get_node("BuildManager").get("gold"), 57, "return keeps main scene gold")

	if is_instance_valid(river):
		river.free()
	if is_instance_valid(main):
		main.free()
	if owns_session:
		session.free()


func _test_river_e_input_return_does_not_use_detached_viewport(
	session_script: Script,
	river_scene_script: Script,
	build_manager_script: Script
) -> void:
	var session := get_root().get_node_or_null("GameSession")
	var owns_session := false
	if session == null:
		session = session_script.new()
		session.name = "GameSession"
		get_root().add_child(session)
		owns_session = true
	elif session.has_method("take_cached_main_scene"):
		session.take_cached_main_scene()

	var main := _make_main_scene(build_manager_script, 71)
	get_root().add_child(main)
	current_scene = main
	_assert_true(session.cache_main_scene(main), "main scene can be cached before E input river return")
	get_root().remove_child(main)

	var river := _make_minimal_river_scene(river_scene_script)
	get_root().add_child(river)
	current_scene = river

	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	river._unhandled_input(event)

	_assert_false(session.has_cached_main_scene(), "E input river return consumes cached main scene")
	_assert_true(current_scene == main, "E input return restores original main scene")
	_assert_equal(current_scene.get_node("BuildManager").get("gold"), 71, "E input return keeps main scene gold")

	if is_instance_valid(river):
		river.free()
	if is_instance_valid(main):
		main.free()
	if owns_session:
		session.free()


func _test_river_travel_return_keeps_main_city_controlled(session_script: Script, build_manager_script: Script) -> void:
	var session := get_root().get_node_or_null("GameSession")
	var owns_session := false
	if session == null:
		session = session_script.new()
		session.name = "GameSession"
		get_root().add_child(session)
		owns_session = true
	elif session.has_method("clear_cached_main_scene"):
		session.clear_cached_main_scene()

	var main := _make_main_scene(build_manager_script, 99)
	get_root().add_child(main)
	current_scene = main
	var manager := main.get_node("BuildManager")
	manager.horse_count = 1
	_track_building(manager, main, "post_station_1", "post_station", Vector2(4300, 472), Vector2(190, 130), 1, false)

	_assert_true(manager.can_build_definition(manager.building_definition_for_id("blacksmith")), "main city can build before river travel")
	_assert_true(manager.travel_to_terrain("river"), "post station travel enters river scene")
	_assert_true(session.has_cached_main_scene(), "river travel caches main scene")

	var cached_main: Node = session.get("cached_main_scene")
	var cached_manager = cached_main.get_node("BuildManager")
	_assert_equal(cached_manager.get("city_terrain"), "", "cached main keeps original terrain while river scene is active")
	_assert_true(cached_manager.get("city_player_controlled"), "cached main stays controlled while river scene is active")
	_assert_true(cached_manager.can_build_definition(cached_manager.building_definition_for_id("blacksmith")), "cached main remains buildable while river scene is active")

	_assert_true(session.restore_cached_main_scene(self), "river return restores cached main scene")
	_assert_true(current_scene == main, "return restores the original main scene instance")
	_assert_equal(manager.get("city_terrain"), "", "returned main keeps original terrain")
	_assert_true(manager.get("city_player_controlled"), "returned main city remains controlled")
	_assert_true(manager.can_build_definition(manager.building_definition_for_id("blacksmith")), "returned main can still build")

	if is_instance_valid(main):
		main.free()
	if owns_session:
		session.free()


func _test_cached_main_scene_autosaves_before_quit(
	session_script: Script,
	build_manager_script: Script,
	save_manager_script: Script
) -> void:
	var session: Node = session_script.new()
	var main := _make_main_scene(build_manager_script, 91)
	var save_manager = save_manager_script.new()
	save_manager.save_root_path = _test_save_root("session_quit")
	_cleanup_save_root(save_manager.save_root_path)
	main.get_node("BuildManager").set("save_manager", save_manager)

	_assert_true(session.cache_main_scene(main), "session caches main scene before quit")
	_assert_true(session.has_method("autosave_cached_main_scene"), "session exposes cached main autosave")
	if session.has_method("autosave_cached_main_scene"):
		_assert_true(session.autosave_cached_main_scene("quit"), "cached main scene autosaves before quit")
		var save_data: Dictionary = save_manager.read_last_save()
		_assert_equal(save_data.get("autosave_reason", ""), "quit", "cached main quit autosave records reason")
		var snapshot: Dictionary = save_data.get("snapshot", {})
		_assert_equal(snapshot.get("gold", -1), 91, "cached main quit autosave keeps gold")

	_cleanup_save_root(save_manager.save_root_path)
	main.free()
	session.free()


func _test_river_escape_pause_saves_active_scene(
	session_script: Script,
	river_scene_script: Script,
	build_manager_script: Script,
	save_manager_script: Script
) -> void:
	var session := _ensure_test_session(session_script)
	if session.has_method("clear_cached_main_scene"):
		session.clear_cached_main_scene()

	var save_manager = save_manager_script.new()
	save_manager.save_root_path = _test_save_root("river_pause_save")
	_cleanup_save_root(save_manager.save_root_path)

	var main := _make_main_scene(build_manager_script, 77)
	var main_manager: Node = main.get_node("BuildManager")
	main_manager.set("save_manager", save_manager)
	main_manager.set("player_dead", false)
	_assert_true(session.cache_main_scene(main), "session caches main before river pause save")
	if main.get_parent() != null:
		main.get_parent().remove_child(main)

	var river := _make_minimal_river_scene(river_scene_script)
	river.set("save_manager", save_manager)
	get_root().add_child(river)
	current_scene = river

	_assert_equal(river.process_mode, Node.PROCESS_MODE_ALWAYS, "river scene keeps receiving escape while paused")
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	river._unhandled_input(event)

	_assert_true(paused, "river escape pauses the game")
	_assert_true(river.get("pause_panel") != null, "river escape opens pause panel")
	river._unhandled_input(event)
	_assert_false(paused, "second river escape resumes the game")
	_assert_true(river.get("pause_panel") == null, "second river escape closes pause panel")
	river._unhandled_input(event)
	_assert_true(paused, "river escape can pause again after resume")
	var save_button := _find_button(river, "SaveButton")
	_assert_true(save_button != null, "river pause menu has save button")
	if save_button != null:
		save_button.emit_signal("pressed")

	var save_data: Dictionary = save_manager.read_last_save()
	_assert_equal(save_data.get("scene_path", ""), "res://scenes/RiverMerchantAlliance.tscn", "river pause save records active scene")
	_assert_equal(save_data.get("autosave_reason", ""), "manual", "river pause save records manual reason")
	_assert_equal(save_data.get("snapshot", {}).get("gold", -1), 77, "river pause save stores cached main gold")
	_assert_false(bool(save_data.get("snapshot", {}).get("player_dead", true)), "river pause save stores non-dead main state")

	paused = false
	current_scene = null
	if is_instance_valid(river):
		river.free()
	if session.has_method("clear_cached_main_scene"):
		session.clear_cached_main_scene()
	_cleanup_save_root(save_manager.save_root_path)


func _test_river_pause_load_rebuilds_non_dead_cached_main(
	session_script: Script,
	river_scene_script: Script,
	build_manager_script: Script,
	save_manager_script: Script
) -> void:
	var session := _ensure_test_session(session_script)
	if session.has_method("clear_cached_main_scene"):
		session.clear_cached_main_scene()

	var save_manager = save_manager_script.new()
	save_manager.save_root_path = _test_save_root("river_pause_load")
	_cleanup_save_root(save_manager.save_root_path)
	_assert_true(
		save_manager.record_autosave(
			"res://scenes/RiverMerchantAlliance.tscn",
			{
				"gold": 88,
				"player_dead": false,
				"player_position": [4800.0, 472.0],
				"city_terrain": "",
				"city_player_controlled": true,
				"horse_count": 1,
			},
			"manual"
		),
		"test river save can be recorded"
	)

	var stale_main := _make_main_scene(build_manager_script, 1)
	stale_main.get_node("BuildManager").set("player_dead", true)
	_assert_true(session.cache_main_scene(stale_main), "session starts with stale dead cached main")
	if stale_main.get_parent() != null:
		stale_main.get_parent().remove_child(stale_main)

	var river := _make_minimal_river_scene(river_scene_script)
	river.set("save_manager", save_manager)
	get_root().add_child(river)
	current_scene = river

	_assert_true(river.load_game_from_pause(), "river pause load applies last save")
	_assert_true(session.has_cached_main_scene(), "river pause load keeps a cached main scene")
	var cached_main: Node = session.get("cached_main_scene")
	var cached_manager: Node = cached_main.get_node("BuildManager") if cached_main != null else null
	_assert_true(cached_manager != null, "river pause load cached main has BuildManager")
	if cached_manager != null:
		_assert_equal(cached_manager.get("gold"), 88, "river pause load restores saved gold")
		_assert_false(bool(cached_manager.get("player_dead")), "river pause load clears stale death state")

	current_scene = null
	if is_instance_valid(river):
		river.free()
	if session.has_method("clear_cached_main_scene"):
		session.clear_cached_main_scene()
	_cleanup_save_root(save_manager.save_root_path)


func _make_minimal_river_scene(river_scene_script: Script) -> Node2D:
	var river := Node2D.new()
	river.name = "RiverMerchantAlliance"
	river.set_script(river_scene_script)
	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(5350, 472)
	river.add_child(player)
	var post_station := Node2D.new()
	post_station.name = "PostStation"
	post_station.global_position = Vector2(5350, 472)
	river.add_child(post_station)
	return river


func _ensure_test_session(session_script: Script) -> Node:
	var session := get_root().get_node_or_null("GameSession")
	if session == null:
		session = session_script.new()
		session.name = "GameSession"
		get_root().add_child(session)
	return session


func _make_main_scene(build_manager_script: Script, gold: int) -> Node2D:
	var main := Node2D.new()
	main.name = "Main"
	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	manager.set("gold", gold)
	main.add_child(manager)
	return main


func _track_building(
	manager: Node2D,
	parent: Node,
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
	parent.add_child(building)
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
	manager.placed_buildings[index] = entity
	return building


func _test_save_root(label: String) -> String:
	return "user://travel_state_test_%s_%d" % [label, Time.get_ticks_usec()]


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
