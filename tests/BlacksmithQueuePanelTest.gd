extends SceneTree

var failures := 0


func _init() -> void:
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if build_manager_script != null:
		var root := Node2D.new()
		var buildings_container := Node2D.new()
		buildings_container.name = "Buildings"
		root.add_child(buildings_container)

		var manager: Node2D = build_manager_script.new()
		manager.name = "BuildManager"
		root.add_child(manager)
		manager.buildings_container = buildings_container
		manager.gold = 20

		var blacksmith := Node2D.new()
		blacksmith.name = "blacksmith_1"
		blacksmith.global_position = Vector2(3000, 472)
		buildings_container.add_child(blacksmith)
		var footprint := Rect2(Vector2(2910, 332), Vector2(180, 140))
		manager._track_placed_entity(
			blacksmith,
			footprint,
			true,
			"铁匠铺",
			"building",
			true,
			"blacksmith"
		)
		var lumberyard := Node2D.new()
		lumberyard.name = "lumberyard_1"
		lumberyard.global_position = Vector2(3300, 472)
		buildings_container.add_child(lumberyard)
		manager._track_placed_entity(
			lumberyard,
			Rect2(Vector2(3200, 342), Vector2(200, 130)),
			true,
			"伐木场",
			"building",
			true,
			"lumberyard"
		)

		_assert_true(manager.has_method("cancel_blacksmith_craft"), "blacksmith can cancel unfinished crafting")
		_assert_true(manager.has_method("destroy_stored_tool"), "blacksmith can destroy completed tools")

		manager._show_building_info_panel(0)
		_assert_true(_find_button(manager.info_panel, "CraftSwordButton") != null, "blacksmith panel has sword button")
		_assert_true(_find_button(manager.info_panel, "CraftAxeButton") != null, "blacksmith panel has axe button")
		_assert_true(_find_button(manager.info_panel, "CraftSickleButton") != null, "blacksmith panel has sickle button")
		_assert_true(_find_button(manager.info_panel, "CraftBowButton") != null, "blacksmith panel has bow button")
		_assert_equal(_find_button(manager.info_panel, "CraftSwordButton").position, Vector2(20, 234), "sword craft button is moved down sixty pixels")
		_assert_equal(_find_button(manager.info_panel, "CraftAxeButton").position, Vector2(154, 234), "axe craft button is moved down sixty pixels")
		_assert_equal(_find_button(manager.info_panel, "CraftSickleButton").position, Vector2(288, 234), "sickle craft button is moved down sixty pixels")
		_assert_true(_panel_has_text(manager.info_panel, "队列"), "blacksmith panel shows crafting queue")
		_assert_true(_panel_has_text(manager.info_panel, "库存"), "blacksmith panel shows current stock")
		_assert_always_clickable(_find_button(manager.info_panel, "CraftBowButton"), "bow craft button")

		var axe_button := _find_button(manager.info_panel, "CraftAxeButton")
		_assert_true(_has_canvas_layer_ancestor(axe_button), "craft button is on a canvas UI layer for mouse clicks")
		_assert_always_clickable(axe_button, "craft button")
		if axe_button != null:
			axe_button.emit_signal("pressed")
		_assert_equal(manager.gold, 17, "clicking craft button spends three gold")
		_assert_equal(_queue_size(manager, 0), 1, "clicking craft button adds to queue")
		var first_cancel_button := _find_button(manager.info_panel, "CancelCraft0Button")
		_assert_equal(first_cancel_button.position, Vector2(142, 298), "queue cancel button is moved down eighty pixels")
		_assert_true(axe_button.z_index > first_cancel_button.z_index, "craft button stays above queued-work controls for mouse clicks")
		_assert_always_clickable(first_cancel_button, "cancel button")
		var sword_button_during_queue := _find_button(manager.info_panel, "CraftSwordButton")
		manager._update_blacksmith_crafting(1.0)
		_assert_true(sword_button_during_queue == _find_button(manager.info_panel, "CraftSwordButton"), "craft button is not rebuilt every frame while queue is working")
		_assert_true(_label_text(manager.info_panel, "QueueItem0Label").begins_with("队列1:"), "queue progress update keeps correct Chinese queue label")

		_assert_true(manager.start_blacksmith_craft(0, "sickle"), "blacksmith queues another unfinished tool")
		_assert_equal(manager.gold, 14, "queueing second tool spends three more gold")
		_assert_equal(_queue_size(manager, 0), 2, "blacksmith displays multiple queued tools")
		_assert_true(_label_text(manager.info_panel, "QueueItem0Label").begins_with("队列1:"), "first queue label uses correct Chinese text")
		_assert_true(_label_text(manager.info_panel, "QueueItem1Label").begins_with("队列2:"), "second queue label uses correct Chinese text")

		if manager.has_method("cancel_blacksmith_craft"):
			_assert_true(manager.cancel_blacksmith_craft(0, 1), "unfinished queued tool can be canceled")
			_assert_equal(manager.gold, 17, "canceling unfinished queued tool refunds gold")
			_assert_equal(_queue_size(manager, 0), 1, "canceling queued tool removes it from queue")
			_assert_true(manager.cancel_blacksmith_craft(0, 0), "unfinished active tool can be canceled")
			_assert_equal(manager.gold, 20, "canceling active unfinished tool refunds gold")
			_assert_equal(_queue_size(manager, 0), 0, "canceling active tool empties queue")

		_assert_true(manager.start_blacksmith_craft(0, "axe"), "blacksmith can craft after canceling")
		manager._update_blacksmith_crafting(30.0)
		_assert_equal(_queue_size(manager, 0), 0, "completed tool leaves queue")
		_assert_equal(manager.tool_count_for_building("blacksmith_1"), 1, "completed tool enters stock")
		_assert_true(_stored_tool_is_inside_footprint(manager, footprint), "completed tool is placed inside blacksmith footprint")
		manager.gold = 100
		_assert_true(manager.start_blacksmith_craft(0, "sword"), "blacksmith shows queue next to stock")
		var layout_cancel_button := _find_button(manager.info_panel, "CancelCraft0Button")
		var layout_destroy_button := _find_button(manager.info_panel, "DestroyTool0Button")
		_assert_equal(layout_cancel_button.position, Vector2(142, 298), "queue UI stays in the lowered left column")
		_assert_equal(layout_destroy_button.position, Vector2(334, 298), "stock UI sits to the right of the queue UI")
		_assert_true(manager.cancel_blacksmith_craft(0, 0), "layout test craft can be canceled")

		if manager.has_method("destroy_stored_tool"):
			var gold_before_destroy: int = manager.gold
			_assert_true(manager.destroy_stored_tool("blacksmith_1", 0), "completed tool can be destroyed")
			_assert_equal(manager.gold, gold_before_destroy, "destroying completed tool does not refund gold")
			_assert_equal(manager.tool_count_for_building("blacksmith_1"), 0, "destroying completed tool removes it from stock")

		manager.gold = 100
		_assert_true(manager.start_blacksmith_craft(0, "sword"), "blacksmith queues first sequential craft")
		_assert_true(manager.start_blacksmith_craft(0, "axe"), "blacksmith queues second sequential craft")
		manager._update_blacksmith_crafting(29.0)
		_assert_equal(manager.tool_count_for_building("blacksmith_1"), 0, "first queued craft waits for thirty seconds")
		_assert_equal(_queue_progress(manager, 0, 0), 29.0, "first queued craft progresses first")
		_assert_equal(_queue_progress(manager, 0, 1), 0.0, "second queued craft waits behind first")
		manager._update_blacksmith_crafting(1.0)
		_assert_equal(_queue_size(manager, 0), 1, "only first queued craft completes after thirty seconds")
		_assert_equal(manager.tool_count_for_building("blacksmith_1"), 1, "first queued tool enters stock before second starts")
		_assert_equal(_queue_progress(manager, 0, 0), 0.0, "remaining queued craft starts after first completes")
		_assert_true(_label_text(manager.info_panel, "QueueItem0Label").begins_with("队列1:"), "remaining queue label is renumbered to queue one")
		manager._update_blacksmith_crafting(29.0)
		_assert_equal(manager.tool_count_for_building("blacksmith_1"), 1, "second queued craft still waits for its own thirty seconds")
		manager._update_blacksmith_crafting(1.0)
		_assert_equal(_queue_size(manager, 0), 0, "second queued craft completes after its own thirty seconds")
		_assert_equal(manager.tool_count_for_building("blacksmith_1"), 2, "sequential queued tools both complete")

		manager.gold = 100
		_assert_true(manager.start_blacksmith_craft(0, "bow"), "blacksmith can queue bow crafting")
		manager._update_blacksmith_crafting(30.0)
		_assert_equal(manager.tool_count_for_building("blacksmith_1"), 3, "completed bow enters blacksmith stock")
		_assert_true(_stored_tool_id_exists(manager, "blacksmith_1", "bow"), "completed bow is stored as a bow tool")

		root.free()

	if failures == 0:
		print("BlacksmithQueuePanelTest: PASS")
	else:
		push_error("BlacksmithQueuePanelTest: %d failure(s)" % failures)

	quit(failures)


