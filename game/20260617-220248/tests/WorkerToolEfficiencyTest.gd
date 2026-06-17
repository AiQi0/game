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

		_assert_true(npc_manager.has_method("worker_has_tool"), "NPCManager reports worker tools")
		_assert_true(npc_manager.has_method("_equip_workers_from_tools"), "NPCManager equips workers from blacksmith tools")

		_test_workers_pick_matching_tools(build_manager, npc_manager, npcs, buildings)
		_test_farmer_role_and_sickle_income(build_manager, npc_manager, npcs, buildings)
		_test_tree_chop_duration_and_axe(build_manager, npc_manager, npcs, buildings)

		root.free()

	if failures == 0:
		print("WorkerToolEfficiencyTest: PASS")
	else:
		push_error("WorkerToolEfficiencyTest: %d failure(s)" % failures)

	quit(failures)


func _test_workers_pick_matching_tools(build_manager: Node2D, npc_manager: Node2D, npcs: Node2D, buildings: Node2D) -> void:
	var blacksmith := Node2D.new()
	blacksmith.name = "blacksmith_1"
	blacksmith.global_position = Vector2(3000, 472)
	buildings.add_child(blacksmith)
	build_manager._track_placed_entity(
		blacksmith,
		Rect2(Vector2(2910, 332), Vector2(180, 140)),
		true,
		"铁匠铺",
		"building",
		true,
		"blacksmith"
	)
	var blacksmith_entity: Dictionary = build_manager.placed_buildings[build_manager.placed_buildings.size() - 1]
	build_manager._spawn_tool_at_building(blacksmith_entity, "sword")
	build_manager._spawn_tool_at_building(blacksmith_entity, "axe")
	build_manager._spawn_tool_at_building(blacksmith_entity, "sickle")

	var villager := _make_villager("Villager_pick_sword", Vector2(3020, 472))
	var lumberjack := _make_villager("Villager_pick_axe", Vector2(3040, 472))
	var farmer := _make_villager("Villager_pick_sickle", Vector2(3060, 472))
	lumberjack.become_lumberjack()
	farmer.become_farmer()
	npcs.add_child(villager)
	npcs.add_child(lumberjack)
	npcs.add_child(farmer)

	npc_manager._equip_workers_from_tools()
	_assert_equal(villager.get("carried_tool"), "", "villager does not instantly pick up sword outside a workplace")
	_assert_equal(lumberjack.get("carried_tool"), "", "lumberjack does not instantly pick up axe outside a workplace")
	_assert_equal(farmer.get("carried_tool"), "", "farmer does not instantly pick up sickle outside a workplace")
	_assert_equal(build_manager.tool_count_for_building("blacksmith_1"), 3, "tools stay at blacksmith until workers travel there")


func _test_farmer_role_and_sickle_income(build_manager: Node2D, npc_manager: Node2D, npcs: Node2D, buildings: Node2D) -> void:
	var farm := Node2D.new()
	farm.name = "farm_1"
	farm.global_position = Vector2(3300, 472)
	buildings.add_child(farm)
	build_manager._track_placed_entity(
		farm,
		Rect2(Vector2(3190, 412), Vector2(220, 60)),
		true,
		"农田",
		"building",
		true,
		"farm"
	)

	var farmer := _make_villager("Villager_01", Vector2(3200, 472))
	npcs.add_child(farmer)
	npc_manager._assign_workplace_to_villager(farmer)
	farmer.global_position = farm.global_position
	npc_manager._finish_arriving_workers()
	_assert_equal(farmer.get("worker_role"), "farmer", "villager becomes farmer when entering farm")

	farmer.set("carried_tool", "sickle")
	build_manager.gold = 0
	build_manager._update_farm_income(29.0)
	_assert_equal(build_manager.gold, 0, "sickle does not pay before thirty seconds")
	build_manager._update_farm_income(1.0)
	_assert_equal(build_manager.gold, 1, "sickle doubles farm income speed")


func _test_tree_chop_duration_and_axe(build_manager: Node2D, npc_manager: Node2D, npcs: Node2D, buildings: Node2D) -> void:
	var plain_worker := _make_villager("Villager_02", Vector2(3500, 472))
	npcs.add_child(plain_worker)
	var plain_tree := _make_tree("Tree_plain", Vector2(3540, 472), build_manager, buildings)
	build_manager.demolition_target_index = build_manager._placed_entity_index_for_node(plain_tree)
	build_manager._demolish_target()
	plain_worker.global_position = plain_tree.global_position
	npc_manager._finish_arriving_tree_choppers()
	build_manager.gold = 0
	npc_manager._advance_tree_choppers(59.0)
	_assert_equal(build_manager.gold, 0, "base tree chopping takes sixty seconds")
	npc_manager._advance_tree_choppers(1.0)
	_assert_equal(build_manager.gold, 1, "base tree chopping finishes after sixty seconds")

	var axe_worker := _make_villager("Villager_03", Vector2(3700, 472))
	axe_worker.set("carried_tool", "axe")
	npcs.add_child(axe_worker)
	var axe_tree := _make_tree("Tree_axe", Vector2(3740, 472), build_manager, buildings)
	build_manager.demolition_target_index = build_manager._placed_entity_index_for_node(axe_tree)
	build_manager._demolish_target()
	axe_worker.global_position = axe_tree.global_position
	npc_manager._finish_arriving_tree_choppers()
	build_manager.gold = 0
	npc_manager._advance_tree_choppers(29.0)
	_assert_equal(build_manager.gold, 0, "axe does not finish before thirty seconds")
	npc_manager._advance_tree_choppers(1.0)
	_assert_equal(build_manager.gold, 1, "axe doubles tree chopping speed")


func _make_villager(npc_name: String, position: Vector2) -> Node2D:
	var factory := NPCFactory.new()
	var npc: Node2D = factory.create_homeless(position, Vector2(4800, 472))
	npc.name = npc_name
	npc.interact()
	return npc


func _make_tree(tree_name: String, position: Vector2, build_manager: Node2D, buildings: Node2D) -> Node2D:
	var tree := Node2D.new()
	tree.name = tree_name
	tree.global_position = position
	buildings.add_child(tree)
	build_manager._track_placed_entity(
		tree,
		Rect2(Vector2(position.x - 32.0, 352), Vector2(64, 120)),
		true,
		"树",
		"tree",
		false,
		"tree"
	)
	return tree


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
