extends Node2D

const NPCRules = preload("res://scripts/NPCRules.gd")
const NPCFactory = preload("res://scripts/NPCFactory.gd")
const GameData = preload("res://scripts/GameData.gd")

const GROUND_MIN_X := GameData.GROUND_MIN_X
const GROUND_MAX_X := GameData.GROUND_MAX_X
const GROUND_TOP_Y := GameData.GROUND_TOP_Y
const CITY_HALL_FRONT := GameData.CITY_HALL_FRONT
const INTERACTION_RANGE := GameData.NPC_INTERACTION_RANGE
const RANDOM_SEED := GameData.NPC_RANDOM_SEED
const STARTING_HOMELESS_RANDOM_SEED := GameData.STARTING_HOMELESS_RANDOM_SEED
const NPC_TREE_CHOP_SECONDS := GameData.NPC_TREE_CHOP_SECONDS
const TOOL_EFFICIENCY_MULTIPLIER := GameData.TOOL_EFFICIENCY_MULTIPLIER
const WARRIOR_ATTACK_RANGE := GameData.WARRIOR_ATTACK_RANGE
const WARRIOR_ATTACK_INTERVAL := GameData.WARRIOR_ATTACK_INTERVAL
const ARCHER_ATTACK_INTERVAL := GameData.ARCHER_ATTACK_INTERVAL

var rules := NPCRules.new()
var factory := NPCFactory.new()
var player: Node2D
var npc_container: Node2D
var elapsed_since_check := 0.0
var rng := RandomNumberGenerator.new()
var spawned_count := 0
var starting_npcs_spawned := false
var warrior_attack_timers := {}
var archer_attack_timers := {}
var game_data := GameData.new()


func _ready() -> void:
	player = get_parent().get_node_or_null("Player")
	npc_container = get_parent().get_node_or_null("NPCs")
	rng.seed = RANDOM_SEED
	spawn_starting_npcs()


func _process(delta: float) -> void:
	_finish_arriving_workers()
	_finish_tool_pickup_travelers()
	_finish_arriving_tree_choppers()
	_equip_workers_from_tools()
	_advance_tree_choppers(delta)
	_assign_idle_archers_to_walls()
	_assign_idle_warriors_to_defense_posts()
	_assign_warrior_patrols()
	_assign_archer_patrols()
	_update_warrior_attacks(delta)
	_update_archer_attacks(delta)
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

	var original_name := npc.name
	npc.interact()
	npc.name = _villager_name_for_homeless(original_name)
	_assign_workplace_to_villager(npc)
	return true


func spawn_starting_npcs() -> void:
	if starting_npcs_spawned or npc_container == null:
		return

	starting_npcs_spawned = true

	for position in rules.starting_villager_positions(CITY_HALL_FRONT):
		_spawn_villager(position)

	var positions: Array = rules.spawn_positions_from_seed(
		STARTING_HOMELESS_RANDOM_SEED,
		rules.starting_homeless_count(),
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y
	)

	for position in positions:
		_spawn_homeless(position)


func release_worker_from_demolished_building(worker_id: String, spawn_position: Vector2) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		npc = factory.create_homeless(spawn_position, CITY_HALL_FRONT)
		npc.name = worker_id if worker_id != "" else _next_npc_name("Villager")
		npc.interact()
		npc_container.add_child(npc)

	npc.exit_building(spawn_position, CITY_HALL_FRONT)


func release_worker_from_damaged_building(
	worker_id: String,
	spawn_position: Vector2,
	workplace_name: String,
	workplace_id: String
) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		npc = factory.create_homeless(spawn_position, CITY_HALL_FRONT)
		npc.name = worker_id if worker_id != "" else _next_npc_name("Villager")
		npc.interact()
		npc_container.add_child(npc)

	npc.exit_building(spawn_position, CITY_HALL_FRONT)
	npc.home_center = spawn_position
	npc.assigned_workplace_name = workplace_name
	npc.assigned_workplace_id = workplace_id
	npc.wander_radius = 90.0


func return_worker_to_repaired_building(
	worker_id: String,
	workplace_position: Vector2,
	workplace_name: String,
	workplace_id: String
) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return
	if npc.get("npc_type") != "villager":
		return
	if npc.has_method("travel_to_workplace"):
		npc.travel_to_workplace(workplace_position, workplace_name, workplace_id)


