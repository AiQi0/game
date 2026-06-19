extends Node2D

const GameData = preload("res://scripts/GameData.gd")

const SPEED := GameData.NPC_SPEED
const ARRIVAL_DISTANCE := GameData.NPC_ARRIVAL_DISTANCE
const HOMELESS_COLOR := GameData.NPC_ROLES.homeless.color
const VILLAGER_COLOR := GameData.NPC_ROLES.villager.color
const LUMBERJACK_COLOR := GameData.NPC_ROLES.lumberjack.color
const FARMER_COLOR := GameData.NPC_ROLES.farmer.color
const MINER_COLOR := GameData.NPC_ROLES.miner.color
const WARRIOR_COLOR := GameData.NPC_ROLES.warrior.color
const ARCHER_COLOR := GameData.NPC_ROLES.archer.color
const WARRIOR_ATTACK_POWER := GameData.NPC_ROLES.warrior.attack_power
const ARCHER_ATTACK_POWER := GameData.NPC_ROLES.archer.attack_power
const ARCHER_ATTACK_RANGE := GameData.NPC_ROLES.archer.attack_range
const ARCHER_WALL_ATTACK_RANGE := GameData.NPC_ROLES.archer.wall_attack_range

var npc_type := "homeless"
var worker_role := "none"
var carried_tool := ""
var arrowhead_tool := ""
var attack_power := 0
var attack_range := 0.0
var is_patrolling := false
var patrol_side := ""
var patrol_anchor := Vector2.ZERO
var is_on_wall := false
var wall_id := ""
var home_center := Vector2.ZERO
var villager_home_center := Vector2.ZERO
var assigned_workplace_name := ""
var assigned_workplace_id := ""
var tree_chop_return_position := Vector2.ZERO
var tree_chop_return_name := ""
var tree_chop_return_id := ""
var is_inside_building := false
var is_traveling_to_workplace := false
var is_traveling_to_tree_chop := false
var is_traveling_to_tool_pickup := false
var is_chopping_tree := false
var tree_chop_task_id := ""
var tool_pickup_tool_id := ""
var tool_pickup_blacksmith_id := ""
var tool_return_position := Vector2.ZERO
var tool_return_name := ""
var tool_return_id := ""
var wander_radius := 120.0
var target_position := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var body: Polygon2D
var game_data := GameData.new()


func setup(start_position: Vector2, city_hall_front: Vector2) -> void:
	global_position = start_position
	home_center = start_position
	villager_home_center = city_hall_front
	target_position = start_position
	rng.randomize()
	_choose_new_target()


func _process(delta: float) -> void:
	var offset := target_position - global_position
	if offset.length() <= ARRIVAL_DISTANCE:
		if is_traveling_to_workplace or is_traveling_to_tree_chop or is_traveling_to_tool_pickup:
			global_position = target_position
			return

		_choose_new_target()
		return

	global_position += offset.normalized() * SPEED * delta


func interact() -> void:
	if npc_type != "homeless":
		return

	npc_type = "villager"
	worker_role = "villager"
	carried_tool = ""
	arrowhead_tool = ""
	attack_power = 0
	attack_range = 0.0
	is_patrolling = false
	patrol_side = ""
	patrol_anchor = Vector2.ZERO
	is_on_wall = false
	wall_id = ""
	home_center = villager_home_center
	assigned_workplace_name = "市政厅"
	assigned_workplace_id = "cityhall"
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	_clear_tool_pickup()
	wander_radius = 160.0
	visible = true
	set_process(true)
	if body != null:
		body.color = VILLAGER_COLOR
	_choose_new_target()


func become_lumberjack() -> void:
	if npc_type != "villager":
		return

	worker_role = "lumberjack"
	if body != null:
		body.color = LUMBERJACK_COLOR


func become_farmer() -> void:
	if npc_type != "villager":
		return

	worker_role = "farmer"
	if body != null:
		body.color = FARMER_COLOR


func become_miner() -> void:
	if npc_type != "villager":
		return

	worker_role = "miner"
	if body != null:
		body.color = MINER_COLOR


