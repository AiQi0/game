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

		_assert_equal(manager.get("gold"), 99, "game starts with 99 gold")
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
			_assert_true(manager.can_afford_building(buildings[0]), "99 gold can afford blacksmith")
			_assert_true(manager.spend_gold_for_building(buildings[0]), "building blacksmith spends gold")
			_assert_equal(manager.gold, 89, "blacksmith leaves 89 gold")
			_assert_true(manager.spend_gold_for_building(buildings[3]), "89 gold can afford tavern")
			_assert_equal(manager.gold, 69, "tavern leaves 69 gold")
			manager.add_gold(1)
			_assert_equal(manager.gold, 70, "add_gold increases balance")

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
			manager._update_farm_income(59.0)
			_assert_equal(manager.gold, 0, "occupied farm does not pay before one minute")
			manager._update_farm_income(1.0)
			_assert_equal(manager.gold, 1, "occupied farm produces one gold per minute")
			farm.free()

		manager.free()

	if failures == 0:
		print("EconomyTest: PASS")
	else:
		push_error("EconomyTest: %d failure(s)" % failures)

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
