extends SceneTree

var failures := 0


func _init() -> void:
	var monster_script := load("res://scripts/Monster.gd")
	if monster_script == null:
		_fail("Monster.gd should load")

	if monster_script != null:
		_test_loot_visual(monster_script)

	if failures == 0:
		print("MonsterLootVisualTest: PASS")
	else:
		push_error("MonsterLootVisualTest: %d failure(s)" % failures)

	quit(failures)


func _test_loot_visual(monster_script: Script) -> void:
	var monster: Node2D = monster_script.new()
	monster.setup("left", Vector2(100, 472))
	_assert_true(monster.get_node_or_null("LootVisual") == null, "monster starts without loot visual")

	monster.begin_return("axe", 0)
	var axe_loot := monster.get_node_or_null("LootVisual") as Polygon2D
	_assert_true(axe_loot != null, "monster shows stolen tool above head")
	if axe_loot != null:
		_assert_true(axe_loot.position.y < -58.0, "stolen tool is held above monster head")
		_assert_equal(axe_loot.color, Color(0.58, 0.38, 0.18, 1), "wood axe loot uses axe color")

	monster.begin_return("bow", 0)
	var bow_loot := monster.get_node_or_null("LootVisual") as Polygon2D
	_assert_true(bow_loot != null, "monster shows stolen bow above head")
	if bow_loot != null:
		_assert_true(bow_loot.position.y < -58.0, "stolen bow is held above monster head")
		_assert_equal(bow_loot.color, Color(0.86, 0.62, 0.22, 1), "bow loot uses bow color")

	monster.begin_return("", 50)
	var gold_loot := monster.get_node_or_null("LootVisual") as Polygon2D
	_assert_true(gold_loot != null, "monster shows stolen gold above head")
	if gold_loot != null:
		_assert_true(gold_loot.position.y < -58.0, "stolen gold is held above monster head")
		_assert_equal(gold_loot.color, Color(1.0, 0.82, 0.22, 1), "gold loot uses gold color")

	monster.begin_return("", 0)
	_assert_true(monster.get_node_or_null("LootVisual") == null, "monster hides loot visual when it carries nothing")
	monster.free()


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
