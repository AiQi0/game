extends SceneTree

var failures := 0


func _init() -> void:
	var manager_script := load("res://scripts/BuildManager.gd")
	if manager_script == null:
		_fail("BuildManager.gd should load")

	if manager_script != null:
		var manager: Node2D = manager_script.new()
		var left_air_wall := Rect2(Vector2(-96, -1000), Vector2(96, 2000))
		var right_air_wall := Rect2(Vector2(9600, -1000), Vector2(96, 2000))
		var building_footprint := Rect2(Vector2(4510, 332), Vector2(180, 140))
		manager.placed_footprints.append(left_air_wall)
		manager.placed_footprints.append(right_air_wall)

		var building := Node2D.new()
		building.name = "blacksmith_1"
		manager._track_placed_entity(
			building,
			building_footprint,
			true,
			"铁匠铺",
			"building",
			true
		)

		manager.demolition_target_index = 0
		manager._demolish_target()

		_assert_equal(manager.placed_footprints.size(), 2, "demolishing removes exactly one footprint")
		_assert_true(manager.placed_footprints.has(left_air_wall), "left air wall footprint remains")
		_assert_true(manager.placed_footprints.has(right_air_wall), "right air wall footprint remains")
		_assert_false(
			manager.rules.has_overlap(building_footprint, manager.placed_footprints),
			"demolished building footprint no longer blocks rebuilding at same location"
		)
		building.free()
		manager.free()

	if failures == 0:
		print("DemolishClearsFootprintTest: PASS")
	else:
		push_error("DemolishClearsFootprintTest: %d failure(s)" % failures)

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