func become_warrior() -> void:
	if npc_type != "villager":
		return

	worker_role = "warrior"
	attack_power = WARRIOR_ATTACK_POWER
	attack_range = 0.0
	is_on_wall = false
	wall_id = ""
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	assigned_workplace_name = "patrol"
	assigned_workplace_id = "patrol"
	wander_radius = 140.0
	visible = true
	set_process(true)
	if body != null:
		body.color = WARRIOR_COLOR


func become_archer() -> void:
	if npc_type != "villager":
		return

	worker_role = "archer"
	attack_power = ARCHER_ATTACK_POWER
	attack_range = ARCHER_ATTACK_RANGE
	is_on_wall = false
	wall_id = ""
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	assigned_workplace_name = "patrol"
	assigned_workplace_id = "patrol"
	wander_radius = 140.0
	visible = true
	set_process(true)
	if body != null:
		body.color = ARCHER_COLOR


func equip_tool(tool_id: String) -> void:
	if tool_id == "stone_arrowhead":
		if worker_role != "archer" and carried_tool != "bow":
			return

		arrowhead_tool = tool_id
		attack_power = int(round(float(ARCHER_ATTACK_POWER) * game_data.tool_damage_multiplier(tool_id)))
		var old_arrowhead := get_node_or_null("HeldArrowhead")
		if old_arrowhead != null:
			old_arrowhead.queue_free()
		var held_arrowhead := Polygon2D.new()
		held_arrowhead.name = "HeldArrowhead"
		held_arrowhead.color = _tool_color(tool_id)
		held_arrowhead.polygon = PackedVector2Array([
			Vector2(18, -42),
			Vector2(28, -28),
			Vector2(12, -28),
		])
		add_child(held_arrowhead)
		return

	carried_tool = tool_id
	var old_tool := get_node_or_null("HeldTool")
	if old_tool != null:
		old_tool.queue_free()
	if tool_id == "":
		return
	if tool_id == "sword" or tool_id == "stone_sword":
		become_warrior()
	elif tool_id == "bow":
		become_archer()
		if arrowhead_tool != "":
			attack_power = int(round(float(ARCHER_ATTACK_POWER) * game_data.tool_damage_multiplier(arrowhead_tool)))

	var held_tool := Polygon2D.new()
	held_tool.name = "HeldTool"
	held_tool.color = _tool_color(tool_id)
	held_tool.polygon = _held_tool_polygon(tool_id)
	add_child(held_tool)


func drop_carried_tool() -> String:
	var tool_id := carried_tool
	carried_tool = ""
	arrowhead_tool = ""
	var old_tool := get_node_or_null("HeldTool")
	if old_tool != null:
		old_tool.queue_free()
	var old_arrowhead := get_node_or_null("HeldArrowhead")
	if old_arrowhead != null:
		old_arrowhead.queue_free()
	if worker_role == "warrior" or worker_role == "archer":
		worker_role = "villager"
		attack_power = 0
		attack_range = 0.0
		is_patrolling = false
		patrol_side = ""
		patrol_anchor = Vector2.ZERO
		is_on_wall = false
		wall_id = ""
		is_inside_building = false
		visible = true
		set_process(true)
		assigned_workplace_name = "cityhall"
		assigned_workplace_id = "cityhall"
		home_center = villager_home_center
		wander_radius = 160.0
		if body != null:
			body.color = VILLAGER_COLOR
		_choose_new_target()
	return tool_id


func become_homeless() -> void:
	npc_type = "homeless"
	worker_role = "none"
	attack_power = 0
	attack_range = 0.0
	is_patrolling = false
	patrol_side = ""
	patrol_anchor = Vector2.ZERO
	is_on_wall = false
	wall_id = ""
	carried_tool = ""
	arrowhead_tool = ""
	var old_tool := get_node_or_null("HeldTool")
	if old_tool != null:
		old_tool.queue_free()
	var old_arrowhead := get_node_or_null("HeldArrowhead")
	if old_arrowhead != null:
		old_arrowhead.queue_free()
	home_center = global_position
	assigned_workplace_name = ""
	assigned_workplace_id = ""
	_clear_tree_chop_return()
	_clear_tool_pickup()
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	wander_radius = 120.0
	visible = true
	set_process(true)
	if body != null:
		body.color = HOMELESS_COLOR
	_choose_new_target()