func cancel_worker_assignment_from_demolished_building(worker_id: String) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return

	npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")


func assign_tree_chopper(task_id: String, tree_position: Vector2) -> String:
	var npc := _nearest_available_tree_chopper(tree_position)
	if npc == null:
		return ""

	npc.travel_to_tree_chop(tree_position, task_id)
	return npc.name


func assign_lumberjack_tree_chop(
	worker_id: String,
	task_id: String,
	tree_position: Vector2,
	return_position: Vector2,
	return_name: String,
	return_id: String,
	resource_worker_role := "lumberjack"
) -> bool:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return false
	if npc.get("npc_type") != "villager":
		return false

	if resource_worker_role == "miner" and npc.has_method("become_miner"):
		npc.become_miner()
	elif npc.has_method("become_lumberjack"):
		npc.become_lumberjack()
	if npc.has_method("travel_to_tree_chop_from_workplace"):
		npc.travel_to_tree_chop_from_workplace(tree_position, task_id, return_position, return_name, return_id)
	else:
		npc.travel_to_tree_chop(tree_position, task_id)
	return true


func finish_tree_chop_for_worker(worker_id: String) -> void:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return

	if npc.has_method("has_tree_chop_return_workplace") and npc.has_tree_chop_return_workplace():
		npc.finish_tree_chop_to_workplace()
	elif npc.has_method("finish_tree_chop"):
		npc.finish_tree_chop(CITY_HALL_FRONT)


func worker_has_tool(worker_id: String, tool_id: String) -> bool:
	var npc := _npc_by_name(worker_id)
	return npc != null and npc.get("carried_tool") == tool_id


func monster_hit_npc(npc_name: String) -> Dictionary:
	var npc := _npc_by_name(npc_name)
	if npc == null:
		return {}

	var carried_tool: String = npc.get("carried_tool")
	if carried_tool != "":
		var dropped_tool := carried_tool
		var build_manager := get_parent().get_node_or_null("BuildManager") if get_parent() != null else null
		if build_manager != null and build_manager.has_method("release_work_site_for_worker"):
			build_manager.release_work_site_for_worker(npc.name)
		if npc.has_method("drop_carried_tool"):
			dropped_tool = npc.drop_carried_tool()
		else:
			npc.set("carried_tool", "")
		return {
			"tool_id": dropped_tool,
			"converted_to_homeless": false,
		}

	if npc.has_method("become_homeless"):
		npc.become_homeless()
	else:
		npc.set("npc_type", "homeless")
		npc.set("worker_role", "none")
	return {
		"tool_id": "",
		"converted_to_homeless": true,
	}


func convert_random_half_villagers_to_homeless(seed: int) -> Array:
	var converted: Array = []
	if npc_container == null:
		return converted

	var villagers: Array = []
	for child in npc_container.get_children():
		if child.get("npc_type") == "villager":
			villagers.append(child)

	var target_count := int(ceil(float(villagers.size()) * 0.5))
	if target_count <= 0:
		return converted

	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed
	var chosen_indexes := {}
	while chosen_indexes.size() < target_count:
		chosen_indexes[local_rng.randi_range(0, villagers.size() - 1)] = true

	var build_manager := get_parent().get_node_or_null("BuildManager") if get_parent() != null else null
	for index in chosen_indexes.keys():
		var npc: Node2D = villagers[index]
		if build_manager != null and build_manager.has_method("release_work_site_for_worker"):
			build_manager.release_work_site_for_worker(npc.name)
		if npc.has_method("drop_carried_tool"):
			npc.drop_carried_tool()
		if npc.has_method("become_homeless"):
			npc.become_homeless()
		else:
			npc.set("npc_type", "homeless")
			npc.set("worker_role", "none")
		converted.append(npc.name)

	return converted


func get_warriors() -> Array:
	var warriors: Array = []
	if npc_container == null:
		return warriors

	for child in npc_container.get_children():
		if child.get("npc_type") == "villager" and child.get("worker_role") == "warrior":
			warriors.append(child)

	return warriors


