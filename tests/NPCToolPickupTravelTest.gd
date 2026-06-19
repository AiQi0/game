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

		var supports_tool_travel := (
			build_manager.has_method("reserve_tool_for_role")
			and build_manager.has_method("claim_reserved_tool_for_worker")
			and build_manager.has_method("worker_leaves_work_site")
			and npc_manager.has_method("_finish_tool_pickup_travelers")
		)
		_assert_true(build_manager.has_method("reserve_tool_for_role"), "BuildManager reserves tools for worker pickup")
		_assert_true(build_manager.has_method("claim_reserved_tool_for_worker"), "BuildManager lets workers claim reserved tools")
		_assert_true(build_manager.has_method("worker_leaves_work_site"), "BuildManager marks workers outside while fetching tools")
		_assert_true(npc_manager.has_method("_finish_tool_pickup_travelers"), "NPCManager finishes tool pickup trips")

		var blacksmith := _make_building("blacksmith_1", Vector2(3000, 472))
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
		var blacksmith_entity: Dictionary = build_manager.placed_buildings[0]
		build_manager._spawn_tool_at_building(blacksmith_entity, "sickle")

		var farm := _make_building("farm_1", Vector2(3400, 472))
		buildings.add_child(farm)
		build_manager._track_placed_entity(
			farm,
			Rect2(Vector2(3290, 412), Vector2(220, 60)),
			true,
			"农田",
			"building",
			true,
			"farm"
		)

		var farmer := _make_villager("Villager_farmer_tool", farm.global_position)
		farmer.become_farmer()
		npcs.add_child(farmer)
		_assert_true(build_manager.claim_work_site(1, farmer.name), "farmer claims farm")
		_assert_true(build_manager.occupy_work_site("farm_1", farmer.name), "farmer occupies farm")
		farmer.enter_building(farm.global_position, "农田", "farm_1")

		if supports_tool_travel:
			npc_manager._equip_workers_from_tools()
			_assert_equal(farmer.get("carried_tool"), "", "farmer does not instantly equip sickle")
			_assert_true(farmer.get("is_traveling_to_tool_pickup") == true, "farmer travels to blacksmith for sickle")
			_assert_false(farmer.get("is_inside_building"), "farmer leaves farm while fetching tool")
			_assert_false(_worker_inside(build_manager, "farm_1"), "farm records worker outside during tool pickup")
			_assert_equal(build_manager.tool_count_for_building("blacksmith_1"), 1, "reserved tool stays at blacksmith until pickup")

			build_manager.gold = 0
			build_manager._update_farm_income(60.0)
			_assert_equal(build_manager.gold, 0, "farm does not produce while farmer is fetching tool")

			farmer.global_position = blacksmith.global_position
			npc_manager._finish_tool_pickup_travelers()
			_assert_equal(farmer.get("carried_tool"), "sickle", "farmer equips sickle at blacksmith")
			_assert_true(farmer.get("is_traveling_to_workplace") == true, "farmer returns to farm after pickup")
			_assert_equal(farmer.get("assigned_workplace_id"), "farm_1", "farmer keeps original workplace after pickup")
			_assert_equal(build_manager.tool_count_for_building("blacksmith_1"), 0, "tool leaves blacksmith inventory after pickup")

			farmer.global_position = farm.global_position
			npc_manager._finish_arriving_workers()
			_assert_true(farmer.get("is_inside_building"), "farmer re-enters farm after returning")
			_assert_true(_worker_inside(build_manager, "farm_1"), "farm records returned worker inside")

			build_manager.gold = 0
			build_manager._update_farm_income(40.0)
			_assert_equal(build_manager.gold, 1, "returned farmer uses wood sickle efficiency")

		root.free()

	if failures == 0:
		print("NPCToolPickupTravelTest: PASS")
	else:
		push_error("NPCToolPickupTravelTest: %d failure(s)" % failures)

	quit(failures)


func _make_building(node_name: String, position: Vector2) -> Node2D:
	var building := Node2D.new()
	building.name = node_name
	building.global_position = position
	return building


func _make_villager(npc_name: String, position: Vector2) -> Node2D:
	var factory := NPCFactory.new()
	var npc: Node2D = factory.create_homeless(position, Vector2(4800, 472))
	npc.name = npc_name
	npc.interact()
	return npc


func _worker_inside(build_manager: Node2D, workplace_id: String) -> bool:
	for site in build_manager.get_work_sites():
		if site.get("workplace_id", "") == workplace_id:
			return site.get("worker_inside", false)
	return false


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