func set_warrior_patrol(side: String, anchor: Vector2) -> void:
	if worker_role != "warrior":
		return

	_set_guard_patrol(side, anchor)


func set_archer_patrol(side: String, anchor: Vector2) -> void:
	if worker_role != "archer" or is_on_wall:
		return

	_set_guard_patrol(side, anchor)


func _set_guard_patrol(side: String, anchor: Vector2) -> void:
	patrol_side = side
	patrol_anchor = anchor
	is_patrolling = true
	home_center = anchor
	assigned_workplace_name = "patrol"
	assigned_workplace_id = "patrol"
	wander_radius = 140.0
	if target_position == Vector2.ZERO or global_position.distance_to(home_center) > wander_radius * 2.0:
		target_position = home_center


func set_workplace(workplace_position: Vector2, workplace_name: String, workplace_id := "") -> void:
	_clear_wall_state()
	home_center = workplace_position
	assigned_workplace_name = workplace_name
	assigned_workplace_id = workplace_id
	is_patrolling = false
	patrol_side = ""
	patrol_anchor = Vector2.ZERO
	_clear_tree_chop_return()
	_clear_tool_pickup()
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	wander_radius = 90.0
	_choose_new_target()


func travel_to_workplace(workplace_position: Vector2, workplace_name: String, workplace_id := "") -> void:
	_clear_wall_state()
	home_center = workplace_position
	assigned_workplace_name = workplace_name
	assigned_workplace_id = workplace_id
	_clear_tree_chop_return()
	_clear_tool_pickup()
	is_inside_building = false
	is_traveling_to_workplace = true
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	wander_radius = 90.0
	target_position = workplace_position
	visible = true
	set_process(true)


func travel_to_tree_chop(tree_position: Vector2, task_id: String) -> void:
	home_center = tree_position
	assigned_workplace_name = "砍树"
	assigned_workplace_id = "tree_chop"
	_clear_tree_chop_return()
	_clear_tool_pickup()
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = true
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = task_id
	wander_radius = 0.0
	target_position = tree_position
	visible = true
	set_process(true)


func travel_to_tree_chop_from_workplace(
	tree_position: Vector2,
	task_id: String,
	return_position: Vector2,
	return_name: String,
	return_id: String
) -> void:
	travel_to_tree_chop(tree_position, task_id)
	tree_chop_return_position = return_position
	tree_chop_return_name = return_name
	tree_chop_return_id = return_id


func travel_to_tool_pickup(
	blacksmith_position: Vector2,
	blacksmith_id: String,
	tool_id: String,
	return_position: Vector2,
	return_name: String,
	return_id: String
) -> void:
	tool_pickup_tool_id = tool_id
	tool_pickup_blacksmith_id = blacksmith_id
	tool_return_position = return_position
	tool_return_name = return_name
	tool_return_id = return_id
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = true
	is_chopping_tree = false
	tree_chop_task_id = ""
	wander_radius = 0.0
	target_position = blacksmith_position
	visible = true
	set_process(true)


func start_tree_chop() -> void:
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = true
	visible = true
	set_process(false)


func finish_tree_chop(city_hall_front: Vector2) -> void:
	tree_chop_task_id = ""
	_clear_tree_chop_return()
	_clear_tool_pickup()
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	set_workplace(city_hall_front, "市政厅", "cityhall")
	visible = true
	set_process(true)


func finish_tree_chop_to_workplace() -> void:
	var return_position := tree_chop_return_position
	var return_name := tree_chop_return_name
	var return_id := tree_chop_return_id
	tree_chop_task_id = ""
	tree_chop_return_position = Vector2.ZERO
	tree_chop_return_name = ""
	tree_chop_return_id = ""
	travel_to_workplace(return_position, return_name, return_id)