func get_archers() -> Array:
	var archers: Array = []
	if npc_container == null:
		return archers

	for child in npc_container.get_children():
		if child.get("npc_type") == "villager" and child.get("worker_role") == "archer":
			archers.append(child)

	return archers


func worker_role_for(worker_id: String) -> String:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return ""
	return npc.get("worker_role")


func train_shield_guard(worker_id: String) -> bool:
	var npc := _npc_by_name(worker_id)
	if npc == null:
		return false
	if npc.get("npc_type") != "villager":
		return false
	if npc.get("worker_role") != "villager":
		return false

	var build_manager := get_parent().get_node_or_null("BuildManager") if get_parent() != null else null
	if build_manager == null or not build_manager.has_method("spend_gold_for_shield_guard_training"):
		return false
	if not build_manager.spend_gold_for_shield_guard_training():
		return false

	if npc.has_method("become_shield_guard"):
		npc.become_shield_guard()
	return true


func train_nearest_shield_guard_candidate(origin: Vector2) -> bool:
	var candidate := _nearest_shield_guard_candidate(origin)
	if candidate == null:
		return false

	return train_shield_guard(candidate.name)


func shield_guard_count() -> int:
	var count := 0
	if npc_container == null:
		return count

	for child in npc_container.get_children():
		if child.get("npc_type") == "villager" and child.get("worker_role") == "shield_guard":
			count += 1
	return count


func expedition_loss_multiplier() -> float:
	var reduction := float(game_data.npc_role_value("shield_guard", "expedition_loss_reduction", 0.2)) * shield_guard_count()
	var max_reduction := float(game_data.defense_value("max_expedition_loss_reduction", 0.6))
	return 1.0 - minf(reduction, max_reduction)


func _nearest_shield_guard_candidate(origin: Vector2) -> Node2D:
	if npc_container == null:
		return null

	var nearest: Node2D = null
	var nearest_distance := INF
	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("worker_role") != "villager":
			continue
		if child.get("is_traveling_to_workplace") or child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_tree_chop") or child.get("is_chopping_tree"):
			continue

		var distance := origin.distance_to(child.global_position)
		if distance < nearest_distance:
			nearest = child
			nearest_distance = distance
	return nearest


func _equip_workers_from_tools() -> void:
	if npc_container == null:
		return

	var build_manager := get_parent().get_node_or_null("BuildManager")
	if (
		build_manager == null
		or not build_manager.has_method("reserve_tool_for_role")
		or not build_manager.has_method("worker_leaves_work_site")
	):
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		var role: String = child.get("worker_role")
		if role == "warrior":
			continue
		if role == "archer":
			if child.get("arrowhead_tool") != "":
				continue
		elif child.get("carried_tool") != "":
			continue
		if child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_workplace"):
			continue
		if child.get("is_traveling_to_tree_chop") or child.get("is_chopping_tree"):
			continue

		var workplace_id: String = child.get("assigned_workplace_id")
		if workplace_id == "" or workplace_id == "cityhall":
			continue
		if not child.get("is_inside_building"):
			continue

		var pickup: Dictionary = build_manager.reserve_tool_for_role(role, child.name)
		if pickup.is_empty():
			continue

		var released_work_site := false
		if _is_patrol_tool(pickup.get("tool_id", "")) and build_manager.has_method("release_work_site_for_worker"):
			released_work_site = build_manager.release_work_site_for_worker(child.name)
		else:
			released_work_site = build_manager.worker_leaves_work_site(workplace_id, child.name)

		if not released_work_site:
			if build_manager.has_method("cancel_reserved_tool_for_worker"):
				build_manager.cancel_reserved_tool_for_worker(child.name)
			continue

		if child.has_method("travel_to_tool_pickup"):
			child.travel_to_tool_pickup(
				pickup.get("position", child.global_position),
				pickup.get("blacksmith_id", ""),
				pickup.get("tool_id", ""),
				child.home_center,
				child.assigned_workplace_name,
				workplace_id
			)


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
	var npc := factory.create_homeless(position, CITY_HALL_FRONT)
	npc.name = _next_npc_name("Homeless")
	npc_container.add_child(npc)


