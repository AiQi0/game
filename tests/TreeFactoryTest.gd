extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var factory_script := load("res://scripts/TreeFactory.gd")
	if game_data_script == null:
		_fail("GameData.gd should load")
	if factory_script == null:
		_fail("TreeFactory.gd should load")

	if factory_script != null and game_data_script != null:
		var data = game_data_script.new()
		var factory = factory_script.new()
		var tree: Node2D = factory.create_tree_visual()
		_assert_true(tree.get_child_count() > 0, "tree has visible parts")
		_assert_false(_contains_collision_node(tree), "tree has no collision nodes")
		_assert_generated_sprite_target_size(tree, data.resource_size("tree"), "tree generated sprite uses scaled resource size")
		tree.queue_free()

		var stone: Node2D = factory.create_stone_visual()
		_assert_generated_sprite_target_size(stone, data.resource_size("stone"), "stone generated sprite uses scaled resource size")
		stone.queue_free()

		var mother_tree: Node2D = factory.create_mother_tree_visual()
		_assert_generated_sprite_target_size(mother_tree, data.resource_size("mother_tree"), "mother tree generated sprite uses scaled resource size")
		mother_tree.queue_free()

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


func _assert_generated_sprite_target_size(node: Node2D, expected_size: Vector2, message: String) -> void:
	var sprite := node.get_node_or_null("GeneratedSprite") as Sprite2D
	_assert_true(sprite != null, "%s has generated sprite" % message)
	if sprite == null or sprite.texture == null:
		return

	var actual_size := Vector2(
		float(sprite.texture.get_width()) * sprite.scale.x,
		float(sprite.texture.get_height()) * sprite.scale.y
	)
	_assert_true(actual_size.x <= expected_size.x + 0.01, "%s width stays inside target" % message)
	_assert_true(actual_size.y <= expected_size.y + 0.01, "%s height stays inside target" % message)
	_assert_true(
		absf(actual_size.x - expected_size.x) < 0.01 or absf(actual_size.y - expected_size.y) < 0.01,
		"%s fits at least one target edge" % message
	)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
