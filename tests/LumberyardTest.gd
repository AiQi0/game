extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")
const GameData = preload("res://scripts/GameData.gd")
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

		var buildings := Node2D.new()
		buildings.name = "Buildings"
		root.add_child(buildings)

		var npcs := Node2D.new()
		npcs.name = "NPCs"
		root.add_child(npcs)

		var build_manager: Node2D = build_manager_script.new()
		build_manager.name = "BuildManager"
		root.add_child(build_manager)
		build_manager.buildings_container = buildings

		var npc_manager: Node2D = npc_manager_script.new()
		npc_manager.name = "NPCManager"
		root.add_child(npc_manager)
		npc_manager.npc_container = npcs

		_assert_true(build_manager.has_method("_update_lumberyards"), "BuildManager updates lumberyards")
		_assert_true(npc_manager.has_method("assign_lumberjack_tree_chop"), "NPCManager can dispatch a lumberjack")

		var lumberyard := _make_building("lumberyard_1", Vector2(3000, 472))
		buildings.add_child(lumberyard)
		build_manager._track_placed_entity(
			lumberyard,
			Rect2(Vector2(2900, 342), Vector2(200, 130)),
			true,
			"伐木场",
			"building",
			true,
			"lumberyard"
		)

		if build_manager.has_method("_update_lumberyards"):
			_test_lumberyard_stops_external_tree_growth(build_manager)

		var tree := Node2D.new()
		tree.name = "ManualTree"
		tree.global_position = Vector2(3260, 472)
		buildings.add_child(tree)
		build_manager._track_placed_entity(
			tree,
			Rect2(Vector2(3228, 352), Vector2(64, 120)),
			true,
			"树",
			"tree",
			false,
			"tree"
		)

		var factory := NPCFactory.new()
		var villager: Node2D = factory.create_homeless(Vector2(2800, 472), Vector2(4800, 472))
		villager.name = "Villager_01"
		villager.interact()
		npcs.add_child(villager)

		npc_manager._assign_workplace_to_villager(villager)
		villager.global_position = lumberyard.global_position
		npc_manager._finish_arriving_workers()
		_assert_equal(villager.get("worker_role"), "lumberjack", "villager becomes a lumberjack inside lumberyard")
		_assert_false(villager.visible, "lumberjack hides while waiting inside lumberyard")
		_assert_equal(_window_color(lumberyard), WINDOW_LIT, "occupied lumberyard window is lit")

		if build_manager.has_method("_update_lumberyards"):
			build_manager._update_lumberyards(0.0)
			_assert_false(villager.get("is_traveling_to_tree_chop") == true, "lumberjack no longer leaves main world lumberyard for automatic tree work")
			_assert_false(villager.visible, "lumberjack remains hidden while work moves to interior scene")
			_assert_equal(_window_color(lumberyard), WINDOW_LIT, "occupied lumberyard window stays lit while interior work owns production")
			_assert_true(build_manager.get_work_sites()[0].worker_inside, "lumberyard keeps worker inside for interior production")

		root.free()

		_test_lumberjack_dispatch_is_disabled_in_main_world(build_manager_script, npc_manager_script)

	if failures == 0:
		print("LumberyardTest: PASS")
	else:
		push_error("LumberyardTest: %d failure(s)" % failures)

	quit(failures)


func _test_lumberyard_stops_external_tree_growth(build_manager: Node2D) -> void:
	var before := _tree_count(build_manager)
	build_manager._update_lumberyards(119.0)
	_assert_equal(_tree_count(build_manager), before, "lumberyard waits two minutes before growing trees")
	build_manager._update_lumberyards(1.0)
	_assert_equal(_tree_count(build_manager), before, "main world lumberyard no longer grows external trees")
	_assert_equal(build_manager.tree_chop_tasks.size(), 0, "main world lumberyard no longer creates automatic chop tasks")


func _test_lumberjack_dispatch_is_disabled_in_main_world(build_manager_script: Script, npc_manager_script: Script) -> void:
	var root := Node2D.new()

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var npcs := Node2D.new()
	npcs.name = "NPCs"
	root.add_child(npcs)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	root.add_child(build_manager)
	build_manager.buildings_container = buildings

	var npc_manager: Node2D = npc_manager_script.new()
	npc_manager.name = "NPCManager"
	root.add_child(npc_manager)
	npc_manager.npc_container = npcs

	var lumberyard_position := Vector2(3000, 472)
	var lumberyard := _make_building("lumberyard_range_test", lumberyard_position)
	buildings.add_child(lumberyard)
	build_manager._track_placed_entity(
		lumberyard,
		Rect2(Vector2(2900, 342), Vector2(200, 130)),
		true,
		"Lumberyard",
		"building",
		true,
		"lumberyard"
	)

	var far_tree_position := lumberyard_position + Vector2(GameData.LUMBERYARD_TREE_RADIUS * 2.0 - 40.0, 0)
	var far_tree := Node2D.new()
	far_tree.name = "FarRangeTree"
	far_tree.global_position = far_tree_position
	buildings.add_child(far_tree)
	build_manager._track_placed_entity(
		far_tree,
		Rect2(far_tree_position - Vector2(GameData.TREE_SIZE.x * 0.5, GameData.TREE_SIZE.y), GameData.TREE_SIZE),
		true,
		"Tree",
		"tree",
		false,
		"tree",
		"tree"
	)

	var factory := NPCFactory.new()
	var villager: Node2D = factory.create_homeless(lumberyard_position, Vector2(4800, 472))
	villager.name = "Villager_Range"
	villager.interact()
	npcs.add_child(villager)

	npc_manager._assign_workplace_to_villager(villager)
	villager.global_position = lumberyard_position
	npc_manager._finish_arriving_workers()

	build_manager._update_lumberyards(0.0)
	_assert_equal(build_manager.tree_chop_tasks.size(), 0, "main world lumberyard does not dispatch external tree work")

	root.free()


func _tree_count(build_manager: Node2D) -> int:
	var count := 0
	for entity in build_manager.placed_buildings:
		if entity.get("entity_kind", "") == "tree":
			count += 1
	return count


func _make_building(node_name: String, position: Vector2) -> Node2D:
	var building := Node2D.new()
	building.name = node_name
	building.global_position = position
	var window := Polygon2D.new()
	window.name = "WindowMain"
	window.color = WINDOW_DARK
	building.add_child(window)
	return building


func _window_color(building: Node) -> Color:
	var window := building.get_node_or_null("WindowMain") as Polygon2D
	return Color.TRANSPARENT if window == null else window.color


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