func _spawn_villager(position: Vector2) -> void:
	var npc := factory.create_homeless(position, CITY_HALL_FRONT)
	npc.name = _next_npc_name("Villager")
	npc.interact()
	npc_container.add_child(npc)


func _next_npc_name(prefix: String) -> String:
	spawned_count += 1
	return "%s_%02d" % [prefix, spawned_count]


func _villager_name_for_homeless(homeless_name: String) -> String:
	if homeless_name.begins_with("Homeless_"):
		return homeless_name.replace("Homeless_", "Villager_")

	return _next_npc_name("Villager")


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
		if child.get("worker_role") == "warrior" or child.get("worker_role") == "archer":
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_workplace"):
			continue
		if child.get("is_traveling_to_tree_chop") or child.get("is_chopping_tree"):
			continue
		if child.get("assigned_workplace_id") != "cityhall":
			continue

		_assign_workplace_to_villager(child)


func _assign_workplace_to_villager(npc: Node2D) -> void:
	if npc.get("worker_role") == "warrior":
		return

	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("get_work_sites"):
		npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")
		return

	var sites: Array = _filtered_work_sites_for_npc(npc, build_manager.get_work_sites())
	var site_list_index := rules.nearest_available_work_site_index(npc.global_position, sites)
	if site_list_index == -1:
		if npc.get("worker_role") == "archer":
			_assign_archer_patrols()
		else:
			npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")
		return

	var site: Dictionary = sites[site_list_index]
	if build_manager.claim_work_site(site.entity_index, npc.name):
		npc.travel_to_workplace(site.position, site.display_name, site.workplace_id)
	else:
		if npc.get("worker_role") == "archer":
			_assign_archer_patrols()
		else:
			npc.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")


func _assign_idle_archers_to_walls() -> void:
	if npc_container == null:
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("worker_role") != "archer":
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_workplace"):
			continue
		if child.get("is_traveling_to_tree_chop") or child.get("is_chopping_tree"):
			continue

		_assign_workplace_to_villager(child)


func _assign_idle_warriors_to_defense_posts() -> void:
	if npc_container == null:
		return

	var build_manager := get_parent().get_node_or_null("BuildManager") if get_parent() != null else null
	if build_manager == null or not build_manager.has_method("get_work_sites"):
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("worker_role") != "warrior":
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_workplace"):
			continue
		if child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_tree_chop") or child.get("is_chopping_tree"):
			continue

		var sites := _filtered_work_sites_for_npc(child, build_manager.get_work_sites())
		var site_list_index := rules.nearest_available_work_site_index(child.global_position, sites)
		if site_list_index == -1:
			continue

		var site: Dictionary = sites[site_list_index]
		if build_manager.claim_work_site(site.entity_index, child.name):
			child.travel_to_workplace(site.position, site.display_name, site.workplace_id)


func _filtered_work_sites_for_npc(npc: Node2D, sites: Array) -> Array:
	var filtered: Array = []
	var role: String = npc.get("worker_role")
	for site in sites:
		var required_role: String = site.get("required_role", "")
		var required_roles: Array = required_role.split(",") if required_role.find(",") != -1 else [required_role]
		if role == "archer":
			if required_roles.has("archer"):
				filtered.append(site)
			continue
		if role == "warrior":
			if required_roles.has("warrior"):
				filtered.append(site)
			continue
		if required_role != "":
			continue
		filtered.append(site)

	return filtered


