extends SceneTree

var failures := 0


func _init() -> void:
	var factory_script := load("res://scripts/TreeFactory.gd")
	if factory_script == null:
		_fail("TreeFactory.gd should load")

	if factory_script != null:
		var factory = factory_script.new()
		var tree: Node2D = factory.create_tree_visual()
		_assert_true(tree.get_child_count() > 0, "tree has visible parts")
		_assert_false(_contains_collision_node(tree), "tree has no collision nodes")
		tree.queue_free()

	if failures == 0:
		print("TreeFactoryTest: PASS")
	else:
		push_error("TreeFactoryTest: %d failure(s)" % failures)

	quit(failures)


func _contains_collision_node(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		return true

	for child in node.get_children():
		if _contains_collision_node(child):
			return true

	return false


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
