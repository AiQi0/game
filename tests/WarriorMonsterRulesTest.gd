extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	var monster_rules_script := load("res://scripts/MonsterRules.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")
	if monster_rules_script == null:
		_fail("MonsterRules.gd should load")

	if build_manager_script != null:
		var build_manager: Node2D = build_manager_script.new()
		_assert_equal(build_manager.get("gold"), 99, "game starts with 99 gold")
		build_manager.free()

	_test_sword_equips_warrior()

	if build_manager_script != null and npc_manager_script != null:
		_test_warrior_patrol_balance(build_manager_script, npc_manager_script)

	if monster_rules_script != null:
		_test_monster_spawn_rules(monster_rules_script)

	if failures == 0:
		print("WarriorMonsterRulesTest: PASS")
	else:
		push_error("WarriorMonsterRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_sword_equips_warrior() -> void:
	var npc := _make_villager("Villager_sword", Vector2(4800, 472))
	npc.equip_tool("sword")
	_assert_equal(npc.get("worker_role"), "warrior", "equipping sword turns villager into warrior")
	_assert_equal(npc.get("carried_tool"), "sword", "warrior carries sword")
	_assert_equal(npc.get("attack_power"), 2, "warrior attack power is 2")
	npc.free()


func _test_warrior_patrol_balance(build_manager_script: Script, npc_manager_script: Script) -> void:
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

	_add_building(build_manager, buildings, "farm_left", Vector2(3200, 472), "farm")
	_add_building(build_manager, buildings, "wall_right", Vector2(6100, 472), "wall")
	_add_building(build_manager, buildings, "tavern_right_far", Vector2(7600, 472), "tavern")

	for i in range(3):
		var warrior := _make_villager("Warrior_%02d" % i, Vector2(4800 + i * 20, 472))
		warrior.equip_tool("sword")
		npcs.add_child(warrior)

	_assert_true(npc_manager.has_method("_assign_warrior_patrols"), "NPCManager assigns warrior patrols")
	if npc_manager.has_method("_assign_warrior_patrols"):
		npc_manager._assign_warrior_patrols()
		var left_count := 0
		var right_count := 0
		for child in npcs.get_children():
			if child.get("patrol_side") == "left":
				left_count += 1
				_assert_equal(child.get("patrol_anchor").x, 3200.0, "left warriors patrol the farthest left building")
			elif child.get("patrol_side") == "right":
				right_count += 1
				_assert_equal(child.get("patrol_anchor").x, 7600.0, "right warriors patrol the farthest right building")
		_assert_true(abs(left_count - right_count) <= 1, "warrior sides stay balanced")

	root.free()


func _test_monster_spawn_rules(monster_rules_script: Script) -> void:
	var rules = monster_rules_script.new()
	_assert_false(rules.should_spawn_side(2, 0.0, 0), "monsters do not spawn before the third night")
	_assert_true(rules.should_spawn_side(3, 0.19, 0), "third night spawns when side roll is below twenty percent")
	_assert_false(rules.should_spawn_side(3, 0.2, 0), "twenty percent roll does not spawn")
	_assert_false(rules.should_spawn_side(5, 0.0, 1), "safe nights suppress monster spawning")
	var count: int = rules.spawn_count_from_seed(42)
	_assert_true(count >= 1 and count <= 4, "monster spawn count is between one and four")
	_assert_equal(rules.gold_loss_for_player_hit(120), 60, "monster steals half of high player gold")
	_assert_equal(rules.gold_loss_for_player_hit(80), 50, "monster steals at least fifty gold")
	_assert_true(rules.player_dies_from_gold_hit(49), "player dies when unable to pay minimum loss")


func _add_building(build_manager: Node2D, buildings: Node2D, node_name: String, position: Vector2, building_id: String) -> void:
	var node := Node2D.new()
	node.name = node_name
	node.global_position = position
	buildings.add_child(node)
	build_manager._track_placed_entity(
		node,
		Rect2(position - Vector2(50, 50), Vector2(100, 100)),
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