func _finish_arriving_workers() -> void:
	if npc_container == null:
		return

	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("occupy_work_site"):
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("worker_role") == "warrior" and not str(child.get("assigned_workplace_id")).begins_with("cliff_fort"):
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_workplace") != true:
			continue
		if child.has_method("is_at_assigned_workplace") and not child.is_at_assigned_workplace():
			continue

		var workplace_id: String = child.get("assigned_workplace_id")
		if build_manager.occupy_work_site(workplace_id, child.name):
			var work_site_role := ""
			if build_manager.has_method("work_site_role_for_workplace_id"):
				work_site_role = build_manager.work_site_role_for_workplace_id(workplace_id)
			if workplace_id.begins_with("wall") and child.get("worker_role") == "archer" and child.has_method("enter_wall_top"):
				child.enter_wall_top(child.home_center, child.assigned_workplace_name, workplace_id)
			elif workplace_id.begins_with("cliff_fort") and child.has_method("enter_defense_post"):
				var range_bonus := 0.0
				if build_manager.has_method("defense_post_range_bonus_for_workplace_id"):
					range_bonus = build_manager.defense_post_range_bonus_for_workplace_id(workplace_id)
				child.enter_defense_post(child.home_center, child.assigned_workplace_name, workplace_id, range_bonus)
			elif workplace_id.begins_with("lumberyard"):
				_apply_work_role(child, "lumberjack" if work_site_role == "" else work_site_role)
				child.enter_building(child.home_center, child.assigned_workplace_name, workplace_id)
			elif work_site_role != "":
				_apply_work_role(child, work_site_role)
				child.enter_building(child.home_center, child.assigned_workplace_name, workplace_id)
			else:
				child.enter_building(child.home_center, child.assigned_workplace_name, workplace_id)
		else:
			child.set_workplace(CITY_HALL_FRONT, "市政厅", "cityhall")


func _finish_tool_pickup_travelers() -> void:
	if npc_container == null:
		return

	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("claim_reserved_tool_for_worker"):
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("is_traveling_to_tool_pickup") != true:
			continue
		if child.has_method("is_at_tool_pickup_target") and not child.is_at_tool_pickup_target():
			continue

		var tool_id: String = build_manager.claim_reserved_tool_for_worker(child.name)
		if child.has_method("finish_tool_pickup_to_workplace"):
			child.finish_tool_pickup_to_workplace(tool_id)
		elif tool_id != "":
			child.set("carried_tool", tool_id)
		if _is_warrior_tool(tool_id):
			_assign_warrior_patrols()
		elif tool_id == "bow":
			_assign_workplace_to_villager(child)
			_assign_archer_patrols()


func _apply_work_role(npc: Node2D, work_role: String) -> void:
	match work_role:
		"farmer":
			if npc.has_method("become_farmer"):
				npc.become_farmer()
		"miner":
			if npc.has_method("become_miner"):
				npc.become_miner()
		"lumberjack":
			if npc.has_method("become_lumberjack"):
				npc.become_lumberjack()
		"merchant":
			if npc.has_method("become_merchant"):
				npc.become_merchant()


func _is_warrior_tool(tool_id: String) -> bool:
	return tool_id == "sword" or tool_id == "stone_sword" or game_data.tool_value(tool_id, "attack_power", null) != null


func _is_patrol_tool(tool_id: String) -> bool:
	return _is_warrior_tool(tool_id) or tool_id == "bow"


func _finish_arriving_tree_choppers() -> void:
	if npc_container == null:
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("is_traveling_to_tree_chop") != true:
			continue
		if child.has_method("is_at_tree_chop_target") and not child.is_at_tree_chop_target():
			continue
		if child.has_method("start_tree_chop"):
			child.start_tree_chop()


func _advance_tree_choppers(delta: float) -> void:
	if npc_container == null:
		return

	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("advance_tree_chop"):
		return

	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("is_chopping_tree") != true:
			continue

		var task_id: String = child.get("tree_chop_task_id")
		var resource_kind := "tree"
		if build_manager.has_method("resource_kind_for_task"):
			resource_kind = build_manager.resource_kind_for_task(task_id)
		var duration := game_data.resource_npc_seconds(resource_kind)
		var carried_tool: String = child.get("carried_tool")
		if game_data.tool_resource_kind(carried_tool) == resource_kind:
			duration /= game_data.tool_efficiency_multiplier(carried_tool)
		build_manager.advance_tree_chop(task_id, delta, duration)


func _nearest_available_tree_chopper(tree_position: Vector2) -> Node2D:
	if npc_container == null:
		return null

	var nearest: Node2D = null
	var nearest_distance := INF
	for child in npc_container.get_children():
		if child.get("npc_type") != "villager":
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_tool_pickup"):
			continue
		if child.get("is_traveling_to_workplace"):
			continue
		if child.get("is_traveling_to_tree_chop") or child.get("is_chopping_tree"):
			continue
		if child.get("assigned_workplace_id") != "cityhall":
			continue

		var distance := tree_position.distance_to(child.global_position)
		if distance < nearest_distance:
			nearest = child
			nearest_distance = distance

	return nearest


