extends SceneTree

const GameData = preload("res://scripts/GameData.gd")

var failures := 0


func _init() -> void:
	var npc_manager_script := load("res://scripts/NPCManager.gd")
	if npc_manager_script == null:
		_fail("NPCManager.gd should load")

	if npc_manager_script != null:
		var root := Node2D.new()
		var npcs := Node2D.new()
		npcs.name = "NPCs"
		root.add_child(npcs)

		var npc_manager: Node2D = npc_manager_script.new()
		npc_manager.name = "NPCManager"
		root.add_child(npc_manager)
		npc_manager.npc_container = npcs

		_assert_true(npc_manager.has_method("spawn_starting_npcs"), "NPCManager exposes startup NPC spawning")
		if npc_manager.has_method("spawn_starting_npcs"):
			npc_manager.spawn_starting_npcs()
			_assert_starting_counts(npcs, "startup spawn creates requested NPCs")
			_assert_starting_positions(npcs)
			_assert_unique_names(npcs)

			npc_manager.spawn_starting_npcs()
			_assert_starting_counts(npcs, "startup spawn runs only once")

		root.free()

	if failures == 0:
		print("NPCStartupSpawnTest: PASS")
	else:
		push_error("NPCStartupSpawnTest: %d failure(s)" % failures)

	quit(failures)


func _assert_starting_counts(npcs: Node2D, message: String) -> void:
	var villager_count := 0
	var homeless_count := 0
	for child in npcs.get_children():
		if child.get("npc_type") == "villager":
			villager_count += 1
		elif child.get("npc_type") == "homeless":
			homeless_count += 1

	_assert_equal(villager_count, 3, "%s: starts with three villagers" % message)
	_assert_equal(homeless_count, 5, "%s: starts with five homeless" % message)


func _assert_starting_positions(npcs: Node2D) -> void:
	for child in npcs.get_children():
		if child.get("npc_type") == "villager":
			_assert_equal(child.global_position.y, 472.0, "starting villager stands on ground")
			_assert_true(absf(child.global_position.x - 4800.0) <= 80.0, "starting villager is in front of city hall")
			_assert_equal(child.get("assigned_workplace_id"), "cityhall", "starting villager belongs to city hall")
		elif child.get("npc_type") == "homeless":
			_assert_true(child.global_position.x >= GameData.GROUND_MIN_X, "starting homeless is inside left map edge")
			_assert_true(child.global_position.x <= GameData.GROUND_MAX_X, "starting homeless is inside right map edge")
			_assert_equal(child.global_position.y, 472.0, "starting homeless stands on ground")


func _assert_unique_names(npcs: Node2D) -> void:
	var names := {}
	for child in npcs.get_children():
		_assert_false(names.has(child.name), "startup NPC names are unique")
		names[child.name] = true


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
