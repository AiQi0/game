extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	if game_data_script == null:
		_fail("GameData.gd should load")

	if game_data_script != null:
		var data = game_data_script.new()
		_assert_equal(data.world_value("ground_max_x"), 9600.0, "world ground width is data-driven")
		_assert_equal(data.economy_value("starting_gold"), 99, "starting gold is data-driven")
		_assert_equal(data.tool_value("bow", "display_name"), "弓", "bow display name is data-driven")
		_assert_equal(data.tool_ids_for_role("villager"), ["stone_sword", "sword", "bow"], "villager tool choices are data-driven")
		_assert_equal(data.tool_ids_for_role("miner"), ["stone_pickaxe"], "miner tool choices are data-driven")
		_assert_equal(data.npc_role_value("archer", "attack_power"), 1, "archer attack power is data-driven")
		_assert_equal(data.npc_role_value("archer", "attack_range"), 600.0, "archer attack range is data-driven")
		_assert_equal(data.npc_role_value("archer", "wall_attack_range"), 900.0, "wall archer range is data-driven")
		_assert_equal(data.arrow_value("landed_visible_seconds"), 5.0, "arrow landed duration is data-driven")
		_assert_equal(data.building_upgrade_cost("cityhall", 2), 50, "building upgrade costs are data-driven")
		_assert_equal(data.building_upgrade_requirements("farm", 2), {"cityhall": 2}, "building upgrade unlocks are data-driven")
		_assert_equal(data.world_value("stone_count"), 3, "initial stone count is data-driven")
		_assert_equal(data.quarry_value("cost"), 20, "quarry cost is data-driven")
		_assert_equal(data.quarry_value("requires_worker"), true, "quarry worker requirement is data-driven")
		_assert_equal(data.quarry_value("worker_role"), "miner", "quarry worker role is data-driven")
		_assert_equal(data.quarry_value("income_gold"), 3, "quarry income is data-driven")
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
