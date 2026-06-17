extends Node2D

const MonsterScript = preload("res://scripts/Monster.gd")
const MonsterRules = preload("res://scripts/MonsterRules.gd")
const ArrowScript = preload("res://scripts/Arrow.gd")

const GROUND_MIN_X := 0.0
const GROUND_MAX_X := 9600.0
const GROUND_TOP_Y := 472.0
const SPAWN_EDGE_PADDING := 28.0
const MONSTER_SPEED := 70.0
const RETURN_SPEED := 110.0
const DETECTION_RANGE := 86.0
const HIT_RANGE := 44.0
const CHARGE_SECONDS := 1.0
const RANDOM_SEED := 20260617

var rules := MonsterRules.new()
var rng := RandomNumberGenerator.new()
var player: Node2D
var build_manager: Node
var npc_manager: Node
var day_night_manager: Node
var monsters_container: Node2D
var projectiles_container: Node2D
var last_phase := ""
var night_number := 0
var safe_nights_remaining := 0
var monster_sequence := 0
var arrow_sequence := 0


func _ready() -> void:
	rng.seed = RANDOM_SEED
	var parent := get_parent()
	if parent == null:
		return

	player = parent.get_node_or_null("Player")
	build_manager = parent.get_node_or_null("BuildManager")
	npc_manager = parent.get_node_or_null("NPCManager")
	day_night_manager = parent.get_node_or_null("DayNightManager")
	monsters_container = parent.get_node_or_null("Monsters")
	if monsters_container == null:
		monsters_container = Node2D.new()
		monsters_container.name = "Monsters"
		parent.add_child(monsters_container)
	projectiles_container = parent.get_node_or_null("Projectiles")
	if projectiles_container == null:
		projectiles_container = Node2D.new()
		projectiles_container.name = "Projectiles"
		parent.add_child(projectiles_container)


func _process(delta: float) -> void:
	_update_night_spawn()
	_update_monsters(delta)


func begin_safe_nights(count: int) -> void:
	safe_nights_remaining = max(safe_nights_remaining, count)


func clear_monsters() -> void:
	if monsters_container == null:
		return

	for monster in monsters_container.get_children():
		monster.queue_free()


func run_night_spawn(current_night: int) -> int:
	var spawned := 0
	for side in ["left", "right"]:
		if not rules.should_spawn_side(current_night, rng.randf(), safe_nights_remaining):
			continue

		var count := rng.randi_range(MonsterRules.MIN_MONSTERS_PER_SIDE, MonsterRules.MAX_MONSTERS_PER_SIDE)
		spawn_monsters(side, count)
		spawned += count

	return spawned


func spawn_monsters(spawn_side: String, count: int) -> void:
	for i in range(count):
		spawn_monster(spawn_side, i)


func spawn_monster(spawn_side: String, lane_index := 0) -> Node2D:
	if monsters_container == null:
		return null

	monster_sequence += 1
	var monster := Node2D.new()
	monster.name = "Monster_%02d" % monster_sequence
	monster.set_script(MonsterScript)
	var x := GROUND_MIN_X - SPAWN_EDGE_PADDING if spawn_side == "left" else GROUND_MAX_X + SPAWN_EDGE_PADDING
	monster.setup(spawn_side, Vector2(x, GROUND_TOP_Y - lane_index * 4.0))
	monsters_container.add_child(monster)
	return monster


func damage_nearest_monster(origin: Vector2, damage: int, attack_range: float) -> bool:
	var monster := _nearest_monster(origin, attack_range)
	if monster == null:
		return false

	if monster.has_method("take_damage"):
		monster.take_damage(damage)
	return true


func shoot_nearest_monster(origin: Vector2, damage: int, attack_range: float) -> bool:
	var monster := _nearest_monster(origin, attack_range)
	if monster == null:
		return false

	spawn_arrow(origin, monster.global_position, damage)
	if monster.has_method("take_damage"):
		monster.take_damage(damage)
	return true


func spawn_arrow(origin: Vector2, target: Vector2, damage: int) -> Node2D:
	if projectiles_container == null:
		var parent := get_parent()
		if parent == null:
			return null
		projectiles_container = parent.get_node_or_null("Projectiles")
		if projectiles_container == null:
			projectiles_container = Node2D.new()
			projectiles_container.name = "Projectiles"
			parent.add_child(projectiles_container)

	arrow_sequence += 1
	var arrow := Node2D.new()
	arrow.name = "Arrow_%02d" % arrow_sequence
	arrow.set_script(ArrowScript)
	projectiles_container.add_child(arrow)
	if arrow.has_method("setup"):
		arrow.setup(origin, target, damage)
	return arrow


