extends Node2D

const SPEED := 52.0
const ARRIVAL_DISTANCE := 6.0
const HOMELESS_COLOR := Color(0.56, 0.44, 0.36, 1)
const VILLAGER_COLOR := Color(0.26, 0.5, 0.92, 1)

var npc_type := "homeless"
var home_center := Vector2.ZERO
var villager_home_center := Vector2.ZERO
var assigned_workplace_name := ""
var assigned_workplace_id := ""
var is_inside_building := false
var is_traveling_to_workplace := false
var wander_radius := 120.0
var target_position := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var body: Polygon2D


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
		if is_traveling_to_workplace:
			global_position = target_position
			return

		_choose_new_target()
		return

	global_position += offset.normalized() * SPEED * delta


func interact() -> void:
	if npc_type != "homeless":
		return

	npc_type = "villager"
	home_center = villager_home_center
	assigned_workplace_name = "市政厅"
	assigned_workplace_id = "cityhall"
	is_inside_building = false
	is_traveling_to_workplace = false
	wander_radius = 160.0
	visible = true
	set_process(true)
	if body != null:
		body.color = VILLAGER_COLOR
	_choose_new_target()


func set_workplace(workplace_position: Vector2, workplace_name: String, workplace_id := "") -> void:
	home_center = workplace_position
	assigned_workplace_name = workplace_name
	assigned_workplace_id = workplace_id
	is_traveling_to_workplace = false
	wander_radius = 90.0
	_choose_new_target()


func travel_to_workplace(workplace_position: Vector2, workplace_name: String, workplace_id := "") -> void:
	home_center = workplace_position
	assigned_workplace_name = workplace_name
	assigned_workplace_id = workplace_id
	is_inside_building = false
	is_traveling_to_workplace = true
	wander_radius = 90.0
	target_position = workplace_position
	visible = true
	set_process(true)


func enter_building(workplace_position: Vector2, workplace_name: String, workplace_id: String) -> void:
	set_workplace(workplace_position, workplace_name, workplace_id)
	global_position = workplace_position
	is_inside_building = true
	is_traveling_to_workplace = false
	visible = false
	set_process(false)


func exit_building(spawn_position: Vector2, city_hall_front: Vector2) -> void:
	global_position = spawn_position
	home_center = city_hall_front
	assigned_workplace_name = "市政厅"
	assigned_workplace_id = "cityhall"
	wander_radius = 160.0
	is_inside_building = false
	is_traveling_to_workplace = false
	visible = true
	set_process(true)
	_choose_new_target()


func is_at_assigned_workplace(threshold := ARRIVAL_DISTANCE) -> bool:
	return is_traveling_to_workplace and global_position.distance_to(home_center) <= threshold


func _choose_new_target() -> void:
	target_position = Vector2(
		home_center.x + rng.randf_range(-wander_radius, wander_radius),
		home_center.y
	)
