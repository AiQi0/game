extends SceneTree

var failures := 0


func _init() -> void:
	var arrow_script := load("res://scripts/Arrow.gd")
	var monster_manager_script := load("res://scripts/MonsterManager.gd")
	var monster_script := load("res://scripts/Monster.gd")
	if arrow_script == null:
		_fail("Arrow.gd should load")
	if monster_manager_script == null:
		_fail("MonsterManager.gd should load")
	if monster_script == null:
		_fail("Monster.gd should load")

	if arrow_script != null:
		_test_arrow_arc_and_fade(arrow_script)
	if monster_manager_script != null and monster_script != null:
		_test_archer_shot_spawns_arrow(monster_manager_script, monster_script)

	if failures == 0:
		print("ArrowProjectileTest: PASS")
	else:
		push_error("ArrowProjectileTest: %d failure(s)" % failures)

	quit(failures)


func _test_arrow_arc_and_fade(arrow_script: Script) -> void:
	var root := Node2D.new()
	var arrow: Node2D = arrow_script.new()
	root.add_child(arrow)
	_assert_true(arrow.has_method("setup"), "arrow exposes setup")
	if not arrow.has_method("setup"):
		root.free()
		return

	var start := Vector2(100, 420)
	var target := Vector2(500, 460)
	arrow.setup(start, target, 1)
	arrow._process(0.4)
	_assert_true(arrow.global_position.y < min(start.y, target.y) - 30.0, "arrow travels on an upward parabolic arc")
	arrow._process(0.4)
	_assert_true(arrow.get("has_landed"), "arrow lands after its flight")
	_assert_equal(arrow.global_position, target, "arrow remains where it lands")
	arrow._process(5.0)
	_assert_equal(arrow.modulate.a, 1.0, "landed arrow stays fully visible for five seconds")
	arrow._process(0.5)
	_assert_true(arrow.modulate.a < 1.0 and arrow.modulate.a > 0.0, "arrow fades during the final second")
	arrow._process(0.6)
	_assert_true(arrow.is_queued_for_deletion(), "arrow queues itself for removal after fading")
	root.free()


func _test_archer_shot_spawns_arrow(monster_manager_script: Script, monster_script: Script) -> void:
	var root := Node2D.new()
	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	root.add_child(projectiles)
	var manager: Node2D = monster_manager_script.new()
	manager.name = "MonsterManager"
	root.add_child(manager)
	manager._ready()

	var monster: Node2D = monster_script.new()
	monster.setup("left", Vector2(500, 472))
	monsters.add_child(monster)

	_assert_true(manager.has_method("shoot_nearest_monster"), "MonsterManager supports archer arrow shots")
	if manager.has_method("shoot_nearest_monster"):
		_assert_true(manager.shoot_nearest_monster(Vector2(100, 472), 1, 600.0), "archer shot hits monster in range")
		_assert_equal(monster.get("health"), 2, "archer arrow deals one damage")
		_assert_equal(projectiles.get_child_count(), 1, "archer shot leaves one arrow projectile")
		if projectiles.get_child_count() > 0:
			_assert_true(projectiles.get_child(0).name.begins_with("Arrow_"), "projectile is named as an arrow")

	root.free()


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
