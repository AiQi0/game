extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	if game_data_script == null:
		_fail("GameData.gd should load")

	if game_data_script != null:
		var data = game_data_script.new()
		_assert_equal(data.world_value("ground_min_x"), -4000.0, "world left edge is data-driven")
		_assert_equal(data.world_value("ground_max_x"), 13600.0, "world right edge is data-driven")
		_assert_equal(data.world_value("autosave_seconds"), 60.0, "autosave interval is data-driven")
		_assert_true(data.has_method("homeless_spawn_value"), "homeless spawn tuning is data-driven")
		if data.has_method("homeless_spawn_value"):
			_assert_equal(data.homeless_spawn_value("early_spawn_chance"), 0.3, "early homeless spawn chance is data-driven")
			_assert_equal(data.homeless_spawn_value("late_spawn_chance"), 0.15, "late homeless spawn chance is data-driven")
			_assert_equal(data.homeless_spawn_value("early_count_range"), Vector2i(2, 4), "early homeless spawn count range is data-driven")
			_assert_equal(data.homeless_spawn_value("late_count_range"), Vector2i(1, 2), "late homeless spawn count range is data-driven")
			_assert_equal(data.homeless_spawn_value("late_reduction_start_day"), 4, "homeless spawn reduction start day is data-driven")
		_assert_true(data.has_method("tavern_attraction_value"), "tavern attraction tuning is data-driven")
		if data.has_method("tavern_attraction_value"):
			_assert_equal(data.tavern_attraction_value("homeless_capacity"), 3, "tavern homeless attraction capacity is data-driven")
			_assert_equal(data.tavern_attraction_value("wander_radius"), 90.0, "tavern homeless wander radius is data-driven")
		_assert_equal(data.world_value("lumberjack_tree_search_radius"), 840.0, "lumberjack tree search range is data-driven")
		_assert_equal(data.world_value("mother_tree_lumberjack_search_radius"), 1040.0, "mother tree lumberjack search range is data-driven")
		_assert_equal(data.economy_value("starting_gold"), 30, "starting gold is data-driven")
		_assert_equal(data.fishing_value("reward_gold"), 1, "fishing reward is data-driven")
		_assert_equal(data.fishing_value("hook_window_seconds"), 1.5, "fishing hook window is data-driven")
		_assert_equal(data.fishing_value("bite_base_chance"), 0.05, "fishing bite base chance is data-driven")
		_assert_equal(data.fishing_value("reel_start_progress"), 0.2, "fishing start progress is data-driven")
		_assert_equal(data.fishing_value("movement_cancel_distance"), 4.0, "fishing movement cancel distance is data-driven")
		_assert_equal(data.building_interior_scene_path(), "res://scenes/BuildingInterior.tscn", "building interior scene path is data-driven")
		_assert_equal(data.building_interior_value("farm", "display_name"), "农田室内", "farm interior display name is Chinese")
		_assert_equal(data.building_interior_value("farm", "cycle_seconds"), 300.0, "farm interior cycle is data-driven")
		_assert_equal(data.building_interior_value("farm", "sow_action_seconds"), 2.0, "farm sow action is data-driven")
		_assert_equal(data.building_interior_value("lumberyard", "max_resources"), 6, "lumberyard interior resource cap is data-driven")
		_assert_equal(data.building_interior_value("quarry", "resource_kind"), "stone", "quarry interior resource kind is data-driven")
		_assert_equal(data.interior_worker_default_position(), Vector2(360.0, 792.0), "interior worker default position is data-driven")
		_assert_equal(data.interior_farm_plot_position(2), Vector2(560.0, 740.0), "interior farm plot positions are data-driven")
		_assert_equal(data.interior_farm_worker_position(2), Vector2(560.0, 748.0), "interior farm worker positions are data-driven")
		_assert_equal(data.interior_resource_worker_position(700.0), Vector2(700.0, 792.0), "interior resource worker positions are data-driven")
		_assert_equal(data.crop_ids(), ["wheat", "carrot", "cabbage", "pumpkin", "blueberry", "moon_mushroom"], "crop catalog is data-driven")
		_assert_equal(data.crop_value("wheat", "display_name"), "小麦", "crop display names are Chinese")
		_assert_equal(data.crop_value("carrot", "seed_display_name"), "胡萝卜种子", "seed display names are Chinese")
		_assert_equal(data.crop_value("wheat", "reward_gold"), 1, "crop reward is data-driven")
		_assert_equal(data.default_unlocked_crops(), {"wheat": true}, "default crop unlocks are data-driven")
		_assert_equal(data.seed_drop_chance(), 0.02, "seed drop chance is data-driven")
		_assert_equal(data.fish_species().size(), 6, "fish species catalog is data-driven")
		_assert_equal(data.fish_species_definition("river_bass").get("display_name", ""), "河湾鲈", "fish display names are Chinese")
		_assert_equal(data.fish_species_definition("moon_kingfish").get("rarity", ""), "legendary", "legendary fish data is data-driven")
		_assert_equal(data.tool_value("bow", "display_name"), "弓", "bow display name is data-driven")
		_assert_equal(data.tool_ids_for_role("villager"), ["iron_sword", "stone_sword", "sword", "bow"], "villager tool choices are data-driven")
		_assert_equal(data.tool_ids_for_role("miner"), ["iron_pickaxe", "stone_pickaxe"], "miner tool choices are data-driven")
		_assert_equal(data.tool_ids_for_role("soldier"), ["iron_spear", "stone_spear"], "soldier tool choices are data-driven")
		_assert_equal(data.blacksmith_craft_tool_ids(2), ["stone_sword", "stone_pickaxe", "stone_sickle", "bow", "stone_arrowhead", "stone_spear"], "level two blacksmith craft list is data-driven")
		_assert_equal(data.blacksmith_craft_tool_ids(3), ["iron_sword", "iron_pickaxe", "iron_sickle", "bow", "iron_arrowhead", "iron_spear"], "level three blacksmith craft list is data-driven")
		_assert_true(data.has_method("tool_class"), "tool class lookup is data-driven")
		if data.has_method("tool_class"):
			_assert_equal(data.tool_class("axe"), "axe", "wood axe is in the axe class")
			_assert_equal(data.tool_class("stone_pickaxe"), "axe", "stone pickaxe is in the axe class")
			_assert_equal(data.tool_class("iron_pickaxe"), "axe", "iron pickaxe is in the axe class")
			_assert_equal(data.tool_class("sword"), "sword", "sword keeps its own tool class")
		_assert_equal(data.npc_role_value("archer", "attack_power"), 1, "archer attack power is data-driven")
		_assert_equal(data.npc_role_value("archer", "attack_range"), 600.0, "archer attack range is data-driven")
		_assert_equal(data.npc_role_value("archer", "wall_attack_range"), 900.0, "wall archer range is data-driven")
		_assert_equal(data.npc_role_value("soldier", "attack_power"), 2, "soldier attack power is data-driven")
		_assert_equal(data.barracks_capacity_for_level(3), 20, "barracks level three capacity is data-driven")
		_assert_equal(data.barracks_training_level_for_elapsed(25200.0), 3, "barracks training time is data-driven")
		_assert_true(data.has_method("monster_value"), "monster tuning is data-driven")
		if data.has_method("monster_value"):
			_assert_equal(data.monster_value("speed"), 105.0, "monster speed is increased by fifty percent")
			_assert_equal(data.monster_value("spawn_interval_seconds"), 1.0, "monster spawn interval is data-driven")
			_assert_equal(data.monster_value("dash_distance"), 132.0, "monster dash distance is data-driven")
			_assert_equal(data.monster_value("dash_speed_multiplier"), 5.0, "monster dash speed multiplier is data-driven")
		_assert_equal(data.arrow_value("landed_visible_seconds"), 5.0, "arrow landed duration is data-driven")
		_assert_true(data.has_method("river_mirror_water_visual"), "river mirror water visual settings are data-driven")
		if data.has_method("river_mirror_water_visual"):
			var mirror_water: Dictionary = data.river_mirror_water_visual()
			_assert_equal(mirror_water.get("waterline_y"), 520.0, "river mirror waterline is data-driven")
			_assert_equal(mirror_water.get("reflection_height_pixels"), 560.0, "river mirror reflection height is data-driven")
			_assert_equal(mirror_water.get("ripple_amplitude_pixels"), 8.0, "river mirror ripple amplitude is data-driven")
			_assert_equal(mirror_water.get("ripple_speed"), 0.65, "river mirror ripple speed is data-driven")
			_assert_equal(mirror_water.get("shimmer_strength"), 0.08, "river mirror shimmer strength is data-driven")
			_assert_equal(mirror_water.get("top_blur_fraction"), 0.25, "river mirror top blur fraction is data-driven")
			_assert_equal(mirror_water.get("top_blur_radius_pixels"), 6.0, "river mirror top blur radius is data-driven")
			_assert_equal(mirror_water.get("water_grass_count"), 24, "river water grass count is data-driven")
			_assert_equal(mirror_water.get("water_grass_random_seed"), 20260620, "river water grass seed is data-driven")
			_assert_equal(mirror_water.get("water_grass_y_min"), 560.0, "river water grass min y is data-driven")
			_assert_equal(mirror_water.get("water_grass_y_max"), 1010.0, "river water grass max y is data-driven")
		_assert_true(data.has_method("day_night_visual"), "day/night visual layering is data-driven")
		if data.has_method("day_night_visual"):
			var day_night_visual: Dictionary = data.day_night_visual()
			_assert_equal(day_night_visual.get("sky_background_z_index"), -260, "sky background z index is data-driven")
			_assert_equal(day_night_visual.get("celestial_z_index"), -70, "sun and moon z index is data-driven")
			_assert_equal(day_night_visual.get("terrain_background_top_z_index"), -80, "terrain background top z index is data-driven")
		_assert_equal(data.building_upgrade_cost("cityhall", 2), 50, "building upgrade costs are data-driven")
		_assert_equal(data.building_upgrade_requirements("farm", 2), {"cityhall": 2}, "building upgrade unlocks are data-driven")
		_assert_true(data.has_method("wall_health_for_level"), "wall health is data-driven")
		if data.has_method("wall_health_for_level"):
			_assert_equal(data.wall_health_for_level(1), 20, "level one wall health is data-driven")
			_assert_equal(data.wall_health_for_level(2), 40, "level two wall health is data-driven")
		_assert_equal(data.farm_value("worker_capacity"), 1, "farm worker capacity is data-driven")
		_assert_equal(data.world_value("stone_count"), 3, "initial stone count is data-driven")
		_assert_equal(data.quarry_value("cost"), 20, "quarry cost is data-driven")
		_assert_equal(data.quarry_value("requires_worker"), true, "quarry worker requirement is data-driven")
		_assert_equal(data.quarry_value("worker_role"), "miner", "quarry worker role is data-driven")
		_assert_equal(data.quarry_value("income_gold"), 3, "quarry income is data-driven")
		_assert_equal(data.terrain_building_ids("mountain"), ["iron_mine", "cliff_fort"], "terrain buildings are data-driven")
		_assert_equal(data.post_station_panel_travel_destinations(), ["river"], "post station panel travel destinations are data-driven")
		_assert_equal(data.tool_required_building("iron_sword"), "iron_mine", "iron tool supply is data-driven")
		_assert_true(data.is_valid_tool_id("bow"), "tool validation is data-driven")
		_assert_false(data.is_valid_tool_id("hammer"), "unknown tools are rejected by data")

	if failures == 0:
		print("GameDataSeparationTest: PASS")
	else:
		push_error("GameDataSeparationTest: %d failure(s)" % failures)

	quit(failures)


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