func _queue_size(manager: Node2D, entity_index: int) -> int:
	var entity: Dictionary = manager.placed_buildings[entity_index]
	return (entity.get("craft_queue", []) as Array).size()


func _queue_progress(manager: Node2D, entity_index: int, queue_index: int) -> float:
	var entity: Dictionary = manager.placed_buildings[entity_index]
	var queue := entity.get("craft_queue", []) as Array
	if queue_index < 0 or queue_index >= queue.size():
		return -1.0
	return float((queue[queue_index] as Dictionary).get("progress", 0.0))


func _label_text(node: Node, label_name: String) -> String:
	var label := _find_label(node, label_name)
	return "" if label == null else label.text


func _stored_tool_is_inside_footprint(manager: Node2D, footprint: Rect2) -> bool:
	for item in manager.tool_items:
		var node: Node2D = item.node
		if not is_instance_valid(node):
			continue
		if _rect_contains_point_inclusive(footprint, node.global_position):
			return true
	return false


func _stored_tool_id_exists(manager: Node2D, building_name: String, tool_id: String) -> bool:
	for item in manager.tool_items:
		if item.get("source_building_id", "") == building_name and item.get("tool_id", "") == tool_id:
			return true
	return false


func _find_button(node: Node, button_name: String) -> Button:
	if node == null:
		return null
	if node is Button and node.name == button_name:
		return node as Button
	for child in node.get_children():
		var button := _find_button(child, button_name)
		if button != null:
			return button
	return null


