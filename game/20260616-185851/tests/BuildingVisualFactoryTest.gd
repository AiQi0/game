extends SceneTree

var failures := 0


func _init() -> void:
	var catalog_script := load("res://scripts/BuildingCatalog.gd")
	var factory_script := load("res://scripts/BuildingVisualFactory.gd")

	if catalog_script == null:
		_fail("BuildingCatalog.gd should load")
	if factory_script == null:
		_fail("BuildingVisualFactory.gd should load")

	if catalog_script != null and factory_script != null:
		var catalog = catalog_script.new()
		var factory = factory_script.new()

		for building in catalog.get_buildings():
			var visual: Node2D = factory.create_building_visual(building)
			_assert_true(visual.get_child_count() > 0, "%s has visible parts" % building.display_name)
			_assert_false(_contains_collision_node(visual), "%s has no collision nodes" % building.display_name)
			_assert_true(_window_nodes(visual).size() > 0, "%s has windows" % building.display_name)
			var dark_color: Color = _window_nodes(visual)[0].color
			_assert_true(factory.has_method("set_occupied"), "factory can set occupied window state")
			if factory.has_method("set_occupied"):
				factory.set_occupied(visual, true)
				var lit_color: Color = _window_nodes(visual)[0].color
				_assert_true(lit_color != dark_color, "%s windows light up when occupied" % building.display_name)
				factory.set_occupied(visual, false)
				_assert_true(_window_nodes(visual)[0].color == dark_color, "%s windows go dark when empty" % building.display_name)
			visual.queue_free()

	if failures == 0:
		print("BuildingVisualFactoryTest: PASS")
	else:
		push_error("BuildingVisualFactoryTest: %d failure(s)" % failures)

	quit(failures)


func _contains_collision_node(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		return true

	for child in node.get_children():
		if _contains_collision_node(child):
			return true

	return false


func _window_nodes(node: Node) -> Array:
	var windows: Array = []
	if node is Polygon2D and node.name.begins_with("Window"):
		windows.append(node)

	for child in node.get_children():
		windows.append_array(_window_nodes(child))

	return windows


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
