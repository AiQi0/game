extends SceneTree

var failures := 0


func _init() -> void:
	var manager_script := load("res://scripts/BuildManager.gd")
	var catalog_script := load("res://scripts/BuildingCatalog.gd")
	if manager_script == null:
		_fail("BuildManager.gd should load")
	if catalog_script == null:
		_fail("BuildingCatalog.gd should load")

	if manager_script != null and catalog_script != null:
		var manager: Node2D = manager_script.new()
		var catalog = catalog_script.new()
		var buildings: Array = catalog.get_buildings()

		_assert_equal(manager.get("gold"), 30, "game starts with 30 gold")
		_assert_equal(manager.get("selected_index"), -1, "game starts with no build bar slot selected")
		_assert_true(manager.has_method("can_afford_building"), "BuildManager can check building affordability")
		_assert_true(manager.has_method("spend_gold_for_building"), "BuildManager can spend gold for buildings")
		_assert_true(manager.has_method("add_gold"), "BuildManager can add gold")
		_assert_true(manager.has_method("_update_farm_income"), "BuildManager updates farm income")

		if (
			manager.get("gold") != null
			and manager.has_method("can_afford_building")
			and manager.has_method("spend_gold_for_building")
			and manager.has_method("add_gold")
		):
			_assert_true(manager.can_afford_building(buildings[0]), "30 gold can afford blacksmith")
			_assert_true(manager.spend_gold_for_building(buildings[0]), "building blacksmith spends gold")
			_assert_equal(manager.gold, 20, "blacksmith leaves 20 gold")
			_assert_true(manager.spend_gold_for_building(buildings[2]), "20 gold can afford tavern")
			_assert_equal(manager.gold, 0, "tavern leaves 0 gold")
			manager.add_gold(1)
			_assert_equal(manager.gold, 1, "add_gold increases balance")

		if manager.has_method("_refresh_building_choices") and manager.has_method("_create_ui"):
			_test_build_bar_gold_refresh(manager)

		if manager.get("gold") != null and manager.has_method("_update_farm_income"):
			manager.gold = 0
			var farm := Node2D.new()
			farm.name = "farm_1"
			farm.global_position = Vector2(4600, 472)
			manager._track_placed_entity(
				farm,
				Rect2(Vector2(4490, 412), Vector2(220, 60)),
				true,
				"农田",
				"building",
				true
			)
			_assert_true(manager.claim_work_site(0, "Villager_01"), "farm can be claimed")
			_assert_true(manager.occupy_work_site("farm_1", "Villager_01"), "farm can be occupied")
			_assert_false(manager.claim_work_site(0, "Villager_02"), "farm cannot accept a second villager")
			_assert_false(manager.occupy_work_site("farm_1", "Villager_02"), "second villager cannot enter farm")
			manager._update_farm_income(59.0)
			_assert_equal(manager.gold, 0, "occupied farm does not pay before one minute")
			manager._update_farm_income(1.0)
			_assert_equal(manager.gold, 1, "single occupied farm worker produces one gold per minute")
			farm.free()

		manager.free()

	if failures == 0:
		print("EconomyTest: PASS")
	else:
		push_error("EconomyTest: %d failure(s)" % failures)

	quit(failures)


func _test_build_bar_gold_refresh(manager: Node2D) -> void:
	manager.gold = 0
	manager.selected_index = 0
	manager._refresh_building_choices()
	manager._create_ui()
	manager._refresh_ui()

	_assert_true(manager.ui_slots.size() > 0, "build bar has at least one slot")
	if manager.ui_slots.is_empty():
		return

	var slot: Label = manager.ui_slots[0]
	_assert_equal(
		slot.get_theme_color("font_color"),
		Color(0.52, 0.56, 0.55, 1),
		"selected unaffordable building slot is gray"
	)

	manager.add_gold(10)
	_assert_equal(
		slot.get_theme_color("font_color"),
		Color(1.0, 0.92, 0.45, 1),
		"building slot refreshes automatically when added gold makes it affordable"
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
