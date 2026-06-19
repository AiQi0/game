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
		_test_completion_data(game_data_script.new())
	if build_manager_script != null and npc_manager_script != null:
		_test_support_buildings_unlock_terrain_targets(build_manager_script)
		_test_trade_bonus_and_horse_purchase(build_manager_script)
		_test_beacon_damage_reduction(build_manager_script)
		_test_cliff_fort_guard_rules(build_manager_script, npc_manager_script)
		_test_shield_guard_training(build_manager_script, npc_manager_script)
		_test_occupation_allows_terrain_building(build_manager_script)
		_test_diplomacy_travel_and_expedition(build_manager_script)
		_test_special_panel_buttons(build_manager_script)

	if failures == 0:
		print("TerrainCompletionTest: PASS")
	else:
		push_error("TerrainCompletionTest: %d failure(s)" % failures)

	quit(failures)


func _test_completion_data(data) -> void:
	_assert_true(data.has_method("trade_value"), "GameData exposes trade values")
	_assert_true(data.has_method("training_value"), "GameData exposes training values")
	_assert_true(data.has_method("travel_destination_scene_path"), "GameData exposes travel destination scenes")
	if not data.has_method("trade_value") or not data.has_method("training_value"):
		return

	_assert_equal(data.trade_value("horse_base_price"), 30, "horse base price is data-driven")
	_assert_equal(data.trade_value("horse_treaty_price"), 20, "trade treaty horse price is data-driven")
	_assert_equal(data.training_value("shield_guard_cost"), 25, "shield guard training cost is data-driven")
	_assert_equal(data.npc_role_value("shield_guard", "defense_power"), 4, "shield guard defense is data-driven")
	if data.has_method("travel_destination_scene_path"):
		_assert_equal(data.travel_destination_scene_path("river"), "res://scenes/RiverMerchantAlliance.tscn", "river travel scene is data-driven")
		_assert_true(ResourceLoader.exists(data.travel_destination_scene_path("river")), "river merchant alliance scene exists")


func _test_support_buildings_unlock_terrain_targets(build_manager_script) -> void:
	var river_setup := _create_world(build_manager_script)
	var river_manager = river_setup.manager
	var river_buildings: Node2D = river_setup.buildings
	_require_methods(river_manager, ["set_city_context", "building_definition_for_id", "can_build_definition"])
	if failures > 0:
		river_setup.root.free()
		return

	river_manager.set_city_context("river", true)
	river_manager.gold = 500
	_track_building(river_manager, river_buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 3, false, "cityhall")
	var removed_horse_market: Dictionary = river_manager.building_definition_for_id("horse_market")
	_assert_true(removed_horse_market.is_empty(), "horse market is no longer a separate terrain building")
	var river_port: Dictionary = river_manager.building_definition_for_id("river_port")
	_assert_true(river_manager.can_build_definition(river_port), "river port remains buildable in river city")
	_track_building(river_manager, river_buildings, "post_station_1", "post_station", Vector2(4100, 472), Vector2(190, 130), 1, false)
	_assert_true(river_manager.buy_horse(), "post station provides horse purchase function")
	river_setup.root.free()

	var northern_setup := _create_world(build_manager_script)
	var northern_manager = northern_setup.manager
	var northern_buildings: Node2D = northern_setup.buildings
	northern_manager.set_city_context("northern", true)
	northern_manager.gold = 500
	_track_building(northern_manager, northern_buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 4, false, "cityhall")
	var shield_barracks: Dictionary = northern_manager.building_definition_for_id("shield_barracks")
	_assert_false(northern_manager.can_build_definition(shield_barracks), "shield barracks requires barracks")
	_track_building(northern_manager, northern_buildings, "barracks_1", "barracks", Vector2(4100, 472), Vector2(220, 150), 1, false)
	_assert_true(northern_manager.can_build_definition(shield_barracks), "barracks unlocks shield barracks")
	northern_setup.root.free()