func _assign_warrior_patrols() -> void:
	var warriors := get_warriors()
	if warriors.is_empty():
		return

	warriors.sort_custom(func(a: Node2D, b: Node2D) -> bool: return String(a.name) < String(b.name))

	var anchors := {
		"left": CITY_HALL_FRONT + Vector2(-240, 0),
		"right": CITY_HALL_FRONT + Vector2(240, 0),
	}
	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager != null and build_manager.has_method("get_warrior_patrol_anchors"):
		anchors = build_manager.get_warrior_patrol_anchors()

	for i in range(warriors.size()):
		var warrior: Node2D = warriors[i]
		if warrior.get("is_inside_building") or warrior.get("is_traveling_to_workplace"):
			continue
		var side := "left" if i % 2 == 0 else "right"
		var anchor: Vector2 = anchors.get(side, CITY_HALL_FRONT)
		if warrior.has_method("set_warrior_patrol"):
			warrior.set_warrior_patrol(side, anchor)


func _assign_archer_patrols() -> void:
	var archers: Array = []
	for archer in get_archers():
		if archer.get("is_on_wall"):
			continue
		if archer.get("is_inside_building"):
			continue
		if archer.get("is_traveling_to_workplace"):
			continue
		if archer.get("is_traveling_to_tool_pickup"):
			continue
		if archer.get("is_traveling_to_tree_chop") or archer.get("is_chopping_tree"):
			continue
		archers.append(archer)

	if archers.is_empty():
		return

	archers.sort_custom(func(a: Node2D, b: Node2D) -> bool: return String(a.name) < String(b.name))

	var anchors := {
		"left": CITY_HALL_FRONT + Vector2(-240, 0),
		"right": CITY_HALL_FRONT + Vector2(240, 0),
	}
	var build_manager := get_parent().get_node_or_null("BuildManager")
	if build_manager != null and build_manager.has_method("get_warrior_patrol_anchors"):
		anchors = build_manager.get_warrior_patrol_anchors()

	for i in range(archers.size()):
		var archer: Node2D = archers[i]
		var side := "left" if i % 2 == 0 else "right"
		var anchor: Vector2 = anchors.get(side, CITY_HALL_FRONT)
		if archer.has_method("set_archer_patrol"):
			archer.set_archer_patrol(side, anchor)


func _update_warrior_attacks(delta: float) -> void:
	var monster_manager := get_parent().get_node_or_null("MonsterManager")
	if monster_manager == null or not monster_manager.has_method("damage_nearest_monster"):
		return

	for warrior in get_warriors():
		var timer := float(warrior_attack_timers.get(warrior.name, 0.0)) - delta
		if timer > 0.0:
			warrior_attack_timers[warrior.name] = timer
			continue

		var damage := int(warrior.get("attack_power"))
		if damage <= 0:
			continue

		if monster_manager.damage_nearest_monster(warrior.global_position, damage, WARRIOR_ATTACK_RANGE):
			warrior_attack_timers[warrior.name] = WARRIOR_ATTACK_INTERVAL


func _update_archer_attacks(delta: float) -> void:
	var monster_manager := get_parent().get_node_or_null("MonsterManager")
	if monster_manager == null or not monster_manager.has_method("shoot_nearest_monster"):
		return

	for archer in get_archers():
		if not archer.visible:
			continue
		var timer := float(archer_attack_timers.get(archer.name, 0.0)) - delta
		if timer > 0.0:
			archer_attack_timers[archer.name] = timer
			continue

		var damage := int(archer.get("attack_power"))
		if damage <= 0:
			continue

		var range := float(archer.get("attack_range"))
		if range <= 0.0:
			range = 600.0
		if monster_manager.shoot_nearest_monster(archer.global_position, damage, range):
			archer_attack_timers[archer.name] = ARCHER_ATTACK_INTERVAL


func _npc_by_name(npc_name: String) -> Node2D:
	if npc_container == null:
		return null

	for child in npc_container.get_children():
		if child.name == npc_name:
			return child

	return null
