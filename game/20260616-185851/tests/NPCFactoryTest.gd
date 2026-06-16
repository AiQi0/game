extends SceneTree

var failures := 0


func _init() -> void:
	var factory_script := load("res://scripts/NPCFactory.gd")
	var npc_script := load("res://scripts/NPC.gd")
	if factory_script == null:
		_fail("NPCFactory.gd should load")
	if npc_script == null:
		_fail("NPC.gd should load")

	if factory_script != null:
		var factory = factory_script.new()
		var npc: Node2D = factory.create_homeless(Vector2(4800, 472), Vector2(4800, 472))
		_assert_equal(npc.npc_type, "homeless", "factory creates homeless NPC")
		_assert_true(npc.has_method("interact"), "NPC supports interaction")
		_assert_false(_contains_collision_node(npc), "NPC has no collision nodes")
		npc.interact()
		_assert_equal(npc.npc_type, "villager", "interaction converts homeless into villager")
		_assert_equal(npc.home_center, Vector2(4800, 472), "villager home is city hall front")
		npc.set_workplace(Vector2(4600, 472), "铁匠铺")
		_assert_equal(npc.home_center, Vector2(4600, 472), "villager home moves to assigned workplace")
		_assert_equal(npc.assigned_workplace_name, "铁匠铺", "villager records assigned workplace name")
		if npc.has_method("travel_to_workplace"):
			npc.travel_to_workplace(Vector2(4500, 472), "酒馆", "tavern_1")
			_assert_true(npc.visible, "villager stays visible while walking to work")
			_assert_false(npc.is_inside_building, "villager is not inside before arriving")
			_assert_true(npc.is_traveling_to_workplace, "villager records travel-to-work state")
			_assert_equal(npc.target_position, Vector2(4500, 472), "villager walks toward building front")
		else:
			_fail("NPC should support walking to a workplace before entering")
		_assert_true(npc.has_method("enter_building"), "villager can enter a building")
		_assert_true(npc.has_method("exit_building"), "villager can exit a building")
		if npc.has_method("enter_building") and npc.has_method("exit_building"):
			npc.enter_building(Vector2(4600, 472), "铁匠铺", "blacksmith_1")
			_assert_false(npc.visible, "villager model hides while working inside")
			_assert_true(npc.is_inside_building, "villager records inside-building state")
			npc.exit_building(Vector2(4620, 472), Vector2(4800, 472))
			_assert_true(npc.visible, "villager model appears after leaving building")
			_assert_false(npc.is_inside_building, "villager clears inside-building state")
			_assert_equal(npc.global_position, Vector2(4620, 472), "released villager appears at demolition site")
		npc.queue_free()

	if failures == 0:
		print("NPCFactoryTest: PASS")
	else:
		push_error("NPCFactoryTest: %d failure(s)" % failures)

	quit(failures)


func _contains_collision_node(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		return true

	for child in node.get_children():
		if _contains_collision_node(child):
			return true

	return false


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