func _update_night_spawn() -> void:
	if day_night_manager == null or day_night_manager.get("rules") == null:
		return

	var phase: String = day_night_manager.rules.phase_for_time(day_night_manager.elapsed_seconds)
	if last_phase == "":
		last_phase = phase
		return

	if phase == "night" and last_phase != "night":
		night_number += 1
		if safe_nights_remaining > 0:
			safe_nights_remaining -= 1
		else:
			run_night_spawn(night_number)

	last_phase = phase


func _update_monsters(delta: float) -> void:
	if monsters_container == null:
		return

	for monster in monsters_container.get_children():
		if not is_instance_valid(monster):
			continue

		if monster.get("state") == "returning":
			_update_returning_monster(monster, delta)
			continue

		_update_attacking_monster(monster, delta)


func _update_returning_monster(monster: Node2D, delta: float) -> void:
	var return_direction := -1 if monster.get("side") == "left" else 1
	monster.global_position.x += return_direction * RETURN_SPEED * delta
	if monster.global_position.x < GROUND_MIN_X - SPAWN_EDGE_PADDING * 2.0:
		monster.queue_free()
	elif monster.global_position.x > GROUND_MAX_X + SPAWN_EDGE_PADDING * 2.0:
		monster.queue_free()


func _update_attacking_monster(monster: Node2D, delta: float) -> void:
	var target := _nearest_attack_target(monster.global_position)
	if target == null:
		monster.set("state", "advance")
		monster.set("attack_target", null)
		monster.set("charge_elapsed", 0.0)
		monster.global_position.x += int(monster.get("direction")) * MONSTER_SPEED * delta
		_free_if_outside_far_edge(monster)
		return

	if monster.get("state") != "charging" or monster.get("attack_target") != target:
		monster.set("state", "charging")
		monster.set("attack_target", target)
		monster.set("charge_elapsed", 0.0)
		return

	var charge_elapsed := float(monster.get("charge_elapsed")) + delta
	monster.set("charge_elapsed", charge_elapsed)
	if charge_elapsed < CHARGE_SECONDS:
		return

	if monster.global_position.distance_to(target.global_position) <= HIT_RANGE:
		_resolve_monster_hit(monster, target)
	else:
		monster.global_position.x += int(monster.get("direction")) * MONSTER_SPEED * delta
		_free_if_outside_far_edge(monster)


func _resolve_monster_hit(monster: Node2D, target: Node2D) -> void:
	if target == player:
		var result := {}
		if build_manager != null and build_manager.has_method("apply_player_monster_hit"):
			result = build_manager.apply_player_monster_hit()
		monster.begin_return("", int(result.get("lost_gold", 0)))
		return

	var loot := {}
	if npc_manager != null and npc_manager.has_method("monster_hit_npc"):
		loot = npc_manager.monster_hit_npc(target.name)
	monster.begin_return(loot.get("tool_id", ""), 0)


func _nearest_attack_target(origin: Vector2) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF

	if player != null and not _player_is_dead():
		var player_distance := origin.distance_to(player.global_position)
		if player_distance <= DETECTION_RANGE:
			nearest = player
			nearest_distance = player_distance

	var npc_container := get_parent().get_node_or_null("NPCs") if get_parent() != null else null
	if npc_container != null:
		for npc in npc_container.get_children():
			if npc.get("npc_type") != "villager":
				continue
			if not npc.visible:
				continue
			var distance := origin.distance_to(npc.global_position)
			if distance <= DETECTION_RANGE and distance < nearest_distance:
				nearest = npc
				nearest_distance = distance

	return nearest


func _free_if_outside_far_edge(monster: Node2D) -> void:
	if monster.global_position.x < GROUND_MIN_X - SPAWN_EDGE_PADDING * 2.0:
		monster.queue_free()
	elif monster.global_position.x > GROUND_MAX_X + SPAWN_EDGE_PADDING * 2.0:
		monster.queue_free()


func _nearest_monster(origin: Vector2, attack_range: float) -> Node2D:
	if monsters_container == null:
		return null

	var nearest: Node2D = null
	var nearest_distance := INF
	for monster in monsters_container.get_children():
		if not is_instance_valid(monster):
			continue

		var distance := origin.distance_to(monster.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest = monster
			nearest_distance = distance

	return nearest


func _player_is_dead() -> bool:
	return build_manager != null and build_manager.get("player_dead") == true
