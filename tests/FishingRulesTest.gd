extends SceneTree

var failures := 0


func _init() -> void:
	var rules_script := load("res://scripts/FishingRules.gd")
	var data_script := load("res://scripts/GameData.gd")
	if rules_script == null:
		_fail("FishingRules.gd should load")
	if data_script == null:
		_fail("GameData.gd should load")

	if rules_script != null and data_script != null:
		var rules = rules_script.new()
		var data = data_script.new()
		_test_bite_chance(rules, data)
		_test_bite_rolls(rules, data)
		_test_reel_progress(rules, data)

	if failures == 0:
		print("FishingRulesTest: PASS")
	else:
		push_error("FishingRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_bite_chance(rules, data) -> void:
	_assert_approx(rules.bite_chance_for_second(1, data), 0.05, "first second bite chance is five percent")
	_assert_approx(rules.bite_chance_for_second(2, data), 0.10, "second second bite chance is ten percent")
	_assert_approx(rules.bite_chance_for_second(3, data), 0.15, "third second bite chance is fifteen percent")
	_assert_approx(rules.bite_chance_for_second(4, data), 0.20, "fourth second bite chance is twenty percent")
	_assert_approx(rules.bite_chance_for_second(99, data), 0.80, "bite chance is capped")


func _test_bite_rolls(rules, data) -> void:
	_assert_true(rules.should_bite(1, 0.049, data), "roll below chance bites")
	_assert_false(rules.should_bite(1, 0.05, data), "roll equal to chance does not bite")
	_assert_false(rules.should_bite(1, 0.5, data), "roll above chance does not bite")


func _test_reel_progress(rules, data) -> void:
	var progress := float(data.fishing_value("reel_start_progress", 0.0))
	_assert_approx(progress, 0.2, "reeling starts at twenty percent")
	progress = rules.reel_progress_after_press(progress, data)
	_assert_approx(progress, 0.35, "pressing F adds reel progress")
	progress = rules.reel_progress_after_decay(progress, 1.0, data)
	_assert_approx(progress, 0.17, "reel progress decays over time")
	_assert_equal(rules.reel_outcome(1.0), "success", "full progress succeeds")
	_assert_equal(rules.reel_outcome(0.0), "failed", "zero progress fails")
	_assert_equal(rules.reel_outcome(0.5), "active", "middle progress remains active")


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_approx(actual: float, expected: float, message: String) -> void:
	if abs(actual - expected) > 0.001:
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
