extends SceneTree

const GameData = preload("res://scripts/GameData.gd")

var failures := 0


func _init() -> void:
	var interior_script := load("res://scripts/BuildingInteriorManager.gd")
	var session_script := load("res://scripts/GameSession.gd")
	_assert_true(interior_script != null, "BuildingInteriorManager.gd loads")
	_assert_true(ResourceLoader.exists("res://scenes/BuildingInterior.tscn"), "BuildingInterior scene exists")
	_assert_true(session_script != null, "GameSession.gd loads")

	if interior_script != null:
		_test_farm_cycle(interior_script)
		_test_farm_outdoor_layout_and_models(interior_script)
		_test_worker_position_persists_between_entries(interior_script)
		_test_resource_rooms(interior_script)
		_test_seed_collection_does_not_pause_work(interior_script)
		_test_exit_requires_door(interior_script)
	if session_script != null:
		_test_game_session_interior_context(session_script)

	if failures == 0:
		print("BuildingInteriorTest: PASS")
	else:
		push_error("BuildingInteriorTest: %d failure(s)" % failures)
	quit(failures)


func _test_farm_cycle(interior_script: Script) -> void:
	var interior: Node = _make_interior(interior_script, "farm", [{"worker_id": "Farmer_01", "tool_multiplier": 1.0}])
	interior.worker_visual = Node2D.new()
	interior.worker_visual.position = interior._plot_position(0) + Vector2(0, 8)
	var plots: Array = interior.interior_state.get("plots", [])
	_assert_equal(plots.size(), 6, "farm interior creates six plots")
	_assert_equal(interior.interior_definition.get("cycle_seconds", 0.0), 300.0, "farm cycle is three hundred seconds")
	_assert_equal(interior.interior_definition.get("sow_action_seconds", 0.0), 2.0, "farm sow action takes two seconds")
	_assert_equal(interior.interior_definition.get("harvest_action_seconds", 0.0), 2.0, "farm harvest action takes two seconds")

	interior._update_farm(0.1)
	plots = interior.interior_state.get("plots", [])
	_assert_equal(plots[0].get("stage", ""), "sowing", "worker starts sowing the first empty plot")
	_assert_equal(plots[1].get("stage", ""), "empty", "worker does not sow every empty plot at once")
	interior._update_farm(1.9)
	plots = interior.interior_state.get("plots", [])
	_assert_equal(plots[0].get("stage", ""), "growing", "after two seconds the first plot has been sown")
	interior.worker_visual.position = Vector2(1200, 792)
	interior._update_farm(296.0)
	plots = interior.interior_state.get("plots", [])
	_assert_equal(plots[0].get("stage", ""), "harvesting", "after growth the first plot waits for harvest action")
	interior.worker_visual.position = interior._plot_position(0) + Vector2(0, 8)
	interior._update_farm(2.0)
	_assert_equal(interior.gold_delta, 1, "one worked plot harvests one gold after full cycle")
	plots = interior.interior_state.get("plots", [])
	_assert_equal(plots[0].get("stage", ""), "empty", "harvested plot returns to empty for next cycle")
	interior.worker_visual.free()
	interior.worker_visual = null
	interior.free()


func _test_farm_outdoor_layout_and_models(interior_script: Script) -> void:
	var interior: Node = _make_interior(interior_script, "farm", [{"worker_id": "Farmer_01", "role": "farmer", "tool_multiplier": 1.0}])
	interior._create_scene_nodes()
	var hut := interior.get_node_or_null("FarmHut") as Node2D
	_assert_true(hut != null, "farm interior has a small hut")
	if hut != null:
		_assert_true(hut.position.x > 1200.0, "farm hut is placed on the right side")

	interior._refresh_visuals()
	var plots := interior.get_node_or_null("Plots")
	_assert_true(plots != null, "farm has plot container")
	if plots != null:
		_assert_equal(plots.get_child_count(), 6, "farm keeps six plantable plots")
		var previous_x := -INF
		var row_y := INF
		for child in plots.get_children():
			var plot := child as Node2D
			_assert_true(plot != null and plot.position.x < 1150.0, "%s stays on the left side" % child.name)
			if plot != null:
				if row_y == INF:
					row_y = plot.position.y
				else:
					_assert_equal(plot.position.y, row_y, "%s stays in the same row" % child.name)
				_assert_true(plot.position.x > previous_x, "%s is ordered left to right" % child.name)
				previous_x = plot.position.x

	_assert_sprite_texture_path(interior.get_node_or_null("InteriorPlayer"), "GeneratedSprite", "res://assets/medieval_pixel_pack_v3_no_outline/npcs/player.png", "interior player uses generated model")
	_assert_sprite_texture_path(interior.get_node_or_null("InteriorWorker"), "GeneratedSprite", "res://assets/medieval_pixel_pack_v3_no_outline/npcs/farmer.png", "interior worker uses role model")
	_assert_true(interior.player.z_index > interior.plot_container.z_index, "interior player renders above farm plots")
	_assert_true(interior.worker_visual.z_index > interior.plot_container.z_index, "interior worker renders above farm plots")
	interior.building_display_name = "农田"
	interior._refresh_runtime_labels()
	_assert_true(interior.status_label.text.contains("门口按 S 返回"), "interior status label is Chinese")
	_assert_true(interior.detail_label.text.contains("本室内获得金币"), "interior detail label is Chinese")
	_assert_true(interior.progress_label.text.contains("农田作物"), "farm progress label is Chinese")
	var wheat_button := interior.crop_button_container.get_node_or_null("Crop_wheat") as Button
	_assert_true(wheat_button != null and wheat_button.text == "小麦", "crop button uses Chinese crop name")
	interior.free()


