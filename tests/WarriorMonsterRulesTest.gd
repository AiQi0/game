extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	var monster_rules_script := load("res://scripts/MonsterRules.gd")
	var monster_manager_script := load("res://scripts/MonsterManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")
	if monster_rules_script == null:
		_fail("MonsterRules.gd should load")
	if monster_manager_script == null:
		_fail("MonsterManager.gd should load")

	if build_manager_script != null:
		var build_manager: Node2D = build_manager_script.new()
		_assert_equal(build_manager.get("gold"), 30, "game starts with 30 gold")
		build_manager.free()

	_test_sword_equips_warrior()

	if build_manager_script != null and npc_manager_script != null:
		_test_warrior_patrol_balance(build_manager_script, npc_manager_script)

	if monster_rules_script != null:
		_test_monster_spawn_rules(monster_rules_script)
	if monster_manager_script != null:
		_test_monster_manager_early_nights(monster_manager_script)

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
	_assert_false(rules.should_spawn_side(0, 0.0, 0), "night zero does not spawn monsters")
	_assert_true(rules.should_spawn_side(1, 1.0, 0), "first night fixed raid ignores side roll")
	_assert_true(rules.should_spawn_side(2, 1.0, 0), "second night fixed raid ignores side roll")
	_assert_true(rules.should_spawn_side(3, 0.39, 0), "third night spawns when side roll is below forty percent")
	_assert_false(rules.should_spawn_side(3, 0.4, 0), "forty percent roll does not spawn")
	_assert_false(rules.should_spawn_side(5, 0.0, 1), "safe nights suppress monster spawning")
	var count: int = rules.spawn_count_from_seed(42)
	_assert_true(count >= 3 and count <= 6, "monster spawn count is between three and six")
	_assert_equal(rules.spawn_count_for_side(1, "left", 1.0, 42, 0), 1, "first night left side spawns one monster")
	_assert_equal(rules.spawn_count_for_side(1, "right", 1.0, 42, 0), 1, "first night right side spawns one monster")
	_assert_equal(rules.spawn_count_for_side(2, "left", 1.0, 42, 0), 1, "second night left side spawns one monster")
	_assert_equal(rules.spawn_count_for_side(2, "right", 1.0, 42, 0), 1, "second night right side spawns one monster")
	_assert_equal(rules.spawn_count_for_side(1, "left", 0.0, 42, 1), 0, "safe nights suppress first night fixed raid")
	_assert_equal(rules.spawn_count_for_side(3, "left", 0.4, 42, 0), 0, "third night side does not spawn at forty percent roll")
	var random_count: int = rules.spawn_count_for_side(3, "left", 0.39, 42, 0)
	_assert_true(random_count >= 3 and random_count <= 6, "third night successful side spawns three to six monsters")
	_assert_equal(rules.gold_loss_for_player_hit(120), 60, "monster steals half of high player gold")
	_assert_equal(rules.gold_loss_for_player_hit(80), 50, "monster steals at least fifty gold")
	_assert_true(rules.player_dies_from_gold_hit(49), "player dies when unable to pay minimum loss")


func _test_monster_manager_early_nights(monster_manager_script: Script) -> void:
	var root := Node2D.new()
	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)

	var manager: Node2D = monster_manager_script.new()
	manager.name = "MonsterManager"
	root.add_child(manager)
	manager.monsters_container = monsters

	_assert_equal(manager.run_night_spawn(1), 2, "first night spawns one monster from each side")
	_assert_equal(_monster_count_for_side(monsters, "left"), 1, "first night has one left monster")
	_assert_equal(_monster_count_for_side(monsters, "right"), 1, "first night has one right monster")
	_clear_children(monsters)

	_assert_equal(manager.run_night_spawn(2), 2, "second night spawns one monster from each side")
	_assert_equal(_monster_count_for_side(monsters, "left"), 1, "second night has one left monster")
	_assert_equal(_monster_count_for_side(monsters, "right"), 1, "second night has one right monster")
	_clear_children(monsters)

	manager.begin_safe_nights(3)
	_assert_equal(manager.run_night_spawn(1), 0, "safe nights suppress fixed first night raid")
	_assert_equal(monsters.get_child_count(), 0, "safe first night creates no monsters")
	_assert_equal(manager.run_night_spawn(3), 0, "safe nights suppress random third night raid")
	_assert_equal(monsters.get_child_count(), 0, "safe third night creates no monsters")

	root.free()


func _monster_count_for_side(monsters: Node2D, side: String) -> int:
	var count := 0
	for monster in monsters.get_children():
		if monster.get("side") == side:
			count += 1
	return count


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()


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
