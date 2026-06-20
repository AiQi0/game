extends SceneTree

const NPCFactory = preload("res://scripts/NPCFactory.gd")

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")
	var npc_manager_script := load("res://scripts/NPCManager.gd")

	if game_data_script == null:
		_fail("GameData.gd should load")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")

	if game_data_script != null:
		_test_tool_tier_data(game_data_script.new())
	if build_manager_script != null and npc_manager_script != null:
		_test_initial_stone_distribution(build_manager_script)
		_test_blacksmith_craft_requirements(build_manager_script)
		_test_tool_efficiency_tiers(build_manager_script, npc_manager_script)
		_test_level_two_lumberyard_stays_lumberyard(build_manager_script, npc_manager_script)
		_test_city_hall_two_builds_quarry_on_stone(build_manager_script)
		_test_quarry_worker_role_and_income(build_manager_script, npc_manager_script)
		_test_stone_arrowheads_upgrade_archer_damage()

	if failures == 0:
		print("ToolTierAndQuarryTest: PASS")
	else:
		push_error("ToolTierAndQuarryTest: %d failure(s)" % failures)

	quit(failures)


func _test_tool_tier_data(data) -> void:
	_assert_equal(data.tool_display_name("sword"), "木剑", "level 1 sword is a wooden sword")
	_assert_equal(data.tool_display_name("axe"), "木斧", "level 1 axe is a wooden axe")
	_assert_equal(data.tool_display_name("sickle"), "木镰刀", "level 1 sickle is a wooden sickle")
	_assert_equal(data.tool_display_name("stone_pickaxe"), "石镐", "level 2 axe slot becomes a stone pickaxe")
	_assert_equal(data.tool_efficiency_multiplier("axe"), 1.5, "wood tools are fifty percent faster")
	_assert_equal(data.tool_efficiency_multiplier("stone_pickaxe"), 2.0, "stone tools are one hundred percent faster")
	_assert_equal(data.tool_damage_multiplier("stone_arrowhead"), 2.0, "stone arrowheads double archer damage")
	_assert_equal(data.blacksmith_craft_tool_ids(1), ["sword", "axe", "sickle", "bow"], "level 1 blacksmith crafts wood tools and bow")
	_assert_equal(data.blacksmith_craft_tool_ids(2), ["stone_sword", "stone_pickaxe", "stone_sickle", "bow", "stone_arrowhead"], "level 2 blacksmith crafts stone tools, bow, and stone arrowheads")
	_assert_equal(data.blacksmith_craft_requirements(2), {"quarry": 1}, "level 2 blacksmith requires a quarry")
	_assert_equal(data.lumberyard_display_name(2), "2级伐木场", "level 2 lumberyard keeps lumberyard identity")
	_assert_equal(data.lumberyard_resource_kind(2), "tree", "level 2 lumberyard still grows trees")
	_assert_equal(data.quarry_value("cost"), 20, "quarry costs twenty gold")
	_assert_equal(data.quarry_value("income_gold"), 3, "quarry produces three gold per income tick")
	_assert_equal(data.world_value("stone_count"), 3, "map starts with three stones")


