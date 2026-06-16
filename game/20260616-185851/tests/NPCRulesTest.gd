extends SceneTree

var failures := 0


func _init() -> void:
	var rules_script := load("res://scripts/NPCRules.gd")
	if rules_script == null:
		_fail("NPCRules.gd should load")

	if rules_script != null:
		var rules = rules_script.new()
		_test_spawn_interval(rules)
		_test_spawn_roll(rules)
		_test_spawn_count_range(rules)
		_test_spawn_positions(rules)
		_test_nearest_available_work_site(rules)

	if failures == 0:
		print("NPCRulesTest: PASS")
	else:
		push_error("NPCRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_spawn_interval(rules) -> void:
	_assert_equal(rules.spawn_interval_seconds(), 300.0, "homeless spawn check runs every five minutes")


func _test_spawn_roll(rules) -> void:
	_assert_true(rules.should_spawn_from_roll(0.0), "roll below 30 percent spawns")
	_assert_true(rules.should_spawn_from_roll(0.299), "roll just below 30 percent spawns")
	_assert_false(rules.should_spawn_from_roll(0.3), "roll at 30 percent does not spawn")
	_assert_false(rules.should_spawn_from_roll(0.99), "high roll does not spawn")


func _test_spawn_count_range(rules) -> void:
	for seed in range(16):
		var count: int = rules.spawn_count_from_seed(seed)
		_assert_true(count >= 2, "spawn count is at least two")
		_assert_true(count <= 4, "spawn count is at most four")


func _test_spawn_positions(rules) -> void:
	var positions: Array = rules.spawn_positions_from_seed(20260616, 8, 0.0, 9600.0, 472.0)
	_assert_equal(positions.size(), 8, "creates requested spawn positions")

	for position in positions:
		_assert_true(position.x >= 0.0, "spawn is inside left map edge")
		_assert_true(position.x <= 9600.0, "spawn is inside right map edge")
		_assert_equal(position.y, 472.0, "spawn lands on ground top")


func _test_nearest_available_work_site(rules) -> void:
	if not rules.has_method("nearest_available_work_site_index"):
		_fail("NPCRules should select nearest available non-city-hall building")
		return

	var sites := [
		{
			"entity_index": 0,
			"display_name": "市政厅",
			"position": Vector2(4800, 472),
			"is_workplace": false,
			"worker_id": "",
		},
		{
			"entity_index": 1,
			"display_name": "铁匠铺",
			"position": Vector2(4600, 472),
			"is_workplace": true,
			"worker_id": "",
		},
		{
			"entity_index": 2,
			"display_name": "酒馆",
			"position": Vector2(4900, 472),
			"is_workplace": true,
			"worker_id": "Villager_01",
		},
		{
			"entity_index": 3,
			"display_name": "树",
			"position": Vector2(4500, 472),
			"is_workplace": false,
			"worker_id": "",
		},
	]

	_assert_equal(
		rules.nearest_available_work_site_index(Vector2(4880, 472), sites),
		1,
		"nearest available workplace skips city hall, tree, and occupied tavern"
	)

	sites[1].worker_id = "Villager_02"
	_assert_equal(
		rules.nearest_available_work_site_index(Vector2(4880, 472), sites),
		-1,
		"no available workplace when every building is occupied"
	)


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
