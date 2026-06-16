extends SceneTree

var failures := 0


func _init() -> void:
	var rules_script := load("res://scripts/DayNightRules.gd")
	if rules_script == null:
		_fail("DayNightRules.gd should load")

	if rules_script != null:
		var rules = rules_script.new()
		_test_phase_timing(rules)
		_test_phase_progress(rules)
		_test_arc_positions(rules)

	if failures == 0:
		print("DayNightRulesTest: PASS")
	else:
		push_error("DayNightRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_phase_timing(rules) -> void:
	_assert_equal(rules.phase_for_time(0.0), "day", "cycle starts during day")
	_assert_equal(rules.phase_for_time(299.9), "day", "first five minutes are day")
	_assert_equal(rules.phase_for_time(300.0), "night", "second five minutes start night")
	_assert_equal(rules.phase_for_time(599.9), "night", "second five minutes are night")
	_assert_equal(rules.phase_for_time(600.0), "day", "cycle loops back to day")


func _test_phase_progress(rules) -> void:
	_assert_approx(rules.phase_progress(0.0), 0.0, "day starts at progress zero")
	_assert_approx(rules.phase_progress(150.0), 0.5, "day midpoint is half progress")
	_assert_approx(rules.phase_progress(300.0), 0.0, "night starts at progress zero")
	_assert_approx(rules.phase_progress(450.0), 0.5, "night midpoint is half progress")


func _test_arc_positions(rules) -> void:
	_assert_vec2_approx(
		rules.celestial_arc_position(0.0, Vector2(1920, 1080)),
		Vector2(160, 300),
		"arc starts low on the left"
	)
	_assert_vec2_approx(
		rules.celestial_arc_position(0.5, Vector2(1920, 1080)),
		Vector2(960, 96),
		"arc midpoint is high in the sky"
	)
	_assert_vec2_approx(
		rules.celestial_arc_position(1.0, Vector2(1920, 1080)),
		Vector2(1760, 300),
		"arc ends low on the right"
	)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_approx(actual: float, expected: float, message: String) -> void:
	if abs(actual - expected) > 0.001:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_vec2_approx(actual: Vector2, expected: Vector2, message: String) -> void:
	if actual.distance_to(expected) > 0.01:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
