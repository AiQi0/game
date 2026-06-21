extends SceneTree

const GameData = preload("res://scripts/GameData.gd")

var failures := 0


func _init() -> void:
	var rules_script := load("res://scripts/CollectionRules.gd")
	_assert_true(rules_script != null, "CollectionRules.gd loads")
	if rules_script != null:
		var rules = rules_script.new()
		var data := GameData.new()
		_test_fish_rolls(rules, data)
		_test_fish_codex_records(rules)
		_test_seed_drops(rules, data)

	if failures == 0:
		print("CollectionRulesTest: PASS")
	else:
		push_error("CollectionRulesTest: %d failure(s)" % failures)
	quit(failures)


func _test_fish_rolls(rules, data: GameData) -> void:
	var first: Dictionary = rules.fish_catch_from_rolls(0.0, 0.0, data)
	_assert_equal(first.get("id", ""), "silver_crucian", "lowest roll catches silver crucian")
	_assert_equal(first.get("weight", 0.0), 0.2, "lowest weight roll uses min weight")

	var legendary: Dictionary = rules.fish_catch_from_rolls(0.99, 1.0, data)
	_assert_equal(legendary.get("id", ""), "moon_kingfish", "highest roll catches legendary fish")
	_assert_equal(legendary.get("weight", 0.0), 12.0, "highest weight roll uses max weight")


func _test_fish_codex_records(rules) -> void:
	var first_update: Dictionary = rules.record_fish_catch({}, {
		"id": "river_bass",
		"display_name": "River Bass",
		"rarity": "common",
		"weight": 1.2,
	})
	_assert_true(first_update.get("is_new", false), "first fish catch is new")
	var codex: Dictionary = first_update.get("codex", {})
	var second_update: Dictionary = rules.record_fish_catch(codex, {
		"id": "river_bass",
		"display_name": "River Bass",
		"rarity": "common",
		"weight": 1.8,
	})
	var entry: Dictionary = second_update.get("codex", {}).get("river_bass", {})
	_assert_false(second_update.get("is_new", true), "second fish catch is not new")
	_assert_true(second_update.get("new_max", false), "larger second fish records new max")
	_assert_equal(entry.get("min_weight", 0.0), 1.2, "old min remains")
	_assert_equal(entry.get("max_weight", 0.0), 1.8, "new max is recorded")


func _test_seed_drops(rules, data: GameData) -> void:
	var unlocked := data.default_unlocked_crops()
	_assert_equal(rules.seed_drop_from_rolls("harvest", 0.5, 0.0, unlocked, data), "", "high drop roll gives no seed")
	var seed_id: String = rules.seed_drop_from_rolls("harvest", 0.0, 0.0, unlocked, data)
	_assert_true(seed_id != "" and seed_id != "wheat", "low harvest roll grants a locked crop seed")
	_assert_equal(rules.seed_drop_from_rolls("unknown", 0.0, 0.0, unlocked, data), "", "unknown activity never drops seeds")


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
