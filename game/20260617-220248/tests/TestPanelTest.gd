extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var monster_manager_script := load("res://scripts/MonsterManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if monster_manager_script == null:
		_fail("MonsterManager.gd should load")

	if build_manager_script != null and monster_manager_script != null:
		_test_debug_panel(build_manager_script, monster_manager_script)

	if failures == 0:
		print("TestPanelTest: PASS")
	else:
		push_error("TestPanelTest: %d failure(s)" % failures)

	quit(failures)


func _test_debug_panel(build_manager_script: Script, monster_manager_script: Script) -> void:
	var root := Node2D.new()
	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)

	var monster_manager: Node2D = monster_manager_script.new()
	monster_manager.name = "MonsterManager"
	root.add_child(monster_manager)
	monster_manager.monsters_container = monsters

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.gold = 50
	manager._create_ui()

	var test_button := _find_button(manager, "TestButton")
	_assert_true(test_button != null, "test button exists")
	_assert_always_clickable(test_button, "test button")
	if test_button != null:
		test_button.emit_signal("pressed")

	_assert_true(manager.test_panel != null, "clicking test button opens test panel")
	_assert_true(_find_spinbox(manager.test_panel, "GoldAmountSpinBox") != null, "test panel has gold amount input")
	_assert_true(_find_spinbox(manager.test_panel, "MonsterCountSpinBox") != null, "test panel has monster count input")

	var gold_input := _find_spinbox(manager.test_panel, "GoldAmountSpinBox")
	if gold_input != null:
		gold_input.value = 15
	var add_button := _find_button(manager.test_panel, "AddGoldButton")
	var remove_button := _find_button(manager.test_panel, "RemoveGoldButton")
	_assert_always_clickable(add_button, "add gold button")
	_assert_always_clickable(remove_button, "remove gold button")
	if add_button != null:
		add_button.emit_signal("pressed")
	_assert_equal(manager.gold, 65, "add gold button adds configured amount")
	if remove_button != null:
		remove_button.emit_signal("pressed")
	_assert_equal(manager.gold, 50, "remove gold button removes configured amount")
	manager.gold = 5
	if remove_button != null:
		remove_button.emit_signal("pressed")
	_assert_equal(manager.gold, 0, "remove gold button does not make gold negative")

	var monster_input := _find_spinbox(manager.test_panel, "MonsterCountSpinBox")
	if monster_input != null:
		monster_input.value = 2
	var left_button := _find_button(manager.test_panel, "SpawnLeftMonsterButton")
	var right_button := _find_button(manager.test_panel, "SpawnRightMonsterButton")
	var both_button := _find_button(manager.test_panel, "SpawnBothMonsterButton")
	_assert_always_clickable(left_button, "spawn left monster button")
	_assert_always_clickable(right_button, "spawn right monster button")
	_assert_always_clickable(both_button, "spawn both monster button")
	if left_button != null:
		left_button.emit_signal("pressed")
	_assert_equal(monsters.get_child_count(), 2, "left spawn button creates configured monsters")
	if right_button != null:
		right_button.emit_signal("pressed")
	_assert_equal(monsters.get_child_count(), 4, "right spawn button creates configured monsters")
	if both_button != null:
		both_button.emit_signal("pressed")
	_assert_equal(monsters.get_child_count(), 8, "both spawn button creates monsters on both sides")

	if test_button != null:
		test_button.emit_signal("pressed")
	_assert_true(manager.test_panel == null, "clicking test button again closes test panel")

	root.free()


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


func _find_spinbox(node: Node, spinbox_name: String) -> SpinBox:
	if node == null:
		return null
	if node is SpinBox and node.name == spinbox_name:
		return node as SpinBox
	for child in node.get_children():
		var spinbox := _find_spinbox(child, spinbox_name)
		if spinbox != null:
			return spinbox
	return null


func _assert_always_clickable(button: Button, label: String) -> void:
	_assert_true(button != null, "%s exists" % label)
	if button == null:
		return
	_assert_false(button.disabled, "%s is not disabled" % label)
	_assert_equal(button.mouse_filter, Control.MOUSE_FILTER_STOP, "%s stops mouse input" % label)
	_assert_equal(button.process_mode, Node.PROCESS_MODE_ALWAYS, "%s processes always" % label)
	_assert_equal(button.focus_mode, Control.FOCUS_ALL, "%s accepts focus" % label)


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
