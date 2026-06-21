extends SceneTree

const GameData = preload("res://scripts/GameData.gd")

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_script := load("res://scripts/NPC.gd")
	var interior_script := load("res://scripts/BuildingInteriorManager.gd")
	var data := GameData.new()

	_test_barracks_data(data)
	if build_manager_script != null:
		_test_barracks_work_site_capacity(build_manager_script)
	if npc_script != null:
		_test_soldier_role_and_spear_tools(npc_script, data)
	if interior_script != null:
		_test_barracks_interior_training(interior_script, data)

	if failures == 0:
		print("BarracksTrainingTest: PASS")
	else:
		push_error("BarracksTrainingTest: %d failure(s)" % failures)
	quit(failures)


func _test_barracks_data(data: GameData) -> void:
	_assert_equal(data.barracks_capacity_for_level(1), 10, "level one barracks holds ten soldiers")
	_assert_equal(data.barracks_capacity_for_level(2), 15, "level two barracks holds fifteen soldiers")
	_assert_equal(data.barracks_capacity_for_level(3), 20, "level three barracks holds twenty soldiers")
	_assert_equal(data.barracks_training_level_for_elapsed(3599.0), 0, "soldier has no level before first hour")
	_assert_equal(data.barracks_training_level_for_elapsed(3600.0), 1, "soldier reaches level one after one hour")
	_assert_equal(data.barracks_training_level_for_elapsed(10800.0), 2, "soldier reaches level two after two more hours")
	_assert_equal(data.barracks_training_level_for_elapsed(25200.0), 3, "soldier reaches level three after four more hours")
	_assert_equal(data.barracks_stat_multiplier_for_level(1), 2.0, "soldier level one doubles base stats")
	_assert_equal(data.barracks_stat_multiplier_for_level(2), 3.0, "soldier level two triples base stats")
	_assert_equal(data.barracks_stat_multiplier_for_level(3), 4.0, "soldier level three quadruples base stats")
	_assert_equal(data.blacksmith_craft_tool_ids(2), ["stone_sword", "stone_pickaxe", "stone_sickle", "bow", "stone_arrowhead", "stone_spear"], "level two blacksmith crafts stone spear")
	_assert_equal(data.blacksmith_craft_tool_ids(3), ["iron_sword", "iron_pickaxe", "iron_sickle", "bow", "iron_arrowhead", "iron_spear"], "level three blacksmith crafts iron spear")
	_assert_equal(data.tool_ids_for_role("soldier"), ["iron_spear", "stone_spear"], "soldier tool choices are data-driven")
	_assert_equal(data.tool_value("stone_spear", "soldier_attack_bonus"), 0.3, "stone spear attack bonus is data-driven")
	_assert_equal(data.tool_value("iron_spear", "soldier_health_bonus"), 0.5, "iron spear health bonus is data-driven")
	_assert_equal(data.building_interior_value("barracks", "layout"), "barracks", "barracks interior layout is data-driven")
	_assert_equal(data.building_interior_value("barracks", "columns"), 5, "barracks training columns are data-driven")
	_assert_equal(data.building_interior_value("barracks", "rows"), 4, "barracks training rows are data-driven")


func _test_barracks_work_site_capacity(build_manager_script: Script) -> void:
	var root := Node2D.new()
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)
	var manager: Node = build_manager_script.new()
	root.add_child(manager)
	manager.buildings_container = buildings

	var node := Node2D.new()
	node.name = "Barracks_1"
	node.global_position = Vector2(4800, 472)
	buildings.add_child(node)
	manager.placed_buildings.append({
		"node": node,
		"building_id": "barracks",
		"display_name": "barracks",
		"is_workplace": true,
		"level": 2,
		"worker_ids": [],
		"workers_inside": [],
		"damaged": false,
	})
	var sites: Array = manager.get_work_sites()
	_assert_equal(sites.size(), 1, "barracks is exposed as a work site")
	_assert_equal(sites[0].get("worker_capacity", 0), 15, "level two barracks exposes fifteen worker slots")
	for i in range(15):
		_assert_true(manager.claim_work_site(0, "Soldier_%02d" % i), "barracks accepts soldier slot %d" % i)
	_assert_false(manager.claim_work_site(0, "Soldier_Overflow"), "barracks rejects workers over capacity")
	root.free()


