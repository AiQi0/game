extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")

	if build_manager_script != null and npc_manager_script != null:
		var root := Node2D.new()
		var npcs := Node2D.new()
		npcs.name = "NPCs"
		root.add_child(npcs)

		var npc_manager: Node2D = npc_manager_script.new()
		npc_manager.name = "NPCManager"
		root.add_child(npc_manager)
		npc_manager.npc_container = npcs

		var build_manager: Node2D = build_manager_script.new()
		build_manager.name = "BuildManager"
		root.add_child(build_manager)

		_assert_true(npc_manager.has_method("assign_tree_chopper"), "NPCManager assigns villagers to tree chop tasks")
		_assert_true(npc_manager.has_method("_finish_arriving_tree_choppers"), "NPCManager starts chopping after villagers arrive")
		_assert_true(npc_manager.has_method("_advance_tree_choppers"), "NPCManager advances villager chopping progress")

		var factory := NPCFactory.new()
		var villager: Node2D = factory.create_homeless(Vector2(4400, 472), Vector2(4800, 472))
		villager.name = "Villager_01"
		villager.interact()
		npcs.add_child(villager)

		var tree := Node2D.new()
		tree.name = "Tree_01"
		tree.global_position = Vector2(4500, 472)
		build_manager._track_placed_entity(
			tree,
			Rect2(Vector2(4468, 352), Vector2(64, 120)),
			true,
			"树",
			"tree",
			false
		)
		build_manager.demolition_target_index = 0
		build_manager._demolish_target()

		_assert_true(villager.get("is_traveling_to_tree_chop") == true, "confirmed tree chop sends idle villager to tree")
		_assert_equal(villager.get("tree_chop_task_id"), "Tree_01", "villager stores tree task id")

		if npc_manager.has_method("_finish_arriving_tree_choppers") and npc_manager.has_method("_advance_tree_choppers"):
			villager.global_position = Vector2(4500, 472)
			npc_manager._finish_arriving_tree_choppers()
			_assert_true(villager.get("is_chopping_tree") == true, "villager starts chopping after reaching tree")
			build_manager.gold = 0
			npc_manager._advance_tree_choppers(59.0)
			_assert_equal(build_manager.gold, 0, "villager chop takes sixty seconds")
			npc_manager._advance_tree_choppers(1.0)
			_assert_equal(build_manager.gold, 1, "villager completed chop grants one gold")
			_assert_false(villager.get("is_chopping_tree") == true, "villager stops chopping after completion")
			_assert_equal(villager.assigned_workplace_id, "cityhall", "villager returns to city hall after chopping")

		if is_instance_valid(tree):
			tree.free()
		root.free()

	if failures == 0:
		print("NPCTreeChopTest: PASS")
	else:
		push_error("NPCTreeChopTest: %d failure(s)" % failures)

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
