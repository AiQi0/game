extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	var npc_factory_script := load("res://scripts/NPCFactory.gd")

	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")
	if npc_factory_script == null:
		_fail("NPCFactory.gd should load")

	if build_manager_script != null and npc_manager_script != null and npc_factory_script != null:
		_test_tavern_attracts_three_homeless(build_manager_script, npc_manager_script, npc_factory_script.new())

	if failures == 0:
		print("TavernAttractionTest: PASS")
	else:
		push_error("TavernAttractionTest: %d failure(s)" % failures)

	quit(failures)


func _test_tavern_attracts_three_homeless(build_manager_script: Script, npc_manager_script: Script, factory) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager: Node2D = setup.npc_manager
	var npcs: Node2D = setup.npcs
	var tavern_position := Vector2(5200, 472)

	var tavern := Node2D.new()
	tavern.name = "tavern_1"
	tavern.global_position = tavern_position
	setup.buildings.add_child(tavern)
	setup.build_manager._track_placed_entity(
		tavern,
		Rect2(tavern_position - Vector2(190, 150), Vector2(380, 300)),
		true,
		"酒馆",
		"building",
		true,
		"tavern"
	)

	for i in range(4):
		var homeless: Node2D = factory.create_homeless(Vector2(4000 + i * 60, 472), Vector2(4800, 472))
		homeless.name = "Homeless_%02d" % [i + 1]
		npcs.add_child(homeless)

	_assert_true(manager.has_method("_assign_homeless_to_taverns"), "NPCManager can assign homeless to taverns")
	_assert_true(manager.has_method("_finish_arriving_tavern_homeless"), "NPCManager finishes tavern-bound homeless")
	if not manager.has_method("_assign_homeless_to_taverns"):
		setup.root.free()
		return

	manager._assign_homeless_to_taverns()

	var attracted := _homeless_assigned_to(npcs, "tavern_1")
	_assert_equal(attracted.size(), 3, "one tavern attracts at most three homeless")
	_assert_equal(_unassigned_homeless_count(npcs), 1, "one homeless remains unassigned after tavern reaches capacity")
	for npc in attracted:
		_assert_equal(npc.get("target_position"), tavern_position, "attracted homeless walks to tavern front")
		_assert_true(bool(npc.get("is_traveling_to_workplace")), "attracted homeless is traveling")

	for npc in attracted:
		npc.global_position = tavern_position
	manager._finish_arriving_tavern_homeless()

	for npc in attracted:
		_assert_equal(str(npc.get("npc_type")), "homeless", "tavern visitor remains homeless")
		_assert_false(bool(npc.get("is_inside_building")), "tavern visitor does not enter building")
		_assert_false(bool(npc.get("is_traveling_to_workplace")), "tavern visitor stops traveling after arrival")
		_assert_equal(npc.get("home_center"), tavern_position, "tavern visitor wanders at tavern front")

	setup.root.free()


func _create_world(build_manager_script: Script, npc_manager_script: Script) -> Dictionary:
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

	return {
		"root": root,
		"buildings": buildings,
		"npcs": npcs,
		"build_manager": build_manager,
		"npc_manager": npc_manager,
	}


func _homeless_assigned_to(npcs: Node2D, workplace_id: String) -> Array:
	var assigned := []
	for child in npcs.get_children():
		if child.get("npc_type") == "homeless" and child.get("assigned_workplace_id") == workplace_id:
			assigned.append(child)
	return assigned


func _unassigned_homeless_count(npcs: Node2D) -> int:
	var count := 0
	for child in npcs.get_children():
		if child.get("npc_type") == "homeless" and str(child.get("assigned_workplace_id")) == "":
			count += 1
	return count


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
