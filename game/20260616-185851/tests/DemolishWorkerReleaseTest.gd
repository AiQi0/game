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

		var factory := NPCFactory.new()
		var villager: Node2D = factory.create_homeless(Vector2(4500, 472), Vector2(4800, 472))
		villager.name = "Villager_01"
		villager.interact()
		villager.enter_building(Vector2(4600, 472), "铁匠铺", "blacksmith_1")
		npcs.add_child(villager)

		var building := Node2D.new()
		building.name = "blacksmith_1"
		building.global_position = Vector2(4600, 472)
		build_manager._track_placed_entity(building, Rect2(Vector2(4510, 332), Vector2(180, 140)), true, "铁匠铺", "building", true)
		_assert_true(build_manager.claim_work_site(0, "Villager_01"), "villager claims test building")
		_assert_true(build_manager.occupy_work_site("blacksmith_1", "Villager_01"), "villager enters test building")

		build_manager.demolition_target_index = 0
		build_manager._demolish_target()

		_assert_true(villager.visible, "demolishing occupied building releases villager model")
		_assert_false(villager.is_inside_building, "released villager is no longer inside building")
		_assert_equal(villager.global_position, Vector2(4600, 472), "released villager appears at demolished building")

		root.free()

	if failures == 0:
		print("DemolishWorkerReleaseTest: PASS")
	else:
		push_error("DemolishWorkerReleaseTest: %d failure(s)" % failures)

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