func _test_blacksmith_craft_requirements(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	var blacksmith := _track_building(manager, buildings, "blacksmith_1", "blacksmith", Vector2(3000, 472), Vector2(180, 140), 1)

	manager.gold = 20
	_assert_false(manager.start_blacksmith_craft(0, "sword"), "level 1 blacksmith needs a lumberyard before crafting wood tools")

	_track_building(manager, buildings, "lumberyard_1", "lumberyard", Vector2(3300, 472), Vector2(200, 130), 1)
	_assert_true(manager.start_blacksmith_craft(0, "sword"), "lumberyard unlocks wood tool crafting")
	_assert_false(manager.start_blacksmith_craft(0, "stone_pickaxe"), "stone tools are not crafted by a level 1 blacksmith")

	var blacksmith_entity: Dictionary = manager.placed_buildings[0]
	blacksmith_entity.level = 2
	manager.placed_buildings[0] = blacksmith_entity
	_assert_false(manager.start_blacksmith_craft(0, "stone_pickaxe"), "level 2 blacksmith needs a quarry before crafting stone tools")

	var lumberyard_entity: Dictionary = manager.placed_buildings[1]
	lumberyard_entity.level = 2
	manager.placed_buildings[1] = lumberyard_entity
	_assert_false(manager.start_blacksmith_craft(0, "stone_pickaxe"), "level 2 lumberyard is not a quarry")
	_track_building(manager, buildings, "quarry_1", "quarry", Vector2(3600, 472), Vector2(180, 120), 1, false)
	_assert_true(manager.start_blacksmith_craft(0, "stone_pickaxe"), "quarry unlocks stone tool crafting")
	_assert_true(manager.start_blacksmith_craft(0, "stone_arrowhead"), "quarry unlocks stone arrowhead crafting")

	_assert_true(is_instance_valid(blacksmith), "blacksmith fixture remains valid")
	setup.root.free()


func _test_initial_stone_distribution(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	manager._spawn_stones()
	_assert_equal(_resource_count(manager, "stone"), 3, "map generation creates three random stones")

	setup.root.free()


func _test_tool_efficiency_tiers(build_manager_script, npc_manager_script) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager = setup.manager
	var npc_manager = setup.npc_manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs

	var farm := _track_building(manager, buildings, "farm_1", "farm", Vector2(3000, 472), Vector2(220, 60), 1)
	var farmer := _make_villager("Farmer_wood", farm.global_position)
	farmer.become_farmer()
	npcs.add_child(farmer)
	manager.claim_work_site(0, farmer.name)
	manager.occupy_work_site("farm_1", farmer.name)
	farmer.enter_building(farm.global_position, "农田", "farm_1")

	farmer.set("carried_tool", "sickle")
	manager.gold = 0
	manager._update_farm_income(39.0)
	_assert_equal(manager.gold, 0, "wood sickle does not finish before forty seconds")
	manager._update_farm_income(1.0)
	_assert_equal(manager.gold, 1, "wood sickle improves farm speed by fifty percent")

	farmer.set("carried_tool", "stone_sickle")
	manager.gold = 0
	manager._update_farm_income(29.0)
	_assert_equal(manager.gold, 0, "stone sickle does not finish before thirty seconds")
	manager._update_farm_income(1.0)
	_assert_equal(manager.gold, 1, "stone sickle doubles farm speed")

	var miner := _make_villager("Miner_stone_pickaxe", Vector2(3400, 472))
	miner.set("carried_tool", "stone_pickaxe")
	npcs.add_child(miner)
	var stone: Node2D = manager._spawn_stone_at(Vector2(3440, 472))
	manager.demolition_target_index = manager._placed_entity_index_for_node(stone)
	manager._demolish_target()
	miner.global_position = stone.global_position
	npc_manager._finish_arriving_tree_choppers()
	manager.gold = 0
	npc_manager._advance_tree_choppers(29.0)
	_assert_equal(manager.gold, 0, "stone pickaxe does not finish before thirty seconds")
	npc_manager._advance_tree_choppers(1.0)
	_assert_equal(manager.gold, 3, "stone pickaxe doubles mining speed and stone grants three gold")

	setup.root.free()


func _test_level_two_lumberyard_stays_lumberyard(build_manager_script, npc_manager_script) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager = setup.manager
	var npc_manager = setup.npc_manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs

	var lumberyard := _track_building(manager, buildings, "lumberyard_1", "lumberyard", Vector2(3600, 472), Vector2(200, 130), 2)
	var before_trees := _resource_count(manager, "tree")
	manager._update_lumberyards(120.0)
	_assert_equal(_resource_count(manager, "tree"), before_trees + 3, "level 2 lumberyard still generates three trees")
	_assert_equal(_resource_count(manager, "stone"), 0, "level 2 lumberyard does not generate stones")

	var worker := _make_villager("Lumberjack_01", lumberyard.global_position)
	npcs.add_child(worker)
	npc_manager._assign_workplace_to_villager(worker)
	worker.global_position = lumberyard.global_position
	npc_manager._finish_arriving_workers()
	_assert_equal(worker.get("worker_role"), "lumberjack", "worker entering level 2 lumberyard remains lumberjack")

	manager._update_lumberyards(0.0)
	_assert_true(worker.get("is_traveling_to_tree_chop") == true, "lumberjack leaves level 2 lumberyard to chop nearby tree")
	var task: Dictionary = manager.tree_chop_tasks[0]
	_assert_equal(task.get("resource_kind", ""), "tree", "level 2 lumberyard dispatch creates a tree task")

	worker.global_position = task.position
	npc_manager._finish_arriving_tree_choppers()
	manager.gold = 0
	npc_manager._advance_tree_choppers(60.0)
	_assert_equal(manager.gold, 1, "level 2 lumberyard chopping grants tree gold")

	setup.root.free()


func _test_city_hall_two_builds_quarry_on_stone(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs
	_assert_true(npcs != null, "world fixture includes npc container")

	var city_hall := _track_building(manager, buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 1, false, "cityhall")
	var stone: Node2D = manager._spawn_stone_at(Vector2(4300, 472))
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.global_position = stone.global_position
	setup.root.add_child(player)
	manager.player = player
	manager.gold = 99

	_assert_true(manager.has_method("_try_build_quarry_at_player"), "BuildManager can build quarry at player stone")
	_assert_true(manager._try_build_quarry_at_player(), "city hall level one handles quarry attempt at stone")
	_assert_equal(_building_count(manager, "quarry"), 0, "city hall level one cannot build quarry")
	_assert_equal(manager.gold, 99, "failed locked quarry build does not spend gold")

	var city_entity: Dictionary = manager.placed_buildings[0]
	city_entity.level = 2
	manager.placed_buildings[0] = city_entity
	manager.gold = 19
	_assert_true(manager._try_build_quarry_at_player(), "not enough gold quarry attempt is handled")
	_assert_equal(_building_count(manager, "quarry"), 0, "not enough gold prevents quarry")

	manager.gold = 20
	_assert_true(manager._try_build_quarry_at_player(), "city hall level two builds quarry on stone")
	_assert_equal(manager.gold, 0, "building quarry spends twenty gold")
	_assert_equal(_resource_count(manager, "stone"), 1, "stone remains as the quarry source")
	_assert_true(is_instance_valid(stone), "quarry construction keeps the source stone node")
	if is_instance_valid(stone):
		_assert_false(stone.visible, "source stone is hidden while occupied by a quarry")
	_assert_equal(_building_count(manager, "quarry"), 1, "one quarry is built")

	var stone_index := _first_resource_index(manager, "stone")
	if stone_index != -1:
		var stone_entity: Dictionary = manager.placed_buildings[stone_index]
		_assert_true(bool(stone_entity.get("has_quarry", false)), "source stone records the quarry occupying it")
		_assert_false(bool(stone_entity.get("demolishable", true)), "occupied source stone cannot be demolished before its quarry")

	var quarry_index := _first_building_index(manager, "quarry")
	_assert_true(quarry_index != -1, "quarry entity is tracked before demolition")
	if quarry_index != -1:
		manager.demolition_target_index = quarry_index
		manager._demolish_target()
	_assert_equal(_building_count(manager, "quarry"), 0, "demolishing quarry removes the quarry")
	_assert_equal(_resource_count(manager, "stone"), 1, "demolishing quarry restores the source stone")
	_assert_true(is_instance_valid(stone), "source stone node remains valid after quarry demolition")
	if is_instance_valid(stone):
		_assert_true(stone.visible, "source stone is visible again after quarry demolition")

	stone_index = _first_resource_index(manager, "stone")
	if stone_index != -1:
		var restored_stone_entity: Dictionary = manager.placed_buildings[stone_index]
		_assert_false(bool(restored_stone_entity.get("has_quarry", false)), "restored stone is no longer occupied by a quarry")
		_assert_true(bool(restored_stone_entity.get("demolishable", false)), "restored stone can be demolished again")

	manager.gold = 20
	_assert_true(manager._try_build_quarry_at_player(), "restored stone can build a replacement quarry")
	_assert_equal(_building_count(manager, "quarry"), 1, "replacement quarry is built on restored stone")
	_assert_true(is_instance_valid(city_hall), "city hall fixture remains valid")

	setup.root.free()


func _test_quarry_worker_role_and_income(build_manager_script, npc_manager_script) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager = setup.manager
	var npc_manager = setup.npc_manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs
	var quarry := _track_building(manager, buildings, "quarry_1", "quarry", Vector2(4400, 472), Vector2(180, 120), 1)

	manager.gold = 0
	_assert_true(manager.has_method("_update_quarry_income"), "BuildManager updates quarry income")
	manager._update_quarry_income(1.0)
	_assert_equal(manager.gold, 0, "quarry without worker does not produce gold")

	var sites: Array = manager.get_work_sites()
	_assert_equal(sites.size(), 1, "quarry is available as a work site")
	_assert_equal(sites[0].get("worker_role", ""), "miner", "quarry assigns miner role")

	var worker := _make_villager("Miner_quarry", quarry.global_position)
	npcs.add_child(worker)
	npc_manager._assign_workplace_to_villager(worker)
	worker.global_position = quarry.global_position
	npc_manager._finish_arriving_workers()
	_assert_equal(worker.get("worker_role"), "miner", "villager becomes miner after entering quarry")
	_assert_true(worker.get("is_inside_building"), "miner disappears inside quarry while working")

	manager._update_quarry_income(59.0)
	_assert_equal(manager.gold, 0, "quarry with miner waits one minute before producing")
	manager._update_quarry_income(1.0)
	_assert_equal(manager.gold, 3, "quarry with miner produces three gold per minute")

	setup.root.free()


func _test_stone_arrowheads_upgrade_archer_damage() -> void:
	var archer := _make_villager("Archer_arrowhead", Vector2(4800, 472))
	archer.equip_tool("bow")
	_assert_equal(archer.get("attack_power"), 1, "bow archer starts at one damage")
	archer.equip_tool("stone_arrowhead")
	_assert_equal(archer.get("worker_role"), "archer", "stone arrowhead keeps archer role")
	_assert_equal(archer.get("carried_tool"), "bow", "stone arrowhead does not replace the bow")
	_assert_equal(archer.get("arrowhead_tool"), "stone_arrowhead", "archer records equipped stone arrowheads")
	_assert_equal(archer.get("attack_power"), 2, "stone arrowheads double archer damage")
	archer.free()


func _create_world(build_manager_script, npc_manager_script = null) -> Dictionary:
	var root := Node2D.new()
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)
	var npcs := Node2D.new()
	npcs.name = "NPCs"
	root.add_child(npcs)

	var manager: Node2D = build_manager_script.new()
	manager.name = "BuildManager"
	root.add_child(manager)
	manager.buildings_container = buildings

	var npc_manager: Node2D = null
	if npc_manager_script != null:
		npc_manager = npc_manager_script.new()
		npc_manager.name = "NPCManager"
		root.add_child(npc_manager)
		npc_manager.npc_container = npcs

	return {
		"root": root,
		"manager": manager,
		"npc_manager": npc_manager,
		"buildings": buildings,
		"npcs": npcs,
	}


func _track_building(
	manager: Node2D,
	buildings: Node2D,
	node_name: String,
	building_id: String,
	position: Vector2,
	size: Vector2,
	level: int,
	is_workplace := true,
	entity_kind := "building"
) -> Node2D:
	var building := Node2D.new()
	building.name = node_name
	building.global_position = position
	buildings.add_child(building)
	manager._track_placed_entity(
		building,
		Rect2(Vector2(position.x - size.x * 0.5, position.y - size.y), size),
		true,
		building_id,
		entity_kind,
		is_workplace,
		building_id
	)
	var index: int = manager.placed_buildings.size() - 1
	var entity: Dictionary = manager.placed_buildings[index]
	entity.level = level
	manager.placed_buildings[index] = entity
	return building


func _make_villager(npc_name: String, position: Vector2) -> Node2D:
	var factory := NPCFactory.new()
	var npc: Node2D = factory.create_homeless(position, Vector2(4800, 472))
	npc.name = npc_name
	npc.interact()
	return npc


func _resource_count(manager: Node2D, resource_kind: String) -> int:
	var count := 0
	for entity in manager.placed_buildings:
		if entity.get("resource_kind", "") == resource_kind:
			count += 1
	return count


func _first_resource_index(manager: Node2D, resource_kind: String) -> int:
	for i in range(manager.placed_buildings.size()):
		if manager.placed_buildings[i].get("resource_kind", "") == resource_kind:
			return i
	return -1


func _building_count(manager: Node2D, building_id: String) -> int:
	var count := 0
	for entity in manager.placed_buildings:
		if entity.get("building_id", "") == building_id:
			count += 1
	return count


func _first_building_index(manager: Node2D, building_id: String) -> int:
	for i in range(manager.placed_buildings.size()):
		if manager.placed_buildings[i].get("building_id", "") == building_id:
			return i
	return -1


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
