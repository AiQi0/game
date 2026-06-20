extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	var monster_manager_script := load("res://scripts/MonsterManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")
	if monster_manager_script == null:
		_fail("MonsterManager.gd should load")

	if build_manager_script != null and npc_manager_script != null:
		_test_player_hit_and_revival(build_manager_script, npc_manager_script)
	if monster_manager_script != null:
		_test_revival_safe_nights_block_early_and_random_raids(monster_manager_script)

	if failures == 0:
		print("MonsterRevivalTest: PASS")
	else:
		push_error("MonsterRevivalTest: %d failure(s)" % failures)

	quit(failures)


func _test_player_hit_and_revival(build_manager_script: Script, npc_manager_script: Script) -> void:
	var root := Node2D.new()
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = Vector2(6200, 472)
	root.add_child(player)
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)
	var npcs := Node2D.new()
	npcs.name = "NPCs"
	root.add_child(npcs)
	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	root.add_child(build_manager)
	build_manager.player = player
	build_manager.buildings_container = buildings

	var npc_manager: Node2D = npc_manager_script.new()
	npc_manager.name = "NPCManager"
	root.add_child(npc_manager)
	npc_manager.npc_container = npcs

	for i in range(4):
		_add_building(build_manager, buildings, "work_%02d" % i, Vector2(3500 + i * 700, 472), "farm")

	for i in range(4):
		var villager := _make_villager("Villager_%02d" % i, Vector2(4800 + i * 24, 472))
		if i < 2:
			villager.equip_tool("axe")
		npcs.add_child(villager)

	build_manager.gold = 120
	_assert_true(build_manager.has_method("apply_player_monster_hit"), "BuildManager handles player monster hits")
	if build_manager.has_method("apply_player_monster_hit"):
		var hit_result: Dictionary = build_manager.apply_player_monster_hit()
		_assert_false(hit_result.get("died", false), "player survives when enough gold can be stolen")
		_assert_equal(hit_result.get("lost_gold", 0), 60, "monster steals half gold when above minimum")
		_assert_equal(build_manager.gold, 60, "player gold is reduced by monster hit")

	build_manager.gold = 40
	if build_manager.has_method("apply_player_monster_hit"):
		var death_result: Dictionary = build_manager.apply_player_monster_hit()
		_assert_true(death_result.get("died", false), "player dies when below minimum monster gold loss")
		_assert_true(build_manager.get("player_dead"), "death flag is set")

	_assert_true(build_manager.has_method("apply_revival_penalty"), "BuildManager applies revival penalty")
	if build_manager.has_method("apply_revival_penalty"):
		var penalty: Dictionary = build_manager.apply_revival_penalty(17)
		_assert_equal(build_manager.gold, 0, "revival removes all player gold")
		_assert_equal(penalty.get("damaged_buildings", []).size(), 2, "revival damages random half of non-cityhall buildings")
		_assert_equal(penalty.get("converted_villagers", []).size(), 2, "revival converts random half of villagers to homeless")
		_assert_equal(player.global_position, Vector2(4800, 472), "player revives at city hall")

		var damaged_index := int(penalty.get("damaged_buildings", [])[0])
		var damaged_entity: Dictionary = build_manager.placed_buildings[damaged_index]
		_assert_true(damaged_entity.get("damaged", false), "revival marks buildings as damaged")
		_assert_true(build_manager.has_method("repair_building"), "damaged buildings can be repaired")
		if build_manager.has_method("repair_building"):
			build_manager.gold = 99
			var repair_cost: int = build_manager.repair_cost_for_entity_index(damaged_index)
			_assert_true(build_manager.repair_building(damaged_index), "repair spends gold and clears damaged state")
			_assert_equal(build_manager.gold, 99 - repair_cost, "repair spends half building cost rounded up")
			_assert_false(build_manager.placed_buildings[damaged_index].get("damaged", true), "repair clears damaged state")

	root.free()


func _test_revival_safe_nights_block_early_and_random_raids(monster_manager_script: Script) -> void:
	var root := Node2D.new()
	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)

	var manager: Node2D = monster_manager_script.new()
	manager.name = "MonsterManager"
	root.add_child(manager)
	manager.monsters_container = monsters

	manager.begin_safe_nights(3)
	_assert_equal(manager.run_night_spawn(1), 0, "revival safe nights suppress first night fixed raid")
	_assert_equal(monsters.get_child_count(), 0, "first safe night creates no monsters")
	_assert_equal(manager.run_night_spawn(3), 0, "revival safe nights suppress third night random raid")
	_assert_equal(monsters.get_child_count(), 0, "third safe night creates no monsters")

	root.free()


func _add_building(build_manager: Node2D, buildings: Node2D, node_name: String, position: Vector2, building_id: String) -> void:
	var node := Node2D.new()
	node.name = node_name
	node.global_position = position
	buildings.add_child(node)
	build_manager._track_placed_entity(
		node,
		Rect2(position - Vector2(60, 50), Vector2(120, 100)),
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