func _find_label(node: Node, label_name: String) -> Label:
	if node == null:
		return null
	if node is Label and node.name == label_name:
		return node as Label
	for child in node.get_children():
		var label := _find_label(child, label_name)
		if label != null:
			return label
	return null


func _has_canvas_layer_ancestor(node: Node) -> bool:
	var current := node
	while current != null:
		if current is CanvasLayer:
			return true
		current = current.get_parent()
	return false


func _assert_always_clickable(button: Button, label: String) -> void:
	_assert_true(button != null, "%s exists" % label)
	if button == null:
		return
	_assert_false(button.disabled, "%s is not disabled" % label)
	_assert_equal(button.mouse_filter, Control.MOUSE_FILTER_STOP, "%s stops mouse input" % label)
	_assert_equal(button.process_mode, Node.PROCESS_MODE_ALWAYS, "%s processes always" % label)
	_assert_equal(button.focus_mode, Control.FOCUS_ALL, "%s accepts focus" % label)


func _panel_has_text(node: Node, needle: String) -> bool:
	if node == null:
		return false
	if node is Label and (node as Label).text.find(needle) != -1:
		return true
	if node is Button and (node as Button).text.find(needle) != -1:
		return true
	for child in node.get_children():
		if _panel_has_text(child, needle):
			return true
	return false


func _rect_contains_point_inclusive(rect: Rect2, point: Vector2) -> bool:
	return (
		point.x >= rect.position.x
		and point.x <= rect.position.x + rect.size.x
		and point.y >= rect.position.y
		and point.y <= rect.position.y + rect.size.y
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