func _test_trade_bonus_and_horse_purchase(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	_require_methods(manager, ["set_trade_treaty_active", "horse_price", "buy_horse"])
	if failures > 0:
		setup.root.free()
		return

	manager.set_city_context("river", true)
	_track_building(manager, buildings, "river_port_1", "river_port", Vector2(4300, 472), Vector2(220, 130), 1)
	var port_entity: Dictionary = manager.placed_buildings[0]
	port_entity.worker_inside = true
	port_entity.worker_id = "Merchant_01"
	manager.placed_buildings[0] = port_entity

	manager.gold = 0
	manager._update_quarry_income(60.0)
	_assert_equal(manager.gold, 4, "river port produces base income without treaty")
	manager.set_trade_treaty_active(true)
	manager._update_quarry_income(60.0)
	_assert_equal(manager.gold, 10, "river port gains trade treaty bonus")

	_track_building(manager, buildings, "post_station_1", "post_station", Vector2(4600, 472), Vector2(190, 130), 1, false)
	_assert_equal(manager.horse_price(), 20, "trade treaty lowers horse price")
	manager.gold = 20
	_assert_true(manager.buy_horse(), "post station can sell a horse")
	_assert_equal(manager.get("horse_count"), 1, "buying a horse increments inventory")
	_assert_equal(manager.gold, 0, "horse purchase spends treaty price from current gold")
	setup.root.free()


func _test_beacon_damage_reduction(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	_require_methods(manager, ["city_defense_score", "building_damage_reduction"])
	if failures > 0:
		setup.root.free()
		return

	_track_building(manager, buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 4, false, "cityhall")
	_track_building(manager, buildings, "beacon_tower_1", "beacon_tower", Vector2(4200, 472), Vector2(110, 190), 1)
	_track_building(manager, buildings, "farm_1", "farm", Vector2(4400, 472), Vector2(220, 60), 1)
	_track_building(manager, buildings, "farm_2", "farm", Vector2(4700, 472), Vector2(220, 60), 1)
	_track_building(manager, buildings, "farm_3", "farm", Vector2(5000, 472), Vector2(220, 60), 1)
	var beacon: Dictionary = manager.placed_buildings[1]
	beacon.worker_inside = true
	beacon.worker_id = "Archer_01"
	manager.placed_buildings[1] = beacon

	_assert_equal(manager.city_defense_score(), 18, "occupied beacon tower adds defense score")
	_assert_equal(manager.building_damage_reduction(), 0.2, "occupied beacon tower adds damage reduction")
	var damaged: Array = manager.damage_random_half_buildings(20260619)
	_assert_equal(damaged.size(), 1, "beacon tower reduces revival raid damage count")
	setup.root.free()


func _test_cliff_fort_guard_rules(build_manager_script, npc_manager_script) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager = setup.manager
	var npc_manager = setup.npc_manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs
	_require_methods(manager, ["monster_charge_block_chance", "defense_post_range_bonus_for_workplace_id"])
	if failures > 0:
		setup.root.free()
		return

	var archer := _make_villager("Archer_cliff", Vector2(4400, 472))
	archer.equip_tool("bow")
	npcs.add_child(archer)
	var warrior := _make_villager("Warrior_cliff", Vector2(4450, 472))
	warrior.equip_tool("iron_sword")
	npcs.add_child(warrior)
	_track_building(manager, buildings, "cliff_fort_1", "cliff_fort", Vector2(4500, 472), Vector2(210, 170), 1)

	_assert_true(manager.claim_work_site(0, archer.name), "cliff fort accepts archer")
	manager.release_work_site_for_worker(archer.name)
	_assert_true(manager.claim_work_site(0, warrior.name), "cliff fort accepts warrior")
	_assert_true(manager.occupy_work_site("cliff_fort_1", warrior.name), "warrior can occupy cliff fort")
	_assert_true(manager.monster_charge_block_chance() > 0.0, "warrior in cliff fort lowers monster charge success")
	_assert_equal(manager.defense_post_range_bonus_for_workplace_id("cliff_fort_1"), 250.0, "cliff fort exposes archer range bonus")
	_assert_equal(npc_manager.worker_role_for(warrior.name), "warrior", "warrior fixture remains a warrior")
	setup.root.free()


func _test_shield_guard_training(build_manager_script, npc_manager_script) -> void:
	var setup := _create_world(build_manager_script, npc_manager_script)
	var manager = setup.manager
	var npc_manager = setup.npc_manager
	var buildings: Node2D = setup.buildings
	var npcs: Node2D = setup.npcs
	_require_methods(npc_manager, ["train_shield_guard", "shield_guard_count", "expedition_loss_multiplier"])
	if failures > 0:
		setup.root.free()
		return

	_track_building(manager, buildings, "shield_barracks_1", "shield_barracks", Vector2(4500, 472), Vector2(220, 150), 1, false)
	var villager := _make_villager("Shield_guard_candidate", Vector2(4500, 472))
	npcs.add_child(villager)
	manager.gold = 25
	_assert_true(npc_manager.train_shield_guard(villager.name), "shield barracks trains shield guard")
	_assert_equal(villager.get("worker_role"), "shield_guard", "trained villager becomes shield guard")
	_assert_equal(npc_manager.shield_guard_count(), 1, "trained shield guard is counted")
	_assert_true(npc_manager.expedition_loss_multiplier() < 1.0, "shield guard lowers expedition loss multiplier")
	_assert_equal(manager.gold, 0, "shield guard training spends gold")
	setup.root.free()


func _test_occupation_allows_terrain_building(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	_require_methods(manager, ["occupy_terrain", "set_city_context_for_occupied_terrain"])
	if failures > 0:
		setup.root.free()
		return

	_track_building(manager, buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 3, false, "cityhall")
	_track_building(manager, buildings, "quarry_1", "quarry", Vector2(4200, 472), Vector2(180, 120), 1)
	manager.gold = 500
	manager.set_city_context("mountain", false)
	var iron_mine: Dictionary = manager.building_definition_for_id("iron_mine")
	_assert_false(manager.can_build_definition(iron_mine), "unoccupied mountain city cannot build iron mine")
	manager.occupy_terrain("mountain")
	_assert_true(manager.set_city_context_for_occupied_terrain("mountain"), "occupied mountain city can become active context")
	_assert_true(manager.can_build_definition(iron_mine), "occupied mountain city can build iron mine")
	setup.root.free()


func _test_diplomacy_travel_and_expedition(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	_require_methods(manager, [
		"can_use_diplomacy",
		"sign_trade_treaty",
		"has_trade_treaty",
		"can_travel_to_terrain",
		"travel_to_terrain",
		"launch_expedition",
	])
	if failures > 0:
		setup.root.free()
		return

	_track_building(manager, buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 4, false, "cityhall")
	_track_building(manager, buildings, "post_station_1", "post_station", Vector2(4300, 472), Vector2(190, 130), 1, false)
	_track_building(manager, buildings, "barracks_1", "barracks", Vector2(4550, 472), Vector2(220, 150), 1, false)
	manager.horse_count = 1

	_assert_true(manager.can_use_diplomacy(), "city hall level 4 unlocks diplomacy")
	_assert_true(manager.sign_trade_treaty("river"), "diplomacy can sign river trade treaty")
	_assert_true(manager.has_trade_treaty("river"), "signed treaty is recorded")
	_assert_true(manager.can_travel_to_terrain("river"), "post station and horse allow travel")
	_assert_true(manager.travel_to_terrain("river"), "travel switches to river destination")
	_assert_equal(manager.get("horse_count"), 1, "travel requires but does not consume a horse")
	_assert_equal(manager.get("city_terrain"), "river", "travel sets active city terrain")
	_assert_false(manager.get("city_player_controlled"), "travel does not occupy the destination by itself")

	var result: Dictionary = manager.launch_expedition("mountain")
	_assert_true(result.get("occupied", false), "barracks expedition occupies target terrain")
	_assert_true(manager.terrain_is_occupied("mountain"), "expedition records occupied terrain")
	_assert_true(manager.set_city_context_for_occupied_terrain("mountain"), "occupied expedition target can become active city")
	setup.root.free()


func _test_special_panel_buttons(build_manager_script) -> void:
	var setup := _create_world(build_manager_script)
	var manager = setup.manager
	var buildings: Node2D = setup.buildings
	_track_building(manager, buildings, "CityHall", "cityhall", Vector2(4800, 472), Vector2(400, 334), 4, false, "cityhall")
	_track_building(manager, buildings, "post_station_1", "post_station", Vector2(4300, 472), Vector2(190, 130), 1, false)
	_track_building(manager, buildings, "barracks_1", "barracks", Vector2(4550, 472), Vector2(220, 150), 1, false)
	_track_building(manager, buildings, "shield_barracks_1", "shield_barracks", Vector2(5100, 472), Vector2(220, 150), 1, false)

	manager._show_building_info_panel(0)
	_assert_true(_node_named(manager.info_panel, "SignRiverTradeButton") != null, "city hall panel exposes diplomacy button")
	manager._clear_info_panel()
	manager._show_building_info_panel(1)
	_assert_true(_node_named(manager.info_panel, "TravelRiverButton") != null, "post station panel exposes travel button")
	_assert_true(_node_named(manager.info_panel, "BuyHorseButton") != null, "post station panel exposes buy horse button")
	manager._clear_info_panel()
	manager._show_building_info_panel(2)
	_assert_true(_node_named(manager.info_panel, "ExpeditionMountainButton") != null, "barracks panel exposes expedition button")
	manager._clear_info_panel()
	manager._show_building_info_panel(3)
	_assert_true(_node_named(manager.info_panel, "TrainShieldGuardButton") != null, "shield barracks panel exposes training button")
	setup.root.free()


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


func _require_methods(object: Object, method_names: Array) -> void:
	for method_name in method_names:
		_assert_true(object.has_method(method_name), "%s exposes %s" % [object.name, method_name])


func _node_named(node: Node, node_name: String) -> Node:
	if node == null:
		return null
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _node_named(child, node_name)
		if found != null:
			return found
	return null


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
