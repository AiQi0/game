extends SceneTree

var failures := 0


func _init() -> void:
	var manager_script := load("res://scripts/BuildManager.gd")
	if manager_script == null:
		_fail("BuildManager.gd should load")

	if manager_script != null:
		var manager: Node2D = manager_script.new()
		_assert_true(manager.has_method("advance_tree_chop"), "BuildManager advances tree chopping progress")
		_assert_true(manager.has_method("get_tree_chop_task_for_point"), "BuildManager finds tree chop tasks by point")

		var tree := Node2D.new()
		tree.name = "Tree_01"
		tree.global_position = Vector2(4500, 472)
		var footprint := Rect2(Vector2(4468, 352), Vector2(64, 120))
		manager._track_placed_entity(tree, footprint, true, "树", "tree", false)
		manager.demolition_target_index = 0
		manager._demolish_target()

		_assert_equal(manager.placed_buildings.size(), 1, "confirming tree demolition starts chopping instead of removing immediately")
		_assert_equal(manager.placed_footprints.size(), 1, "tree footprint remains while chopping is in progress")
		_assert_true(is_instance_valid(tree), "tree remains visible during chopping task")
		_assert_true(manager.get("tree_chop_tasks") is Array, "BuildManager stores tree chop tasks")

		if manager.get("tree_chop_tasks") is Array and manager.tree_chop_tasks.size() > 0:
			var task: Dictionary = manager.tree_chop_tasks[0]
			_assert_equal(task.task_id, "Tree_01", "tree task id uses tree node name")
			_assert_equal(task.progress, 0.0, "new tree task starts with zero progress")
			_assert_equal(manager.get_tree_chop_task_for_point(Vector2(4500, 472)), "Tree_01", "player can target confirmed tree task")

			manager.gold = 0
			_assert_false(manager.advance_tree_chop("Tree_01", 4.0, 10.0), "partial player chop does not remove tree")
			_assert_true(manager.tree_chop_tasks[0].progress > 0.39, "partial progress is stored")
			_assert_false(manager.advance_tree_chop("Tree_01", 5.0, 10.0), "stored progress survives pauses")
			_assert_true(manager.advance_tree_chop("Tree_01", 1.0, 10.0), "player completes tree after ten total seconds")
			_assert_equal(manager.gold, 1, "completed tree chop grants one gold")
			_assert_equal(manager.placed_buildings.size(), 0, "completed tree chop removes tree entity")
			_assert_false(manager.rules.has_overlap(footprint, manager.placed_footprints), "completed tree chop frees tree footprint")

		manager.free()

	if failures == 0:
		print("TreeChopTaskTest: PASS")
	else:
		push_error("TreeChopTaskTest: %d failure(s)" % failures)

	quit(failures)


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
