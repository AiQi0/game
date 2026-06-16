extends Node2D

const NPCRules = preload("res://scripts/NPCRules.gd")
const NPCFactory = preload("res://scripts/NPCFactory.gd")

const GROUND_MIN_X := 0.0
const GROUND_MAX_X := 9600.0
const GROUND_TOP_Y := 472.0
const CITY_HALL_FRONT := Vector2(4800, 472)
const INTERACTION_RANGE := 72.0
const RANDOM_SEED := 20260616

var rules := NPCRules.new()
var factory := NPCFactory.new()
var player: Node2D
var npc_container: Node2D
var elapsed_since_check := 0.0
var rng := RandomNumberGenerator.new()
var spawned_count := 0


func _ready() -> void:
	player = get_parent().get_node_or_null("Player")
	npc_container = get_parent().get_node_or_null("NPCs")
	rng.seed = RANDOM_SEED


func _process(delta: float) -> void:
	_finish_arriving_workers()
	_assign_idle_villagers_to_work()

	elapsed_since_check += delta
	if elapsed_since_check < rules.spawn_interval_seconds():
		return

	elapsed_since_check = 0.0
	_run_spawn_check()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_E and interact_with_nearest_homeless():
		get_viewport().set_input_as_handled()


func has_interactable_homeless() -> bool:
	return _nearest_homeless() != null


func interact_with_nearest_homeless() -> bool:
	var npc := _nearest_homeless()
	if npc == null:
		return false

	npc.interact()
	npc.name = "Villager_%02d" % spawned_count
	_assign_workplace_to_villager(npc)
	return true


func release_worker_from_demolished_building(worker_id: String, spawn_position: Vector2) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		npc = factory.create_homeless(spawn_position, CITY_HALL_FRONT)
		npc.name = worker_id if worker_id != "" else "Villager_%02d" % (spawned_count + 1)
		npc.interact()
		npc_container.add_child(npc)

	npc.exit_building(spawn_position, CITY_HALL_FRONT)


func cancel_worker_assignment_from_demolished_building(worker_id: String) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return

	npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")


func _run_spawn_check() -> void:
	if npc_container == null:
		return

	if not rules.should_spawn_from_roll(rng.randf()):
		return

	var count := rng.randi_range(NPCRules.MIN_HOMELESS_COUNT, NPCRules.MAX_HOMELESS_COUNT)
	var positions: Array = rules.spawn_positions_from_seed(
		rng.randi(),
		count,
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y
	)

	for position in positions:
		_spawn_homeless(position)


func _spawn_homeless(position: Vector2) -> void:
	spawned_count += 1
	var npc := factory.create_homeless(position, CITY_HALL_FRONT)
	npc.name = "Homeless_%02d" % spawned_count
	npc_container.add_child(npc)


func _nearest_homeless() -> Node2D:
	if player == null or npc_container == null:
		return null

	var nearest: Node2D = null
	var nearest_distance := INF
	for child in npc_container.get_children():
		if child.get("npc_type") != "homeless":
			continue

		var distance := player.global_position.distance_to(child.global_position)
		if distance <= INTERACTION_RANGE and distance < nearest_distance:
			nearest = child
			nearest_distance = distance

	return nearest


func _assign_idle_villagers_to_work() -> void:
	if npc_container == null:
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_workplace"):
			continue
		if child.get("assigned_workplace_id") != "cityhall":
			continue

		_assign_workplace_to_villager(child)


func _assign_workplace_to_villager(npc: Node2D) -> void:
	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("get_work_sites"):
		npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")
		return

	var sites: Array = build_manager.get_work_sites()
	var site_list_index := rules.nearest_available_work_site_index(npc.global_position, sites)
	if site_list_index == -1:
		npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")
		return

	var site: Dictionary = sites[site_list_index]
	if build_manager.claim_work_site(site.entity_index, npc.name):
		npc.travel_to_workplace(site.position, site.display_name, site.workplace_id)
	else:
		npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")


func _finish_arriving_workers() -> void:
	if npc_container == null:
		return

	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("occupy_work_site"):
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_workplace") != true:
			continue
		if child.has_method("is_at_assigned_workplace") and not child.is_at_assigned_workplace():
			continue

		var workplace_id: String = child.get("assigned_workplace_id")
		if build_manager.occupy_work_site(workplace_id, child.name):
			child.enter_building(child.home_center, child.assigned_workplace_name, workplace_id)
		else:
			child.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")


func _npc_by_name(npc_name: String) -> Node2D:
	if npc_container == null:
		return null

	for child in npc_container.get_children():
		if child.name == npc_name:
			return child

	return null
