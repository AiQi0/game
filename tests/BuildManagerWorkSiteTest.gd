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

			manager._track_placed_entity(city_hall, Rect2(Vector2(4600, 138), Vector2(400, 334)), false, "市政厅", "cityhall", false)
			manager._track_placed_entity(blacksmith, Rect2(Vector2(4510, 332), Vector2(180, 140)), true, "铁匠铺", "building", true)
			manager._track_placed_entity(tree, Rect2(Vector2(4468, 352), Vector2(64, 120)), true, "树", "tree", false)

			var sites: Array = manager.get_work_sites()
			_assert_equal(sites.size(), 1, "only player buildings are work sites")
			_assert_equal(sites[0].display_name, "铁匠铺", "work site keeps building name")
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
			manager._track_placed_entity(farm, Rect2(Vector2(4080, 412), Vector2(440, 120)), true, "鍐滅敯", "building", true, "farm")
			var farm_site_index: int = manager.get_work_sites().size() - 1
			var farm_entity_index: int = int(manager.get_work_sites()[farm_site_index].get("entity_index", -1))
			for worker_number in range(4):
				var worker_id := "Farmer_%02d" % [worker_number + 1]
				_assert_true(manager.claim_work_site(farm_entity_index, worker_id), "farm worker slot %d can be claimed" % [worker_number + 1])
				_assert_true(manager.occupy_work_site("farm_1", worker_id), "farm worker slot %d can enter" % [worker_number + 1])
			_assert_false(manager.claim_work_site(farm_entity_index, "Farmer_05"), "farm rejects a fifth worker")
			var farm_site: Dictionary = manager.get_work_sites()[farm_site_index]
			_assert_equal(farm_site.get("worker_capacity", 0), 4, "farm exposes four worker slots")
			_assert_equal(farm_site.get("worker_count", 0), 4, "farm records four assigned workers")
			_assert_equal(farm_site.get("workers_inside", []).size(), 4, "farm records four workers inside")

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