func _test_soldier_role_and_spear_tools(npc_script: Script, data: GameData) -> void:
	var npc: Node = npc_script.new()
	npc.setup(Vector2(100, 472), Vector2(4800, 472))
	npc.interact()
	npc.become_soldier()
	_assert_equal(npc.get("worker_role"), "soldier", "villager becomes soldier")
	_assert_false(bool(npc.get("is_patrolling")), "soldier does not start patrol")
	_assert_equal(int(npc.get("soldier_level")), 0, "new soldier starts untrained")
	var base_attack := int(npc.get("attack_power"))
	var base_health := int(npc.get("max_health"))
	npc.set_soldier_training(3600.0)
	_assert_equal(int(npc.get("soldier_level")), 1, "training elapsed applies soldier level one")
	_assert_true(int(npc.get("attack_power")) > base_attack, "soldier training increases attack")
	_assert_true(int(npc.get("max_health")) > base_health, "soldier training increases health")
	var trained_attack := int(npc.get("attack_power"))
	var trained_health := int(npc.get("max_health"))
	npc.equip_tool("stone_spear")
	_assert_equal(npc.get("worker_role"), "soldier", "stone spear keeps soldier role")
	_assert_false(bool(npc.get("is_patrolling")), "stone spear does not send soldier to patrol")
	_assert_equal(int(npc.get("attack_power")), int(round(float(trained_attack) * 1.3)), "stone spear adds thirty percent attack")
	_assert_equal(int(npc.get("max_health")), int(round(float(trained_health) * 1.3)), "stone spear adds thirty percent health")
	npc.equip_tool("iron_spear")
	_assert_equal(int(npc.get("attack_power")), int(round(float(trained_attack) * 1.5)), "iron spear adds fifty percent attack")
	_assert_equal(int(npc.get("max_health")), int(round(float(trained_health) * 1.5)), "iron spear adds fifty percent health")
	_assert_equal(data.tool_class("iron_spear"), "spear", "iron spear uses spear tool class")
	npc.free()


func _test_barracks_interior_training(interior_script: Script, data: GameData) -> void:
	var interior: Node = interior_script.new()
	interior.building_id = "barracks"
	interior.building_node_name = "barracks_1"
	interior.building_display_name = "barracks"
	interior.interior_definition = data.building_interior_definition("barracks")
	interior.unlocked_crops = data.default_unlocked_crops()
	interior.workers = []
	for i in range(20):
		interior.workers.append({"worker_id": "Soldier_%02d" % i, "role": "soldier", "tool_multiplier": 1.0})
	interior.interior_state = {}
	interior._ensure_layout_state()
	interior._create_scene_nodes()
	var trainees := interior.get_node_or_null("BarracksTrainees")
	_assert_true(trainees != null, "barracks interior creates trainee container")
	if trainees != null:
		_assert_equal(trainees.get_child_count(), 20, "barracks interior lays out twenty trainee visuals")
		_assert_equal((trainees.get_child(0) as Node2D).position, data.barracks_training_position(0), "first trainee uses data-driven position")
		_assert_equal((trainees.get_child(4) as Node2D).position.y, (trainees.get_child(0) as Node2D).position.y, "fifth trainee stays in first row")
		_assert_equal((trainees.get_child(5) as Node2D).position, data.barracks_training_position(5), "sixth trainee starts second row")
	interior._update_barracks_training(3600.0)
	var training: Dictionary = interior.interior_state.get("training_workers", {})
	var first: Dictionary = training.get("Soldier_00", {})
	_assert_equal(int(first.get("level", 0)), 1, "barracks interior advances worker to level one")
	interior.free()


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
