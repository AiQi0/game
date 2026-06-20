extends SceneTree

class BiteRulesProbe:
	var bite_calls: Array = []

	func should_bite(second_number: int, roll: float, data) -> bool:
		bite_calls.append({
			"second": second_number,
			"roll": roll,
			"data": data,
		})
		return second_number >= 2

	func reel_progress_after_press(current_progress: float, data) -> float:
		return current_progress

	func reel_progress_after_decay(current_progress: float, delta: float, data) -> float:
		return current_progress

	func reel_outcome(progress: float) -> String:
		return "active"

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var fishing_manager_script := load("res://scripts/FishingManager.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if fishing_manager_script == null:
		_fail("FishingManager.gd should load")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if fishing_manager_script != null and build_manager_script != null:
		_test_start_bite_reel_success(fishing_manager_script, build_manager_script)
		_test_hook_timeout_and_cancel(fishing_manager_script, build_manager_script)
		_test_decay_failure(fishing_manager_script, build_manager_script)
		_test_process_driven_bite_checks(fishing_manager_script, build_manager_script)
		_test_cancel_when_dead_or_paused(fishing_manager_script, build_manager_script)
		_test_press_fishing_key_respects_blocked_context(fishing_manager_script, build_manager_script)
		_test_f_key_input_only_handled_when_action_occurs(fishing_manager_script)
		_test_runtime_ui_nodes_exist(fishing_manager_script, build_manager_script)
		_test_build_manager_blocks_fishing_when_busy(fishing_manager_script, build_manager_script)
		_test_build_manager_ignores_build_input_while_fishing(fishing_manager_script, build_manager_script)

	_test_main_scene_wiring()

	if failures == 0:
		print("FishingManagerTest: PASS")
	else:
		push_error("FishingManagerTest: %d failure(s)" % failures)

	quit(failures)


func _test_start_bite_reel_success(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")
	build_manager.gold = 0

	_assert_true(fishing_manager.try_start_fishing(), "F starts fishing from idle")
	_assert_equal(fishing_manager.state_name(), "waiting_for_bite", "fishing starts waiting for bite")
	fishing_manager._enter_bite_window()
	_assert_equal(fishing_manager.state_name(), "bite_window", "forced bite enters hook window")
	fishing_manager.press_fishing_key()
	_assert_equal(fishing_manager.state_name(), "reeling", "F during hook window starts reeling")
	for i in range(6):
		fishing_manager.press_fishing_key()
	_assert_equal(fishing_manager.state_name(), "success", "reeling reaches success")
	_assert_equal(build_manager.gold, 1, "successful fishing grants one gold")

	root.free()


func _test_hook_timeout_and_cancel(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var fishing_manager: Node = root.get_node("FishingManager")

	_assert_true(fishing_manager.try_start_fishing(), "fishing can start")
	fishing_manager._enter_bite_window()
	fishing_manager._process(1.6)
	_assert_equal(fishing_manager.state_name(), "failed", "hook window expires after one and a half seconds")

	fishing_manager._finish_result()
	_assert_true(fishing_manager.try_start_fishing(), "fishing can restart after result")
	fishing_manager.cancel_fishing()
	_assert_equal(fishing_manager.state_name(), "idle", "Q cancel returns fishing to idle")

	root.free()


func _test_decay_failure(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")
	build_manager.gold = 0

	_assert_true(fishing_manager.try_start_fishing(), "fishing can start")
	fishing_manager._enter_bite_window()
	fishing_manager.press_fishing_key()
	fishing_manager._process(2.0)
	_assert_equal(fishing_manager.state_name(), "failed", "reel progress decays to failure")
	_assert_equal(build_manager.gold, 0, "failed fishing grants no gold")

	root.free()


func _test_process_driven_bite_checks(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var fishing_manager: Node = root.get_node("FishingManager")
	var rules_probe := BiteRulesProbe.new()
	fishing_manager.rules = rules_probe

	_assert_true(fishing_manager.try_start_fishing(), "fishing can start for bite checks")
	fishing_manager._process(0.5)
	_assert_equal(rules_probe.bite_calls.size(), 0, "bite is not checked before bite_check_seconds")
	_assert_equal(fishing_manager.bite_second, 0, "bite second waits for first check")

	fishing_manager._process(0.5)
	_assert_equal(rules_probe.bite_calls.size(), 1, "first bite check happens after bite_check_seconds")
	_assert_equal(fishing_manager.bite_second, 1, "first bite check increments bite second")
	_assert_equal(rules_probe.bite_calls[0].second, 1, "first bite check passes second one to rules")
	_assert_equal(fishing_manager.state_name(), "waiting_for_bite", "failed bite roll keeps waiting")

	fishing_manager._process(1.0)
	_assert_equal(rules_probe.bite_calls.size(), 2, "second bite check happens on next interval")
	_assert_equal(rules_probe.bite_calls[1].second, 2, "second bite check passes second two to rules")
	_assert_equal(fishing_manager.state_name(), "bite_window", "rules bite enters hook window")

	root.free()


func _test_cancel_when_dead_or_paused(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")

	_assert_true(fishing_manager.try_start_fishing(), "fishing can start before player death")
	build_manager.player_dead = true
	fishing_manager._process(0.1)
	_assert_equal(fishing_manager.state_name(), "idle", "player death cancels active fishing")
	root.free()

	var tree_root := _create_fishing_only_root(fishing_manager_script)
	get_root().add_child(tree_root)
	var paused_fishing_manager: Node = tree_root.get_node("FishingManager")

	_assert_true(paused_fishing_manager.try_start_fishing(), "fishing can start before pause")
	get_root().get_tree().paused = true
	_assert_true(get_root().get_tree().paused, "test scene tree is paused")
	paused_fishing_manager._process(0.1)
	_assert_equal(paused_fishing_manager.state_name(), "idle", "scene tree pause cancels active fishing")
	get_root().get_tree().paused = false
	tree_root.free()


func _test_press_fishing_key_respects_blocked_context(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var idle_root := _create_root(fishing_manager_script, build_manager_script)
	var idle_build_manager: Node2D = idle_root.get_node("BuildManager")
	var idle_fishing_manager: Node = idle_root.get_node("FishingManager")
	idle_build_manager.player_dead = true

	_assert_false(idle_fishing_manager.press_fishing_key(), "F from idle returns false while start is blocked")
	_assert_equal(idle_fishing_manager.state_name(), "idle", "blocked idle F stays idle")
	idle_root.free()

	var bite_root := _create_root(fishing_manager_script, build_manager_script)
	var bite_build_manager: Node2D = bite_root.get_node("BuildManager")
	var bite_fishing_manager: Node = bite_root.get_node("FishingManager")

	_assert_true(bite_fishing_manager.try_start_fishing(), "fishing can start before blocked hook")
	bite_fishing_manager._enter_bite_window()
	bite_build_manager.player_dead = true
	_assert_false(bite_fishing_manager.press_fishing_key(), "F in bite window returns false when context blocks fishing")
	_assert_equal(bite_fishing_manager.state_name(), "idle", "blocked bite F cancels to idle instead of reeling")
	bite_root.free()

	var reel_root := _create_root(fishing_manager_script, build_manager_script)
	var reel_build_manager: Node2D = reel_root.get_node("BuildManager")
	var reel_fishing_manager: Node = reel_root.get_node("FishingManager")
	reel_build_manager.gold = 0

	_assert_true(reel_fishing_manager.try_start_fishing(), "fishing can start before blocked reeling")
	reel_fishing_manager._enter_bite_window()
	_assert_true(reel_fishing_manager.press_fishing_key(), "F starts reeling before context blocks")
	reel_build_manager.player_dead = true
	for i in range(6):
		_assert_false(reel_fishing_manager.press_fishing_key(), "blocked reel press %d returns false" % (i + 1))
	_assert_equal(reel_fishing_manager.state_name(), "idle", "blocked reel presses cancel to idle")
	_assert_equal(reel_build_manager.gold, 0, "blocked reel presses do not grant gold")
	reel_root.free()


func _test_f_key_input_only_handled_when_action_occurs(fishing_manager_script: Script) -> void:
	var root := _create_fishing_only_root(fishing_manager_script)
	get_root().add_child(root)
	var fishing_manager: Node = root.get_node("FishingManager")
	var viewport := get_root()

	_assert_false(viewport.is_input_handled(), "test viewport starts with unhandled input")
	_assert_true(fishing_manager.try_start_fishing(), "fishing can start before waiting input check")
	fishing_manager._unhandled_input(_f_key_event())
	_assert_false(viewport.is_input_handled(), "F while waiting does not mark input handled")

	fishing_manager.cancel_fishing()
	fishing_manager._unhandled_input(_f_key_event())
	_assert_true(viewport.is_input_handled(), "F that starts fishing marks input handled")

	root.free()


func _test_runtime_ui_nodes_exist(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var fishing_manager: Node = root.get_node("FishingManager")
	var ui := fishing_manager.get_node_or_null("FishingUI")

	_assert_true(ui != null, "FishingUI canvas exists")
	if ui != null:
		_assert_true(ui.find_child("FishingStatus", true, false) is Label, "FishingStatus label exists")
		_assert_true(ui.find_child("FishingDetail", true, false) is Label, "FishingDetail label exists")
		_assert_true(ui.find_child("FishingProgress", true, false) is ProgressBar, "FishingProgress bar exists")

	root.free()


func _test_build_manager_ignores_build_input_while_fishing(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")
	build_manager.fishing_manager = fishing_manager
	build_manager._refresh_building_choices()
	build_manager.selected_index = 0

	var requested_index: int = build_manager.rules.selected_index_from_key(KEY_2)
	_assert_true(build_manager.buildings.size() > requested_index, "BuildManager has KEY_2 building choice")
	if build_manager.buildings.size() <= requested_index:
		root.free()
		return

	_assert_true(fishing_manager.try_start_fishing(), "fishing starts before BuildManager input guard check")
	build_manager._unhandled_input(_key_event(KEY_2))
	_assert_equal(build_manager.selected_index, 0, "BuildManager ignores building selection while fishing")

	fishing_manager.cancel_fishing()
	build_manager._unhandled_input(_key_event(KEY_2))
	_assert_equal(build_manager.selected_index, requested_index, "BuildManager accepts building selection after fishing ends")

	root.free()


func _test_build_manager_blocks_fishing_when_busy(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")

	_assert_true(build_manager.can_start_fishing(), "idle BuildManager allows fishing")
	_assert_true(fishing_manager.try_start_fishing(), "fishing starts when BuildManager allows it")
	fishing_manager.cancel_fishing()

	build_manager.player_dead = true
	_assert_false(build_manager.can_start_fishing(), "dead player cannot start fishing")
	build_manager.player_dead = false

	build_manager.pause_panel = Control.new()
	_assert_false(build_manager.can_start_fishing(), "pause panel blocks fishing")
	build_manager.pause_panel.free()
	build_manager.pause_panel = null

	build_manager.test_panel = Control.new()
	_assert_false(build_manager.can_start_fishing(), "test panel blocks fishing")
	build_manager.test_panel.free()
	build_manager.test_panel = null

	build_manager.info_panel = Control.new()
	_assert_false(build_manager.can_start_fishing(), "info panel blocks fishing")
	var info_panel_start_result: bool = fishing_manager.try_start_fishing()
	_assert_false(info_panel_start_result, "fishing cannot start while info panel is open")
	_assert_equal(fishing_manager.state_name(), "idle", "blocked info panel fishing stays idle")
	if info_panel_start_result:
		fishing_manager.cancel_fishing()
	build_manager.info_panel.free()
	build_manager.info_panel = null

	build_manager.demolition_target_index = 0
	_assert_false(build_manager.can_start_fishing(), "demolition confirmation blocks fishing")
	var demolition_start_result: bool = fishing_manager.try_start_fishing()
	_assert_false(demolition_start_result, "fishing cannot start during demolition confirmation")
	_assert_equal(fishing_manager.state_name(), "idle", "blocked demolition fishing stays idle")
	if demolition_start_result:
		fishing_manager.cancel_fishing()
	build_manager.demolition_target_index = -1

	build_manager.player_tree_task_id = "TreeTask_01"
	_assert_false(build_manager.can_start_fishing(), "active player tree chop blocks fishing")
	var tree_task_start_result: bool = fishing_manager.try_start_fishing()
	_assert_false(tree_task_start_result, "fishing cannot start during player tree chop")
	_assert_equal(fishing_manager.state_name(), "idle", "blocked tree chop fishing stays idle")
	if tree_task_start_result:
		fishing_manager.cancel_fishing()

	root.free()

	var paused_root := _create_root(fishing_manager_script, build_manager_script)
	get_root().add_child(paused_root)
	var paused_build_manager: Node2D = paused_root.get_node("BuildManager")
	var previous_pause_state: bool = get_root().get_tree().paused
	get_root().get_tree().paused = true
	_assert_false(paused_build_manager.can_start_fishing(), "paused tree blocks fishing")
	get_root().get_tree().paused = previous_pause_state
	paused_root.free()


func _test_main_scene_wiring() -> void:
	var packed_scene := load("res://scenes/Main.tscn")
	_assert_true(packed_scene != null, "Main scene should load")
	if packed_scene == null:
		return

	var scene: Node = packed_scene.instantiate()
	var fishing_manager := scene.get_node_or_null("FishingManager")
	_assert_true(fishing_manager != null, "Main scene has FishingManager node")
	if fishing_manager != null:
		_assert_equal(fishing_manager.get_script().resource_path, "res://scripts/FishingManager.gd", "FishingManager uses fishing script")

	scene.free()


func _create_root(fishing_manager_script: Script, build_manager_script: Script) -> Node2D:
	var root := Node2D.new()

	var player := CharacterBody2D.new()
	player.name = "Player"
	root.add_child(player)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	root.add_child(build_manager)

	var fishing_manager: Node = fishing_manager_script.new()
	fishing_manager.name = "FishingManager"
	root.add_child(fishing_manager)
	fishing_manager.build_manager = build_manager
	fishing_manager.player = player
	fishing_manager._create_ui()

	return root


func _create_fishing_only_root(fishing_manager_script: Script) -> Node2D:
	var root := Node2D.new()

	var player := CharacterBody2D.new()
	player.name = "Player"
	root.add_child(player)

	var fishing_manager: Node = fishing_manager_script.new()
	fishing_manager.name = "FishingManager"
	root.add_child(fishing_manager)
	fishing_manager.player = player
	fishing_manager._create_ui()

	return root


func _f_key_event() -> InputEventKey:
	return _key_event(KEY_F)


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


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