func finish_tool_pickup_to_workplace(tool_id: String) -> void:
	var return_position := tool_return_position
	var return_name := tool_return_name
	var return_id := tool_return_id
	if tool_id != "":
		equip_tool(tool_id)
	_clear_tool_pickup()
	if tool_id == "sword" or tool_id == "stone_sword" or tool_id == "bow":
		return
	travel_to_workplace(return_position, return_name, return_id)


func has_tree_chop_return_workplace() -> bool:
	return tree_chop_return_id != ""


func enter_building(workplace_position: Vector2, workplace_name: String, workplace_id: String) -> void:
	set_workplace(workplace_position, workplace_name, workplace_id)
	global_position = workplace_position
	is_inside_building = true
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	visible = false
	set_process(false)


func enter_wall_top(wall_position: Vector2, workplace_name: String, workplace_id: String) -> void:
	if worker_role != "archer":
		return

	home_center = wall_position + Vector2(0.0, -100.0)
	global_position = home_center
	assigned_workplace_name = workplace_name
	assigned_workplace_id = workplace_id
	is_inside_building = true
	is_on_wall = true
	wall_id = workplace_id
	is_patrolling = false
	patrol_side = ""
	patrol_anchor = Vector2.ZERO
	attack_range = ARCHER_WALL_ATTACK_RANGE
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	wander_radius = 0.0
	target_position = home_center
	visible = true
	set_process(false)


func exit_building(spawn_position: Vector2, city_hall_front: Vector2) -> void:
	global_position = spawn_position
	_clear_wall_state()
	home_center = city_hall_front
	assigned_workplace_name = "市政厅"
	assigned_workplace_id = "cityhall"
	_clear_tree_chop_return()
	_clear_tool_pickup()
	wander_radius = 160.0
	is_inside_building = false
	is_traveling_to_workplace = false
	is_traveling_to_tree_chop = false
	is_traveling_to_tool_pickup = false
	is_chopping_tree = false
	tree_chop_task_id = ""
	visible = true
	set_process(true)
	_choose_new_target()


func is_at_assigned_workplace(threshold := ARRIVAL_DISTANCE) -> bool:
	return is_traveling_to_workplace and global_position.distance_to(home_center) <= threshold


func is_at_tree_chop_target(threshold := ARRIVAL_DISTANCE) -> bool:
	return is_traveling_to_tree_chop and global_position.distance_to(home_center) <= threshold


func is_at_tool_pickup_target(threshold := ARRIVAL_DISTANCE) -> bool:
	return is_traveling_to_tool_pickup and global_position.distance_to(target_position) <= threshold


func _choose_new_target() -> void:
	target_position = Vector2(
		home_center.x + rng.randf_range(-wander_radius, wander_radius),
		home_center.y
	)


func _clear_tree_chop_return() -> void:
	tree_chop_return_position = Vector2.ZERO
	tree_chop_return_name = ""
	tree_chop_return_id = ""


func _clear_tool_pickup() -> void:
	tool_pickup_tool_id = ""
	tool_pickup_blacksmith_id = ""
	tool_return_position = Vector2.ZERO
	tool_return_name = ""
	tool_return_id = ""


func _clear_wall_state() -> void:
	is_on_wall = false
	wall_id = ""
	if worker_role == "archer":
		attack_range = ARCHER_ATTACK_RANGE


func _tool_color(tool_id: String) -> Color:
	return game_data.tool_color(tool_id)


func _held_tool_polygon(tool_id: String) -> PackedVector2Array:
	if tool_id == "bow":
		return PackedVector2Array([
			Vector2(8, -40),
			Vector2(18, -34),
			Vector2(22, -24),
			Vector2(18, -14),
			Vector2(8, -8),
			Vector2(12, -24),
		])

	return PackedVector2Array([
		Vector2(10, -34),
		Vector2(18, -34),
		Vector2(18, -12),
		Vector2(10, -12),
	])
