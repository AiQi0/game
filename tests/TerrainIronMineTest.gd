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
		_test_terrain_building_data(game_data_script.new())
	if build_manager_script != null and npc_manager_script != null:
		_test_mountain_city_builds_iron_mine(build_manager_script)
		_test_iron_mine_worker_income(build_manager_script, npc_manager_script)
		_test_iron_equipment_requires_working_iron_mine(build_manager_script)
		_test_iron_equipment_roles_and_damage()

	if failures == 0:
		print("TerrainIronMineTest: PASS")
	else:
		push_error("TerrainIronMineTest: %d failure(s)" % failures)

	quit(failures)


func _test_terrain_building_data(data) -> void:
	_assert_true(data.has_method("terrain_building_ids"), "GameData exposes terrain building ids")
	_assert_true(data.has_method("terrain_building_definition"), "GameData exposes terrain building definitions")
	if not data.has_method("terrain_building_ids") or not data.has_method("terrain_building_definition"):
		return

	_assert_equal(data.terrain_building_ids("river"), ["river_port"], "river terrain has one exclusive building after horse market is merged into post station")
	_assert_equal(data.terrain_building_ids("northern"), ["beacon_tower", "shield_barracks"], "northern terrain has two exclusive buildings")
	_assert_equal(data.terrain_building_ids("mountain"), ["iron_mine", "cliff_fort"], "mountain terrain has iron mine and cliff fort")

	var iron_mine: Dictionary = data.terrain_building_definition("iron_mine")
	_assert_equal(iron_mine.get("display_name", ""), "铁矿", "mountain mine is iron mine")
	_assert_equal(iron_mine.get("terrain_required", ""), "mountain", "iron mine is mountain-only")
	_assert_equal(iron_mine.get("cost", 0), 65, "iron mine costs sixty-five gold")
	_assert_equal(iron_mine.get("work_role", ""), "miner", "iron mine requires a miner")
	_assert_equal(iron_mine.get("income_gold", 0), 4, "iron mine produces four gold")
	_assert_equal(iron_mine.get("unlocks_equipment_tier", ""), "iron", "iron mine unlocks iron equipment")
	_assert_equal(iron_mine.get("max_count_per_city", 0), 2, "iron mine is capped at two per mountain city")

	_assert_equal(data.tool_display_name("iron_sword"), "铁剑", "iron sword is data-driven")
	_assert_equal(data.tool_efficiency_multiplier("iron_pickaxe"), 3.0, "iron pickaxe is stronger than stone pickaxe")
	_assert_equal(data.tool_damage_multiplier("iron_arrowhead"), 3.0, "iron arrowheads triple archer damage")
	_assert_equal(data.blacksmith_craft_tool_ids(3), ["iron_sword", "iron_pickaxe", "iron_sickle", "bow", "iron_arrowhead", "iron_spear"], "level 3 blacksmith crafts iron tools and iron spear")


func _test_mountain_city_builds_iron_mine(build_manager_script) -> void:
	var mountain_setup := _create_world(build_manager_script)
	var mountain_manager = mountain_setup.manager
	var mountain_buildings: Node2D = mountain_setup.buildings
	_assert_true(mountain_manager.has_method("set_city_context"), "BuildManager supports city terrain context")
	_assert_true(mountain_manager.has_method("building_definition_for_id"), "BuildManager finds building definitions by id")
	_assert_true(mountain_manager.has_method("can_build_definition"), "BuildManager validates city-specific building definitions")
	if not mountain_manager.has_method("set_city_context") or not mountain_manager.has_method("building_definition_for_id") or not mountain_manager.has_method("can_build_definition"):
		mountain_setup.root.free()
		return

	mountain_manager.set_city_context("mountain", true)
	_assert_equal(
		_building_ids(mountain_manager.buildings),
		["blacksmith", "wall", "tavern", "post_station", "barracks", "iron_mine", "cliff_fort"],
		"mountain city build bar exposes base and mountain buildings"
	)
	mountain_manager.gold = 500
	_track_building(mountain_manager, mountain_buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 3, false, "cityhall")
	_track_building(mountain_manager, mountain_buildings, "quarry_1", "quarry", Vector2(4200, 472), Vector2(180, 120), 1)
	var iron_mine: Dictionary = mountain_manager.building_definition_for_id("iron_mine")
	var cliff_fort: Dictionary = mountain_manager.building_definition_for_id("cliff_fort")
	_assert_true(mountain_manager.can_build_definition(iron_mine), "mountain city can build iron mine")
	_assert_false(mountain_manager.can_build_definition(cliff_fort), "level 3 mountain city cannot build cliff fort")
	var cityhall_entity: Dictionary = mountain_manager.placed_buildings[0]
	cityhall_entity.level = 4
	mountain_manager.placed_buildings[0] = cityhall_entity
	_assert_true(mountain_manager.can_build_definition(cliff_fort), "level 4 mountain city can build cliff fort")
	_track_building(mountain_manager, mountain_buildings, "iron_mine_1", "iron_mine", Vector2(3600, 472), Vector2(190, 130), 1)
	_track_building(mountain_manager, mountain_buildings, "iron_mine_2", "iron_mine", Vector2(3900, 472), Vector2(190, 130), 1)
	_assert_false(mountain_manager.can_build_definition(iron_mine), "mountain city cannot exceed two iron mines")
	mountain_setup.root.free()

	var river_setup := _create_world(build_manager_script)
	var river_manager = river_setup.manager
	var river_buildings: Node2D = river_setup.buildings
	river_manager.set_city_context("river", true)
	_assert_equal(
		_building_ids(river_manager.buildings),
		["blacksmith", "wall", "tavern", "post_station", "barracks", "river_port"],
		"river city build bar exposes base buildings and river port only"
	)
	river_manager.gold = 500
	_track_building(river_manager, river_buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 3, false, "cityhall")
	_track_building(river_manager, river_buildings, "quarry_1", "quarry", Vector2(4200, 472), Vector2(180, 120), 1)
	_assert_false(river_manager.can_build_definition(river_manager.building_definition_for_id("iron_mine")), "non-mountain city cannot build iron mine")
	river_setup.root.free()


