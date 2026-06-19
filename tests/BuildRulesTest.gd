extends SceneTree

var failures := 0


func _init() -> void:
	var catalog_script := load("res://scripts/BuildingCatalog.gd")
	var rules_script := load("res://scripts/BuildRules.gd")

	if catalog_script == null:
		_fail("BuildingCatalog.gd should load")
	if rules_script == null:
		_fail("BuildRules.gd should load")

	if catalog_script != null and rules_script != null:
		var catalog = catalog_script.new()
		var rules = rules_script.new()

		_test_catalog(catalog)
		_test_number_row_selection(rules)
		_test_selection_toggle(rules)
		_test_build_position(rules)
		_test_footprints(rules)
		_test_overlap_rules(rules)
		_test_demolition_targeting(rules)
		_test_demolishable_entity_targeting(rules)
		_test_random_tree_positions(rules)
		_test_lumberyard_tree_positions(rules)
		_test_air_wall_footprints(rules)

	if failures == 0:
		print("BuildRulesTest: PASS")
	else:
		push_error("BuildRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_catalog(catalog) -> void:
	var buildings: Array = catalog.get_buildings()
	_assert_equal(buildings.size(), 5, "catalog has five build targets")
	_assert_equal(buildings[0].display_name, "铁匠铺", "slot 1 is blacksmith")
	_assert_equal(buildings[0].get("cost"), 10, "blacksmith costs 10 gold")
	_assert_equal(buildings[1].display_name, "城墙", "slot 2 is wall")
	_assert_equal(buildings[1].get("cost"), 5, "wall costs 5 gold")
	_assert_equal(buildings[2].display_name, "农田", "slot 3 is farm")
	_assert_equal(buildings[2].get("cost"), 5, "farm costs 5 gold")
	_assert_equal(buildings[3].display_name, "酒馆", "slot 4 is tavern")
	_assert_equal(buildings[3].get("cost"), 20, "tavern costs 20 gold")
	_assert_equal(buildings[4].id, "lumberyard", "slot 5 is lumberyard")
	_assert_equal(buildings[4].keycode, KEY_5, "lumberyard uses top-row 5")
	_assert_equal(buildings[4].get("cost"), 10, "lumberyard costs 10 gold")
	_assert_equal(buildings[0].keycode, KEY_1, "blacksmith uses top-row 1")
	_assert_equal(buildings[3].keycode, KEY_4, "tavern uses top-row 4")


func _test_number_row_selection(rules) -> void:
	_assert_equal(rules.selected_index_from_key(KEY_1), 0, "top-row 1 selects first slot")
	_assert_equal(rules.selected_index_from_key(KEY_2), 1, "top-row 2 selects second slot")
	_assert_equal(rules.selected_index_from_key(KEY_3), 2, "top-row 3 selects third slot")
	_assert_equal(rules.selected_index_from_key(KEY_4), 3, "top-row 4 selects fourth slot")
	_assert_equal(rules.selected_index_from_key(KEY_5), 4, "top-row 5 selects lumberyard")
	_assert_equal(rules.selected_index_from_key(KEY_KP_1), -1, "keypad 1 does not select a slot")
	_assert_equal(rules.selected_index_from_key(KEY_KP_4), -1, "keypad 4 does not select a slot")
	_assert_equal(rules.selected_index_from_key(KEY_KP_5), -1, "keypad 5 does not select a slot")


func _test_selection_toggle(rules) -> void:
	if not rules.has_method("selected_index_after_request"):
		_fail("BuildRules should support toggling repeated building selection")
		return

	_assert_equal(
		rules.selected_index_after_request(-1, 0),
		0,
		"selecting a slot from no selection activates it"
	)
	_assert_equal(
		rules.selected_index_after_request(0, 0),
		-1,
		"selecting the active slot cancels selection"
	)
	_assert_equal(
		rules.selected_index_after_request(0, 2),
		2,
		"selecting a different slot switches selection"
	)


func _test_build_position(rules) -> void:
	var size := Vector2(100, 80)
	_assert_equal(
		rules.build_position_for_player(Vector2(4800, 472), 1, size, 472.0),
		Vector2(4906, 472),
		"right-facing build preview is in front of player"
	)
	_assert_equal(
		rules.build_position_for_player(Vector2(4800, 472), -1, size, 472.0),
		Vector2(4694, 472),
		"left-facing build preview is in front of player"
	)


func _test_footprints(rules) -> void:
	_assert_equal(
		rules.footprint_for_position(Vector2(100, 472), Vector2(80, 60)),
		Rect2(Vector2(60, 412), Vector2(80, 60)),
		"footprint uses bottom-center position"
	)


func _test_overlap_rules(rules) -> void:
	var placed := [Rect2(Vector2(0, 0), Vector2(100, 100))]

	_assert_true(
		rules.has_overlap(Rect2(Vector2(50, 20), Vector2(60, 60)), placed),
		"overlapping footprint is blocked"
	)
	_assert_false(
		rules.has_overlap(Rect2(Vector2(100, 0), Vector2(50, 50)), placed),
		"touching footprint edge is allowed"
	)
	_assert_false(
		rules.has_overlap(Rect2(Vector2(140, 0), Vector2(50, 50)), placed),
		"separate footprint is allowed"
	)


func _test_demolition_targeting(rules) -> void:
	if not rules.has_method("footprint_index_containing_point"):
		_fail("BuildRules should find a demolition target from player position")
		return

	var footprints := [
		Rect2(Vector2(100, 300), Vector2(120, 172)),
		Rect2(Vector2(300, 360), Vector2(90, 112)),
	]

	_assert_equal(
		rules.footprint_index_containing_point(Vector2(160, 472), footprints),
		0,
		"player on bottom edge of first footprint targets first building"
	)
	_assert_equal(
		rules.footprint_index_containing_point(Vector2(345, 420), footprints),
		1,
		"player inside second footprint targets second building"
	)
	_assert_equal(
		rules.footprint_index_containing_point(Vector2(90, 472), footprints),
		-1,
		"player outside all footprints has no demolition target"
	)


func _test_demolishable_entity_targeting(rules) -> void:
	if not rules.has_method("demolishable_entity_index_containing_point"):
		_fail("BuildRules should skip non-demolishable entities")
		return

	var city_hall := {
		"name": "CityHall",
		"demolishable": false,
		"footprint": Rect2(Vector2(4600, 138), Vector2(400, 334)),
	}
	var tree := {
		"name": "Tree",
		"demolishable": true,
		"footprint": Rect2(Vector2(5200, 352), Vector2(64, 120)),
	}
	var entities := [city_hall, tree]

	_assert_equal(
		rules.demolishable_entity_index_containing_point(Vector2(4800, 472), entities),
		-1,
		"city hall footprint is not a demolition target"
	)
	_assert_equal(
		rules.demolishable_entity_index_containing_point(Vector2(5232, 472), entities),
		1,
		"tree footprint is a demolition target"
	)


func _test_random_tree_positions(rules) -> void:
	if not rules.has_method("random_tree_positions"):
		_fail("BuildRules should generate random tree positions")
		return

	var tree_size := Vector2(64, 120)
	var blocked := [Rect2(Vector2(4600, 138), Vector2(400, 334))]
	var positions: Array = rules.random_tree_positions(20260616, 8, 0.0, 9600.0, 472.0, tree_size, blocked)
	var occupied := blocked.duplicate()

	_assert_equal(positions.size(), 8, "random tree generation returns requested count")

	for position in positions:
		var footprint = rules.footprint_for_position(position, tree_size)
		_assert_true(position.x >= tree_size.x * 0.5, "tree is inside left ground edge")
		_assert_true(position.x <= 9600.0 - tree_size.x * 0.5, "tree is inside right ground edge")
		_assert_false(rules.has_overlap(footprint, occupied), "tree does not overlap blocked footprints")
		occupied.append(footprint)


func _test_lumberyard_tree_positions(rules) -> void:
	if not rules.has_method("tree_positions_around_source"):
		_fail("BuildRules should generate lumberyard trees around a source building")
		return

	var tree_size := Vector2(64, 120)
	var source_position := Vector2(3000, 472)
	var blocked := [
		Rect2(Vector2(2900, 342), Vector2(200, 130)),
		Rect2(Vector2(3032, 352), Vector2(64, 120)),
	]
	var positions: Array = rules.tree_positions_around_source(
		20260617,
		3,
		source_position,
		420.0,
		0.0,
		9600.0,
		472.0,
		tree_size,
		blocked
	)
	var occupied := blocked.duplicate()

	_assert_equal(positions.size(), 3, "lumberyard grows three trees per batch")
	for position in positions:
		var footprint = rules.footprint_for_position(position, tree_size)
		_assert_true(absf(position.x - source_position.x) <= 420.0, "lumberyard tree grows near source")
		_assert_false(rules.has_overlap(footprint, occupied), "lumberyard tree grows on free ground")
		occupied.append(footprint)


func _test_air_wall_footprints(rules) -> void:
	if not rules.has_method("air_wall_footprints"):
		_fail("BuildRules should expose air wall footprints")
		return

	var footprints: Array = rules.air_wall_footprints(0.0, 9600.0, 96.0, 1000.0)
	_assert_equal(footprints.size(), 2, "map has two air wall footprints")
	_assert_equal(footprints[0].size.x, 96.0, "left air wall footprint is thickened")
	_assert_equal(footprints[1].size.x, 96.0, "right air wall footprint is thickened")
	_assert_true(
		rules.has_overlap(Rect2(Vector2(-12, 360), Vector2(80, 100)), footprints),
		"left air wall blocks build footprint"
	)
	_assert_true(
		rules.has_overlap(Rect2(Vector2(9560, 360), Vector2(80, 100)), footprints),
		"right air wall blocks build footprint"
	)
	_assert_false(
		rules.has_overlap(Rect2(Vector2(320, 360), Vector2(80, 100)), footprints),
		"interior footprint does not overlap air walls"
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
