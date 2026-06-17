extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")
const WINDOW_DARK := Color(0.08, 0.1, 0.13, 1)
const WINDOW_LIT := Color(1.0, 0.82, 0.24, 1)

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

		var build_manager: Node2D = build_manager_script.new()
		build_manager.name = "BuildManager"
		root.add_child(build_manager)

		var npc_manager: Node2D = npc_manager_script.new()
		npc_manager.name = "NPCManager"
		root.add_child(npc_manager)
		npc_manager.npc_container = npcs

		var building := Node2D.new()
		building.name = "blacksmith_1"
		building.global_position = Vector2(4600, 472)
		var window := Polygon2D.new()
		window.name = "WindowMain"
		window.color = WINDOW_DARK
		building.add_child(window)
		build_manager._track_placed_entity(
			building,
			Rect2(Vector2(4510, 332), Vector2(180, 140)),
			true,
			"铁匠铺",
			"building",
			true
		)

		var factory := NPCFactory.new()
		var villager: Node2D = factory.create_homeless(Vector2(4400, 472), Vector2(4800, 472))
		villager.name = "Villager_01"
		villager.interact()
		npcs.add_child(villager)

		npc_manager._assign_workplace_to_villager(villager)
		_assert_true(villager.visible, "assigned villager remains visible before reaching building")
		_assert_false(villager.is_inside_building, "assigned villager is not inside immediately")
		_assert_true(villager.get("is_traveling_to_workplace") == true, "assigned villager starts walking to building")
		_assert_equal(villager.assigned_workplace_id, "blacksmith_1", "villager stores target building id")
		_assert_equal(build_manager.get_work_sites()[0].worker_id, "Villager_01", "walking villager reserves work site")
		_assert_equal(window.color, WINDOW_DARK, "reserved building window stays dark until villager enters")

		villager.global_position = Vector2(4600, 472)
		if npc_manager.has_method("_finish_arriving_workers"):
			npc_manager._finish_arriving_workers()
			_assert_false(villager.visible, "villager hides after arriving at building")
			_assert_true(villager.is_inside_building, "villager is inside after arriving")
			_assert_false(villager.get("is_traveling_to_workplace") == true, "villager clears travel state after entering")
			_assert_equal(window.color, WINDOW_LIT, "occupied building window lights after villager enters")
		else:
			_fail("NPCManager should finish workers after they reach building front")

		building.free()
		root.free()

	if failures == 0:
		print("VillagerWorkArrivalTest: PASS")
	else:
		push_error("VillagerWorkArrivalTest: %d failure(s)" % failures)

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