func _test_iron_mine_worker_income(build_manager_script, npc_manager_script) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager = setup.manager
	var npc_manager = setup.npc_manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs
	manager.set_city_context("mountain", true)
	var iron_mine := _track_building(manager, buildings, "iron_mine_1", "iron_mine", Vector2(4400, 472), Vector2(190, 130), 1)

	manager.gold = 0
	manager._update_quarry_income(60.0)
	_assert_equal(manager.gold, 0, "iron mine without miner does not produce")

	var miner := _make_villager("Miner_iron", iron_mine.global_position)
	npcs.add_child(miner)
	npc_manager._assign_workplace_to_villager(miner)
	miner.global_position = iron_mine.global_position
	npc_manager._finish_arriving_workers()
	_assert_equal(miner.get("worker_role"), "miner", "villager becomes miner inside iron mine")

	manager._update_quarry_income(59.0)
	_assert_equal(manager.gold, 0, "iron mine waits one minute")
	manager._update_quarry_income(1.0)
	_assert_equal(manager.gold, 4, "iron mine with miner produces four gold")
	setup.root.free()


func _test_iron_equipment_requires_working_iron_mine(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	manager.set_city_context("mountain", true)
	manager.gold = 99
	var blacksmith := _track_building(manager, buildings, "blacksmith_1", "blacksmith", Vector2(3000, 472), Vector2(180, 140), 3)
	_track_building(manager, buildings, "quarry_1", "quarry", Vector2(3300, 472), Vector2(180, 120), 1)
	_assert_false(manager.start_blacksmith_craft(0, "iron_sword"), "level 3 blacksmith needs working iron mine")

	var iron_mine := _track_building(manager, buildings, "iron_mine_1", "iron_mine", Vector2(3600, 472), Vector2(190, 130), 1)
	_assert_false(manager.start_blacksmith_craft(0, "iron_sword"), "empty iron mine does not unlock iron tools")
	var iron_entity: Dictionary = manager.placed_buildings[2]
	iron_entity.worker_id = "Miner_01"
	iron_entity.worker_inside = true
	manager.placed_buildings[2] = iron_entity
	_assert_true(manager.has_method("iron_mine_supply_available"), "BuildManager exposes iron mine supply")
	_assert_true(manager.iron_mine_supply_available(), "working iron mine unlocks iron supply")
	_assert_true(manager.start_blacksmith_craft(0, "iron_sword"), "working iron mine unlocks iron sword")
	_assert_true(manager.start_blacksmith_craft(0, "iron_pickaxe"), "working iron mine unlocks iron pickaxe")
	_assert_true(manager.start_blacksmith_craft(0, "iron_sickle"), "working iron mine unlocks iron sickle")
	_assert_true(manager.start_blacksmith_craft(0, "iron_arrowhead"), "working iron mine unlocks iron arrowhead")

	_assert_true(is_instance_valid(blacksmith), "blacksmith fixture remains valid")
	_assert_true(is_instance_valid(iron_mine), "iron mine fixture remains valid")
	setup.root.free()


func _test_iron_equipment_roles_and_damage() -> void:
	var warrior := _make_villager("Iron_warrior", Vector2(4800, 472))
	warrior.equip_tool("iron_sword")
	_assert_equal(warrior.get("worker_role"), "warrior", "iron sword turns villager into warrior")
	_assert_true(int(warrior.get("attack_power")) > 2, "iron sword warrior is stronger than stone sword warrior")
	warrior.free()

	var archer := _make_villager("Iron_archer", Vector2(4800, 472))
	archer.equip_tool("bow")
	archer.equip_tool("iron_arrowhead")
	_assert_equal(archer.get("worker_role"), "archer", "iron arrowhead keeps archer role")
	_assert_equal(archer.get("arrowhead_tool"), "iron_arrowhead", "archer records iron arrowheads")
	_assert_equal(archer.get("attack_power"), 3, "iron arrowheads triple archer damage")
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


func _building_ids(definitions: Array) -> Array:
	var ids: Array = []
	for definition in definitions:
		ids.append(str(definition.get("id", "")))
	return ids


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
