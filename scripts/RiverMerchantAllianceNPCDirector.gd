extends Node

const GameData = preload("res://scripts/GameData.gd")
const NPCFactory = preload("res://scripts/NPCFactory.gd")

var factory := NPCFactory.new()
var game_data := GameData.new()


func _ready() -> void:
	setup_scene_npcs()


func _process(_delta: float) -> void:
	_finish_arriving_workers()


func setup_scene_npcs() -> void:
	var root := get_parent()
	if root == null:
		return

	var npc_container := _ensure_npc_container(root)
	_clear_generated_npcs(npc_container)
	_hide_static_npc_fallback(root)

	for definition in game_data.river_merchant_alliance_npc_layout():
		var npc := _create_npc(definition)
		npc_container.add_child(npc)


func _ensure_npc_container(root: Node) -> Node2D:
	var npc_container := root.get_node_or_null("NPCs") as Node2D
	if npc_container != null:
		return npc_container

	npc_container = Node2D.new()
	npc_container.name = "NPCs"
	npc_container.z_index = 1
	root.add_child(npc_container)
	return npc_container


func _clear_generated_npcs(npc_container: Node2D) -> void:
	for child in npc_container.get_children():
		if child.has_meta("river_dynamic_npc"):
			npc_container.remove_child(child)
			child.free()


func _hide_static_npc_fallback(root: Node) -> void:
	var static_npcs := root.get_node_or_null("StaticNPCs")
	if static_npcs != null:
		static_npcs.visible = false


func _create_npc(definition: Dictionary) -> Node2D:
	var start_position: Vector2 = definition.get("position", GameData.CITY_HALL_FRONT)
	var npc := factory.create_homeless(start_position, GameData.CITY_HALL_FRONT)
	npc.name = str(definition.get("name", "RiverNPC"))
	npc.set_meta("river_dynamic_npc", true)
	npc.interact()

	var role := str(definition.get("role", "villager"))
	_apply_role(npc, role)
	_apply_behavior(npc, definition, role)
	return npc


func _apply_role(npc: Node2D, role: String) -> void:
	match role:
		"farmer":
			if npc.has_method("become_farmer"):
				npc.become_farmer()
		"lumberjack":
			if npc.has_method("become_lumberjack"):
				npc.become_lumberjack()
		"miner":
			if npc.has_method("become_miner"):
				npc.become_miner()
		"merchant":
			if npc.has_method("become_merchant"):
				npc.become_merchant()
		"warrior":
			if npc.has_method("equip_tool"):
				npc.equip_tool("sword")
		"archer":
			if npc.has_method("equip_tool"):
				npc.equip_tool("bow")


func _apply_behavior(npc: Node2D, definition: Dictionary, role: String) -> void:
	if role == "warrior":
		var warrior_anchor: Vector2 = definition.get("patrol_anchor", npc.global_position)
		if npc.has_method("set_warrior_patrol"):
			npc.set_warrior_patrol(str(definition.get("patrol_side", "")), warrior_anchor)
		npc.set("target_position", warrior_anchor)
		return

	if role == "archer":
		var archer_anchor: Vector2 = definition.get("patrol_anchor", npc.global_position)
		if npc.has_method("set_archer_patrol"):
			npc.set_archer_patrol(str(definition.get("patrol_side", "")), archer_anchor)
		npc.set("target_position", archer_anchor)
		return

	var home_position: Vector2 = definition.get("home_position", npc.global_position)
	var home_name := str(definition.get("home_name", "cityhall"))
	var home_id := str(definition.get("home_id", "cityhall"))
	if bool(definition.get("enters_building", false)) and npc.has_method("travel_to_workplace"):
		npc.travel_to_workplace(home_position, home_name, home_id)
	elif npc.has_method("set_workplace"):
		npc.set_workplace(home_position, home_name, home_id)


func _finish_arriving_workers() -> void:
	var root := get_parent()
	if root == null:
		return

	var npc_container := root.get_node_or_null("NPCs")
	if npc_container == null:
		return

	var occupied_workplaces := {}
	for child in npc_container.get_children():
		if not child.has_meta("river_dynamic_npc"):
			continue
		if child.get("is_inside_building") != true:
			continue

		var occupied_id := str(child.get("assigned_workplace_id"))
		if occupied_id != "":
			occupied_workplaces[occupied_id] = true

	for child in npc_container.get_children():
		if not child.has_meta("river_dynamic_npc"):
			continue
		if child.get("is_inside_building"):
			continue
		if child.get("is_traveling_to_workplace") != true:
			continue
		if child.has_method("is_at_assigned_workplace") and not child.is_at_assigned_workplace():
			continue
		var workplace_id := str(child.get("assigned_workplace_id"))
		if workplace_id != "" and bool(occupied_workplaces.get(workplace_id, false)):
			if child.has_method("set_workplace"):
				child.set_workplace(child.global_position, str(child.get("assigned_workplace_name")), workplace_id)
			continue
		if child.has_method("enter_building"):
			child.enter_building(
				child.get("home_center"),
				str(child.get("assigned_workplace_name")),
				workplace_id
			)
			if workplace_id != "":
				occupied_workplaces[workplace_id] = true
