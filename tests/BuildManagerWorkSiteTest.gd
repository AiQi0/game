extends SceneTree

var failures := 0


func _init() -> void:
	var manager_script := load("res://scripts/BuildManager.gd")
	if manager_script == null:
		_fail("BuildManager.gd should load")

	if manager_script != null:
		var manager: Node2D = manager_script.new()

		if not manager.has_method("get_work_sites"):
			_fail("BuildManager should expose work sites")
		if not manager.has_method("claim_work_site"):
			_fail("BuildManager should claim one worker per site")
		if not manager.has_method("occupy_work_site"):
			_fail("BuildManager should mark a reserved site occupied after arrival")
		if not manager.has_method("_update_background_interiors"):
			_fail("BuildManager should update building interiors in the background")

		if manager.has_method("get_work_sites") and manager.has_method("claim_work_site") and manager.has_method("occupy_work_site"):
			var city_hall := Node2D.new()
			city_hall.global_position = Vector2(4800, 472)
			var blacksmith := Node2D.new()
			blacksmith.name = "blacksmith_1"
			blacksmith.global_position = Vector2(4600, 472)
			var window := Polygon2D.new()
			window.name = "WindowMain"
			window.color = Color(0.08, 0.1, 0.13, 1)
			blacksmith.add_child(window)
			var tree := Node2D.new()
			tree.global_position = Vector2(4500, 472)

			manager._track_placed_entity(city_hall, Rect2(Vector2(4600, 138), Vector2(400, 334)), false, "CityHall", "cityhall", false, "cityhall")
			manager._track_placed_entity(blacksmith, Rect2(Vector2(4510, 332), Vector2(180, 140)), true, "Blacksmith", "building", true, "blacksmith")
			manager._track_placed_entity(tree, Rect2(Vector2(4468, 352), Vector2(64, 120)), true, "Tree", "tree", false, "tree")

			var sites: Array = manager.get_work_sites()
			_assert_equal(sites.size(), 1, "only player buildings are work sites")
			_assert_equal(sites[0].display_name, "Blacksmith", "work site keeps building name")
			_assert_equal(sites[0].worker_id, "", "new work site starts empty")
			_assert_true(manager.claim_work_site(sites[0].entity_index, "Villager_01"), "first worker claims site")
			_assert_equal(window.color, Color(0.08, 0.1, 0.13, 1), "claimed work site stays dark before arrival")
			_assert_false(manager.claim_work_site(sites[0].entity_index, "Villager_02"), "second worker cannot claim occupied site")
			_assert_equal(manager.get_work_sites()[0].worker_id, "Villager_01", "claimed site stores worker id")
			_assert_true(manager.occupy_work_site("blacksmith_1", "Villager_01"), "arrived worker occupies claimed site")
			_assert_true(window.color != Color(0.08, 0.1, 0.13, 1), "occupied work site lights windows")
			_assert_true(manager.get_work_sites()[0].worker_inside, "occupied site records worker inside")
			_assert_false(manager.occupy_work_site("blacksmith_1", "Villager_01"), "occupied site cannot be occupied twice by duplicate worker id")

			var farm := Node2D.new()
			farm.name = "farm_1"
			farm.global_position = Vector2(4300, 472)
			manager._track_placed_entity(farm, Rect2(Vector2(4080, 412), Vector2(440, 120)), true, "Farm", "building", true, "farm")
			var farm_site_index: int = manager.get_work_sites().size() - 1
			var farm_entity_index: int = int(manager.get_work_sites()[farm_site_index].get("entity_index", -1))
			_assert_true(manager.claim_work_site(farm_entity_index, "Farmer_01"), "farm single worker slot can be claimed")
			_assert_true(manager.occupy_work_site("farm_1", "Farmer_01"), "farm single worker slot can enter")
			_assert_false(manager.claim_work_site(farm_entity_index, "Farmer_02"), "farm rejects a second worker")
			_assert_false(manager.occupy_work_site("farm_1", "Farmer_02"), "unclaimed second worker cannot enter farm")
			var farm_site: Dictionary = manager.get_work_sites()[farm_site_index]
			_assert_equal(farm_site.get("worker_capacity", 0), 1, "farm exposes one worker slot")
			_assert_equal(farm_site.get("worker_count", 0), 1, "farm records one assigned worker")
			_assert_equal(farm_site.get("workers_inside", []).size(), 1, "farm records one worker inside")

			var overfilled_farm: Dictionary = manager.placed_buildings[farm_entity_index]
			manager._set_work_site_workers(overfilled_farm, ["Farmer_01", "Farmer_02", "Farmer_03"], ["Farmer_01", "Farmer_02", "Farmer_03"])
			manager.placed_buildings[farm_entity_index] = overfilled_farm
			farm_site = manager.get_work_sites()[farm_site_index]
			_assert_equal(farm_site.get("worker_count", 0), 1, "overfilled farm worker list is normalized to one")
			_assert_equal(farm_site.get("workers_inside", []).size(), 1, "overfilled farm inside list is normalized to one")

			if manager.has_method("_update_background_interiors"):
				manager.gold = 0
				var background_farm: Dictionary = manager.placed_buildings[farm_entity_index]
				background_farm.interior_state = {}
				manager._set_work_site_workers(background_farm, ["Farmer_01"], ["Farmer_01"])
				manager.placed_buildings[farm_entity_index] = background_farm
				manager._update_background_interiors(2.0)
				background_farm = manager.placed_buildings[farm_entity_index]
				var plots: Array = background_farm.get("interior_state", {}).get("plots", [])
				_assert_equal(plots[0].get("stage", ""), "growing", "background farm worker sows without player entering interior")
				_assert_equal(background_farm.get("interior_state", {}).get("worker_position", []), [260.0, 748.0], "background farm stores worker position at the worked plot")
				manager._update_background_interiors(295.9)
				background_farm = manager.placed_buildings[farm_entity_index]
				plots = background_farm.get("interior_state", {}).get("plots", [])
				_assert_equal(plots[0].get("stage", ""), "growing", "background farm crop keeps growing before full cycle")
				manager._update_background_interiors(0.2)
				background_farm = manager.placed_buildings[farm_entity_index]
				plots = background_farm.get("interior_state", {}).get("plots", [])
				_assert_equal(plots[0].get("stage", ""), "harvesting", "background farm crop grows without player entering interior")
				manager._update_background_interiors(1.8)
				background_farm = manager.placed_buildings[farm_entity_index]
				plots = background_farm.get("interior_state", {}).get("plots", [])
				_assert_equal(plots[0].get("stage", ""), "empty", "background farm worker harvests without player entering interior")
				_assert_equal(manager.gold, 1, "background farm harvest pays crop reward")

				var lumberyard := Node2D.new()
				lumberyard.name = "lumberyard_1"
				lumberyard.global_position = Vector2(3900, 472)
				manager._track_placed_entity(lumberyard, Rect2(Vector2(3780, 352), Vector2(240, 120)), true, "Lumberyard", "building", true, "lumberyard")
				var lumberyard_index: int = manager.placed_buildings.size() - 1
				var lumberyard_entity: Dictionary = manager.placed_buildings[lumberyard_index]
				manager._update_background_interiors(120.0)
				lumberyard_entity = manager.placed_buildings[lumberyard_index]
				_assert_equal((lumberyard_entity.get("interior_state", {}).get("resources", []) as Array).size(), 3, "background lumberyard grows trees without player entering interior")
				lumberyard.free()

			city_hall.free()
			blacksmith.free()
			farm.free()
			tree.free()

		manager.free()

	if failures == 0:
		print("BuildManagerWorkSiteTest: PASS")
	else:
		push_error("BuildManagerWorkSiteTest: %d failure(s)" % failures)

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