func _test_worker_position_persists_between_entries(interior_script: Script) -> void:
	var first_entry: Node = _make_interior(interior_script, "farm", [{"worker_id": "Farmer_01", "role": "farmer", "tool_multiplier": 1.0}])
	first_entry._create_scene_nodes()
	var target_position: Vector2 = first_entry._plot_position(2) + Vector2(0, 8)
	first_entry._move_worker_to(target_position, 10.0)
	var result: Dictionary = first_entry._result_snapshot()
	first_entry.free()

	var second_entry: Node = _make_interior(interior_script, "farm", [{"worker_id": "Farmer_01", "role": "farmer", "tool_multiplier": 1.0}])
	second_entry.interior_state = (result.get("interior_state", {}) as Dictionary).duplicate(true)
	second_entry._ensure_layout_state()
	second_entry._create_scene_nodes()
	_assert_equal(second_entry.worker_visual.position, target_position, "worker keeps saved interior position when re-entering scene")
	second_entry.free()


func _test_resource_rooms(interior_script: Script) -> void:
	var lumberyard: Node = _make_interior(interior_script, "lumberyard", [])
	lumberyard._update_resource_room(120.0)
	_assert_equal((lumberyard.interior_state.get("resources", []) as Array).size(), 3, "lumberyard interior grows three trees every two minutes")
	lumberyard.free()

	var quarry: Node = _make_interior(interior_script, "quarry", [])
	quarry._update_resource_room(60.0)
	_assert_equal((quarry.interior_state.get("resources", []) as Array).size(), 1, "quarry interior grows one stone every minute")
	quarry.free()

	var working_quarry: Node = _make_interior(interior_script, "quarry", [{"worker_id": "Miner_01", "tool_multiplier": 1.0}])
	working_quarry.interior_state.resources = [{"id": "stone_1", "kind": "stone", "progress": 0.0, "x": 520.0}]
	working_quarry._update_resource_room(60.0)
	_assert_equal((working_quarry.interior_state.get("resources", []) as Array).size(), 1, "miner completes one stone while the room spawns the next periodic stone")
	_assert_equal(working_quarry.gold_delta, 3, "stone interior work keeps existing stone reward")
	working_quarry.free()


func _test_seed_collection_does_not_pause_work(interior_script: Script) -> void:
	var interior: Node = _make_interior(interior_script, "farm", [{"worker_id": "Farmer_01", "tool_multiplier": 1.0}])
	interior.interior_state.worker_seed_rewards = {"Farmer_01": "carrot"}
	interior.player = Node2D.new()
	interior.player.position = Vector2(300, 792)
	interior.worker_visual = Node2D.new()
	interior.worker_visual.position = Vector2(300, 792)
	_assert_true(interior._try_collect_worker_seed(), "player can collect pending NPC seed with E range")
	_assert_true(bool(interior.unlocked_crops.get("carrot", false)), "collected seed unlocks crop")
	interior._update_farm(1.0)
	var plots: Array = interior.interior_state.get("plots", [])
	_assert_true(plots[0].get("stage", "") != "", "NPC seed reward did not pause farm work")
	interior.player.free()
	interior.worker_visual.free()
	interior.free()


func _test_exit_requires_door(interior_script: Script) -> void:
	var interior: Node = _make_interior(interior_script, "farm", [])
	interior.player = Node2D.new()
	interior.player.position = Vector2(900, 792)
	_assert_false(interior._player_at_door(), "S return is blocked away from the door")
	interior.player.position = interior.door_position
	_assert_true(interior._player_at_door(), "S return is available at the door")
	interior.player.free()
	interior.free()


func _test_game_session_interior_context(session_script: Script) -> void:
	var session: Node = session_script.new()
	var context := {"building_id": "farm", "building_node_name": "farm_1"}
	_assert_true(session.set_active_interior_context(context), "GameSession stores interior context")
	_assert_equal(session.active_interior_context().get("building_id", ""), "farm", "GameSession returns interior context")
	session.clear_active_interior_context()
	_assert_equal(session.active_interior_context().size(), 0, "GameSession clears interior context")
	_assert_true(session.set_pending_interior_result({"building_node_name": "farm_1"}), "GameSession stores pending interior result")
	_assert_equal(session.consume_pending_interior_result().get("building_node_name", ""), "farm_1", "GameSession consumes pending interior result")
	session.free()


func _make_interior(interior_script: Script, building_id: String, workers: Array) -> Node:
	var interior: Node = interior_script.new()
	var data := GameData.new()
	interior.building_id = building_id
	interior.building_node_name = "%s_1" % building_id
	interior.building_display_name = building_id
	interior.interior_definition = data.building_interior_definition(building_id)
	interior.unlocked_crops = data.default_unlocked_crops()
	interior.selected_crop_id = "wheat"
	interior.workers = workers.duplicate(true)
	interior.interior_state = {}
	interior._ensure_layout_state()
	return interior


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _assert_sprite_texture_path(owner: Node, node_path: String, expected_path: String, message: String) -> void:
	_assert_true(owner != null, "%s owner exists" % message)
	if owner == null:
		return
	var node := owner.get_node_or_null(node_path)
	_assert_true(node is Sprite2D, "%s is Sprite2D" % message)
	if not (node is Sprite2D):
		return
	var sprite := node as Sprite2D
	_assert_true(sprite.texture != null, "%s has texture" % message)
	if sprite.texture == null:
		return
	_assert_equal(sprite.texture.resource_path, expected_path, message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
