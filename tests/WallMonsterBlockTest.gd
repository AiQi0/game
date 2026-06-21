extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var monster_manager_script := load("res://scripts/MonsterManager.gd")

	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if monster_manager_script == null:
		_fail("MonsterManager.gd should load")

	if build_manager_script != null:
		_test_wall_health_and_damage(build_manager_script)
	if build_manager_script != null and monster_manager_script != null:
		_test_monster_targets_wall_before_player(build_manager_script, monster_manager_script)

	if failures == 0:
		print("WallMonsterBlockTest: PASS")
	else:
		push_error("WallMonsterBlockTest: %d failure(s)" % failures)

	quit(failures)


func _test_wall_health_and_damage(build_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script)
	var build_manager: Node2D = setup.build_manager

	_add_building(build_manager, setup.buildings, "wall_health_1", Vector2(5050, 472), "wall")
	_assert_true(build_manager.has_method("wall_health_for_entity_index"), "BuildManager exposes wall health")
	_assert_true(build_manager.has_method("damage_wall_by_monster"), "BuildManager lets monsters damage walls")
	if not build_manager.has_method("wall_health_for_entity_index") or not build_manager.has_method("damage_wall_by_monster"):
		setup.root.free()
		return

	_assert_equal(build_manager.wall_health_for_entity_index(0), 20, "level one wall starts with 20 health")
	build_manager.placed_buildings[0].level = 2
	_assert_equal(build_manager.wall_max_health_for_entity_index(0), 40, "level two wall max health is 40")
	build_manager.placed_buildings[0].level = 1

	_assert_true(build_manager.damage_wall_by_monster("wall_health_1", 19), "wall accepts monster damage")
	_assert_equal(build_manager.wall_health_for_entity_index(0), 1, "wall keeps remaining health")
	_assert_true(build_manager.damage_wall_by_monster("wall_health_1", 1), "last wall health point can be damaged")
	_assert_true(bool(build_manager.placed_buildings[0].get("damaged", false)), "wall becomes damaged at zero health")

	setup.root.free()


func _test_monster_targets_wall_before_player(build_manager_script: Script, monster_manager_script: Script) -> void:
	var setup := _create_world(build_manager_script)
	var root: Node2D = setup.root
	var build_manager: Node2D = setup.build_manager

	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(5150, 472)
	root.add_child(player)

	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)

	_add_building(build_manager, setup.buildings, "wall_block_1", Vector2(5030, 472), "wall")

	var monster_manager: Node2D = monster_manager_script.new()
	monster_manager.name = "MonsterManager"
	root.add_child(monster_manager)
	monster_manager.player = player
	monster_manager.build_manager = build_manager
	monster_manager.monsters_container = monsters

	var monster: Node2D = monster_manager.spawn_monster("left", 0)
	monster.global_position = Vector2(5000, 472)
	var target: Node2D = monster_manager._nearest_attack_target(monster.global_position, int(monster.get("direction")))
	_assert_true(target != null, "monster finds a target")
	if target != null:
		_assert_equal(target.name, "wall_block_1", "monster targets blocking wall before player")

	monster.set("state", "charging")
	monster.set("attack_target", target)
	monster.set("charge_elapsed", 1.0)
	monster_manager._update_attacking_monster(monster, 0.0)
	monster_manager._update_attacking_monster(monster, 1.0)
	_assert_equal(build_manager.wall_health_for_entity_index(0), 19, "monster hit damages wall instead of player")

	setup.root.free()


func _create_world(build_manager_script: Script) -> Dictionary:
	var root := Node2D.new()
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	root.add_child(build_manager)
	build_manager.buildings_container = buildings

	return {
		"root": root,
		"buildings": buildings,
		"build_manager": build_manager,
	}


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


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
