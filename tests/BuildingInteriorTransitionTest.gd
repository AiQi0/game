extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	_assert_true(build_manager_script != null, "BuildManager.gd loads")
	if build_manager_script != null:
		_test_enter_blocks_resources_and_damaged_buildings(build_manager_script)
		_test_main_world_enters_and_restores_interior(build_manager_script)
		_test_s_key_returns_to_cached_main_without_viewport_crash(build_manager_script)

	if failures == 0:
		print("BuildingInteriorTransitionTest: PASS")
	else:
		push_error("BuildingInteriorTransitionTest: %d failure(s)" % failures)
	quit(failures)


func _test_main_world_enters_and_restores_interior(build_manager_script: Script) -> void:
	var game_session := get_root().get_node_or_null("GameSession")
	_assert_true(game_session != null, "GameSession autoload exists")
	if game_session == null:
		return

	var main := Node2D.new()
	main.name = "InteriorTransitionMain"

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(3000, 472)
	main.add_child(player)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	player.add_child(camera)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	main.add_child(buildings)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	main.add_child(build_manager)

	var build_ui := CanvasLayer.new()
	build_ui.name = "BuildUI"
	build_ui.visible = true
	build_manager.add_child(build_ui)

	get_root().add_child(main)
	current_scene = main

	var building := Node2D.new()
	building.name = "farm_interior_test"
	building.global_position = player.global_position
	buildings.add_child(building)
	build_manager._track_placed_entity(
		building,
		Rect2(Vector2(2890, 352), Vector2(220, 120)),
		true,
		"Farm",
		"building",
		true,
		"farm"
	)

	_assert_true(build_manager.try_enter_building_at_player(), "player standing on the building footprint bottom edge can enter interior")
	_assert_true(current_scene != main, "current scene switched away from main")
	_assert_equal(current_scene.name, "BuildingInterior", "current scene is building interior")
	_assert_equal(main.get_parent(), get_root(), "main scene remains in the tree while interior is active")
	_assert_false(main.visible, "main scene visuals are hidden while interior is active")
	_assert_false(build_ui.visible, "main scene canvas UI is hidden while interior is active")
	_assert_false(player.is_physics_processing(), "main player physics is disabled while interior is active")
	_assert_false(camera.enabled, "main camera is disabled while interior is active")
	_assert_equal(game_session.active_interior_context().get("building_node_name", ""), "farm_interior_test", "interior context stores source building")
	_assert_true(game_session.has_cached_main_scene(), "main scene is cached during interior")

	if current_scene != null and current_scene != main:
		current_scene.queue_free()
	if game_session.has_method("restore_cached_main_scene"):
		_assert_true(game_session.restore_cached_main_scene(self), "cached main restores after interior")
	_assert_true(main.visible, "main scene visuals resume after interior return")
	_assert_true(build_ui.visible, "main scene canvas UI resumes after interior return")
	_assert_true(player.is_physics_processing(), "main player physics resumes after interior return")
	_assert_true(camera.enabled, "main camera resumes after interior return")
	if current_scene != null and current_scene != main:
		current_scene.queue_free()
	elif main.get_parent() != null:
		main.get_parent().remove_child(main)
		main.queue_free()
	if game_session.has_method("clear_cached_main_scene"):
		game_session.clear_cached_main_scene()
	if game_session.has_method("clear_active_interior_context"):
		game_session.clear_active_interior_context()


func _test_s_key_returns_to_cached_main_without_viewport_crash(build_manager_script: Script) -> void:
	var game_session := get_root().get_node_or_null("GameSession")
	_assert_true(game_session != null, "GameSession autoload exists for S return")
	if game_session == null:
		return

	var main := Node2D.new()
	main.name = "InteriorSReturnMain"

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(3000, 472)
	main.add_child(player)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	main.add_child(buildings)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	main.add_child(build_manager)

	get_root().add_child(main)
	current_scene = main

	var building := Node2D.new()
	building.name = "farm_s_return_test"
	building.global_position = player.global_position
	buildings.add_child(building)
	build_manager._track_placed_entity(
		building,
		Rect2(Vector2(2890, 352), Vector2(220, 120)),
		true,
		"Farm",
		"building",
		true,
		"farm"
	)

	_assert_true(build_manager.try_enter_building_at_player(), "player enters interior before S return")
	var interior := current_scene
	_assert_true(interior != null and interior.name == "BuildingInterior", "S return test reaches interior scene")
	if interior == null or interior.name != "BuildingInterior":
		_cleanup_transition_state(game_session, main)
		return

	interior.player.position = interior.door_position
	var event := InputEventKey.new()
	event.keycode = KEY_S
	event.pressed = true
	interior._unhandled_input(event)

	_assert_equal(current_scene, main, "S at interior door restores cached main scene")
	_assert_equal(game_session.active_interior_context().size(), 0, "S return clears active interior context")

	_cleanup_transition_state(game_session, main)


func _test_enter_blocks_resources_and_damaged_buildings(build_manager_script: Script) -> void:
	var main := Node2D.new()
	main.name = "InteriorBlockMain"

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(3000, 472)
	main.add_child(player)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	main.add_child(buildings)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	build_manager.status_label = Label.new()
	main.add_child(build_manager.status_label)
	main.add_child(build_manager)

	get_root().add_child(main)
	current_scene = main

	var tree := Node2D.new()
	tree.name = "TreeResource"
	tree.global_position = player.global_position
	buildings.add_child(tree)
	build_manager._track_placed_entity(
		tree,
		Rect2(Vector2(2940, 420), Vector2(120, 120)),
		true,
		"Tree",
		"resource",
		true,
		"tree"
	)
	_assert_false(build_manager.try_enter_building_at_player(), "resource entities cannot open building interiors")

	var damaged_building := Node2D.new()
	damaged_building.name = "damaged_farm"
	damaged_building.global_position = player.global_position
	buildings.add_child(damaged_building)
	build_manager._track_placed_entity(
		damaged_building,
		Rect2(Vector2(2890, 390), Vector2(220, 120)),
		true,
		"Damaged Farm",
		"building",
		true,
		"farm"
	)
	var damaged_index: int = build_manager.placed_buildings.size() - 1
	var damaged_entity: Dictionary = build_manager.placed_buildings[damaged_index]
	damaged_entity.damaged = true
	build_manager.placed_buildings[damaged_index] = damaged_entity
	_assert_true(build_manager.try_enter_building_at_player(), "damaged building consumes enter input for repair prompt")
	_assert_equal(build_manager.status_label.text, "Building damaged: press E to repair", "damaged building shows repair prompt instead of entering")
	_assert_equal(current_scene, main, "damaged building does not switch to interior scene")

	if main.get_parent() != null:
		main.get_parent().remove_child(main)
	main.queue_free()


func _cleanup_transition_state(game_session: Node, main: Node) -> void:
	if game_session != null and game_session.has_method("clear_cached_main_scene"):
		game_session.clear_cached_main_scene()
	if game_session != null and game_session.has_method("clear_active_interior_context"):
		game_session.clear_active_interior_context()
	if main != null and is_instance_valid(main):
		if main.get_parent() != null:
			main.get_parent().remove_child(main)
		main.queue_free()


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
