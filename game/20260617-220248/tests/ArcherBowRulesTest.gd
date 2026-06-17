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

	_test_bow_equips_archer()

	if build_manager_script != null and npc_manager_script != null:
		_test_archer_patrol_balance(build_manager_script, npc_manager_script)
		_test_wall_accepts_only_archers(build_manager_script, npc_manager_script)
		_test_archer_enters_wall_top(build_manager_script, npc_manager_script)

	if failures == 0:
		print("ArcherBowRulesTest: PASS")
	else:
		push_error("ArcherBowRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_bow_equips_archer() -> void:
	var npc := _make_villager("Villager_bow", Vector2(4800, 472))
	npc.equip_tool("bow")
	_assert_equal(npc.get("worker_role"), "archer", "equipping bow turns villager into archer")
	_assert_equal(npc.get("carried_tool"), "bow", "archer carries bow")
	_assert_equal(npc.get("attack_power"), 1, "archer attack power is 1")
	_assert_equal(_float_value(npc.get("attack_range")), 600.0, "archer ground attack range is 600")
	npc.free()


func _test_archer_patrol_balance(build_manager_script: Script, npc_manager_script: Script) -> void:
	var root := _make_root(build_manager_script, npc_manager_script)
	var buildings: Node2D = root.get_node("Buildings")
	var npcs: Node2D = root.get_node("NPCs")
	var build_manager: Node2D = root.get_node("BuildManager")
	var npc_manager: Node2D = root.get_node("NPCManager")

	_add_building(build_manager, buildings, "farm_left", Vector2(3200, 472), "farm")
	_add_building(build_manager, buildings, "wall_right", Vector2(6100, 472), "wall")
	_add_building(build_manager, buildings, "tavern_right_far", Vector2(7600, 472), "tavern")

	for i in range(3):
		var archer := _make_villager("Archer_%02d" % i, Vector2(4800 + i * 20, 472))
		archer.equip_tool("bow")
		npcs.add_child(archer)

	_assert_true(npc_manager.has_method("_assign_archer_patrols"), "NPCManager assigns archer patrols")
	if npc_manager.has_method("_assign_archer_patrols"):
		npc_manager._assign_archer_patrols()
		var left_count := 0
		var right_count := 0
		for child in npcs.get_children():
			if child.get("patrol_side") == "left":
				left_count += 1
				_assert_equal(child.get("patrol_anchor").x, 3200.0, "left archers patrol the farthest left building")
			elif child.get("patrol_side") == "right":
				right_count += 1
				_assert_equal(child.get("patrol_anchor").x, 7600.0, "right archers patrol the farthest right building")
		_assert_true(abs(left_count - right_count) <= 1, "archer sides stay balanced")

	root.free()


func _test_wall_accepts_only_archers(build_manager_script: Script, npc_manager_script: Script) -> void:
	var root := _make_root(build_manager_script, npc_manager_script)
	var buildings: Node2D = root.get_node("Buildings")
	var npcs: Node2D = root.get_node("NPCs")
	var build_manager: Node2D = root.get_node("BuildManager")

	_add_building(build_manager, buildings, "wall_1", Vector2(5200, 472), "wall")
	var villager := _make_villager("Villager_plain_wall", Vector2(5200, 472))
	var archer := _make_villager("Villager_archer_wall", Vector2(5200, 472))
	archer.equip_tool("bow")
	npcs.add_child(villager)
	npcs.add_child(archer)

	var plain_claimed: bool = build_manager.claim_work_site(0, villager.name)
	_assert_false(plain_claimed, "non-archer cannot claim wall work site")
	if plain_claimed:
		build_manager.release_work_site_for_worker(villager.name)
	_assert_true(build_manager.claim_work_site(0, archer.name), "archer can claim wall work site")
	_assert_true(build_manager.occupy_work_site("wall_1", archer.name), "archer can occupy wall work site")

	root.free()


func _test_archer_enters_wall_top(build_manager_script: Script, npc_manager_script: Script) -> void:
	var root := _make_root(build_manager_script, npc_manager_script)
	var buildings: Node2D = root.get_node("Buildings")
	var npcs: Node2D = root.get_node("NPCs")
	var build_manager: Node2D = root.get_node("BuildManager")
	var npc_manager: Node2D = root.get_node("NPCManager")

	var wall_position := Vector2(5400, 472)
	_add_building(build_manager, buildings, "wall_2", wall_position, "wall")
	var archer := _make_villager("Archer_wall_top", wall_position)
	archer.equip_tool("bow")
	npcs.add_child(archer)

	npc_manager._assign_workplace_to_villager(archer)
	archer.global_position = wall_position
	npc_manager._finish_arriving_workers()
	_assert_true(archer.get("is_inside_building"), "archer is recorded as assigned inside wall")
	_assert_true(archer.visible, "archer remains visible on top of wall")
	_assert_true(archer.get("is_on_wall") == true, "archer records wall-top state")
	_assert_true(archer.global_position.y < wall_position.y - 70.0, "archer stands on top of the wall")
	_assert_equal(_float_value(archer.get("attack_range")), 900.0, "wall-top archer attack range is 900")
	_assert_true(_worker_inside(build_manager, "wall_2"), "wall records archer inside")

	root.free()


func _make_root(build_manager_script: Script, npc_manager_script: Script) -> Node2D:
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
	return root


func _add_building(build_manager: Node2D, buildings: Node2D, node_name: String, position: Vector2, building_id: String) -> void:
	var node := Node2D.new()
	node.name = node_name
	node.global_position = position
	buildings.add_child(node)
	build_manager._track_placed_entity(
		node,
		Rect2(position - Vector2(60, 100), Vector2(120, 100)),
		true,
		building_id,
		"building",
		true,
		building_id
	)


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


func _float_value(value) -> float:
	if value == null:
		return -1.0
	return float(value)


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
