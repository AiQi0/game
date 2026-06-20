extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	if game_data_script == null:
		_fail("GameData.gd should load")

	if game_data_script != null:
		var data = game_data_script.new()
		_assert_equal(data.world_value("ground_max_x"), 9600.0, "world ground width is data-driven")
		_assert_equal(data.world_value("autosave_seconds"), 60.0, "autosave interval is data-driven")
		_assert_equal(data.world_value("lumberjack_tree_search_radius"), 840.0, "lumberjack tree search range is data-driven")
		_assert_equal(data.world_value("mother_tree_lumberjack_search_radius"), 1040.0, "mother tree lumberjack search range is data-driven")
		_assert_equal(data.economy_value("starting_gold"), 30, "starting gold is data-driven")
		_assert_equal(data.fishing_value("reward_gold"), 1, "fishing reward is data-driven")
		_assert_equal(data.fishing_value("hook_window_seconds"), 1.5, "fishing hook window is data-driven")
		_assert_equal(data.fishing_value("bite_base_chance"), 0.05, "fishing bite base chance is data-driven")
		_assert_equal(data.fishing_value("reel_start_progress"), 0.2, "fishing start progress is data-driven")
		_assert_equal(data.tool_value("bow", "display_name"), "弓", "bow display name is data-driven")
		_assert_equal(data.tool_ids_for_role("villager"), ["iron_sword", "stone_sword", "sword", "bow"], "villager tool choices are data-driven")
		_assert_equal(data.tool_ids_for_role("miner"), ["iron_pickaxe", "stone_pickaxe"], "miner tool choices are data-driven")
		_assert_true(data.has_method("tool_class"), "tool class lookup is data-driven")
		if data.has_method("tool_class"):
			_assert_equal(data.tool_class("axe"), "axe", "wood axe is in the axe class")
			_assert_equal(data.tool_class("stone_pickaxe"), "axe", "stone pickaxe is in the axe class")
			_assert_equal(data.tool_class("iron_pickaxe"), "axe", "iron pickaxe is in the axe class")
			_assert_equal(data.tool_class("sword"), "sword", "sword keeps its own tool class")
		_assert_equal(data.npc_role_value("archer", "attack_power"), 1, "archer attack power is data-driven")
		_assert_equal(data.npc_role_value("archer", "attack_range"), 600.0, "archer attack range is data-driven")
		_assert_equal(data.npc_role_value("archer", "wall_attack_range"), 900.0, "wall archer range is data-driven")
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
		_assert_equal(data.farm_value("worker_capacity"), 4, "farm worker capacity is data-driven")
		_assert_equal(data.world_value("stone_count"), 3, "initial stone count is data-driven")
		_assert_equal(data.quarry_value("cost"), 20, "quarry cost is data-driven")
		_assert_equal(data.quarry_value("requires_worker"), true, "quarry worker requirement is data-driven")
		_assert_equal(data.quarry_value("worker_role"), "miner", "quarry worker role is data-driven")
		_assert_equal(data.quarry_value("income_gold"), 3, "quarry income is data-driven")
		_assert_equal(data.terrain_building_ids("mountain"), ["iron_mine", "cliff_fort"], "terrain buildings are data-driven")
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
