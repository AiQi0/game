extends SceneTree

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var monster_manager_script := load("res://scripts/MonsterManager.gd")
	if game_data_script == null:
		_fail("GameData.gd should load")
	if monster_manager_script == null:
		_fail("MonsterManager.gd should load")

	if game_data_script != null:
		var data = game_data_script.new()
		_assert_equal(data.monster_value("dash_distance"), 132.0, "monster dash distance is data-driven and tripled")
		_assert_equal(data.monster_value("dash_speed_multiplier"), 5.0, "monster dash speed multiplier is data-driven")
	if monster_manager_script != null:
		_test_charged_monster_sprints_even_when_target_leaves_detection(monster_manager_script)

	if failures == 0:
		print("MonsterChargeDashTest: PASS")
	else:
		push_error("MonsterChargeDashTest: %d failure(s)" % failures)

	quit(failures)


func _test_charged_monster_sprints_even_when_target_leaves_detection(monster_manager_script: Script) -> void:
	var root := Node2D.new()
	var monsters := Node2D.new()
	monsters.name = "Monsters"
	root.add_child(monsters)

	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(5200, 472)
	root.add_child(player)

	var monster_manager: Node2D = monster_manager_script.new()
	monster_manager.name = "MonsterManager"
	root.add_child(monster_manager)
	monster_manager.player = player
	monster_manager.monsters_container = monsters

	var monster: Node2D = monster_manager.spawn_monster("left", 0)
	monster.global_position = Vector2(5000, 472)
	monster.set("state", "charging")
	monster.set("attack_target", player)
	monster.set("charge_elapsed", 1.0)

	monster_manager._update_attacking_monster(monster, 0.0)

	_assert_equal(monster.global_position.x, 5000.0, "charged monster does not teleport at dash start")
	_assert_equal(monster.get("state"), "dashing", "charged monster enters sprint dash state")
	_assert_equal(monster.get("attack_target"), player, "dash keeps the locked target after it leaves detection range")

	monster_manager._update_attacking_monster(monster, 0.1)

	_assert_almost_equal(monster.global_position.x, 5052.5, 0.001, "monster sprints at five times base speed")
	_assert_equal(monster.get("state"), "dashing", "monster keeps dashing until full dash distance is covered")

	monster_manager._update_attacking_monster(monster, 1.0)

	_assert_almost_equal(monster.global_position.x, 5132.0, 0.001, "monster stops after covering the configured dash distance")
	_assert_equal(monster.get("state"), "advance", "monster resumes advancing after a missed dash")
	_assert_equal(monster.get("attack_target"), null, "missed dash clears the old target")

	root.free()


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_almost_equal(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
