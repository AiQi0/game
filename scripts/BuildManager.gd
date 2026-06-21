extends Node2D

const BuildingCatalog = preload("res://scripts/BuildingCatalog.gd")
const BuildingVisualFactory = preload("res://scripts/BuildingVisualFactory.gd")
const BuildRules = preload("res://scripts/BuildRules.gd")
const TreeFactory = preload("res://scripts/TreeFactory.gd")
const MonsterRules = preload("res://scripts/MonsterRules.gd")
const GameData = preload("res://scripts/GameData.gd")
const SaveGameManager = preload("res://scripts/SaveGameManager.gd")
const CollectionRules = preload("res://scripts/CollectionRules.gd")

const GROUND_MIN_X := GameData.GROUND_MIN_X
const GROUND_MAX_X := GameData.GROUND_MAX_X
const GROUND_TOP_Y := GameData.GROUND_TOP_Y
const AIR_WALL_WIDTH := GameData.AIR_WALL_WIDTH
const AIR_WALL_HEIGHT := GameData.AIR_WALL_HEIGHT
const CITY_HALL_SIZE := GameData.CITY_HALL_SIZE
const TREE_SIZE := GameData.TREE_SIZE
const MOTHER_TREE_SIZE := GameData.MOTHER_TREE_SIZE
const STONE_SIZE := GameData.STONE_SIZE
const BRIDGE_SIZE := GameData.BRIDGE_SIZE
const BRIDGE_WATER_SIZE := GameData.BRIDGE_WATER_SIZE
const TREE_COUNT := GameData.TREE_COUNT
const TREE_RANDOM_SEED := GameData.TREE_RANDOM_SEED
const MOTHER_TREE_COUNT := GameData.MOTHER_TREE_COUNT
const MOTHER_TREE_RANDOM_SEED := GameData.MOTHER_TREE_RANDOM_SEED
const MOTHER_TREE_GROW_RADIUS := GameData.MOTHER_TREE_GROW_RADIUS
const STONE_COUNT := GameData.STONE_COUNT
const STONE_RANDOM_SEED := GameData.STONE_RANDOM_SEED
const BRIDGE_COUNT := GameData.BRIDGE_COUNT
const BRIDGE_RANDOM_SEED := GameData.BRIDGE_RANDOM_SEED
const CITY_HALL_RESOURCE_INNER_RADIUS := GameData.CITY_HALL_RESOURCE_INNER_RADIUS
const CITY_HALL_RESOURCE_OUTER_RADIUS := GameData.CITY_HALL_RESOURCE_OUTER_RADIUS
const BRIDGE_CITY_HALL_RING_OFFSET := GameData.BRIDGE_CITY_HALL_RING_OFFSET
const MOTHER_TREE_CITY_HALL_RING_OFFSET := GameData.MOTHER_TREE_CITY_HALL_RING_OFFSET
const STONE_CITY_HALL_RING_OFFSET := GameData.STONE_CITY_HALL_RING_OFFSET
const STARTING_GOLD := GameData.STARTING_GOLD
const FARM_INCOME_SECONDS := GameData.FARM_INCOME_SECONDS
const LUMBERYARD_TREE_INTERVAL_SECONDS := GameData.LUMBERYARD_TREE_INTERVAL_SECONDS
const LUMBERYARD_TREE_BATCH_COUNT := GameData.LUMBERYARD_TREE_BATCH_COUNT
const LUMBERYARD_TREE_RADIUS := GameData.LUMBERYARD_TREE_RADIUS
const LUMBERJACK_TREE_SEARCH_RADIUS := GameData.LUMBERJACK_TREE_SEARCH_RADIUS
const MOTHER_TREE_LUMBERJACK_SEARCH_RADIUS := GameData.MOTHER_TREE_LUMBERJACK_SEARCH_RADIUS
const PLAYER_TREE_CHOP_SECONDS := GameData.PLAYER_TREE_CHOP_SECONDS
const TOOL_CRAFT_SECONDS := GameData.TOOL_CRAFT_SECONDS
const TOOL_CRAFT_COST := GameData.TOOL_CRAFT_COST
const BLACKSMITH_TOOL_LIMIT := GameData.BLACKSMITH_TOOL_LIMIT
const AUTOSAVE_SECONDS := GameData.AUTOSAVE_SECONDS
const INFO_PANEL_SIZE := Vector2(430, 460)
const VALID_PREVIEW_COLOR := Color(0.25, 1.0, 0.3, 0.45)
const INVALID_PREVIEW_COLOR := Color(1.0, 0.15, 0.1, 0.45)
const DEMOLITION_PREVIEW_COLOR := Color(1.0, 0.08, 0.05, 0.45)

var catalog := BuildingCatalog.new()
var visual_factory := BuildingVisualFactory.new()
var tree_factory := TreeFactory.new()
var rules := BuildRules.new()
var monster_rules := MonsterRules.new()
var game_data := GameData.new()
var collection_rules := CollectionRules.new()

var buildings: Array = []
var placed_buildings: Array = []
var placed_footprints: Array = []
var tree_chop_tasks: Array = []
var gold := STARTING_GOLD
var city_terrain := ""
var city_player_controlled := true
var occupied_terrains := {}
var trade_treaties := {}
var trade_treaty_active := false
var horse_count := 0
var selected_index := -1
var preview: Node2D
var preview_building_id := ""
var preview_valid := false
var player: CharacterBody2D
var buildings_container: Node2D
var ui_slots: Array = []
var status_label: Label
var gold_label: Label
var demolition_target_index := -1
var demolition_original_modulate := Color.WHITE
var player_tree_task_id := ""
var tree_sequence := 0
var mother_tree_sequence := 0
var bridge_sequence := 0
var tool_sequence := 0
var tool_items: Array = []
var info_panel: Control
var info_panel_canvas: CanvasLayer
var info_panel_entity_index := -1
var player_dead := false
var death_canvas: CanvasLayer
var test_panel: Control
var test_gold_amount_spinbox: SpinBox
var test_monster_count_spinbox: SpinBox
var save_manager = SaveGameManager.new()
var autosave_elapsed := 0.0
var pause_canvas: CanvasLayer
var pause_panel: Control
var fishing_manager: Node
var fish_codex_canvas: CanvasLayer
var fish_codex_panel: Control
var unlocked_crops := {}
var fish_codex := {}
var last_fishing_result := {}
var interaction_focus_index := 0
var interaction_focus_signature := ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent().get_node_or_null("Player")
	buildings_container = get_parent().get_node_or_null("Buildings")
	fishing_manager = get_parent().get_node_or_null("FishingManager")
	_ensure_collection_state()
	_refresh_building_choices()

	_seed_existing_buildings()
	_spawn_bridges()
	_spawn_mother_trees()
	_spawn_stones()
	_spawn_trees()
	_create_ui()
	_recreate_preview()
	_refresh_ui()
	_update_preview()
	_apply_pending_save_on_ready()


func _process(delta: float) -> void:
	if _is_tree_paused():
		return

	if demolition_target_index != -1 and not _player_inside_demolition_target():
		_cancel_demolition()
	if info_panel != null and player != null and not _player_inside_info_panel_entity():
		_clear_info_panel()

	_update_background_interiors(delta)
	_update_farm_income(delta)
	_update_quarry_income(delta)
	_update_blacksmith_crafting(delta)
	_update_lumberyards(delta)
	_assign_waiting_tree_choppers()
	_update_player_tree_chop(delta)
	_update_autosave(delta)
	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if _has_active_interior_overlay():
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and _is_interaction_cycle_mouse_button(mouse_event.button_index):
			if _is_tree_paused():
				return
			if fishing_manager != null and fishing_manager.has_method("is_fishing") and fishing_manager.is_fishing():
				return
			if fish_codex_panel != null or info_panel != null:
				return
			var direction := 1 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
			if _cycle_interaction_focus(direction):
				_mark_input_handled()
		return

	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_ESCAPE:
		if fish_codex_panel != null:
			_clear_fish_codex_panel()
			return
		_toggle_pause_menu()
		return

	if _is_tree_paused():
		return

	if fishing_manager != null and fishing_manager.has_method("is_fishing") and fishing_manager.is_fishing():
		return

	if key_event.keycode == KEY_P:
		toggle_fish_codex_panel()
		return

	if fish_codex_panel != null:
		return

	if key_event.keycode == KEY_TAB:
		if _cycle_interaction_focus(1):
			_mark_input_handled()
		return

	if selected_index != -1 and key_event.keycode == KEY_E:
		if _execute_focused_interaction():
			_mark_input_handled()
		return

	if _handle_info_panel_input(key_event.keycode):
		return

	if key_event.keycode == KEY_W and try_enter_building_at_player():
		return

	var requested_index := rules.selected_index_from_key(key_event.keycode)
	if requested_index != -1:
		_select_building(requested_index)
		return

	if key_event.keycode == KEY_E:
		if demolition_target_index != -1:
			_cancel_demolition()
		elif _execute_focused_interaction():
			_mark_input_handled()
		return

	if key_event.keycode == KEY_Q:
		_handle_demolition_input()


func _seed_existing_buildings() -> void:
	for footprint in rules.air_wall_footprints(
		GROUND_MIN_X,
		GROUND_MAX_X,
		AIR_WALL_WIDTH,
		AIR_WALL_HEIGHT
	):
		placed_footprints.append(footprint)

	var city_hall := get_parent().get_node_or_null("CityHall")
	if city_hall != null:
		_track_placed_entity(
			city_hall,
			rules.footprint_for_position(city_hall.position, CITY_HALL_SIZE),
			false,
			"市政厅",
			"cityhall",
			false,
			"cityhall"
		)


func _spawn_bridges() -> void:
	if buildings_container == null:
		return

	if BRIDGE_COUNT > 0:
		_spawn_bridge_at(_city_hall_resource_position(BRIDGE_CITY_HALL_RING_OFFSET, BRIDGE_SIZE))

	var bridge_blocked_footprints := placed_footprints.duplicate()
	bridge_blocked_footprints.append(_city_hall_resource_exclusion_footprint(CITY_HALL_RESOURCE_OUTER_RADIUS, BRIDGE_SIZE))
	var random_positions: Array = rules.random_tree_positions(
		BRIDGE_RANDOM_SEED,
		maxi(0, BRIDGE_COUNT - 1),
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y,
		BRIDGE_SIZE,
		bridge_blocked_footprints
	)
	for position in random_positions:
		_spawn_bridge_at(position)


func _city_hall_resource_position(offset: float, resource_size: Vector2) -> Vector2:
	var city_hall_position := _city_hall_position()
	return Vector2(
		clampf(
			city_hall_position.x + offset,
			GROUND_MIN_X + resource_size.x * 0.5,
			GROUND_MAX_X - resource_size.x * 0.5
		),
		GROUND_TOP_Y
	)


func _city_hall_resource_exclusion_footprint(radius: float, resource_size: Vector2) -> Rect2:
	var city_hall_position := _city_hall_position()
	var width := maxf(0.0, radius * 2.0 - resource_size.x)
	return Rect2(
		Vector2(
			city_hall_position.x - radius + resource_size.x * 0.5,
			GROUND_TOP_Y - resource_size.y
		),
		Vector2(width, resource_size.y)
	)


func _spawn_bridge_at(position: Vector2) -> Node2D:
	if buildings_container == null:
		return null

	bridge_sequence += 1
	var bridge := Node2D.new()
	bridge.name = "Bridge_%02d" % bridge_sequence
	bridge.position = buildings_container.to_local(position)
	bridge.z_index = 2

	var water := Polygon2D.new()
	water.name = "Water"
	water.color = Color(0.1, 0.34, 0.72, 1)
	water.polygon = PackedVector2Array([
		Vector2(-BRIDGE_WATER_SIZE.x * 0.5, BRIDGE_SIZE.y),
		Vector2(BRIDGE_WATER_SIZE.x * 0.5, BRIDGE_SIZE.y),
		Vector2(BRIDGE_WATER_SIZE.x * 0.5, BRIDGE_SIZE.y + BRIDGE_WATER_SIZE.y),
		Vector2(-BRIDGE_WATER_SIZE.x * 0.5, BRIDGE_SIZE.y + BRIDGE_WATER_SIZE.y),
	])
	bridge.add_child(water)

	var deck := Polygon2D.new()
	deck.name = "Deck"
	deck.color = Color(0.5, 0.29, 0.12, 1)
	deck.polygon = PackedVector2Array([
		Vector2(-BRIDGE_SIZE.x * 0.5, 0.0),
		Vector2(BRIDGE_SIZE.x * 0.5, 0.0),
		Vector2(BRIDGE_SIZE.x * 0.5, BRIDGE_SIZE.y),
		Vector2(-BRIDGE_SIZE.x * 0.5, BRIDGE_SIZE.y),
	])
	bridge.add_child(deck)

	for i in range(5):
		var plank := Polygon2D.new()
		plank.name = "Plank%d" % i
		plank.color = Color(0.68, 0.45, 0.22, 1)
		var left := -BRIDGE_SIZE.x * 0.45 + i * BRIDGE_SIZE.x * 0.225
		plank.polygon = PackedVector2Array([
			Vector2(left, 0.0),
			Vector2(left + BRIDGE_SIZE.x * 0.12, 0.0),
			Vector2(left + BRIDGE_SIZE.x * 0.12, BRIDGE_SIZE.y),
			Vector2(left, BRIDGE_SIZE.y),
		])
		bridge.add_child(plank)

	buildings_container.add_child(bridge)
	_track_placed_entity(
		bridge,
		rules.footprint_for_position(position, BRIDGE_SIZE),
		false,
		"短桥梁",
		"bridge",
		false,
		"",
		"bridge"
	)
	var index := placed_buildings.size() - 1
	var entity: Dictionary = placed_buildings[index]
	entity.farm_built = false
	entity.farm_node_name = ""
	placed_buildings[index] = entity
	return bridge


func _spawn_mother_trees() -> void:
	if buildings_container == null:
		return

	if MOTHER_TREE_COUNT > 0:
		_spawn_mother_tree_at(_city_hall_resource_position(MOTHER_TREE_CITY_HALL_RING_OFFSET, MOTHER_TREE_SIZE))

	var mother_tree_blocked_footprints := placed_footprints.duplicate()
	mother_tree_blocked_footprints.append(_city_hall_resource_exclusion_footprint(CITY_HALL_RESOURCE_OUTER_RADIUS, MOTHER_TREE_SIZE))
	var positions: Array = rules.random_tree_positions(
		MOTHER_TREE_RANDOM_SEED,
		maxi(0, MOTHER_TREE_COUNT - 1),
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y,
		MOTHER_TREE_SIZE,
		mother_tree_blocked_footprints
	)

	for position in positions:
		_spawn_mother_tree_at(position)


func _spawn_mother_tree_at(position: Vector2) -> Node2D:
	if buildings_container == null:
		return null

	mother_tree_sequence += 1
	var mother_tree := tree_factory.create_mother_tree_visual()
	mother_tree.name = "MotherTree_%02d" % mother_tree_sequence
	mother_tree.position = buildings_container.to_local(position)
	buildings_container.add_child(mother_tree)
	_track_placed_entity(
		mother_tree,
		rules.footprint_for_position(position, MOTHER_TREE_SIZE),
		false,
		game_data.resource_display_name("mother_tree"),
		"mother_tree",
		false,
		"mother_tree",
		"mother_tree"
	)
	var index := placed_buildings.size() - 1
	var entity: Dictionary = placed_buildings[index]
	entity.has_lumberyard = false
	entity.lumberyard_node_name = ""
	placed_buildings[index] = entity
	return mother_tree


func _spawn_trees() -> void:
	if buildings_container == null:
		return

	var positions: Array = rules.random_tree_positions(
		TREE_RANDOM_SEED,
		TREE_COUNT,
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y,
		TREE_SIZE,
		placed_footprints
	)

	for i in range(positions.size()):
		var tree_position: Vector2 = positions[i]
		var tree := tree_factory.create_tree_visual()
		tree.name = "Tree_%02d" % (i + 1)
		tree.position = buildings_container.to_local(tree_position)
		buildings_container.add_child(tree)
		_track_placed_entity(
			tree,
			rules.footprint_for_position(tree_position, TREE_SIZE),
			true,
			"树",
			"tree",
			false,
			"tree",
			"tree"
		)


func _spawn_stones() -> void:
	if buildings_container == null:
		return

	if STONE_COUNT > 0:
		_spawn_stone_at(_city_hall_resource_position(STONE_CITY_HALL_RING_OFFSET, STONE_SIZE))

	var stone_blocked_footprints := placed_footprints.duplicate()
	stone_blocked_footprints.append(_city_hall_resource_exclusion_footprint(CITY_HALL_RESOURCE_OUTER_RADIUS, STONE_SIZE))
	var positions: Array = rules.random_tree_positions(
		STONE_RANDOM_SEED,
		maxi(0, STONE_COUNT - 1),
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y,
		STONE_SIZE,
		stone_blocked_footprints
	)

	for position in positions:
		_spawn_stone_at(position)


func _select_building(index: int) -> void:
	if index < 0 or index >= buildings.size():
		return

	if demolition_target_index != -1:
		_cancel_demolition()

	selected_index = rules.selected_index_after_request(selected_index, index)
	_recreate_preview()
	_refresh_ui()
	_update_preview()


func _recreate_preview() -> void:
	_clear_preview()

	if selected_index == -1:
		return

	_ensure_preview_for_definition(buildings[selected_index])


func _ensure_preview_for_definition(definition: Dictionary) -> void:
	var building_id := str(definition.get("id", ""))
	if preview != null and preview_building_id == building_id:
		return

	_clear_preview()
	if definition.is_empty():
		return

	preview = visual_factory.create_building_visual(definition)
	preview.name = "BuildPreview"
	preview.z_index = 4
	preview.modulate = VALID_PREVIEW_COLOR
	preview_building_id = building_id
	add_child(preview)


func _clear_preview() -> void:
	if preview != null:
		preview.queue_free()
		preview = null
	preview_building_id = ""


func _update_preview() -> void:
	if status_label == null:
		return

	_refresh_gold_ui()

	if player_tree_task_id != "":
		status_label.text = "正在砍树 %d%%" % int(_tree_chop_progress(player_tree_task_id) * 100.0)
		return

	if demolition_target_index != -1:
		status_label.text = "Q 拆除 / E 取消"
		return

	if selected_index != -1:
		_update_selected_build_preview()
		return

	var damaged_entity_index := _damaged_building_index_at_player()
	if damaged_entity_index != -1:
		status_label.text = _repair_prompt_for_entity(damaged_entity_index)
		_show_interaction_prompt_if_any()
		return

	var resource_preview := _resource_build_preview_for_player()
	if not resource_preview.is_empty():
		_update_build_preview(
			resource_preview.get("definition", {}),
			resource_preview.get("position", Vector2.ZERO),
			bool(resource_preview.get("valid", false)),
			str(resource_preview.get("prompt", ""))
		)
		_show_interaction_prompt_if_any()
		return

	var quarry_prompt := _quarry_prompt_for_player()
	if quarry_prompt != "":
		preview_valid = false
		status_label.text = quarry_prompt
		return

	var mother_tree_prompt := _mother_tree_lumberyard_prompt_for_player()
	if selected_index == -1 and mother_tree_prompt != "":
		preview_valid = false
		status_label.text = mother_tree_prompt
		return

	var bridge_farm_prompt := _bridge_farm_prompt_for_player()
	if selected_index == -1 and bridge_farm_prompt != "":
		preview_valid = false
		status_label.text = bridge_farm_prompt
		return

	if selected_index == -1:
		_clear_preview()
		preview_valid = false
		var tree_task_id := _tree_task_for_player()
		status_label.text = "E 砍树 / 1-0 选择建筑" if tree_task_id != "" else "1-0 选择建筑 / Q 拆除"
		_show_interaction_prompt_if_any()
		return

func _update_selected_build_preview() -> void:
	if selected_index == -1 or player == null:
		return
	var definition: Dictionary = buildings[selected_index]
	_ensure_preview_for_definition(definition)
	if preview == null:
		return

	var unavailable_reason := _building_unavailable_reason(definition)
	var footprint_size := _building_footprint_size(definition)
	var build_position := rules.build_position_for_player(
		player.global_position,
		_get_player_facing_direction(),
		footprint_size,
		GROUND_TOP_Y
	)
	var footprint := rules.footprint_for_position(build_position, footprint_size)

	preview.global_position = build_position
	_apply_building_orientation(preview, str(definition.get("id", "")), build_position)
	preview_valid = not rules.has_overlap(footprint, placed_footprints) and unavailable_reason == ""
	preview.modulate = VALID_PREVIEW_COLOR if preview_valid else INVALID_PREVIEW_COLOR
	if preview_valid:
		status_label.text = "E 建造"
	elif unavailable_reason != "":
		status_label.text = unavailable_reason
	else:
		status_label.text = "位置重叠，无法建造"
	_show_interaction_prompt_if_any()


func _update_build_preview(definition: Dictionary, build_position: Vector2, is_valid: bool, text: String) -> void:
	_ensure_preview_for_definition(definition)
	if preview == null:
		return

	preview.global_position = build_position
	preview_valid = is_valid
	preview.modulate = VALID_PREVIEW_COLOR if preview_valid else INVALID_PREVIEW_COLOR
	status_label.text = text


func _interaction_candidates() -> Array:
	var candidates := []

	if selected_index != -1:
		if selected_index < buildings.size():
			var selected_definition: Dictionary = buildings[selected_index]
			candidates.append({
				"id": "build_selected",
				"label": "建造" + str(selected_definition.get("display_name", "建筑")),
				"priority": 50,
			})
		_sync_interaction_focus(candidates)
		return candidates

	if _has_npc_interaction():
		candidates.append({
			"id": "recruit_homeless",
			"label": "招募流浪汉",
			"priority": 10,
		})

	var damaged_entity_index := _damaged_building_index_at_player()
	if damaged_entity_index != -1:
		var repair_prompt := _repair_prompt_for_entity(damaged_entity_index)
		if _prompt_is_e_interaction(repair_prompt):
			candidates.append({
				"id": "repair_building",
				"label": _interaction_label_from_prompt(repair_prompt),
				"entity_index": damaged_entity_index,
				"priority": 20,
			})

	var building_info_index := -1
	if player != null:
		building_info_index = _building_info_entity_index_containing_point(player.global_position)
	if building_info_index != -1 and damaged_entity_index == -1:
		var entity: Dictionary = placed_buildings[building_info_index]
		candidates.append({
			"id": "building_info",
			"label": "打开%s面板" % str(entity.get("display_name", "建筑")),
			"entity_index": building_info_index,
			"priority": 30,
		})

	var stone_index := -1
	if player != null:
		stone_index = _stone_entity_index_containing_point(player.global_position)
	if stone_index != -1:
		var quarry_prompt := _quarry_prompt_for_player()
		if _prompt_is_e_interaction(quarry_prompt):
			candidates.append({
				"id": "build_quarry",
				"label": _interaction_label_from_prompt(quarry_prompt),
				"entity_index": stone_index,
				"priority": 40,
			})

	if selected_index == -1:
		var mother_tree_index := -1
		if player != null:
			mother_tree_index = _mother_tree_entity_index_containing_point(player.global_position)
		if mother_tree_index != -1:
			var lumberyard_prompt := _mother_tree_lumberyard_prompt_for_player()
			if _prompt_is_e_interaction(lumberyard_prompt):
				candidates.append({
					"id": "build_lumberyard",
					"label": _interaction_label_from_prompt(lumberyard_prompt),
					"entity_index": mother_tree_index,
					"priority": 41,
				})

		var bridge_index := -1
		if player != null:
			bridge_index = _bridge_entity_index_containing_point(player.global_position)
		if bridge_index != -1:
			var farm_prompt := _bridge_farm_prompt_for_player()
			if _prompt_is_e_interaction(farm_prompt):
				candidates.append({
					"id": "build_farm",
					"label": _interaction_label_from_prompt(farm_prompt),
					"entity_index": bridge_index,
					"priority": 42,
				})

	if selected_index == -1 and _tree_task_for_player() != "":
		candidates.append({
			"id": "player_tree_chop",
			"label": "砍树",
			"priority": 60,
		})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) < int(b.get("priority", 0)))
	_sync_interaction_focus(candidates)
	return candidates


func _focused_interaction_candidate() -> Dictionary:
	var candidates := _interaction_candidates()
	if candidates.is_empty():
		return {}
	return candidates[clampi(interaction_focus_index, 0, candidates.size() - 1)]


func _cycle_interaction_focus(direction: int) -> bool:
	var candidates := _interaction_candidates()
	if candidates.size() <= 1:
		return false
	interaction_focus_index = posmod(interaction_focus_index + direction, candidates.size())
	_show_interaction_prompt(candidates)
	return true


func _execute_focused_interaction() -> bool:
	var candidate := _focused_interaction_candidate()
	if candidate.is_empty():
		return false

	match str(candidate.get("id", "")):
		"recruit_homeless":
			var npc_manager := _npc_manager()
			return npc_manager != null and npc_manager.has_method("interact_with_nearest_homeless") and npc_manager.interact_with_nearest_homeless()
		"repair_building":
			return _try_repair_damaged_building(int(candidate.get("entity_index", -1)))
		"building_info":
			return _try_toggle_building_info_panel()
		"build_quarry":
			return _try_build_quarry_at_player()
		"build_lumberyard":
			return _try_build_lumberyard_at_player_mother_tree()
		"build_farm":
			return _try_build_farm_at_player_bridge()
		"build_selected":
			_try_build()
			return true
		"player_tree_chop":
			return _try_start_player_tree_chop()
	return false


func _sync_interaction_focus(candidates: Array) -> void:
	var signature := _interaction_signature(candidates)
	if signature != interaction_focus_signature:
		interaction_focus_signature = signature
		interaction_focus_index = 0
	if candidates.is_empty():
		interaction_focus_index = 0
	elif interaction_focus_index >= candidates.size():
		interaction_focus_index = candidates.size() - 1


func _interaction_signature(candidates: Array) -> String:
	var parts := []
	for candidate in candidates:
		if not (candidate is Dictionary):
			continue
		parts.append("%s:%s" % [str(candidate.get("id", "")), str(candidate.get("entity_index", ""))])
	return "|".join(parts)


func _show_interaction_prompt_if_any() -> bool:
	var candidates := _interaction_candidates()
	if candidates.is_empty():
		return false
	if candidates.size() == 1 and str((candidates[0] as Dictionary).get("id", "")) == "build_selected":
		return false
	_show_interaction_prompt(candidates)
	return true


func _show_interaction_prompt(candidates: Array) -> void:
	if status_label == null or candidates.is_empty():
		return
	var candidate: Dictionary = candidates[clampi(interaction_focus_index, 0, candidates.size() - 1)]
	var label := str(candidate.get("label", "交互"))
	if candidates.size() == 1:
		status_label.text = "E %s" % label
	else:
		status_label.text = "E %s / Tab/滚轮切换 %d/%d" % [label, interaction_focus_index + 1, candidates.size()]


func _interaction_label_from_prompt(prompt: String) -> String:
	var label := prompt.strip_edges()
	if label.begins_with("E "):
		label = label.substr(2).strip_edges()
	return label


func _prompt_is_e_interaction(prompt: String) -> bool:
	return prompt.strip_edges().begins_with("E ")


func _is_interaction_cycle_mouse_button(button_index: int) -> bool:
	return button_index == MOUSE_BUTTON_WHEEL_UP or button_index == MOUSE_BUTTON_WHEEL_DOWN


func _mark_input_handled() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _resource_build_preview_for_player() -> Dictionary:
	if player == null:
		return {}

	var stone_index := _stone_entity_index_containing_point(player.global_position)
	if stone_index != -1:
		return {
			"definition": game_data.quarry_definition(),
			"position": _resource_build_position(stone_index),
			"valid": _can_preview_quarry_at_stone(stone_index),
			"prompt": _quarry_prompt_for_player(),
		}

	if selected_index != -1:
		return {}

	var mother_tree_index := _mother_tree_entity_index_containing_point(player.global_position)
	if mother_tree_index != -1:
		return {
			"definition": game_data.lumberyard_definition(),
			"position": _resource_build_position(mother_tree_index),
			"valid": _can_preview_lumberyard_at_mother_tree(mother_tree_index),
			"prompt": _mother_tree_lumberyard_prompt_for_player(),
		}

	var bridge_index := _bridge_entity_index_containing_point(player.global_position)
	if bridge_index != -1:
		return {
			"definition": game_data.farm_definition(),
			"position": _resource_build_position(bridge_index),
			"valid": _can_preview_farm_at_bridge(bridge_index),
			"prompt": _bridge_farm_prompt_for_player(),
		}

	return {}


func _resource_build_position(entity_index: int) -> Vector2:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return Vector2.ZERO

	var entity: Dictionary = placed_buildings[entity_index]
	var node = entity.get("node", null)
	if node is Node2D and is_instance_valid(node):
		return (node as Node2D).global_position

	var footprint: Rect2 = entity.get("footprint", Rect2())
	return Vector2(
		footprint.position.x + footprint.size.x * 0.5,
		footprint.position.y + footprint.size.y
	)


func _can_preview_quarry_at_stone(stone_index: int) -> bool:
	if stone_index == -1:
		return false

	var stone_entity: Dictionary = placed_buildings[stone_index]
	if bool(stone_entity.get("has_quarry", false)):
		return false

	var cost := int(game_data.quarry_value("cost", 0))
	return building_level_for_id("cityhall") >= 2 and gold >= cost


func _can_preview_lumberyard_at_mother_tree(mother_tree_index: int) -> bool:
	if mother_tree_index == -1:
		return false

	var mother_tree_entity: Dictionary = placed_buildings[mother_tree_index]
	var cost := int(game_data.lumberyard_value("cost", 0))
	return not bool(mother_tree_entity.get("has_lumberyard", false)) and gold >= cost


func _can_preview_farm_at_bridge(bridge_index: int) -> bool:
	if bridge_index == -1:
		return false

	var bridge_entity: Dictionary = placed_buildings[bridge_index]
	var cost := int(game_data.farm_definition().get("cost", game_data.economy_value("bridge_farm_cost", 0)))
	return not bool(bridge_entity.get("farm_built", false)) and gold >= cost


func _try_build() -> void:
	if selected_index == -1:
		return

	_update_preview()
	if not preview_valid or buildings_container == null:
		return

	var definition: Dictionary = buildings[selected_index]
	if not can_build_definition(definition) or not spend_gold_for_building(definition):
		_update_preview()
		return

	var building := visual_factory.create_building_visual(definition)
	building.name = "%s_%d" % [definition.id, placed_footprints.size()]
	building.position = buildings_container.to_local(preview.global_position)
	_apply_building_orientation(building, str(definition.get("id", "")), preview.global_position)
	buildings_container.add_child(building)

	_track_placed_entity(
		building,
		rules.footprint_for_position(preview.global_position, _building_footprint_size(definition)),
		true,
		definition.display_name,
		"building",
		bool(definition.get("is_workplace", true)),
		definition.id
	)
	_refresh_ui()
	_update_preview()


func _handle_info_panel_input(keycode: Key) -> bool:
	if info_panel == null:
		return false

	if keycode == KEY_E:
		upgrade_building(info_panel_entity_index)
		return true

	if keycode == KEY_Q:
		_clear_info_panel()
		return true

	var tool_slot := -1
	match keycode:
		KEY_1:
			tool_slot = 0
		KEY_2:
			tool_slot = 1
		KEY_3:
			tool_slot = 2
		KEY_4:
			tool_slot = 3
		KEY_5:
			tool_slot = 4

	if tool_slot == -1:
		return false

	var craft_tools := _blacksmith_craft_tool_ids_for_entity(info_panel_entity_index)
	if tool_slot >= craft_tools.size():
		return true

	var tool_id: String = craft_tools[tool_slot]
	start_blacksmith_craft(info_panel_entity_index, tool_id)
	return true


func _try_toggle_building_info_panel() -> bool:
	if player == null:
		return false

	var entity_index := _building_info_entity_index_containing_point(player.global_position)
	if entity_index == -1:
		return false

	if _try_repair_damaged_building(entity_index):
		return true

	if info_panel != null and info_panel_entity_index == entity_index:
		_clear_info_panel()
	else:
		_show_building_info_panel(entity_index)
	return true


func _try_repair_damaged_building_at_player() -> bool:
	if player == null:
		return false

	var entity_index := _building_info_entity_index_containing_point(player.global_position)
	if entity_index == -1:
		return false

	return _try_repair_damaged_building(entity_index)


func _try_repair_damaged_building(entity_index: int) -> bool:
	if not _is_repairable_damage(entity_index):
		return false

	var repaired := repair_building(entity_index)
	if not repaired and status_label != null:
		status_label.text = "金币不足，无法修复"
	return true


func _try_build_quarry_at_player() -> bool:
	if player == null:
		return false

	var stone_index := _stone_entity_index_containing_point(player.global_position)
	if stone_index == -1:
		return false

	var definition := game_data.quarry_definition()
	var cost := int(definition.get("cost", 0))
	if building_level_for_id("cityhall") < 2:
		if status_label != null:
			status_label.text = "市政厅2级后可在石头处建采石场"
		return true
	if gold < cost:
		if status_label != null:
			status_label.text = "金币不足，采石场需要%d金" % cost
		return true

	_build_quarry_on_stone(stone_index, definition)
	return true


func _build_quarry_on_stone(stone_index: int, definition: Dictionary) -> void:
	if stone_index < 0 or stone_index >= placed_buildings.size() or buildings_container == null:
		return

	var stone_entity: Dictionary = placed_buildings[stone_index]
	var stone_node: Node2D = stone_entity.node
	if not is_instance_valid(stone_node):
		return

	var build_position := stone_node.global_position
	gold -= int(definition.get("cost", 0))

	var quarry := visual_factory.create_building_visual(definition)
	quarry.name = "quarry_%d" % placed_footprints.size()
	quarry.position = buildings_container.to_local(build_position)
	buildings_container.add_child(quarry)
	_track_placed_entity(
		quarry,
		rules.footprint_for_position(build_position, _building_footprint_size(definition)),
		true,
		definition.get("display_name", "采石场"),
		"building",
		bool(definition.get("requires_worker", true)),
		"quarry"
	)
	_set_stone_quarry_state(stone_index, quarry.name, true)
	_refresh_gold_ui()
	_refresh_ui()
	_update_preview()


func _stone_entity_index_containing_point(point: Vector2) -> int:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("resource_kind", "") != "stone":
			continue
		if bool(entity.get("has_quarry", false)):
			continue

		var footprint: Rect2 = entity.footprint
		if _rect_contains_point_inclusive(footprint, point):
			return i

	return -1


func _quarry_prompt_for_player() -> String:
	if player == null:
		return ""
	if _stone_entity_index_containing_point(player.global_position) == -1:
		return ""

	var cost := int(game_data.quarry_value("cost", 0))
	if building_level_for_id("cityhall") < 2:
		return "市政厅2级后可在石头处建采石场"
	if gold < cost:
		return "金币不足，采石场需要%d金" % cost

	return "E 建造采石场 %d金" % cost


func _bridge_entity_index_containing_point(point: Vector2) -> int:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("entity_kind", "") != "bridge":
			continue
		if bool(entity.get("farm_built", false)):
			continue

		var footprint: Rect2 = entity.footprint
		if _rect_contains_point_inclusive(footprint, point):
			return i

	return -1


func _bridge_farm_prompt_for_player() -> String:
	if player == null:
		return ""

	var bridge_index := _bridge_entity_index_containing_point(player.global_position)
	if bridge_index == -1:
		return ""

	var bridge_entity: Dictionary = placed_buildings[bridge_index]
	if bool(bridge_entity.get("farm_built", false)):
		return "桥上已有农田"

	var cost := int(game_data.economy_value("bridge_farm_cost", 0))
	if gold < cost:
		return "金币不足，农田需要%d金" % cost

	return "E 建造农田 %d金" % cost


func _try_build_farm_at_player_bridge() -> bool:
	if player == null:
		return false

	var bridge_index := _bridge_entity_index_containing_point(player.global_position)
	if bridge_index == -1:
		return false

	var bridge_entity: Dictionary = placed_buildings[bridge_index]
	if bool(bridge_entity.get("farm_built", false)):
		if status_label != null:
			status_label.text = "桥上已有农田"
		return true

	var definition := game_data.farm_definition()
	var cost := int(definition.get("cost", game_data.economy_value("bridge_farm_cost", 0)))
	if gold < cost:
		if status_label != null:
			status_label.text = "金币不足，农田需要%d金" % cost
		return true
	if buildings_container == null:
		return true

	var bridge_node: Node2D = bridge_entity.node
	var build_position := Vector2(
		bridge_entity.footprint.position.x + bridge_entity.footprint.size.x * 0.5,
		bridge_entity.footprint.position.y + bridge_entity.footprint.size.y
	)
	if is_instance_valid(bridge_node):
		build_position = bridge_node.global_position

	gold -= cost
	var farm := visual_factory.create_building_visual(definition)
	farm.name = "farm_%d" % placed_footprints.size()
	farm.position = buildings_container.to_local(build_position)
	buildings_container.add_child(farm)

	_track_placed_entity(
		farm,
		rules.footprint_for_position(build_position, _building_footprint_size(definition)),
		true,
		definition.get("display_name", "农田"),
		"building",
		true,
		"farm"
	)
	bridge_entity.farm_built = true
	bridge_entity.farm_node_name = farm.name
	placed_buildings[bridge_index] = bridge_entity
	_refresh_gold_ui()
	_refresh_ui()
	_update_preview()
	return true


func _mother_tree_entity_index_containing_point(point: Vector2) -> int:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("entity_kind", "") != "mother_tree":
			continue
		if bool(entity.get("has_lumberyard", false)):
			continue

		var footprint: Rect2 = entity.footprint
		if _rect_contains_point_inclusive(footprint, point):
			return i

	return -1


func _mother_tree_lumberyard_prompt_for_player() -> String:
	if player == null:
		return ""

	var mother_tree_index := _mother_tree_entity_index_containing_point(player.global_position)
	if mother_tree_index == -1:
		return ""

	var mother_tree_entity: Dictionary = placed_buildings[mother_tree_index]
	if bool(mother_tree_entity.get("has_lumberyard", false)):
		return "母树已有伐木场"

	var cost := int(game_data.lumberyard_value("cost", 0))
	if gold < cost:
		return "金币不足，伐木场需要%d金" % cost

	return "E 建造伐木场 %d金" % cost


func _try_build_lumberyard_at_player_mother_tree() -> bool:
	if player == null:
		return false

	var mother_tree_index := _mother_tree_entity_index_containing_point(player.global_position)
	if mother_tree_index == -1:
		return false

	var mother_tree_entity: Dictionary = placed_buildings[mother_tree_index]
	if bool(mother_tree_entity.get("has_lumberyard", false)):
		if status_label != null:
			status_label.text = "母树已有伐木场"
		return true

	var definition := game_data.lumberyard_definition()
	var cost := int(definition.get("cost", 0))
	if gold < cost:
		if status_label != null:
			status_label.text = "金币不足，伐木场需要%d金" % cost
		return true
	if buildings_container == null:
		return true

	var mother_tree_node: Node2D = mother_tree_entity.node
	var build_position := Vector2(
		mother_tree_entity.footprint.position.x + mother_tree_entity.footprint.size.x * 0.5,
		mother_tree_entity.footprint.position.y + mother_tree_entity.footprint.size.y
	)
	if is_instance_valid(mother_tree_node):
		build_position = mother_tree_node.global_position

	gold -= cost
	var lumberyard := visual_factory.create_building_visual(definition)
	lumberyard.name = "lumberyard_%d" % placed_footprints.size()
	lumberyard.position = buildings_container.to_local(build_position)
	buildings_container.add_child(lumberyard)
	_track_placed_entity(
		lumberyard,
		rules.footprint_for_position(build_position, _building_footprint_size(definition)),
		true,
		definition.get("display_name", "伐木场"),
		"building",
		true,
		"lumberyard"
	)

	var lumberyard_index := placed_buildings.size() - 1
	var lumberyard_entity: Dictionary = placed_buildings[lumberyard_index]
	lumberyard_entity.source_mother_tree_name = mother_tree_node.name if is_instance_valid(mother_tree_node) else ""
	placed_buildings[lumberyard_index] = lumberyard_entity

	mother_tree_entity.has_lumberyard = true
	mother_tree_entity.lumberyard_node_name = lumberyard.name
	placed_buildings[mother_tree_index] = mother_tree_entity
	_refresh_gold_ui()
	_refresh_ui()
	_update_preview()
	return true


func _damaged_building_index_at_player() -> int:
	if player == null:
		return -1

	var entity_index := _building_info_entity_index_containing_point(player.global_position)
	if entity_index == -1 or not _is_repairable_damage(entity_index):
		return -1

	return entity_index


func _repair_prompt_for_entity(entity_index: int) -> String:
	var cost := repair_cost_for_entity_index(entity_index)
	if gold >= cost:
		return "E 修复 %d金" % cost

	return "金币不足，修复需要 %d金" % cost


func _building_info_entity_index_containing_point(point: Vector2) -> int:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		var kind: String = entity.get("entity_kind", "")
		if kind != "building" and kind != "cityhall":
			continue

		var footprint: Rect2 = entity.footprint
		if _rect_contains_point_inclusive(footprint, point):
			return i

	return -1


func _player_inside_info_panel_entity() -> bool:
	if player == null or info_panel_entity_index < 0 or info_panel_entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[info_panel_entity_index]
	var footprint: Rect2 = entity.footprint
	return _rect_contains_point_inclusive(footprint, player.global_position)


func _building_info_panel_position(node: Node2D) -> Vector2:
	var world_position := node.global_position + Vector2(80, -300)
	if is_inside_tree():
		return get_viewport().get_canvas_transform() * world_position

	return world_position


func _show_building_info_panel(entity_index: int) -> void:
	_clear_info_panel()
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("damaged", false):
		return

	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return

	info_panel_entity_index = entity_index
	info_panel_canvas = CanvasLayer.new()
	info_panel_canvas.name = "BuildingInfoCanvas"
	info_panel_canvas.layer = 20
	add_child(info_panel_canvas)

	info_panel = Control.new()
	info_panel.name = "BuildingInfoPanel"
	info_panel.z_index = 30
	info_panel.position = _building_info_panel_position(node)
	info_panel.size = INFO_PANEL_SIZE
	info_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	info_panel_canvas.add_child(info_panel)

	var background := ColorRect.new()
	background.name = "PanelBackground"
	background.color = Color(0.04, 0.05, 0.06, 0.88)
	background.size = INFO_PANEL_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(background)

	var border := Line2D.new()
	border.name = "PanelBorder"
	border.default_color = Color(0.95, 0.22, 0.2, 1)
	border.width = 5.0
	border.closed = true
	border.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(INFO_PANEL_SIZE.x, 0),
		Vector2(INFO_PANEL_SIZE.x, INFO_PANEL_SIZE.y),
		Vector2(0, INFO_PANEL_SIZE.y),
	])
	info_panel.add_child(border)

	var icon := Polygon2D.new()
	icon.name = "BuildingIcon"
	icon.color = _building_icon_color(entity.get("building_id", ""))
	icon.polygon = PackedVector2Array([
		Vector2(20, 22),
		Vector2(70, 22),
		Vector2(70, 72),
		Vector2(20, 72),
	])
	info_panel.add_child(icon)

	var lines := _building_info_lines(entity_index)
	for i in range(lines.size()):
		_add_panel_label(lines[i], Vector2(88 if i == 0 else 20, 20 + i * 26), 18 if i == 0 else 14)
	if entity.get("building_id", "") == "blacksmith":
		_add_blacksmith_panel_controls(entity_index, 174.0)
	_add_special_panel_controls(entity_index)
	if _has_next_upgrade(entity_index):
		_add_panel_button(
			"UpgradeBuildingButton",
			_upgrade_button_text(entity_index),
			Vector2(INFO_PANEL_SIZE.x - 146.0, 46.0),
			Callable(self, "upgrade_building").bind(entity_index),
			Vector2(126, 30),
			10
		)
	if _is_repairable_damage(entity_index):
		_add_panel_button(
			"RepairBuildingButton",
			"修复 %d金" % repair_cost_for_entity_index(entity_index),
			Vector2(20, INFO_PANEL_SIZE.y - 48.0),
			Callable(self, "repair_building").bind(entity_index),
			Vector2(120, 30),
			10
		)


func _clear_info_panel() -> void:
	if info_panel_canvas != null:
		info_panel_canvas.queue_free()
	elif info_panel != null:
		info_panel.queue_free()
	info_panel_canvas = null
	info_panel = null
	info_panel_entity_index = -1


func _refresh_info_panel() -> void:
	if info_panel_entity_index != -1:
		_show_building_info_panel(info_panel_entity_index)


func _building_info_lines(entity_index: int) -> Array:
	var entity: Dictionary = placed_buildings[entity_index]
	var building_id: String = entity.get("building_id", "")
	var worker_id: String = entity.get("worker_id", "")
	var worker_text := worker_id if worker_id != "" else "无"
	var level := int(entity.get("level", 1))
	var lines := [
		"名字: %s" % entity.get("display_name", "建筑"),
		"等级: %d" % level,
		"人员: %s" % worker_text,
		"功能: %s" % _building_function_text(building_id),
		"数值: %s" % _building_value_text(entity_index),
	]
	if _has_next_upgrade(entity_index):
		lines.append("升级: %s" % _upgrade_status_text(entity_index))

	if building_id == "blacksmith":
		lines.append("制造栏: 按按钮加入队列")
		lines.append("队列: %s" % _blacksmith_queue_text(entity_index))
		lines.append("库存: %s" % _blacksmith_stock_text(entity_index))

	return lines


func _add_panel_label(text: String, position: Vector2, font_size: int, label_size := Vector2(330, 24), label_name := "") -> Label:
	if info_panel == null:
		return null

	var label := Label.new()
	if label_name != "":
		label.name = label_name
	label.text = text
	label.position = position
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.96, 1))
	info_panel.add_child(label)
	return label


func _add_blacksmith_panel_controls(entity_index: int, start_y: float) -> void:
	var craft_y := start_y + 60.0
	var craft_tools := _blacksmith_craft_tool_ids_for_entity(entity_index)
	var button_names := [
		"CraftSwordButton",
		"CraftAxeButton",
		"CraftSickleButton",
		"CraftBowButton",
		"CraftStoneArrowheadButton",
	]
	var button_positions := [
		Vector2(20, craft_y),
		Vector2(154, craft_y),
		Vector2(288, craft_y),
		Vector2(20, craft_y + 34.0),
		Vector2(154, craft_y + 34.0),
	]
	for i in range(craft_tools.size()):
		var tool_id: String = craft_tools[i]
		_add_panel_button(
			button_names[i] if i < button_names.size() else "CraftTool%dButton" % i,
			game_data.tool_craft_text(tool_id),
			button_positions[i] if i < button_positions.size() else Vector2(20 + i * 134, craft_y),
			Callable(self, "start_blacksmith_craft").bind(entity_index, tool_id),
			Vector2(122, 30 if i < 3 else 26),
			10
		)

	var queue_y := start_y + 128.0
	var row_gap := 28.0
	var queue_label_x := 20.0
	var queue_button_x := 142.0
	var stock_label_x := 230.0
	var stock_button_x := 334.0
	var queue: Array = _craft_queue_for_entity(entity_index)
	for i in range(queue.size()):
		var item: Dictionary = queue[i]
		var progress := int(float(item.get("progress", 0.0)) / TOOL_CRAFT_SECONDS * 100.0)
		_add_panel_label(
			"队列%d: %s %d%%" % [i + 1, _tool_display_name(item.get("tool_id", "")), progress],
			Vector2(queue_label_x, queue_y + i * row_gap),
			13,
			Vector2(118, 24),
			"QueueItem%dLabel" % i
		)
		_add_panel_button(
			"CancelCraft%dButton" % i,
			"取消",
			Vector2(queue_button_x, queue_y - 4.0 + i * row_gap),
			Callable(self, "cancel_blacksmith_craft").bind(entity_index, i),
			Vector2(76, 24)
		)

	var source_name := _building_node_name_for_entity(entity_index)
	var stock := _tool_items_for_building(source_name)
	for i in range(stock.size()):
		var item: Dictionary = stock[i]
		_add_panel_label(
			"库存%d: %s" % [i + 1, _tool_display_name(item.get("tool_id", ""))],
			Vector2(stock_label_x, queue_y + i * row_gap),
			13,
			Vector2(100, 24)
		)
		_add_panel_button(
			"DestroyTool%dButton" % i,
			"销毁",
			Vector2(stock_button_x, queue_y - 4.0 + i * row_gap),
			Callable(self, "destroy_stored_tool").bind(source_name, i),
			Vector2(76, 24)
		)


func _add_special_panel_controls(entity_index: int) -> void:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return

	var entity: Dictionary = placed_buildings[entity_index]
	var building_id := str(entity.get("building_id", ""))
	var y := INFO_PANEL_SIZE.y - 92.0
	match building_id:
		"cityhall":
			if can_use_diplomacy():
				_add_panel_button(
					"SignRiverTradeButton",
					"通商河湾",
					Vector2(20, y),
					Callable(self, "sign_trade_treaty").bind("river"),
					Vector2(112, 30),
					10
				)
		"post_station":
			var travel_x := 20.0
			for terrain in game_data.post_station_panel_travel_destinations():
				var terrain_id := str(terrain)
				_add_panel_button(
					"Travel%sButton" % _terrain_button_suffix(terrain_id),
					"游历%s" % _terrain_display_name(terrain_id),
					Vector2(travel_x, y),
					Callable(self, "travel_to_terrain").bind(terrain_id),
					Vector2(112, 30),
					10
				)
				travel_x += 124.0
			_add_panel_button(
				"BuyHorseButton",
				"买马 %d金" % horse_price(),
				Vector2(20, y + 38.0),
				Callable(self, "buy_horse"),
				Vector2(112, 30),
				10
			)
		"barracks":
			_add_panel_button(
				"ExpeditionRiverButton",
				"远征河湾",
				Vector2(20, y),
				Callable(self, "launch_expedition").bind("river"),
				Vector2(112, 30),
				10
			)
			_add_panel_button(
				"ExpeditionNorthernButton",
				"远征北境",
				Vector2(144, y),
				Callable(self, "launch_expedition").bind("northern"),
				Vector2(112, 30),
				10
			)
			_add_panel_button(
				"ExpeditionMountainButton",
				"远征山岭",
				Vector2(268, y),
				Callable(self, "launch_expedition").bind("mountain"),
				Vector2(112, 30),
				10
			)
		"shield_barracks":
			_add_panel_button(
				"TrainShieldGuardButton",
				"训练盾卫 %d金" % int(game_data.training_value("shield_guard_cost", 25)),
				Vector2(20, y),
				Callable(self, "train_nearest_shield_guard"),
				Vector2(132, 30),
				10
			)


func _add_panel_button(
	button_name: String,
	text: String,
	position: Vector2,
	callback: Callable,
	size := Vector2(122, 30),
	button_z_index := 1
) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.position = position
	button.size = size
	button.z_index = button_z_index
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	info_panel.add_child(button)
	return button


func _building_function_text(building_id: String) -> String:
	match building_id:
		"blacksmith":
			return "制造工具"
		"farm":
			return "农民生产金币"
		"lumberyard":
			return "生成树并派伐木工"
		"quarry":
			return "矿工生产金币"
		"tavern":
			return "容纳村民工作"
		"wall":
			return "阻挡怪物"
		"cityhall":
			return "村民聚集地"
		"post_station":
			return "购买马匹并进行游历"
		"barracks":
			return "解锁盾卫营"
		_:
			var definition := building_definition_for_id(building_id)
			if definition.is_empty():
				return "工作建筑"
			if definition.get("unlocks_equipment_tier", "") == "iron":
				return "生产金币并解锁铁质装备"
			if definition.has("horse_offer_seconds"):
				return "提供马匹购买机会"
			if definition.has("trained_role"):
				return "训练%s" % definition.get("trained_role", "")
			if definition.has("defense_score"):
				return "地形防御岗位"
			if definition.has("income_gold"):
				return "人员工作生产金币"
			return "地形专属建筑"


func _building_value_text(entity_index: int) -> String:
	var entity: Dictionary = placed_buildings[entity_index]
	match entity.get("building_id", ""):
		"blacksmith":
			var node: Node2D = entity.node
			var source_name := ""
			if is_instance_valid(node):
				source_name = node.name
			return "库存 %d/%d" % [tool_count_for_building(source_name), BLACKSMITH_TOOL_LIMIT]
		"farm":
			return "60秒产1金；镰刀30秒"
		"lumberyard":
			if int(entity.get("level", 1)) >= 2:
				return "2级伐木场；120秒长3树"
			return "120秒长3树；木斧砍树提速"
		"quarry":
			return "矿工在岗；%d秒产%d金" % [
				int(game_data.quarry_value("income_seconds", 60.0)),
				int(game_data.quarry_value("income_gold", 3)),
			]
		"wall":
			return "血量 %d/%d" % [
				wall_health_for_entity_index(entity_index),
				wall_max_health_for_entity_index(entity_index),
			]
		"post_station":
			return "买马%d金；拥有马匹可游历" % horse_price()
		"barracks":
			return "盾卫营前置建筑"
		_:
			var definition := building_definition_for_id(str(entity.get("building_id", "")))
			if not definition.is_empty():
				var parts: Array = []
				if definition.has("income_gold"):
					parts.append("%d秒产%d金" % [
						int(definition.get("income_seconds", 60.0)),
						int(definition.get("income_gold", 0)),
					])
				if definition.has("trade_bonus_gold"):
					parts.append("通商额外+%d金" % int(definition.get("trade_bonus_gold", 0)))
				if definition.has("max_count_per_city"):
					parts.append("每城上限%d座" % int(definition.get("max_count_per_city", 0)))
				if definition.has("defense_score"):
					parts.append("防御评分%d" % int(definition.get("defense_score", 0)))
				if definition.has("horse_offer_seconds"):
					parts.append("%d秒刷新马匹机会" % int(definition.get("horse_offer_seconds", 0)))
				if not parts.is_empty():
					return "；".join(parts)
			return "岗位 1 人"


func _blacksmith_queue_text(entity_index: int) -> String:
	var queue := _craft_queue_for_entity(entity_index)
	if queue.is_empty():
		return "空"

	var parts: Array = []
	for item in queue:
		var tool_id: String = item.get("tool_id", "")
		var progress := int(float(item.get("progress", 0.0)) / TOOL_CRAFT_SECONDS * 100.0)
		parts.append("%s %d%%" % [_tool_display_name(tool_id), progress])

	return " / ".join(parts)


func _blacksmith_stock_text(entity_index: int) -> String:
	var source_name := _building_node_name_for_entity(entity_index)
	var stock := _tool_items_for_building(source_name)
	if stock.is_empty():
		return "0/%d" % BLACKSMITH_TOOL_LIMIT

	var counts := {}
	for tool_id in game_data.tool_ids():
		counts[tool_id] = 0
	for item in stock:
		var tool_id: String = item.get("tool_id", "")
		if counts.has(tool_id):
			counts[tool_id] += 1

	var parts: Array = []
	for tool_id in game_data.tool_ids():
		var count := int(counts.get(tool_id, 0))
		if count > 0:
			parts.append("%s%d" % [_tool_display_name(tool_id), count])

	if parts.is_empty():
		return "%d/%d" % [stock.size(), BLACKSMITH_TOOL_LIMIT]

	return "%d/%d %s" % [stock.size(), BLACKSMITH_TOOL_LIMIT, " ".join(parts)]


func _craft_queue_for_entity(entity_index: int) -> Array:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return []

	var entity: Dictionary = placed_buildings[entity_index]
	return (entity.get("craft_queue", []) as Array).duplicate(true)


func _building_node_name_for_entity(entity_index: int) -> String:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return ""

	var entity: Dictionary = placed_buildings[entity_index]
	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return ""

	return node.name


func _tool_items_for_building(building_name: String) -> Array:
	_cleanup_tool_items()
	var items: Array = []
	for item in tool_items:
		if item.get("source_building_id", "") == building_name:
			items.append(item)
	return items


func _blacksmith_craft_status(entity_index: int) -> String:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return "状态: 无"

	var queue := _craft_queue_for_entity(entity_index)
	if queue.is_empty():
		return "状态: 空闲"

	var item: Dictionary = queue[0]
	return "状态: 制作%s %d%%" % [_tool_display_name(item.get("tool_id", "")), int(float(item.get("progress", 0.0)) / TOOL_CRAFT_SECONDS * 100.0)]


func _building_icon_color(building_id: String) -> Color:
	match building_id:
		"blacksmith":
			return Color(0.9, 0.32, 0.18, 1)
		"farm":
			return Color(0.55, 0.34, 0.16, 1)
		"lumberyard":
			return Color(0.22, 0.52, 0.24, 1)
		"quarry":
			return Color(0.5, 0.5, 0.54, 1)
		"cityhall":
			return Color(0.78, 0.78, 0.72, 1)
		_:
			var definition := building_definition_for_id(building_id)
			if not definition.is_empty():
				return definition.get("accent_color", definition.get("base_color", Color(0.48, 0.5, 0.5, 1)))
			return Color(0.48, 0.5, 0.5, 1)


func _blacksmith_can_craft_tool(entity: Dictionary, tool_id: String) -> bool:
	var blacksmith_level := int(entity.get("level", 1))
	if blacksmith_level < game_data.tool_required_blacksmith_level(tool_id):
		return false
	var craft_tools := game_data.blacksmith_craft_tool_ids(blacksmith_level)
	if not craft_tools.has(tool_id):
		return false

	var requirements := game_data.blacksmith_craft_requirements(blacksmith_level)
	for required_building_id in requirements.keys():
		var required_level := int(requirements[required_building_id])
		if building_level_for_id(str(required_building_id)) < required_level:
			return false

	if game_data.tool_tier(tool_id) == "iron" and not iron_mine_supply_available():
		return false

	return true


func _blacksmith_craft_tool_ids_for_entity(entity_index: int) -> Array:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return []

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "blacksmith":
		return []

	return game_data.blacksmith_craft_tool_ids(int(entity.get("level", 1)))


func start_blacksmith_craft(entity_index: int, tool_id: String) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false
	if not _is_valid_tool_id(tool_id):
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "blacksmith":
		return false
	if not _blacksmith_can_craft_tool(entity, tool_id):
		return false

	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return false
	var queue := _craft_queue_for_entity(entity_index)
	if tool_count_for_building(node.name) + queue.size() >= BLACKSMITH_TOOL_LIMIT:
		return false
	if gold < TOOL_CRAFT_COST:
		return false

	gold -= TOOL_CRAFT_COST
	queue.append({
		"tool_id": tool_id,
		"progress": 0.0,
	})
	entity.craft_queue = queue
	entity.crafting_tool = queue[0].get("tool_id", "")
	entity.craft_elapsed = float(queue[0].get("progress", 0.0))
	placed_buildings[entity_index] = entity
	_refresh_gold_ui()
	_refresh_info_panel()
	return true


func cancel_blacksmith_craft(entity_index: int, queue_index: int) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "blacksmith":
		return false

	var queue := _craft_queue_for_entity(entity_index)
	if queue_index < 0 or queue_index >= queue.size():
		return false

	queue.remove_at(queue_index)
	gold += TOOL_CRAFT_COST
	entity.craft_queue = queue
	if queue.is_empty():
		entity.crafting_tool = ""
		entity.craft_elapsed = 0.0
	else:
		entity.crafting_tool = queue[0].get("tool_id", "")
		entity.craft_elapsed = float(queue[0].get("progress", 0.0))
	placed_buildings[entity_index] = entity
	_refresh_gold_ui()
	_refresh_info_panel()
	return true


func _update_blacksmith_crafting(delta: float) -> void:
	var changed := false
	var needs_panel_rebuild := false
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("building_id", "") != "blacksmith":
			continue

		var queue := _craft_queue_for_entity(i)
		if queue.is_empty():
			continue

		var first: Dictionary = queue[0]
		first.progress = float(first.get("progress", 0.0)) + delta
		if first.progress >= TOOL_CRAFT_SECONDS:
			_spawn_tool_at_building(entity, first.get("tool_id", ""))
			queue.remove_at(0)
			needs_panel_rebuild = true
		else:
			queue[0] = first

		entity.craft_queue = queue
		if queue.is_empty():
			entity.crafting_tool = ""
			entity.craft_elapsed = 0.0
		else:
			entity.crafting_tool = queue[0].get("tool_id", "")
			entity.craft_elapsed = float(queue[0].get("progress", 0.0))
		placed_buildings[i] = entity
		changed = true

	if changed:
		if needs_panel_rebuild:
			_refresh_info_panel()
		else:
			_update_blacksmith_panel_progress_labels()


func _update_blacksmith_panel_progress_labels() -> void:
	if info_panel == null or info_panel_entity_index == -1:
		return

	var queue := _craft_queue_for_entity(info_panel_entity_index)
	for i in range(queue.size()):
		var label := info_panel.get_node_or_null("QueueItem%dLabel" % i) as Label
		if label == null:
			continue

		var item: Dictionary = queue[i]
		var progress := int(float(item.get("progress", 0.0)) / TOOL_CRAFT_SECONDS * 100.0)
		label.text = "闃熷垪%d: %s %d%%" % [i + 1, _tool_display_name(item.get("tool_id", "")), progress]


		label.text = "队列%d: %s %d%%" % [i + 1, _tool_display_name(item.get("tool_id", "")), progress]


func tool_count_for_building(building_name: String) -> int:
	_cleanup_tool_items()
	var count := 0
	for item in tool_items:
		if item.get("source_building_id", "") == building_name:
			count += 1
	return count


func try_take_tool_for_role(role: String) -> String:
	var wanted_tools := _tools_for_role(role)
	if wanted_tools.is_empty():
		return ""

	_cleanup_tool_items()
	for i in range(tool_items.size()):
		var item: Dictionary = tool_items[i]
		var tool_id: String = item.get("tool_id", "")
		if not wanted_tools.has(tool_id):
			continue
		if item.get("reserved_worker_id", "") != "":
			continue

		var node: Node2D = item.node
		if is_instance_valid(node):
			node.queue_free()
		tool_items.remove_at(i)
		_refresh_info_panel()
		return tool_id

	return ""


func reserve_tool_for_role(role: String, worker_id: String) -> Dictionary:
	var wanted_tools := _tools_for_role(role)
	if wanted_tools.is_empty() or worker_id == "":
		return {}

	_cleanup_tool_items()
	for wanted_tool in wanted_tools:
		for i in range(tool_items.size()):
			var item: Dictionary = tool_items[i]
			if item.get("tool_id", "") != wanted_tool:
				continue
			if item.get("reserved_worker_id", "") != "":
				continue

			var source_building_id: String = item.get("source_building_id", "")
			var source_position := _building_position_for_node_name(source_building_id)
			if source_position == Vector2.INF:
				continue

			item.reserved_worker_id = worker_id
			tool_items[i] = item
			var node: Node2D = item.node
			if is_instance_valid(node):
				node.modulate = Color(1, 1, 1, 0.55)
			_refresh_info_panel()
			return {
				"tool_id": wanted_tool,
				"blacksmith_id": source_building_id,
				"position": source_position,
			}

	return {}


func cancel_reserved_tool_for_worker(worker_id: String) -> bool:
	if worker_id == "":
		return false

	_cleanup_tool_items()
	for i in range(tool_items.size()):
		var item: Dictionary = tool_items[i]
		if item.get("reserved_worker_id", "") != worker_id:
			continue

		item.reserved_worker_id = ""
		tool_items[i] = item
		var node: Node2D = item.node
		if is_instance_valid(node):
			node.modulate = Color.WHITE
		_refresh_info_panel()
		return true

	return false


func claim_reserved_tool_for_worker(worker_id: String) -> String:
	if worker_id == "":
		return ""

	_cleanup_tool_items()
	for i in range(tool_items.size()):
		var item: Dictionary = tool_items[i]
		if item.get("reserved_worker_id", "") != worker_id:
			continue

		var tool_id: String = item.get("tool_id", "")
		var node: Node2D = item.node
		if is_instance_valid(node):
			node.queue_free()
		tool_items.remove_at(i)
		_refresh_info_panel()
		return tool_id

	return ""


func destroy_stored_tool(building_name: String, stock_index: int) -> bool:
	_cleanup_tool_items()
	if stock_index < 0:
		return false

	var seen := 0
	for i in range(tool_items.size()):
		var item: Dictionary = tool_items[i]
		if item.get("source_building_id", "") != building_name:
			continue
		if item.get("reserved_worker_id", "") != "":
			continue

		if seen != stock_index:
			seen += 1
			continue

		var node: Node2D = item.node
		if is_instance_valid(node):
			node.queue_free()
		tool_items.remove_at(i)
		_refresh_info_panel()
		return true

	return false


func _spawn_tool_at_building(entity: Dictionary, tool_id: String) -> Node2D:
	if buildings_container == null:
		return null

	var source_node: Node2D = entity.node
	if not is_instance_valid(source_node):
		return null

	tool_sequence += 1
	var tool := Node2D.new()
	tool.name = "Tool_%s_%02d" % [tool_id, tool_sequence]
	tool.set_meta("tool_id", tool_id)
	tool.set_meta("source_building_id", source_node.name)
	var slot := tool_count_for_building(source_node.name)
	var world_position := source_node.global_position + Vector2(-60 + slot * 28, -4)
	tool.position = buildings_container.to_local(world_position)
	var visual := _create_tool_visual(tool_id)
	tool.add_child(visual)
	buildings_container.add_child(tool)
	tool_items.append({
		"node": tool,
		"tool_id": tool_id,
		"source_building_id": source_node.name,
		"reserved_worker_id": "",
	})
	return tool


func _create_tool_visual(tool_id: String) -> Node2D:
	var texture := game_data.art_asset_texture("tools", tool_id)
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.name = "ToolVisual"
		sprite.texture = texture
		sprite.centered = false
		var target_size := Vector2(40, 40)
		var scale_factor = minf(
			target_size.x / maxf(1.0, float(texture.get_width())),
			target_size.y / maxf(1.0, float(texture.get_height()))
		)
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2(
			-float(texture.get_width()) * scale_factor * 0.5,
			-float(texture.get_height()) * scale_factor
		)
		return sprite

	var polygon := Polygon2D.new()
	polygon.name = "ToolVisual"
	polygon.color = _tool_color(tool_id)
	match tool_id:
		"sword", "stone_sword", "iron_sword":
			polygon.polygon = PackedVector2Array([
				Vector2(-4, -34),
				Vector2(4, -34),
				Vector2(4, -6),
				Vector2(-4, -6),
			])
		"axe":
			polygon.polygon = PackedVector2Array([
				Vector2(-4, -34),
				Vector2(4, -34),
				Vector2(4, -6),
				Vector2(-4, -6),
				Vector2(4, -30),
				Vector2(18, -24),
				Vector2(4, -18),
			])
		"stone_pickaxe", "iron_pickaxe":
			polygon.polygon = PackedVector2Array([
				Vector2(-4, -34),
				Vector2(4, -34),
				Vector2(4, -6),
				Vector2(-4, -6),
				Vector2(-18, -30),
				Vector2(18, -30),
				Vector2(12, -22),
				Vector2(-12, -22),
			])
		"sickle", "stone_sickle", "iron_sickle":
			polygon.polygon = PackedVector2Array([
				Vector2(-4, -28),
				Vector2(4, -28),
				Vector2(4, -6),
				Vector2(-4, -6),
				Vector2(4, -28),
				Vector2(20, -22),
				Vector2(14, -16),
			])
		"bow":
			polygon.polygon = PackedVector2Array([
				Vector2(-12, -32),
				Vector2(2, -28),
				Vector2(10, -18),
				Vector2(2, -8),
				Vector2(-12, -4),
				Vector2(-6, -18),
			])
		"stone_arrowhead", "iron_arrowhead":
			polygon.polygon = PackedVector2Array([
				Vector2(0, -34),
				Vector2(16, -10),
				Vector2(-16, -10),
			])
		_:
			polygon.polygon = PackedVector2Array([
				Vector2(-6, -24),
				Vector2(6, -24),
				Vector2(6, -8),
				Vector2(-6, -8),
			])
	return polygon


func _cleanup_tool_items() -> void:
	for i in range(tool_items.size() - 1, -1, -1):
		var item: Dictionary = tool_items[i]
		var node: Node2D = item.get("node")
		if not is_instance_valid(node):
			tool_items.remove_at(i)


func _building_position_for_node_name(node_name: String) -> Vector2:
	for entity in placed_buildings:
		var node: Node2D = entity.node
		if is_instance_valid(node) and node.name == node_name:
			return node.global_position

	return Vector2.INF


func _tool_for_role(role: String) -> String:
	var tools := _tools_for_role(role)
	if tools.is_empty():
		return ""
	return tools[0]


func _tools_for_role(role: String) -> Array:
	return game_data.tool_ids_for_role(role)


func _is_valid_tool_id(tool_id: String) -> bool:
	return game_data.is_valid_tool_id(tool_id)


func _tool_color(tool_id: String) -> Color:
	return game_data.tool_color(tool_id)


func _tool_display_name(tool_id: String) -> String:
	return game_data.tool_display_name(tool_id)


func _handle_demolition_input() -> void:
	if player == null:
		return

	if demolition_target_index != -1:
		if _player_inside_demolition_target():
			_demolish_target()
		else:
			_cancel_demolition()
		return

	var target_index := rules.demolishable_entity_index_containing_point(
		player.global_position,
		placed_buildings
	)
	if target_index == -1:
		if status_label != null:
			status_label.text = "没有可拆除建筑"
		return

	_start_demolition(target_index)


func _start_demolition(target_index: int) -> void:
	_clear_preview()
	selected_index = -1
	demolition_target_index = target_index

	var target: Node2D = placed_buildings[target_index].node
	demolition_original_modulate = target.modulate
	target.modulate = DEMOLITION_PREVIEW_COLOR

	_refresh_ui()
	_update_preview()


func _cancel_demolition() -> void:
	if demolition_target_index == -1:
		return

	var target: Node2D = placed_buildings[demolition_target_index].node
	if is_instance_valid(target):
		target.modulate = demolition_original_modulate

	demolition_target_index = -1
	demolition_original_modulate = Color.WHITE
	_update_preview()


func _demolish_target() -> void:
	if demolition_target_index == -1:
		return

	var entity: Dictionary = placed_buildings[demolition_target_index]
	if _is_resource_entity(entity):
		_start_tree_chop_task(demolition_target_index)
		demolition_target_index = -1
		demolition_original_modulate = Color.WHITE
		_update_preview()
		return

	var target: Node2D = entity.node
	if _work_site_has_any_worker(entity):
		if not _work_site_workers_inside(entity).is_empty():
			_release_worker_from_demolished_entity(entity)
		if _work_site_worker_ids(entity).size() > _work_site_workers_inside(entity).size():
			_cancel_worker_assignment_from_demolished_entity(entity)

	_clear_bridge_farm_for_entity(entity)
	_clear_mother_tree_lumberyard_for_entity(entity)
	_clear_stone_quarry_for_entity(entity)

	if is_instance_valid(target):
		target.queue_free()

	placed_buildings.remove_at(demolition_target_index)
	_remove_placed_footprint(entity.footprint)
	demolition_target_index = -1
	demolition_original_modulate = Color.WHITE
	_update_preview()


func _clear_bridge_farm_for_entity(entity: Dictionary) -> void:
	if entity.get("building_id", "") != "farm":
		return

	var farm_node_name := ""
	var farm_node: Node2D = entity.get("node", null)
	if is_instance_valid(farm_node):
		farm_node_name = farm_node.name

	for i in range(placed_buildings.size()):
		var bridge_entity: Dictionary = placed_buildings[i]
		if bridge_entity.get("entity_kind", "") != "bridge":
			continue
		if farm_node_name != "" and bridge_entity.get("farm_node_name", "") != farm_node_name:
			continue

		var bridge_footprint: Rect2 = bridge_entity.footprint
		var farm_footprint: Rect2 = entity.footprint
		if farm_node_name == "" and not rules.has_overlap(bridge_footprint, [farm_footprint]):
			continue

		bridge_entity.farm_built = false
		bridge_entity.farm_node_name = ""
		placed_buildings[i] = bridge_entity
		return


func _clear_mother_tree_lumberyard_for_entity(entity: Dictionary) -> void:
	if entity.get("building_id", "") != "lumberyard":
		return

	var lumberyard_node_name := ""
	var lumberyard_node: Node2D = entity.get("node", null)
	if is_instance_valid(lumberyard_node):
		lumberyard_node_name = lumberyard_node.name

	for i in range(placed_buildings.size()):
		var mother_tree_entity: Dictionary = placed_buildings[i]
		if mother_tree_entity.get("entity_kind", "") != "mother_tree":
			continue
		if lumberyard_node_name != "" and mother_tree_entity.get("lumberyard_node_name", "") != lumberyard_node_name:
			continue

		var mother_tree_footprint: Rect2 = mother_tree_entity.footprint
		var lumberyard_footprint: Rect2 = entity.footprint
		if lumberyard_node_name == "" and not rules.has_overlap(mother_tree_footprint, [lumberyard_footprint]):
			continue

		mother_tree_entity.has_lumberyard = false
		mother_tree_entity.lumberyard_node_name = ""
		placed_buildings[i] = mother_tree_entity
		return


func _clear_stone_quarry_for_entity(entity: Dictionary) -> void:
	if entity.get("building_id", "") != "quarry":
		return

	var quarry_node_name := ""
	var quarry_node: Node2D = entity.get("node", null)
	if is_instance_valid(quarry_node):
		quarry_node_name = quarry_node.name

	var quarry_footprint: Rect2 = entity.get("footprint", Rect2())
	for i in range(placed_buildings.size()):
		var stone_entity: Dictionary = placed_buildings[i]
		if stone_entity.get("resource_kind", "") != "stone":
			continue

		var matches_name: bool = quarry_node_name != "" and str(stone_entity.get("quarry_node_name", "")) == quarry_node_name
		var stone_footprint: Rect2 = stone_entity.get("footprint", Rect2())
		var matches_footprint: bool = rules.has_overlap(stone_footprint, [quarry_footprint])
		if not matches_name and not matches_footprint:
			continue

		_set_stone_quarry_state(i, "", false)
		return


func _set_stone_quarry_state(stone_index: int, quarry_node_name: String, occupied: bool) -> void:
	if stone_index < 0 or stone_index >= placed_buildings.size():
		return

	var stone_entity: Dictionary = placed_buildings[stone_index]
	if stone_entity.get("resource_kind", "") != "stone":
		return

	stone_entity.has_quarry = occupied
	stone_entity.quarry_node_name = quarry_node_name if occupied else ""
	stone_entity.demolishable = not occupied
	var stone_node: Node2D = stone_entity.get("node", null)
	if is_instance_valid(stone_node):
		stone_node.visible = not occupied
	placed_buildings[stone_index] = stone_entity


func _mark_stone_quarry_for_entity(entity: Dictionary) -> void:
	if entity.get("building_id", "") != "quarry":
		return

	var quarry_node: Node2D = entity.get("node", null)
	if not is_instance_valid(quarry_node):
		return

	var quarry_footprint: Rect2 = entity.get("footprint", Rect2())
	for i in range(placed_buildings.size()):
		var stone_entity: Dictionary = placed_buildings[i]
		if stone_entity.get("resource_kind", "") != "stone":
			continue

		var stone_footprint: Rect2 = stone_entity.get("footprint", Rect2())
		if not rules.has_overlap(stone_footprint, [quarry_footprint]):
			continue

		_set_stone_quarry_state(i, quarry_node.name, true)
		return


func _player_inside_demolition_target() -> bool:
	if demolition_target_index == -1 or player == null:
		return false

	var index := rules.demolishable_entity_index_containing_point(
		player.global_position,
		[placed_buildings[demolition_target_index]]
	)
	return index == 0


func _track_placed_entity(
	entity: Node2D,
	footprint: Rect2,
	demolishable: bool,
	display_name: String,
	entity_kind: String,
	is_workplace: bool,
	building_id := "",
	resource_kind := ""
) -> void:
	var resolved_building_id := _resolved_building_id(entity, display_name, entity_kind, building_id)
	var resolved_resource_kind := resource_kind
	if resolved_resource_kind == "" and (entity_kind == "tree" or entity_kind == "stone"):
		resolved_resource_kind = entity_kind
	placed_buildings.append({
		"node": entity,
		"footprint": footprint,
		"demolishable": demolishable,
		"display_name": display_name,
		"entity_kind": entity_kind,
		"building_id": resolved_building_id,
		"resource_kind": resolved_resource_kind,
		"level": 1,
		"damaged": false,
		"is_workplace": is_workplace,
		"worker_id": "",
		"worker_inside": false,
		"worker_ids": [],
		"workers_inside": [],
		"worker_income_elapsed": {},
		"farm_income_elapsed": 0.0,
		"quarry_income_elapsed": 0.0,
		"crafting_tool": "",
		"craft_elapsed": 0.0,
		"craft_queue": [],
		"lumberyard_tree_elapsed": 0.0,
		"has_quarry": false,
		"quarry_node_name": "",
		"wall_health": game_data.wall_health_for_level(1) if resolved_building_id == "wall" else 0,
	})
	placed_footprints.append(footprint)
	if is_workplace:
		visual_factory.set_occupied(entity, false)


func get_work_sites() -> Array:
	var sites: Array = []
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if not entity.get("is_workplace", false):
			continue
		if entity.get("damaged", false):
			continue

		var node: Node2D = entity.node
		if not is_instance_valid(node):
			continue

		sites.append({
			"entity_index": i,
			"display_name": _work_site_display_name(entity),
			"workplace_id": node.name,
			"position": node.global_position,
			"building_id": entity.get("building_id", ""),
			"worker_role": _work_site_worker_role(entity),
			"required_role": _required_role_for_work_site(entity),
			"is_workplace": true,
			"worker_id": entity.get("worker_id", ""),
			"worker_inside": entity.get("worker_inside", false),
			"worker_ids": _work_site_worker_ids(entity),
			"workers_inside": _work_site_workers_inside(entity),
			"worker_capacity": _work_site_capacity(entity),
			"worker_count": _work_site_worker_ids(entity).size(),
		})

	return sites


func claim_work_site(entity_index: int, worker_id: String) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if not entity.get("is_workplace", false):
		return false
	if entity.get("damaged", false):
		return false
	var worker_ids := _work_site_worker_ids(entity)
	if worker_ids.has(worker_id):
		return false
	if worker_ids.size() >= _work_site_capacity(entity):
		return false
	if not _worker_can_use_work_site(entity, worker_id):
		return false

	worker_ids.append(worker_id)
	_set_work_site_workers(entity, worker_ids, _work_site_workers_inside(entity))
	placed_buildings[entity_index] = entity
	return true


func occupy_work_site(workplace_id: String, worker_id: String) -> bool:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if not entity.get("is_workplace", false):
			continue

		var node: Node2D = entity.node
		if not is_instance_valid(node) or node.name != workplace_id:
			continue
		if entity.get("damaged", false):
			return false
		var worker_ids := _work_site_worker_ids(entity)
		var workers_inside := _work_site_workers_inside(entity)
		if not worker_ids.has(worker_id):
			return false
		if workers_inside.has(worker_id):
			return false
		if not _worker_can_use_work_site(entity, worker_id):
			return false

		workers_inside.append(worker_id)
		_set_work_site_workers(entity, worker_ids, workers_inside)
		placed_buildings[i] = entity
		visual_factory.set_occupied(node, true)
		return true

	return false


func worker_leaves_work_site(workplace_id: String, worker_id: String) -> bool:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if not entity.get("is_workplace", false):
			continue

		var node: Node2D = entity.node
		if not is_instance_valid(node) or node.name != workplace_id:
			continue
		var worker_ids := _work_site_worker_ids(entity)
		var workers_inside := _work_site_workers_inside(entity)
		if not worker_ids.has(worker_id):
			return false

		workers_inside.erase(worker_id)
		_set_work_site_workers(entity, worker_ids, workers_inside)
		placed_buildings[i] = entity
		visual_factory.set_occupied(node, not workers_inside.is_empty())
		return true

	return false


func release_work_site_for_worker(worker_id: String) -> bool:
	if worker_id == "":
		return false

	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if not entity.get("is_workplace", false):
			continue
		var worker_ids := _work_site_worker_ids(entity)
		if not worker_ids.has(worker_id):
			continue

		var node: Node2D = entity.node
		var workers_inside := _work_site_workers_inside(entity)
		worker_ids.erase(worker_id)
		workers_inside.erase(worker_id)
		var worker_income_elapsed: Dictionary = entity.get("worker_income_elapsed", {})
		worker_income_elapsed.erase(worker_id)
		entity.worker_income_elapsed = worker_income_elapsed
		_set_work_site_workers(entity, worker_ids, workers_inside)
		placed_buildings[i] = entity
		if is_instance_valid(node):
			visual_factory.set_occupied(node, not workers_inside.is_empty())
		return true

	return false


func _work_site_capacity(entity: Dictionary) -> int:
	var definition := building_definition_for_id(str(entity.get("building_id", "")))
	var capacity_by_level = definition.get("worker_capacity_by_level", null)
	if capacity_by_level is Dictionary:
		var level := int(entity.get("level", 1))
		return max(1, int((capacity_by_level as Dictionary).get(level, (capacity_by_level as Dictionary).get(str(level), (capacity_by_level as Dictionary).get(1, 1)))))
	if str(entity.get("building_id", "")) == "barracks":
		return game_data.barracks_capacity_for_level(int(entity.get("level", 1)))
	return max(1, int(definition.get("worker_capacity", 1)))


func _work_site_worker_ids(entity: Dictionary) -> Array:
	var worker_ids: Array = []
	if entity.has("worker_ids") and entity.get("worker_ids") is Array:
		for value in entity.get("worker_ids", []):
			var worker_id := str(value)
			if worker_id != "" and not worker_ids.has(worker_id):
				worker_ids.append(worker_id)
	var legacy_worker_id := str(entity.get("worker_id", ""))
	if legacy_worker_id != "" and not worker_ids.has(legacy_worker_id):
		worker_ids.append(legacy_worker_id)
	return worker_ids


func _work_site_workers_inside(entity: Dictionary) -> Array:
	var workers_inside: Array = []
	if entity.has("workers_inside") and entity.get("workers_inside") is Array:
		for value in entity.get("workers_inside", []):
			var worker_id := str(value)
			if worker_id != "" and not workers_inside.has(worker_id):
				workers_inside.append(worker_id)
	var legacy_worker_id := str(entity.get("worker_id", ""))
	if bool(entity.get("worker_inside", false)) and legacy_worker_id != "" and not workers_inside.has(legacy_worker_id):
		workers_inside.append(legacy_worker_id)
	return workers_inside


func _set_work_site_workers(entity: Dictionary, worker_ids: Array, workers_inside: Array) -> void:
	var capacity := _work_site_capacity(entity)
	var normalized_worker_ids: Array = []
	for value in worker_ids:
		var worker_id := str(value)
		if worker_id != "" and not normalized_worker_ids.has(worker_id):
			if normalized_worker_ids.size() >= capacity:
				continue
			normalized_worker_ids.append(worker_id)

	var normalized_workers_inside: Array = []
	for value in workers_inside:
		var worker_id := str(value)
		if worker_id != "" and normalized_worker_ids.has(worker_id) and not normalized_workers_inside.has(worker_id):
			if normalized_workers_inside.size() >= capacity:
				continue
			normalized_workers_inside.append(worker_id)

	var worker_income_elapsed: Dictionary = entity.get("worker_income_elapsed", {})
	for worker_id in worker_income_elapsed.keys():
		if not normalized_worker_ids.has(str(worker_id)):
			worker_income_elapsed.erase(worker_id)
	entity.worker_income_elapsed = worker_income_elapsed
	entity.worker_ids = normalized_worker_ids
	entity.workers_inside = normalized_workers_inside
	entity.worker_id = str(normalized_worker_ids[0]) if not normalized_worker_ids.is_empty() else ""
	entity.worker_inside = not normalized_workers_inside.is_empty()


func _work_site_has_any_worker(entity: Dictionary) -> bool:
	return not _work_site_worker_ids(entity).is_empty()


func _required_role_for_work_site(entity: Dictionary) -> String:
	var building_id := str(entity.get("building_id", ""))
	if building_id == "wall":
		return "archer"
	var definition := building_definition_for_id(building_id)
	if not definition.is_empty():
		var required_roles: Array = definition.get("required_roles", [])
		if not required_roles.is_empty():
			return ",".join(required_roles)
		return str(definition.get("required_role", ""))
	return ""


func _work_site_display_name(entity: Dictionary) -> String:
	if entity.get("building_id", "") == "lumberyard":
		return game_data.lumberyard_display_name(int(entity.get("level", 1)))
	return str(entity.get("display_name", ""))


func _work_site_worker_role(entity: Dictionary) -> String:
	if entity.get("building_id", "") == "lumberyard":
		return game_data.lumberyard_worker_role(int(entity.get("level", 1)))
	if entity.get("building_id", "") == "farm":
		return "farmer"
	if entity.get("building_id", "") == "quarry":
		return str(game_data.quarry_value("worker_role", "miner"))
	var definition := building_definition_for_id(str(entity.get("building_id", "")))
	if not definition.is_empty():
		return str(definition.get("work_role", ""))
	return ""


func work_site_role_for_workplace_id(workplace_id: String) -> String:
	if workplace_id == "":
		return ""

	for entity in placed_buildings:
		var node: Node2D = entity.node
		if is_instance_valid(node) and node.name == workplace_id:
			return _work_site_worker_role(entity)

	return ""


func _worker_can_use_work_site(entity: Dictionary, worker_id: String) -> bool:
	var required_role := _required_role_for_work_site(entity)
	if required_role == "":
		return true
	var worker_role := _worker_role_for_id(worker_id)
	if required_role.find(",") != -1:
		return required_role.split(",").has(worker_role)
	return worker_role == required_role


func _worker_role_for_id(worker_id: String) -> String:
	if worker_id == "":
		return ""

	var parent := get_parent()
	if parent == null:
		return ""

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager != null and npc_manager.has_method("worker_role_for"):
		return npc_manager.worker_role_for(worker_id)

	return ""


func can_afford_building(definition: Dictionary) -> bool:
	return gold >= int(definition.get("cost", 0))


func set_city_context(terrain: String, player_controlled := true) -> void:
	city_terrain = terrain
	city_player_controlled = player_controlled
	_refresh_building_choices()
	_recreate_preview()
	_refresh_ui()
	_update_preview()


func occupy_terrain(terrain: String) -> void:
	if terrain == "":
		return
	occupied_terrains[terrain] = true


func terrain_is_occupied(terrain: String) -> bool:
	return bool(occupied_terrains.get(terrain, false))


func set_city_context_for_occupied_terrain(terrain: String) -> bool:
	if not terrain_is_occupied(terrain):
		set_city_context(terrain, false)
		return false

	set_city_context(terrain, true)
	return true


func can_use_diplomacy() -> bool:
	return building_level_for_id("cityhall") >= 4


func sign_trade_treaty(terrain: String) -> bool:
	if terrain == "" or not can_use_diplomacy():
		return false

	trade_treaties[terrain] = true
	trade_treaty_active = true
	return true


func has_trade_treaty(terrain: String) -> bool:
	return bool(trade_treaties.get(terrain, false))


func can_travel_to_terrain(terrain: String) -> bool:
	if terrain == "":
		return false
	if _building_count_for_id("post_station") <= 0:
		return false
	return horse_count > 0


func travel_to_terrain(terrain: String) -> bool:
	if not can_travel_to_terrain(terrain):
		return false

	var scene_path := travel_scene_path_for_terrain(terrain)
	if scene_path != "" and _request_travel_scene_change(scene_path):
		return true

	set_city_context(terrain, terrain_is_occupied(terrain))
	return true


func travel_scene_path_for_terrain(terrain: String) -> String:
	return game_data.travel_destination_scene_path(terrain)


func _request_travel_scene_change(scene_path: String) -> bool:
	if scene_path == "" or not is_inside_tree():
		return false

	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false

	var game_session := tree.root.get_node_or_null("GameSession")
	if (
		game_session != null
		and game_session.has_method("switch_to_scene_preserving_current")
		and game_session.switch_to_scene_preserving_current(tree, scene_path, true)
	):
		return true

	tree.call_deferred("change_scene_to_file", scene_path)
	return true


func launch_expedition(terrain: String) -> Dictionary:
	if terrain == "":
		return {"occupied": false, "loss_multiplier": 1.0}
	if _building_count_for_id("barracks") <= 0:
		return {"occupied": false, "loss_multiplier": 1.0}

	var loss_multiplier := 1.0
	var parent := get_parent()
	if parent != null:
		var npc_manager := parent.get_node_or_null("NPCManager")
		if npc_manager != null and npc_manager.has_method("expedition_loss_multiplier"):
			loss_multiplier = float(npc_manager.expedition_loss_multiplier())

	occupy_terrain(terrain)
	return {
		"occupied": true,
		"loss_multiplier": loss_multiplier,
	}


func building_definition_for_id(building_id: String) -> Dictionary:
	if building_id == "farm":
		return game_data.farm_definition()
	if building_id == "lumberyard":
		return game_data.lumberyard_definition()
	if building_id == "quarry":
		return game_data.quarry_definition()
	for definition in catalog.get_buildings():
		if definition.get("id", "") == building_id:
			return definition.duplicate(true)
	return {}


func can_build_definition(definition: Dictionary) -> bool:
	return _building_unavailable_reason(definition) == ""


func _building_unavailable_reason(definition: Dictionary) -> String:
	if definition.is_empty():
		return "未知建筑"
	if not city_player_controlled:
		return "未占领城市，无法建造"

	var required_terrain := str(definition.get("terrain_required", ""))
	if required_terrain != "" and required_terrain != city_terrain:
		return "需要%s地形" % _terrain_display_name(required_terrain)

	var required_cityhall_level := int(definition.get("unlock_cityhall_level", 1))
	if required_cityhall_level > 1 and building_level_for_id("cityhall") < required_cityhall_level:
		return "需要市政厅%d级" % required_cityhall_level

	var required_buildings: Dictionary = definition.get("requires_buildings", {})
	for required_building_id in required_buildings.keys():
		var required_count := int(required_buildings[required_building_id])
		if _building_count_for_id(str(required_building_id)) < required_count:
			return "需要%s" % _building_display_name_for_id(str(required_building_id))

	var max_count := int(definition.get("max_count_per_city", 0))
	if max_count > 0 and _building_count_for_id(str(definition.get("id", ""))) >= max_count:
		return "已达建造上限"

	if not can_afford_building(definition):
		return "金币不足，需要 %d" % int(definition.get("cost", 0))

	return ""


func _terrain_display_name(terrain: String) -> String:
	match terrain:
		"river":
			return "河湾"
		"northern":
			return "北境"
		"mountain":
			return "山岭"
		_:
			return terrain


func _terrain_button_suffix(terrain: String) -> String:
	match terrain:
		"river":
			return "River"
		"northern":
			return "Northern"
		"mountain":
			return "Mountain"
		_:
			return terrain


func _building_count_for_id(building_id: String) -> int:
	var count := 0
	for entity in placed_buildings:
		if entity.get("building_id", "") == building_id and not entity.get("damaged", false):
			count += 1
	return count


func _building_display_name_for_id(building_id: String) -> String:
	var definition := building_definition_for_id(building_id)
	if not definition.is_empty():
		return str(definition.get("display_name", building_id))
	if building_id == "post_station":
		return "驿站"
	if building_id == "barracks":
		return "军营"
	return building_id


func spend_gold_for_building(definition: Dictionary) -> bool:
	var cost := int(definition.get("cost", 0))
	if gold < cost:
		return false

	gold -= cost
	_refresh_gold_ui()
	return true


func upgrade_cost_for_entity_index(entity_index: int) -> int:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return 0

	var entity: Dictionary = placed_buildings[entity_index]
	var building_id: String = entity.get("building_id", "")
	var target_level := int(entity.get("level", 1)) + 1
	return game_data.building_upgrade_cost(building_id, target_level)


func can_upgrade_entity(entity_index: int) -> bool:
	if not _has_next_upgrade(entity_index):
		return false
	if not _upgrade_requirements_met(entity_index):
		return false

	return gold >= upgrade_cost_for_entity_index(entity_index)


func upgrade_building(entity_index: int) -> bool:
	if not can_upgrade_entity(entity_index):
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	var cost := upgrade_cost_for_entity_index(entity_index)
	gold -= cost
	entity.level = int(entity.get("level", 1)) + 1
	if entity.get("building_id", "") == "lumberyard":
		entity.display_name = game_data.lumberyard_display_name(int(entity.get("level", 1)))
	if entity.get("building_id", "") == "wall":
		entity.wall_health = game_data.wall_health_for_level(int(entity.get("level", 1)))
	placed_buildings[entity_index] = entity
	_refresh_gold_ui()
	_refresh_info_panel()
	return true


func wall_max_health_for_entity_index(entity_index: int) -> int:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return 0

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "wall":
		return 0
	return game_data.wall_health_for_level(int(entity.get("level", 1)))


func wall_health_for_entity_index(entity_index: int) -> int:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return 0

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "wall":
		return 0
	var max_health := wall_max_health_for_entity_index(entity_index)
	var current_health := int(entity.get("wall_health", max_health))
	return clampi(current_health, 0, max_health)


func damage_wall_by_monster(wall_node_name: String, damage_amount := 1) -> bool:
	var entity_index := _building_index_for_node_name(wall_node_name)
	if entity_index == -1:
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "wall" or bool(entity.get("damaged", false)):
		return false

	var health: int = wall_health_for_entity_index(entity_index) - max(1, damage_amount)
	if health <= 0:
		entity.wall_health = 0
		placed_buildings[entity_index] = entity
		_damage_building(entity_index)
	else:
		entity.wall_health = health
		placed_buildings[entity_index] = entity
	return true


func nearest_monster_blocking_wall(origin: Vector2, direction := 0, max_distance := 86.0) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for entity in placed_buildings:
		if entity.get("building_id", "") != "wall":
			continue
		if bool(entity.get("damaged", false)):
			continue

		var node: Node2D = entity.get("node", null)
		if not is_instance_valid(node):
			continue
		var delta_x := node.global_position.x - origin.x
		if direction < 0 and delta_x >= 0.0:
			continue
		if direction > 0 and delta_x <= 0.0:
			continue
		var distance := absf(delta_x)
		if distance > max_distance or distance >= nearest_distance:
			continue
		if absf(node.global_position.y - origin.y) > 120.0:
			continue

		nearest = node
		nearest_distance = distance
	return nearest


func is_monster_blocking_wall(node: Node2D) -> bool:
	if node == null:
		return false
	var entity_index := _building_index_for_node_name(node.name)
	if entity_index == -1:
		return false
	var entity: Dictionary = placed_buildings[entity_index]
	return entity.get("building_id", "") == "wall" and not bool(entity.get("damaged", false))


func building_level_for_id(building_id: String) -> int:
	var highest_level := 0
	for entity in placed_buildings:
		if entity.get("building_id", "") != building_id:
			continue
		highest_level = maxi(highest_level, int(entity.get("level", 1)))

	return highest_level


func iron_mine_supply_available() -> bool:
	if city_terrain != "mountain":
		return false
	for entity in placed_buildings:
		if entity.get("building_id", "") != "iron_mine":
			continue
		if entity.get("damaged", false):
			continue
		if entity.get("worker_inside", false):
			return true
	return false


func _has_next_upgrade(entity_index: int) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	var entity_kind: String = entity.get("entity_kind", "")
	if entity_kind != "building" and entity_kind != "cityhall":
		return false
	if entity.get("damaged", false):
		return false

	var building_id: String = entity.get("building_id", "")
	var target_level := int(entity.get("level", 1)) + 1
	return game_data.has_building_upgrade(building_id, target_level)


func _upgrade_requirements_met(entity_index: int) -> bool:
	if not _has_next_upgrade(entity_index):
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	var building_id: String = entity.get("building_id", "")
	var target_level := int(entity.get("level", 1)) + 1
	var requirements := game_data.building_upgrade_requirements(building_id, target_level)
	for required_building_id in requirements.keys():
		var required_level := int(requirements[required_building_id])
		if building_level_for_id(str(required_building_id)) < required_level:
			return false

	return true


func _upgrade_status_text(entity_index: int) -> String:
	if not _has_next_upgrade(entity_index):
		return "最高级"

	var cost := upgrade_cost_for_entity_index(entity_index)
	if not _upgrade_requirements_met(entity_index):
		return "需要市政厅2级"
	if gold < cost:
		return "需要%d金币" % cost

	return "可升级 %d金币" % cost


func _upgrade_button_text(entity_index: int) -> String:
	if not _has_next_upgrade(entity_index):
		return "最高级"

	return "升级 %d金" % upgrade_cost_for_entity_index(entity_index)


func _ensure_collection_state() -> void:
	unlocked_crops = collection_rules.normalized_crop_unlocks(unlocked_crops, game_data)
	fish_codex = collection_rules.fish_codex_with_all_species(fish_codex, game_data)


func try_enter_building_at_player() -> bool:
	if player == null:
		return false

	var entity_index := _enterable_building_index_containing_point(player.global_position)
	if entity_index == -1:
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if bool(entity.get("damaged", false)):
		if status_label != null:
			status_label.text = "Building damaged: press E to repair"
		return true

	return _enter_building_interior(entity_index)


func apply_interior_result(result: Dictionary) -> bool:
	_ensure_collection_state()
	var node_name := str(result.get("building_node_name", ""))
	if node_name == "":
		return false

	var entity_index := _building_index_for_node_name(node_name)
	if entity_index == -1:
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if result.has("interior_state") and result.get("interior_state") is Dictionary:
		entity.interior_state = (result.get("interior_state", {}) as Dictionary).duplicate(true)
	placed_buildings[entity_index] = entity
	_sync_barracks_training_to_npcs(entity)

	var gold_delta := int(result.get("gold_delta", 0))
	if gold_delta != 0:
		add_gold(gold_delta)

	if result.has("unlocked_crops") and result.get("unlocked_crops") is Dictionary:
		var result_unlocks: Dictionary = result.get("unlocked_crops", {})
		for crop_id in result_unlocks.keys():
			if bool(result_unlocks.get(crop_id, false)):
				unlock_crop(str(crop_id))

	_refresh_ui()
	_refresh_gold_ui()
	return true


func unlocked_crop_ids() -> Array:
	_ensure_collection_state()
	var ids := []
	for crop_id in game_data.crop_ids():
		if bool(unlocked_crops.get(str(crop_id), false)):
			ids.append(str(crop_id))
	return ids


func is_crop_unlocked(crop_id: String) -> bool:
	_ensure_collection_state()
	return bool(unlocked_crops.get(crop_id, false))


func unlock_crop(crop_id: String) -> bool:
	if crop_id == "" or game_data.crop_definition(crop_id).is_empty():
		return false
	_ensure_collection_state()
	var was_unlocked := bool(unlocked_crops.get(crop_id, false))
	unlocked_crops[crop_id] = true
	return not was_unlocked


func record_random_fishing_catch(
	species_roll: float,
	weight_roll: float,
	seed_drop_roll: float,
	seed_choice_roll: float
) -> Dictionary:
	_ensure_collection_state()
	var catch_data := collection_rules.fish_catch_from_rolls(species_roll, weight_roll, game_data)
	var codex_update := collection_rules.record_fish_catch(fish_codex, catch_data)
	fish_codex = codex_update.get("codex", fish_codex)

	var seed_id := collection_rules.seed_drop_from_rolls(
		"fishing",
		seed_drop_roll,
		seed_choice_roll,
		unlocked_crops,
		game_data
	)
	var seed_unlocked := false
	if seed_id != "":
		seed_unlocked = unlock_crop(seed_id)

	last_fishing_result = {
		"catch": catch_data,
		"codex_update": codex_update,
		"seed_id": seed_id,
		"seed_unlocked": seed_unlocked,
	}
	return last_fishing_result.duplicate(true)


func toggle_fish_codex_panel() -> void:
	if fish_codex_panel != null:
		_clear_fish_codex_panel()
	else:
		_show_fish_codex_panel()


func _enter_building_interior(entity_index: int) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false
	if not is_inside_tree():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	var node: Node2D = entity.get("node")
	if not is_instance_valid(node):
		return false

	var scene_path := game_data.building_interior_scene_path()
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false

	var game_session := tree.root.get_node_or_null("GameSession")
	if game_session == null or not game_session.has_method("set_active_interior_context"):
		return false

	var context := {
		"building_node_name": node.name,
		"building_id": str(entity.get("building_id", "")),
		"display_name": str(entity.get("display_name", "")),
		"level": int(entity.get("level", 1)),
		"return_position": [player.global_position.x, player.global_position.y],
		"interior_state": (entity.get("interior_state", {}) as Dictionary).duplicate(true),
		"workers": _interior_worker_payloads(entity),
		"unlocked_crops": unlocked_crops.duplicate(true),
		"fish_codex": fish_codex.duplicate(true),
	}
	if not game_session.set_active_interior_context(context):
		return false

	_prepare_for_interior_transition()
	if (
		game_session.has_method("switch_to_scene_overlaying_current")
		and game_session.switch_to_scene_overlaying_current(tree, scene_path, true)
	):
		return true
	if game_session.has_method("switch_to_scene_preserving_current") and game_session.switch_to_scene_preserving_current(tree, scene_path, true):
		return true

	tree.call_deferred("change_scene_to_file", scene_path)
	return true


func _has_active_interior_overlay() -> bool:
	if not is_inside_tree():
		return false

	var tree := get_tree()
	if tree == null or tree.current_scene == get_parent():
		return false

	var game_session := tree.root.get_node_or_null("GameSession")
	if game_session == null or not game_session.has_method("active_interior_context"):
		return false

	return not game_session.active_interior_context().is_empty()


func _prepare_for_interior_transition() -> void:
	if demolition_target_index != -1:
		_cancel_demolition()
	if fishing_manager != null and fishing_manager.has_method("cancel_fishing"):
		fishing_manager.cancel_fishing()
	_clear_info_panel()
	_clear_fish_codex_panel()
	selected_index = -1
	_recreate_preview()
	_refresh_ui()


func _interior_worker_payloads(entity: Dictionary) -> Array:
	var workers := []
	var building_id := str(entity.get("building_id", ""))
	var worker_ids := _work_site_workers_inside(entity)
	if worker_ids.is_empty():
		worker_ids = _work_site_worker_ids(entity)

	var resource_kind := _interior_resource_kind_for_building(building_id)
	var work_role := str(game_data.building_interior_value(building_id, "worker_role", ""))
	for worker_id_value in worker_ids:
		var worker_id := str(worker_id_value)
		if worker_id == "":
			continue
		workers.append({
			"worker_id": worker_id,
			"role": work_role,
			"tool_multiplier": _worker_best_tool_multiplier(worker_id, resource_kind),
		})
	return workers


func _interior_resource_kind_for_building(building_id: String) -> String:
	match building_id:
		"farm":
			return "farm"
		"lumberyard":
			return "tree"
		"quarry":
			return "stone"
	return ""


func _enterable_building_index_containing_point(point: Vector2) -> int:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		var entity_kind := str(entity.get("entity_kind", ""))
		if entity_kind != "building" and entity_kind != "cityhall":
			continue
		if _is_resource_entity(entity):
			continue
		var footprint: Rect2 = entity.get("footprint", Rect2())
		if _rect_contains_point_inclusive(footprint, point):
			return i
	return -1


func _building_index_for_node_name(node_name: String) -> int:
	if node_name == "":
		return -1
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		var node: Node2D = entity.get("node")
		if is_instance_valid(node) and node.name == node_name:
			return i
	return -1


func _show_fish_codex_panel() -> void:
	_ensure_collection_state()
	_clear_fish_codex_panel()

	fish_codex_canvas = CanvasLayer.new()
	fish_codex_canvas.name = "FishCodexCanvas"
	fish_codex_canvas.layer = 28
	add_child(fish_codex_canvas)

	fish_codex_panel = Panel.new()
	fish_codex_panel.name = "FishCodexPanel"
	fish_codex_panel.position = Vector2(620, 150)
	fish_codex_panel.size = Vector2(680, 560)
	fish_codex_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	fish_codex_canvas.add_child(fish_codex_panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "鱼图鉴"
	title.position = Vector2(24, 18)
	title.size = Vector2(500, 32)
	title.add_theme_font_size_override("font_size", 24)
	fish_codex_panel.add_child(title)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "关闭 (P/Esc)"
	close_button.position = Vector2(540, 18)
	close_button.size = Vector2(112, 34)
	close_button.pressed.connect(Callable(self, "_clear_fish_codex_panel"))
	fish_codex_panel.add_child(close_button)

	var row_y := 76.0
	for fish in game_data.fish_species():
		var fish_id := str(fish.get("id", ""))
		var entry: Dictionary = fish_codex.get(fish_id, {})
		var caught := bool(entry.get("caught", false))
		var row := HBoxContainer.new()
		row.name = "FishRow_%s" % fish_id
		row.position = Vector2(24, row_y)
		row.size = Vector2(628, 62)
		fish_codex_panel.add_child(row)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(52, 52)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = game_data.art_asset_texture("fish", fish_id if caught else "silhouette")
		row.add_child(icon)

		var text := Label.new()
		text.name = "Info"
		text.custom_minimum_size = Vector2(560, 52)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if caught:
			text.text = "%s  最小 %.2fkg  最大 %.2fkg" % [
				str(entry.get("display_name", fish.get("display_name", fish_id))),
				float(entry.get("min_weight", 0.0)),
				float(entry.get("max_weight", 0.0)),
			]
		else:
			text.text = "???  %s" % _fish_rarity_display_name(str(fish.get("rarity", "")))
		row.add_child(text)
		row_y += 70.0


func _fish_rarity_display_name(rarity: String) -> String:
	match rarity:
		"common":
			return "常规"
		"rare":
			return "稀有"
		"legendary":
			return "传说"
	return rarity


func _clear_fish_codex_panel() -> void:
	if fish_codex_canvas != null:
		fish_codex_canvas.queue_free()
	elif fish_codex_panel != null:
		fish_codex_panel.queue_free()
	fish_codex_canvas = null
	fish_codex_panel = null


func add_gold(amount: int) -> void:
	gold += amount
	_refresh_gold_ui()
	_refresh_ui()
	_update_preview()


func can_start_fishing() -> bool:
	if _has_active_interior_overlay():
		return false
	if player_dead:
		return false
	if _is_tree_paused():
		return false
	if pause_panel != null:
		return false
	if test_panel != null:
		return false
	if info_panel != null:
		return false
	if fish_codex_panel != null:
		return false
	if demolition_target_index != -1:
		return false
	if player_tree_task_id != "":
		return false
	return true


func set_trade_treaty_active(active: bool) -> void:
	trade_treaty_active = active


func horse_price() -> int:
	if trade_treaty_active:
		return int(game_data.trade_value("horse_treaty_price", 20))
	return int(game_data.trade_value("horse_base_price", 30))


func buy_horse() -> bool:
	if _building_count_for_id("post_station") <= 0:
		return false

	var price := horse_price()
	if gold < price:
		return false

	gold -= price
	horse_count += 1
	_refresh_gold_ui()
	return true


func can_train_shield_guard() -> bool:
	return _building_count_for_id("shield_barracks") > 0


func spend_gold_for_shield_guard_training() -> bool:
	if not can_train_shield_guard():
		return false

	var cost := int(game_data.training_value("shield_guard_cost", 25))
	if gold < cost:
		return false

	gold -= cost
	_refresh_gold_ui()
	return true


func train_nearest_shield_guard() -> bool:
	var parent := get_parent()
	if parent == null:
		return false

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("train_nearest_shield_guard_candidate"):
		return false

	return npc_manager.train_nearest_shield_guard_candidate(_city_hall_position())


func autosave_game(reason := "interval", scene_path := GameData.MAIN_SCENE_PATH) -> bool:
	if save_manager == null:
		return false

	return save_manager.record_autosave(
		scene_path,
		_autosave_snapshot(),
		reason
	)


func load_last_save() -> bool:
	if save_manager == null:
		return false

	return apply_save_data(save_manager.read_last_save())


func apply_save_data(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		return false

	var snapshot: Dictionary = save_data.get("snapshot", {})
	if snapshot.is_empty():
		return false

	if snapshot.has("gold"):
		gold = int(snapshot.get("gold", gold))
	if snapshot.has("player_dead"):
		player_dead = bool(snapshot.get("player_dead", player_dead))
	if snapshot.has("city_terrain"):
		city_terrain = str(snapshot.get("city_terrain", city_terrain))
	if snapshot.has("city_player_controlled"):
		city_player_controlled = bool(snapshot.get("city_player_controlled", city_player_controlled))
	if snapshot.has("horse_count"):
		horse_count = int(snapshot.get("horse_count", horse_count))
	if snapshot.has("unlocked_crops") and snapshot.get("unlocked_crops") is Dictionary:
		unlocked_crops = collection_rules.normalized_crop_unlocks(snapshot.get("unlocked_crops", {}), game_data)
	else:
		_ensure_collection_state()
	if snapshot.has("fish_codex") and snapshot.get("fish_codex") is Dictionary:
		fish_codex = collection_rules.fish_codex_with_all_species(snapshot.get("fish_codex", {}), game_data)
	else:
		_ensure_collection_state()
	if snapshot.has("resources"):
		_apply_resources_snapshot(snapshot.get("resources", []))
	if snapshot.has("buildings"):
		_apply_buildings_snapshot(snapshot.get("buildings", []))
	if snapshot.has("npcs"):
		_apply_npcs_snapshot(snapshot.get("npcs", []))

	var saved_position = snapshot.get("player_position", [])
	if player != null and saved_position is Array and saved_position.size() >= 2:
		player.global_position = Vector2(float(saved_position[0]), float(saved_position[1]))

	_refresh_building_choices()
	_refresh_gold_ui()
	_refresh_ui()
	_update_preview()
	if player_dead:
		_show_death_overlay()
	elif death_canvas != null:
		death_canvas.queue_free()
		death_canvas = null
	return true


func _apply_pending_save_on_ready() -> bool:
	if not is_inside_tree():
		return false

	var game_session := get_tree().root.get_node_or_null("GameSession")
	if game_session == null or not game_session.has_method("consume_pending_save_data"):
		return false

	var save_data: Dictionary = game_session.consume_pending_save_data()
	if save_data.is_empty() or not save_data.has("snapshot"):
		return false

	return apply_save_data(save_data)


func _update_autosave(delta: float) -> void:
	if delta <= 0.0:
		return

	autosave_elapsed += delta
	while autosave_elapsed >= AUTOSAVE_SECONDS:
		autosave_elapsed -= AUTOSAVE_SECONDS
		autosave_game("interval")


func _autosave_snapshot() -> Dictionary:
	var player_position := Vector2.ZERO
	if player != null:
		player_position = player.global_position

	return {
		"gold": gold,
		"player_dead": player_dead,
		"player_position": [player_position.x, player_position.y],
		"city_terrain": city_terrain,
		"city_player_controlled": city_player_controlled,
		"horse_count": horse_count,
		"unlocked_crops": unlocked_crops.duplicate(true),
		"fish_codex": fish_codex.duplicate(true),
		"placed_entity_count": placed_buildings.size(),
		"resources": _resources_save_snapshot(),
		"buildings": _buildings_save_snapshot(),
		"npcs": _npcs_save_snapshot(),
	}


func _resources_save_snapshot() -> Array:
	var saved_resources := []
	for entity in placed_buildings:
		var entity_kind := str(entity.get("entity_kind", ""))
		if not ["tree", "stone", "mother_tree", "bridge"].has(entity_kind):
			continue

		var node: Node2D = entity.get("node")
		if not is_instance_valid(node):
			continue

		var footprint: Rect2 = entity.get("footprint", Rect2())
		var saved_resource := {
			"node_name": node.name,
			"entity_kind": entity_kind,
			"resource_kind": str(entity.get("resource_kind", entity_kind)),
			"display_name": str(entity.get("display_name", "")),
			"demolishable": bool(entity.get("demolishable", false)),
			"position": [node.global_position.x, node.global_position.y],
			"footprint_position": [footprint.position.x, footprint.position.y],
			"footprint_size": [footprint.size.x, footprint.size.y],
			"visible": node.visible,
		}
		for key in ["has_quarry", "quarry_node_name", "has_lumberyard", "lumberyard_node_name", "farm_built", "farm_node_name"]:
			if entity.has(key):
				saved_resource[key] = entity.get(key)
		saved_resources.append(saved_resource)
	return saved_resources


func _buildings_save_snapshot() -> Array:
	var saved_buildings := []
	for entity in placed_buildings:
		var entity_kind := str(entity.get("entity_kind", ""))
		if entity_kind != "building" and entity_kind != "cityhall":
			continue

		var node: Node2D = entity.get("node")
		if not is_instance_valid(node):
			continue

		var footprint: Rect2 = entity.get("footprint", Rect2())
		saved_buildings.append({
			"node_name": node.name,
			"building_id": str(entity.get("building_id", "")),
			"entity_kind": entity_kind,
			"display_name": str(entity.get("display_name", "")),
			"level": int(entity.get("level", 1)),
			"damaged": bool(entity.get("damaged", false)),
			"demolishable": bool(entity.get("demolishable", true)),
			"is_workplace": bool(entity.get("is_workplace", true)),
			"worker_id": str(entity.get("worker_id", "")),
			"worker_inside": bool(entity.get("worker_inside", false)),
			"worker_ids": _work_site_worker_ids(entity),
			"workers_inside": _work_site_workers_inside(entity),
			"worker_income_elapsed": (entity.get("worker_income_elapsed", {}) as Dictionary).duplicate(true),
			"farm_income_elapsed": float(entity.get("farm_income_elapsed", 0.0)),
			"quarry_income_elapsed": float(entity.get("quarry_income_elapsed", 0.0)),
			"lumberyard_tree_elapsed": float(entity.get("lumberyard_tree_elapsed", 0.0)),
			"wall_health": wall_health_for_entity_index(placed_buildings.find(entity)) if str(entity.get("building_id", "")) == "wall" else int(entity.get("wall_health", 0)),
			"interior_state": (entity.get("interior_state", {}) as Dictionary).duplicate(true),
			"source_mother_tree_name": str(entity.get("source_mother_tree_name", "")),
			"position": [node.global_position.x, node.global_position.y],
			"footprint_position": [footprint.position.x, footprint.position.y],
			"footprint_size": [footprint.size.x, footprint.size.y],
		})
	return saved_buildings


func _npcs_save_snapshot() -> Array:
	var npc_manager := _npc_manager()
	if npc_manager != null and npc_manager.has_method("save_snapshot"):
		return npc_manager.save_snapshot()
	return []


func _apply_resources_snapshot(saved_resources) -> void:
	if not (saved_resources is Array):
		return

	_remove_restorable_resources()
	for saved_resource in saved_resources:
		if saved_resource is Dictionary:
			_restore_resource_snapshot(saved_resource)


func _apply_buildings_snapshot(saved_buildings) -> void:
	if not (saved_buildings is Array):
		return

	_remove_restorable_buildings()
	for saved_building in saved_buildings:
		if not saved_building is Dictionary:
			continue

		var building_id := str(saved_building.get("building_id", ""))
		var entity_kind := str(saved_building.get("entity_kind", "building"))
		if building_id == "cityhall" or entity_kind == "cityhall":
			_apply_cityhall_snapshot(saved_building)
		else:
			_restore_building_snapshot(saved_building)


func _apply_npcs_snapshot(saved_npcs) -> void:
	var npc_manager := _npc_manager()
	if npc_manager != null and npc_manager.has_method("apply_snapshot"):
		npc_manager.apply_snapshot(saved_npcs)


func _remove_restorable_resources() -> void:
	for i in range(placed_buildings.size() - 1, -1, -1):
		var entity: Dictionary = placed_buildings[i]
		if not ["tree", "stone", "mother_tree", "bridge"].has(str(entity.get("entity_kind", ""))):
			continue

		_remove_placed_footprint(entity.get("footprint", Rect2()))
		var node: Node2D = entity.get("node")
		if is_instance_valid(node):
			var node_parent := node.get_parent()
			if node_parent != null:
				node_parent.remove_child(node)
			node.free()
		placed_buildings.remove_at(i)


func _restore_resource_snapshot(saved_resource: Dictionary) -> void:
	if buildings_container == null:
		return

	var entity_kind := str(saved_resource.get("entity_kind", ""))
	var resource_kind := str(saved_resource.get("resource_kind", entity_kind))
	var position := _vector2_from_save(saved_resource.get("position", []), Vector2.ZERO)
	var node: Node2D = null
	match entity_kind:
		"bridge":
			node = _spawn_bridge_at(position)
		"mother_tree":
			node = _spawn_mother_tree_at(position)
		"stone":
			node = _spawn_stone_at(position)
		"tree":
			node = _spawn_tree_at(position)
		_:
			return
	if not is_instance_valid(node):
		return

	var saved_name := str(saved_resource.get("node_name", ""))
	if saved_name != "":
		node.name = saved_name
	node.visible = bool(saved_resource.get("visible", true))

	var index := placed_buildings.size() - 1
	var entity: Dictionary = placed_buildings[index]
	var saved_footprint := _rect2_from_save(
		saved_resource.get("footprint_position", []),
		saved_resource.get("footprint_size", []),
		entity.get("footprint", Rect2())
	)
	_replace_placed_footprint(entity.get("footprint", Rect2()), saved_footprint)
	entity.footprint = saved_footprint
	entity.entity_kind = entity_kind
	entity.resource_kind = resource_kind
	entity.display_name = str(saved_resource.get("display_name", entity.get("display_name", "")))
	entity.demolishable = bool(saved_resource.get("demolishable", entity.get("demolishable", false)))
	for key in ["has_quarry", "quarry_node_name", "has_lumberyard", "lumberyard_node_name", "farm_built", "farm_node_name"]:
		if saved_resource.has(key):
			entity[key] = saved_resource.get(key)
	placed_buildings[index] = entity

	if resource_kind == "stone":
		_set_stone_quarry_state(
			index,
			str(saved_resource.get("quarry_node_name", "")),
			bool(saved_resource.get("has_quarry", false))
		)


func _remove_restorable_buildings() -> void:
	for i in range(placed_buildings.size() - 1, -1, -1):
		var entity: Dictionary = placed_buildings[i]
		if str(entity.get("entity_kind", "")) != "building":
			continue

		_clear_stone_quarry_for_entity(entity)
		_remove_placed_footprint(entity.get("footprint", Rect2()))
		var node: Node2D = entity.get("node")
		if is_instance_valid(node):
			var node_parent := node.get_parent()
			if node_parent != null:
				node_parent.remove_child(node)
			node.free()
		placed_buildings.remove_at(i)


func _apply_cityhall_snapshot(saved_building: Dictionary) -> void:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if str(entity.get("building_id", "")) != "cityhall":
			continue

		entity.level = max(1, int(saved_building.get("level", 1)))
		entity.damaged = bool(saved_building.get("damaged", false))
		if saved_building.has("interior_state") and saved_building.get("interior_state") is Dictionary:
			entity.interior_state = (saved_building.get("interior_state", {}) as Dictionary).duplicate(true)
		placed_buildings[i] = entity
		return


func _restore_building_snapshot(saved_building: Dictionary) -> void:
	if buildings_container == null:
		return

	var building_id := str(saved_building.get("building_id", ""))
	var definition := building_definition_for_id(building_id)
	if definition.is_empty():
		return

	var position := _vector2_from_save(saved_building.get("position", []), Vector2.ZERO)
	var footprint := rules.footprint_for_position(position, _building_footprint_size(definition))
	var building := visual_factory.create_building_visual(definition)
	building.name = str(saved_building.get("node_name", ""))
	if building.name == "":
		building.name = "%s_loaded_%d" % [building_id, placed_buildings.size()]
	building.position = buildings_container.to_local(position)
	_apply_building_orientation(building, building_id, position)
	buildings_container.add_child(building)

	_track_placed_entity(
		building,
		footprint,
		bool(saved_building.get("demolishable", true)),
		str(saved_building.get("display_name", definition.get("display_name", building_id))),
		"building",
		bool(saved_building.get("is_workplace", definition.get("is_workplace", true))),
		building_id
	)
	var index := placed_buildings.size() - 1
	var entity: Dictionary = placed_buildings[index]
	entity.level = max(1, int(saved_building.get("level", 1)))
	entity.damaged = bool(saved_building.get("damaged", false))
	entity.worker_id = str(saved_building.get("worker_id", ""))
	entity.worker_inside = bool(saved_building.get("worker_inside", false))
	if saved_building.has("worker_ids"):
		entity.worker_ids = (saved_building.get("worker_ids", []) as Array).duplicate()
	if saved_building.has("workers_inside"):
		entity.workers_inside = (saved_building.get("workers_inside", []) as Array).duplicate()
	_set_work_site_workers(entity, _work_site_worker_ids(entity), _work_site_workers_inside(entity))
	if saved_building.has("worker_income_elapsed") and saved_building.get("worker_income_elapsed") is Dictionary:
		entity.worker_income_elapsed = (saved_building.get("worker_income_elapsed", {}) as Dictionary).duplicate(true)
	entity.farm_income_elapsed = float(saved_building.get("farm_income_elapsed", 0.0))
	entity.quarry_income_elapsed = float(saved_building.get("quarry_income_elapsed", 0.0))
	entity.lumberyard_tree_elapsed = float(saved_building.get("lumberyard_tree_elapsed", 0.0))
	if building_id == "wall":
		entity.wall_health = int(saved_building.get("wall_health", game_data.wall_health_for_level(int(entity.get("level", 1)))))
	if saved_building.has("interior_state") and saved_building.get("interior_state") is Dictionary:
		entity.interior_state = (saved_building.get("interior_state", {}) as Dictionary).duplicate(true)
	if saved_building.has("source_mother_tree_name"):
		entity.source_mother_tree_name = str(saved_building.get("source_mother_tree_name", ""))
	if building_id == "lumberyard":
		entity.display_name = game_data.lumberyard_display_name(int(entity.get("level", 1)))
	placed_buildings[index] = entity
	if bool(entity.get("worker_inside", false)):
		visual_factory.set_occupied(building, true)
	if bool(entity.get("damaged", false)):
		_apply_damaged_building_visual(entity)
	_mark_stone_quarry_for_entity(entity)


func _apply_damaged_building_visual(entity: Dictionary) -> void:
	var node: Node2D = entity.get("node", null)
	if not is_instance_valid(node):
		return

	node.modulate = Color(0.48, 0.34, 0.34, 1)
	visual_factory.set_occupied(node, false)


func _vector2_from_save(value, default_value: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return default_value


func _rect2_from_save(position_value, size_value, default_value: Rect2) -> Rect2:
	if position_value is Array and position_value.size() >= 2 and size_value is Array and size_value.size() >= 2:
		return Rect2(
			Vector2(float(position_value[0]), float(position_value[1])),
			Vector2(float(size_value[0]), float(size_value[1]))
		)
	return default_value


func apply_player_monster_hit() -> Dictionary:
	var loss := monster_rules.gold_loss_for_player_hit(gold)
	if monster_rules.player_dies_from_gold_hit(gold):
		var stolen_gold := gold
		gold = 0
		_refresh_gold_ui()
		_set_player_dead()
		return {
			"died": true,
			"lost_gold": stolen_gold,
		}

	gold -= loss
	_refresh_gold_ui()
	return {
		"died": false,
		"lost_gold": loss,
	}


func revive_player() -> void:
	apply_revival_penalty()
	player_dead = false
	if death_canvas != null:
		death_canvas.queue_free()
		death_canvas = null


func apply_revival_penalty(seed := 0) -> Dictionary:
	var penalty_seed := seed
	if penalty_seed == 0:
		penalty_seed = int(Time.get_ticks_msec())

	gold = 0
	_refresh_gold_ui()
	_clear_all_monsters()

	var damaged_buildings := damage_random_half_buildings(penalty_seed)
	var converted_villagers: Array = []
	var parent := get_parent()
	if parent != null:
		var npc_manager := parent.get_node_or_null("NPCManager")
		if npc_manager != null and npc_manager.has_method("convert_random_half_villagers_to_homeless"):
			converted_villagers = npc_manager.convert_random_half_villagers_to_homeless(penalty_seed + 31)

		var monster_manager := parent.get_node_or_null("MonsterManager")
		if monster_manager != null and monster_manager.has_method("begin_safe_nights"):
			monster_manager.begin_safe_nights(3)

	var revive_position := _city_hall_position()
	if player != null:
		player.global_position = revive_position

	return {
		"damaged_buildings": damaged_buildings,
		"converted_villagers": converted_villagers,
	}


func damage_random_half_buildings(seed: int) -> Array:
	var candidates: Array = []
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("entity_kind", "") != "building":
			continue
		if entity.get("building_id", "") == "cityhall":
			continue
		candidates.append(i)

	var damaged: Array = []
	if candidates.is_empty():
		return damaged

	var base_target_count := int(ceil(float(candidates.size()) * 0.5))
	var target_count := int(floor(float(base_target_count) * (1.0 - building_damage_reduction())))
	target_count = clampi(target_count, 0, candidates.size())
	if target_count <= 0:
		return damaged

	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed
	var chosen := {}
	while chosen.size() < target_count:
		chosen[local_rng.randi_range(0, candidates.size() - 1)] = true

	for candidate_index in chosen.keys():
		var entity_index: int = candidates[candidate_index]
		_damage_building(entity_index)
		damaged.append(entity_index)

	return damaged


func city_defense_score() -> int:
	var score := 0
	for entity in placed_buildings:
		if not _active_defense_entity(entity):
			continue

		var definition := building_definition_for_id(str(entity.get("building_id", "")))
		score += int(definition.get("defense_score", 0))
	return score


func building_damage_reduction() -> float:
	var reduction := 0.0
	for entity in placed_buildings:
		if not _active_defense_entity(entity):
			continue

		var definition := building_definition_for_id(str(entity.get("building_id", "")))
		reduction += float(definition.get("damage_reduction", 0.0))

	var max_reduction := float(game_data.defense_value("max_building_damage_reduction", 0.6))
	return minf(reduction, max_reduction)


func monster_charge_block_chance() -> float:
	var chance := 0.0
	for entity in placed_buildings:
		if not _active_defense_entity(entity):
			continue
		if _worker_role_for_id(str(entity.get("worker_id", ""))) != "warrior":
			continue

		var definition := building_definition_for_id(str(entity.get("building_id", "")))
		chance += float(definition.get("charge_block_chance", 0.0))
	return minf(chance, 0.75)


func defense_post_range_bonus_for_workplace_id(workplace_id: String) -> float:
	for entity in placed_buildings:
		var node: Node2D = entity.node
		if not is_instance_valid(node) or node.name != workplace_id:
			continue

		var definition := building_definition_for_id(str(entity.get("building_id", "")))
		return float(definition.get("archer_range_bonus", 0.0))
	return 0.0


func _active_defense_entity(entity: Dictionary) -> bool:
	if entity.get("damaged", false):
		return false
	if not entity.get("worker_inside", false):
		return false

	var definition := building_definition_for_id(str(entity.get("building_id", "")))
	return not definition.is_empty() and int(definition.get("defense_score", 0)) > 0


func repair_cost_for_entity_index(entity_index: int) -> int:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return 0

	var entity: Dictionary = placed_buildings[entity_index]
	var base_cost := _building_base_cost(entity.get("building_id", ""))
	return int(ceil(float(base_cost) * 0.5))


func repair_building(entity_index: int) -> bool:
	if not _is_repairable_damage(entity_index):
		return false

	var cost := repair_cost_for_entity_index(entity_index)
	if gold < cost:
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	gold -= cost
	entity.damaged = false
	if entity.get("building_id", "") == "wall":
		entity.wall_health = game_data.wall_health_for_level(int(entity.get("level", 1)))
	placed_buildings[entity_index] = entity
	var node: Node2D = entity.node
	if is_instance_valid(node):
		node.modulate = Color.WHITE
		visual_factory.set_occupied(node, false)
	if _work_site_has_any_worker(entity):
		_return_worker_to_repaired_entity(entity)

	_refresh_gold_ui()
	_refresh_info_panel()
	return true


func get_warrior_patrol_anchors() -> Dictionary:
	var center := _city_hall_position()
	var anchors := {
		"left": center + Vector2(-240.0, 0.0),
		"right": center + Vector2(240.0, 0.0),
	}
	var left_x := center.x
	var right_x := center.x

	for entity in placed_buildings:
		if entity.get("entity_kind", "") != "building":
			continue

		var node: Node2D = entity.node
		if not is_instance_valid(node):
			continue

		if node.global_position.x < left_x:
			left_x = node.global_position.x
			anchors.left = node.global_position
		elif node.global_position.x > right_x:
			right_x = node.global_position.x
			anchors.right = node.global_position

	return anchors


func _set_player_dead() -> void:
	player_dead = true
	autosave_game("death")
	_show_death_overlay()


func _show_death_overlay() -> void:
	if death_canvas != null or not is_inside_tree():
		return

	death_canvas = CanvasLayer.new()
	death_canvas.name = "DeathCanvas"
	death_canvas.layer = 100
	add_child(death_canvas)

	var blocker := ColorRect.new()
	blocker.name = "DeathOverlay"
	blocker.color = Color(0.02, 0.02, 0.03, 0.78)
	blocker.anchor_left = 0.0
	blocker.anchor_top = 0.0
	blocker.anchor_right = 1.0
	blocker.anchor_bottom = 1.0
	death_canvas.add_child(blocker)

	var panel := Control.new()
	panel.name = "DeathPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -210.0
	panel.offset_top = -120.0
	panel.offset_right = 210.0
	panel.offset_bottom = 120.0
	death_canvas.add_child(panel)

	var title := Label.new()
	title.name = "DeathTitle"
	title.text = "你已陨落"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 0)
	title.size = Vector2(420, 52)
	title.add_theme_font_size_override("font_size", 34)
	panel.add_child(title)

	_add_death_button(panel, "ReviveButton", "复活", Vector2(50, 72), Callable(self, "revive_player"))
	_add_death_button(panel, "MainMenuButton", "保存并退出", Vector2(50, 116), Callable(self, "_return_to_main_menu"))
	_add_death_button(panel, "QuitGameButton", "退出游戏", Vector2(50, 160), Callable(self, "_quit_game"))


func _add_death_button(parent_control: Control, button_name: String, text: String, position: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.position = position
	button.size = Vector2(320, 34)
	button.pressed.connect(callback)
	parent_control.add_child(button)


func _return_to_main_menu() -> void:
	autosave_game("manual")
	resume_game()
	if not is_inside_tree():
		return

	var tree := get_tree()

	var game_session := tree.root.get_node_or_null("GameSession")
	if game_session != null and game_session.has_method("clear_cached_main_scene"):
		game_session.clear_cached_main_scene()
	tree.change_scene_to_file(GameData.MAIN_MENU_SCENE_PATH)


func _quit_game() -> void:
	autosave_game("quit")
	if is_inside_tree():
		get_tree().quit()


func _toggle_pause_menu() -> void:
	if pause_panel != null:
		resume_game()
	else:
		_show_pause_menu()


func _is_tree_paused() -> bool:
	return is_inside_tree() and get_tree().paused


func _show_pause_menu() -> void:
	if pause_panel != null:
		return

	if is_inside_tree():
		get_tree().paused = true

	pause_canvas = CanvasLayer.new()
	pause_canvas.name = "PauseCanvas"
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_canvas)

	var overlay := ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.48)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_canvas.add_child(overlay)

	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -180.0
	pause_panel.offset_top = -150.0
	pause_panel.offset_right = 180.0
	pause_panel.offset_bottom = 150.0
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.add_child(pause_panel)

	var title := Label.new()
	title.name = "PauseTitle"
	title.text = "暂停"
	title.position = Vector2(28, 20)
	title.size = Vector2(304, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	pause_panel.add_child(title)

	_add_pause_button("ResumeButton", "继续", Vector2(60, 72), Callable(self, "resume_game"))
	_add_pause_button("LoadButton", "读取", Vector2(60, 120), Callable(self, "load_game_from_pause"))
	_add_pause_button("SaveButton", "存档", Vector2(60, 168), Callable(self, "save_game_from_pause"))
	_add_pause_button("PauseMainMenuButton", "保存并退出", Vector2(60, 216), Callable(self, "return_to_main_menu_from_pause"))


func _add_pause_button(button_name: String, text: String, position: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.position = position
	button.size = Vector2(240, 36)
	_configure_always_clickable_button(button)
	button.pressed.connect(callback)
	pause_panel.add_child(button)
	return button


func resume_game() -> void:
	if is_inside_tree():
		get_tree().paused = false
	_clear_pause_menu()


func save_game_from_pause() -> bool:
	return autosave_game("manual")


func load_game_from_pause() -> bool:
	if not load_last_save():
		return false

	resume_game()
	return true


func return_to_main_menu_from_pause() -> void:
	resume_game()
	_return_to_main_menu()


func _clear_pause_menu() -> void:
	if pause_canvas != null:
		pause_canvas.queue_free()
	pause_canvas = null
	pause_panel = null


func _clear_all_monsters() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var monster_manager := parent.get_node_or_null("MonsterManager")
	if monster_manager != null and monster_manager.has_method("clear_monsters"):
		monster_manager.clear_monsters()
		return

	var monsters := parent.get_node_or_null("Monsters")
	if monsters == null:
		return

	for child in monsters.get_children():
		child.queue_free()


func _damage_building(entity_index: int) -> void:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("entity_kind", "") != "building":
		return

	entity.damaged = true
	entity.level = max(1, int(entity.get("level", 1)) - 1)
	if entity.get("building_id", "") == "wall":
		entity.wall_health = 0
	var workers_inside := _work_site_workers_inside(entity)
	_set_work_site_workers(entity, _work_site_worker_ids(entity), [])
	placed_buildings[entity_index] = entity

	_apply_damaged_building_visual(entity)

	if not workers_inside.is_empty():
		_release_worker_from_damaged_entity(entity)


func _is_repairable_damage(entity_index: int) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	return entity.get("entity_kind", "") == "building" and entity.get("damaged", false)


func _building_base_cost(building_id: String) -> int:
	if building_id == "quarry":
		return int(game_data.quarry_value("cost", 0))
	if building_id == "farm":
		return int(game_data.farm_value("cost", 0))
	if building_id == "lumberyard":
		return int(game_data.lumberyard_value("cost", 0))

	for definition in catalog.get_buildings():
		if definition.get("id", "") == building_id:
			return int(definition.get("cost", 0))

	return 0


func _city_hall_position() -> Vector2:
	for entity in placed_buildings:
		if entity.get("entity_kind", "") != "cityhall":
			continue

		var node: Node2D = entity.node
		if is_instance_valid(node):
			return node.global_position

	var city_hall := get_parent().get_node_or_null("CityHall") if get_parent() != null else null
	if city_hall != null:
		return city_hall.global_position

	return Vector2(4800, 472)


func _update_farm_income(delta: float) -> void:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("building_id", "") != "farm":
			continue
		if _is_active_interior_entity(entity):
			continue
		if _has_background_interior_state(entity):
			continue
		if entity.get("damaged", false):
			continue
		var workers_inside := _work_site_workers_inside(entity)
		if workers_inside.is_empty():
			continue

		var worker_income_elapsed: Dictionary = entity.get("worker_income_elapsed", {})
		for worker_id in workers_inside:
			var elapsed := float(worker_income_elapsed.get(worker_id, 0.0)) + delta
			var income_seconds := _farm_income_seconds_for_worker(str(worker_id))
			while elapsed >= income_seconds:
				elapsed -= income_seconds
				add_gold(1)
			worker_income_elapsed[str(worker_id)] = elapsed
		entity.worker_income_elapsed = worker_income_elapsed
		entity.farm_income_elapsed = float(worker_income_elapsed.get(str(workers_inside[0]), 0.0))
		placed_buildings[i] = entity


func _farm_income_seconds_for_worker(worker_id: String) -> float:
	var multiplier := _worker_best_tool_multiplier(worker_id, "farm")
	if multiplier > 1.0:
		return FARM_INCOME_SECONDS / multiplier

	return FARM_INCOME_SECONDS


func _update_quarry_income(delta: float) -> void:
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if _is_active_interior_entity(entity):
			continue
		if _has_background_interior_state(entity):
			continue
		var income_data := _income_data_for_building(entity)
		if income_data.is_empty():
			continue
		if entity.get("damaged", false):
			continue
		if bool(income_data.get("requires_worker", true)) and not entity.get("worker_inside", false):
			continue

		entity.quarry_income_elapsed = float(entity.get("quarry_income_elapsed", 0.0)) + delta
		var income_seconds := float(income_data.get("income_seconds", 60.0))
		var income_gold := int(income_data.get("income_gold", 0))
		while entity.quarry_income_elapsed >= income_seconds:
			entity.quarry_income_elapsed -= income_seconds
			add_gold(income_gold)
		placed_buildings[i] = entity


func _income_data_for_building(entity: Dictionary) -> Dictionary:
	var building_id := str(entity.get("building_id", ""))
	if building_id == "quarry":
		return {
			"requires_worker": game_data.quarry_value("requires_worker", true),
			"income_seconds": game_data.quarry_value("income_seconds", 60.0),
			"income_gold": game_data.quarry_value("income_gold", 0),
		}

	var definition := building_definition_for_id(building_id)
	if definition.is_empty() or not definition.has("income_gold"):
		return {}
	var income_gold := int(definition.get("income_gold", 0))
	if trade_treaty_active:
		income_gold += int(definition.get("trade_bonus_gold", 0))
	return {
		"requires_worker": definition.get("work_role", "") != "",
		"income_seconds": definition.get("income_seconds", 60.0),
		"income_gold": income_gold,
	}


func _worker_best_tool_multiplier(worker_id: String, resource_kind: String) -> float:
	var best := 1.0
	for tool_id in game_data.tool_ids():
		if game_data.tool_resource_kind(tool_id) != resource_kind:
			continue
		if _worker_has_tool(worker_id, tool_id):
			best = maxf(best, game_data.tool_efficiency_multiplier(tool_id))

	return best


func _worker_has_tool(worker_id: String, tool_id: String) -> bool:
	var parent := get_parent()
	if parent == null:
		return false

	var npc_manager := parent.get_node_or_null("NPCManager")
	return npc_manager != null and npc_manager.has_method("worker_has_tool") and npc_manager.worker_has_tool(worker_id, tool_id)


func _update_lumberyards(delta: float) -> void:
	return


func _update_background_interiors(delta: float) -> void:
	if delta <= 0.0:
		return

	_ensure_collection_state()
	var active_building_node_name := _active_interior_building_node_name()
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if bool(entity.get("damaged", false)):
			continue

		var building_id := str(entity.get("building_id", ""))
		var interior_definition := game_data.building_interior_definition(building_id)
		var layout := str(interior_definition.get("layout", "shell"))
		if layout == "" or layout == "shell":
			continue

		var node: Node2D = entity.get("node", null)
		if active_building_node_name != "" and is_instance_valid(node) and node.name == active_building_node_name:
			continue

		var interior_state := _normalized_background_interior_state(entity, interior_definition)
		var workers_inside := _work_site_workers_inside(entity)
		match layout:
			"farm":
				_update_background_farm_state(interior_state, interior_definition, workers_inside, delta)
			"lumberyard", "quarry":
				_update_background_resource_room_state(interior_state, interior_definition, workers_inside, delta)
			"barracks":
				_update_background_barracks_state(interior_state, workers_inside, delta)
			_:
				continue

		entity.interior_state = interior_state
		placed_buildings[i] = entity
		_sync_barracks_training_to_npcs(entity)


func _active_interior_building_node_name() -> String:
	if not is_inside_tree():
		return ""

	var tree := get_tree()
	if tree == null:
		return ""

	var game_session := tree.root.get_node_or_null("GameSession")
	if game_session == null or not game_session.has_method("active_interior_context"):
		return ""

	var context: Dictionary = game_session.active_interior_context()
	return str(context.get("building_node_name", ""))


func _has_background_interior_state(entity: Dictionary) -> bool:
	if not (entity.get("interior_state", null) is Dictionary):
		return false

	var state: Dictionary = entity.get("interior_state", {})
	if state.is_empty():
		return false

	var layout := str(state.get("layout", ""))
	return layout == "farm" or layout == "lumberyard" or layout == "quarry" or layout == "barracks"


func _is_active_interior_entity(entity: Dictionary) -> bool:
	var active_building_node_name := _active_interior_building_node_name()
	if active_building_node_name == "":
		return false

	var node: Node2D = entity.get("node", null)
	return is_instance_valid(node) and node.name == active_building_node_name


func _normalized_background_interior_state(entity: Dictionary, interior_definition: Dictionary) -> Dictionary:
	var state := {}
	if entity.get("interior_state", null) is Dictionary:
		state = (entity.get("interior_state", {}) as Dictionary).duplicate(true)

	var layout := str(interior_definition.get("layout", "shell"))
	state.layout = layout
	if not (state.get("worker_seed_rewards", null) is Dictionary):
		state.worker_seed_rewards = {}

	if layout == "farm":
		var selected_crop_id := str(state.get("selected_crop_id", "wheat"))
		if selected_crop_id == "" or game_data.crop_definition(selected_crop_id).is_empty():
			selected_crop_id = "wheat"
		state.selected_crop_id = selected_crop_id

		var plots := []
		if state.get("plots", null) is Array:
			plots = (state.get("plots", []) as Array).duplicate(true)
		var plot_count := int(interior_definition.get("plot_count", 6))
		while plots.size() < plot_count:
			plots.append({
				"crop_id": selected_crop_id,
				"stage": "empty",
				"elapsed": 0.0,
				"action_elapsed": 0.0,
			})
		state.plots = plots
		if not (state.get("active_farm_task", null) is Dictionary):
			state.active_farm_task = {}
	elif layout == "lumberyard" or layout == "quarry":
		if not (state.get("resources", null) is Array):
			state.resources = []
		if not state.has("spawn_elapsed"):
			state.spawn_elapsed = 0.0
	elif layout == "barracks":
		if not (state.get("training_workers", null) is Dictionary):
			state.training_workers = {}

	return state


func _update_background_farm_state(
	interior_state: Dictionary,
	interior_definition: Dictionary,
	workers_inside: Array,
	delta: float
) -> void:
	var plots: Array = interior_state.get("plots", [])
	var cycle_seconds := float(interior_definition.get("cycle_seconds", 300.0))
	var sow_seconds := float(interior_definition.get("sow_action_seconds", 2.0))
	var harvest_seconds := float(interior_definition.get("harvest_action_seconds", 2.0))
	var grow_seconds := maxf(0.0, cycle_seconds - sow_seconds - harvest_seconds)
	var production_delta := delta * _best_background_worker_multiplier(workers_inside, "farm")

	_advance_background_farm_growth(plots, grow_seconds, production_delta)
	if workers_inside.is_empty():
		interior_state.plots = plots
		return

	var active_task = interior_state.get("active_farm_task", {})
	if not (active_task is Dictionary):
		active_task = {}
	var task: Dictionary = active_task
	if task.is_empty():
		task = _next_background_farm_task(plots, str(interior_state.get("selected_crop_id", "wheat")))
	if not task.is_empty():
		if _advance_background_farm_task(task, plots, production_delta, sow_seconds, harvest_seconds, interior_state, workers_inside):
			task = {}

	interior_state.active_farm_task = task
	interior_state.plots = plots


func _advance_background_farm_growth(plots: Array, grow_seconds: float, production_delta: float) -> void:
	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		if str(plot.get("stage", "empty")) != "growing":
			continue
		plot.elapsed = float(plot.get("elapsed", 0.0)) + production_delta
		if float(plot.elapsed) >= grow_seconds:
			plot.stage = "harvesting"
			plot.action_elapsed = 0.0
		plots[i] = plot


func _next_background_farm_task(plots: Array, selected_crop_id: String) -> Dictionary:
	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		if str(plot.get("stage", "empty")) == "harvesting":
			return {"type": "harvest", "plot_index": i}

	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		if str(plot.get("stage", "empty")) == "sowing":
			return {"type": "sow", "plot_index": i}

	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		if str(plot.get("stage", "empty")) != "empty":
			continue
		plot.crop_id = selected_crop_id
		plot.stage = "sowing"
		plot.elapsed = 0.0
		plot.action_elapsed = 0.0
		plots[i] = plot
		return {"type": "sow", "plot_index": i}

	return {}


func _advance_background_farm_task(
	task: Dictionary,
	plots: Array,
	production_delta: float,
	sow_seconds: float,
	harvest_seconds: float,
	interior_state: Dictionary,
	workers_inside: Array
) -> bool:
	var plot_index := int(task.get("plot_index", -1))
	if plot_index < 0 or plot_index >= plots.size():
		return true

	var plot: Dictionary = plots[plot_index]
	interior_state.worker_position = _background_farm_worker_position(plot_index)
	var task_type := str(task.get("type", ""))
	if task_type == "":
		task_type = "harvest" if str(plot.get("stage", "empty")) == "harvesting" else "sow"
	var action_seconds := harvest_seconds if task_type == "harvest" else sow_seconds
	plot.action_elapsed = float(plot.get("action_elapsed", 0.0)) + production_delta
	if float(plot.action_elapsed) >= action_seconds:
		if task_type == "harvest":
			add_gold(int(game_data.crop_value(str(plot.get("crop_id", "wheat")), "reward_gold", 1)))
			_try_award_background_worker_seed(interior_state, workers_inside, "harvest")
			plot.crop_id = str(interior_state.get("selected_crop_id", "wheat"))
			plot.stage = "empty"
		else:
			plot.stage = "growing"
		plot.elapsed = 0.0
		plot.action_elapsed = 0.0
		plots[plot_index] = plot
		return true

	plots[plot_index] = plot
	return false


func _update_background_resource_room_state(
	interior_state: Dictionary,
	interior_definition: Dictionary,
	workers_inside: Array,
	delta: float
) -> void:
	var resource_kind := str(interior_definition.get("resource_kind", "tree"))
	var resources: Array = interior_state.get("resources", [])
	var spawn_elapsed := float(interior_state.get("spawn_elapsed", 0.0)) + delta
	var spawn_seconds := float(interior_definition.get("spawn_seconds", 60.0))
	var spawn_count := int(interior_definition.get("spawn_count", 1))
	var max_resources := int(interior_definition.get("max_resources", 3))
	while spawn_elapsed >= spawn_seconds:
		spawn_elapsed -= spawn_seconds
		for i in range(spawn_count):
			if resources.size() >= max_resources:
				break
			resources.append({
				"id": "%s_%d" % [resource_kind, Time.get_ticks_msec() + resources.size()],
				"kind": resource_kind,
				"progress": 0.0,
				"x": 520.0 + float(resources.size() % max_resources) * 180.0,
			})
	interior_state.spawn_elapsed = spawn_elapsed

	if not workers_inside.is_empty() and not resources.is_empty():
		var target: Dictionary = resources[0]
		interior_state.worker_position = _background_resource_worker_position(target)
		var duration := game_data.resource_npc_seconds(resource_kind) / maxf(0.01, _best_background_worker_multiplier(workers_inside, resource_kind))
		target.progress = float(target.get("progress", 0.0)) + delta / maxf(0.01, duration)
		if float(target.progress) >= 1.0:
			add_gold(game_data.resource_gold_reward(resource_kind))
			_try_award_background_worker_seed(interior_state, workers_inside, "tree_chop" if resource_kind == "tree" else "stone_mine")
			resources.remove_at(0)
		else:
			resources[0] = target
	interior_state.resources = resources


func _update_background_barracks_state(interior_state: Dictionary, workers_inside: Array, delta: float) -> void:
	var training_workers: Dictionary = interior_state.get("training_workers", {})
	for worker_id_value in workers_inside:
		var worker_id := str(worker_id_value)
		if worker_id == "":
			continue
		var record: Dictionary = training_workers.get(worker_id, {})
		var elapsed := float(record.get("elapsed", 0.0)) + delta
		record.elapsed = elapsed
		record.level = game_data.barracks_training_level_for_elapsed(elapsed)
		training_workers[worker_id] = record
	for worker_id in training_workers.keys():
		if not workers_inside.has(str(worker_id)):
			training_workers.erase(worker_id)
	interior_state.training_workers = training_workers


func _sync_barracks_training_to_npcs(entity: Dictionary) -> void:
	if str(entity.get("building_id", "")) != "barracks":
		return
	if not (entity.get("interior_state", null) is Dictionary):
		return
	var interior_state: Dictionary = entity.get("interior_state", {})
	var training_workers: Dictionary = interior_state.get("training_workers", {})
	if training_workers.is_empty():
		return
	var parent := get_parent()
	if parent == null:
		return
	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager != null and npc_manager.has_method("apply_soldier_training_records"):
		npc_manager.apply_soldier_training_records(training_workers)


func _background_farm_worker_position(plot_index: int) -> Array:
	var position := game_data.interior_farm_worker_position(plot_index)
	return [position.x, position.y]


func _background_resource_worker_position(resource: Dictionary) -> Array:
	var position := game_data.interior_resource_worker_position(float(resource.get("x", 520.0)))
	return [position.x, position.y]


func _best_background_worker_multiplier(workers_inside: Array, resource_kind: String) -> float:
	var best := 1.0
	for worker_id_value in workers_inside:
		best = maxf(best, _worker_best_tool_multiplier(str(worker_id_value), resource_kind))
	return best


func _try_award_background_worker_seed(interior_state: Dictionary, workers_inside: Array, activity_id: String) -> void:
	if workers_inside.is_empty():
		return

	var seed_id := collection_rules.seed_drop_from_rolls(
		activity_id,
		randf(),
		randf(),
		unlocked_crops,
		game_data
	)
	if seed_id == "":
		return

	var rewards: Dictionary = interior_state.get("worker_seed_rewards", {})
	var worker_id := str(workers_inside[0])
	if str(rewards.get(worker_id, "")) == "":
		rewards[worker_id] = seed_id
	interior_state.worker_seed_rewards = rewards


func _spawn_lumberyard_trees(lumberyard_index: int) -> int:
	if lumberyard_index < 0 or lumberyard_index >= placed_buildings.size() or buildings_container == null:
		return 0

	var entity: Dictionary = placed_buildings[lumberyard_index]
	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return 0

	var resource_kind := _lumberyard_resource_kind(entity)
	var resource_size := game_data.resource_size(resource_kind)
	var source_position := _lumberyard_growth_source_position(entity, node.global_position)
	var growth_radius := _lumberyard_growth_radius(entity)
	var positions: Array = rules.tree_positions_around_source(
		TREE_RANDOM_SEED + tree_sequence + lumberyard_index + 1,
		LUMBERYARD_TREE_BATCH_COUNT,
		source_position,
		growth_radius,
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y,
		resource_size,
		placed_footprints
	)

	for position in positions:
		if resource_kind == "stone":
			_spawn_stone_at(position)
		else:
			_spawn_tree_at(position)

	return positions.size()


func _spawn_tree_at(tree_position: Vector2) -> Node2D:
	if buildings_container == null:
		return null

	var tree := tree_factory.create_tree_visual()
	tree.name = _next_tree_name()
	tree.position = buildings_container.to_local(tree_position)
	buildings_container.add_child(tree)
	_track_placed_entity(
		tree,
		rules.footprint_for_position(tree_position, TREE_SIZE),
		true,
		"树",
		"tree",
		false,
		"tree",
		"tree"
	)
	return tree


func _spawn_stone_at(stone_position: Vector2) -> Node2D:
	if buildings_container == null:
		return null

	var stone := tree_factory.create_stone_visual()
	stone.name = _next_stone_name()
	stone.position = buildings_container.to_local(stone_position)
	buildings_container.add_child(stone)
	_track_placed_entity(
		stone,
		rules.footprint_for_position(stone_position, STONE_SIZE),
		true,
		game_data.resource_display_name("stone"),
		"stone",
		false,
		"stone",
		"stone"
	)
	return stone


func _next_tree_name() -> String:
	while true:
		tree_sequence += 1
		var candidate := "Tree_%02d" % tree_sequence
		if not _building_container_has_node_name(candidate):
			return candidate

	return "Tree_%02d" % tree_sequence


func _next_stone_name() -> String:
	while true:
		tree_sequence += 1
		var candidate := "Stone_%02d" % tree_sequence
		if not _building_container_has_node_name(candidate):
			return candidate

	return "Stone_%02d" % tree_sequence


func _building_container_has_node_name(node_name: String) -> bool:
	if buildings_container == null:
		return false

	for child in buildings_container.get_children():
		if child.name == node_name:
			return true

	return false


func _dispatch_lumberjacks() -> void:
	for i in range(placed_buildings.size()):
		var lumberyard: Dictionary = placed_buildings[i]
		if lumberyard.get("building_id", "") != "lumberyard":
			continue
		if lumberyard.get("damaged", false):
			continue
		if not lumberyard.get("worker_inside", false):
			continue
		if lumberyard.get("worker_id", "") == "":
			continue

		var tree_index := _nearest_tree_index_near_lumberyard(i)
		if tree_index == -1:
			continue

		_start_lumberjack_tree_chop_task(tree_index, i)


func _lumberyard_resource_kind(lumberyard: Dictionary) -> String:
	return game_data.lumberyard_resource_kind(int(lumberyard.get("level", 1)))


func _lumberyard_worker_role(lumberyard: Dictionary) -> String:
	return game_data.lumberyard_worker_role(int(lumberyard.get("level", 1)))


func _lumberyard_growth_source_position(lumberyard: Dictionary, fallback_position: Vector2) -> Vector2:
	var mother_tree_name := str(lumberyard.get("source_mother_tree_name", ""))
	if mother_tree_name == "":
		return fallback_position

	for entity in placed_buildings:
		if entity.get("entity_kind", "") != "mother_tree":
			continue
		var node: Node2D = entity.node
		if is_instance_valid(node) and node.name == mother_tree_name:
			return node.global_position

	return fallback_position


func _lumberyard_growth_radius(lumberyard: Dictionary) -> float:
	if str(lumberyard.get("source_mother_tree_name", "")) != "":
		return MOTHER_TREE_GROW_RADIUS

	return LUMBERYARD_TREE_RADIUS


func _lumberjack_search_radius(lumberyard: Dictionary) -> float:
	if str(lumberyard.get("source_mother_tree_name", "")) != "":
		return MOTHER_TREE_LUMBERJACK_SEARCH_RADIUS

	return LUMBERJACK_TREE_SEARCH_RADIUS


func _is_resource_entity(entity: Dictionary) -> bool:
	var resource_kind: String = entity.get("resource_kind", "")
	return resource_kind == "tree" or resource_kind == "stone"


func _nearest_tree_index_near_lumberyard(lumberyard_index: int) -> int:
	if lumberyard_index < 0 or lumberyard_index >= placed_buildings.size():
		return -1

	var lumberyard: Dictionary = placed_buildings[lumberyard_index]
	var lumberyard_node: Node2D = lumberyard.node
	if not is_instance_valid(lumberyard_node):
		return -1
	var resource_kind := _lumberyard_resource_kind(lumberyard)
	var source_position := _lumberyard_growth_source_position(lumberyard, lumberyard_node.global_position)
	var search_radius := _lumberjack_search_radius(lumberyard)

	var nearest_index := -1
	var nearest_distance := INF
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("resource_kind", "") != resource_kind:
			continue

		var tree_node: Node2D = entity.node
		if not is_instance_valid(tree_node):
			continue
		if _tree_chop_task_index(tree_node.name) != -1:
			continue

		var distance := source_position.distance_to(tree_node.global_position)
		if distance > search_radius:
			continue
		if distance < nearest_distance:
			nearest_index = i
			nearest_distance = distance

	return nearest_index


func _start_lumberjack_tree_chop_task(tree_index: int, lumberyard_index: int) -> void:
	if tree_index < 0 or tree_index >= placed_buildings.size():
		return
	if lumberyard_index < 0 or lumberyard_index >= placed_buildings.size():
		return

	var tree_entity: Dictionary = placed_buildings[tree_index]
	var lumberyard: Dictionary = placed_buildings[lumberyard_index]
	var tree_node: Node2D = tree_entity.node
	var lumberyard_node: Node2D = lumberyard.node
	if not is_instance_valid(tree_node) or not is_instance_valid(lumberyard_node):
		return

	var worker_id: String = lumberyard.get("worker_id", "")
	if worker_id == "":
		return

	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("assign_lumberjack_tree_chop"):
		return

	var task_id := tree_node.name
	if _tree_chop_task_index(task_id) != -1:
		return
	var resource_kind: String = tree_entity.get("resource_kind", tree_entity.get("entity_kind", "tree"))

	if not npc_manager.assign_lumberjack_tree_chop(
		worker_id,
		task_id,
		tree_node.global_position,
		lumberyard_node.global_position,
		_work_site_display_name(lumberyard),
		lumberyard_node.name,
		_lumberyard_worker_role(lumberyard)
	):
		return

	tree_chop_tasks.append({
		"task_id": task_id,
		"node": tree_node,
		"footprint": tree_entity.footprint,
		"position": tree_node.global_position,
		"progress": 0.0,
		"assigned_worker_id": worker_id,
		"source": "lumberyard",
		"resource_kind": resource_kind,
	})
	var worker_ids := _work_site_worker_ids(lumberyard)
	var workers_inside := _work_site_workers_inside(lumberyard)
	workers_inside.erase(worker_id)
	_set_work_site_workers(lumberyard, worker_ids, workers_inside)
	placed_buildings[lumberyard_index] = lumberyard
	visual_factory.set_occupied(lumberyard_node, not workers_inside.is_empty())


func get_tree_chop_task_for_point(point: Vector2) -> String:
	for task in tree_chop_tasks:
		var footprint: Rect2 = task.footprint
		if _rect_contains_point_inclusive(footprint, point):
			return task.task_id

	return ""


func advance_tree_chop(task_id: String, delta: float, duration_seconds: float) -> bool:
	var task_index := _tree_chop_task_index(task_id)
	if task_index == -1 or duration_seconds <= 0.0:
		return false

	var task: Dictionary = tree_chop_tasks[task_index]
	task.progress = min(1.0, float(task.get("progress", 0.0)) + delta / duration_seconds)
	tree_chop_tasks[task_index] = task
	if task.progress < 1.0:
		return false

	_complete_tree_chop(task_index)
	return true


func resource_kind_for_task(task_id: String) -> String:
	var task_index := _tree_chop_task_index(task_id)
	if task_index == -1:
		return "tree"

	return str(tree_chop_tasks[task_index].get("resource_kind", "tree"))


func resource_player_duration_for_task(task_id: String) -> float:
	return game_data.resource_player_seconds(resource_kind_for_task(task_id))


func _start_tree_chop_task(entity_index: int) -> void:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return

	var entity: Dictionary = placed_buildings[entity_index]
	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return

	var task_id := node.name
	if _tree_chop_task_index(task_id) != -1:
		return

	node.modulate = DEMOLITION_PREVIEW_COLOR
	var task := {
		"task_id": task_id,
		"node": node,
		"footprint": entity.footprint,
		"position": node.global_position,
		"progress": 0.0,
		"assigned_worker_id": "",
		"resource_kind": entity.get("resource_kind", entity.get("entity_kind", "tree")),
	}
	tree_chop_tasks.append(task)
	_assign_tree_chopper_to_task(tree_chop_tasks.size() - 1)


func _assign_tree_chopper_to_task(task_index: int) -> void:
	if task_index < 0 or task_index >= tree_chop_tasks.size():
		return

	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("assign_tree_chopper"):
		return

	var task: Dictionary = tree_chop_tasks[task_index]
	var worker_id: String = npc_manager.assign_tree_chopper(task.task_id, task.position)
	if worker_id == "":
		return

	task.assigned_worker_id = worker_id
	tree_chop_tasks[task_index] = task


func _assign_waiting_tree_choppers() -> void:
	for i in range(tree_chop_tasks.size()):
		var task: Dictionary = tree_chop_tasks[i]
		if task.get("assigned_worker_id", "") != "":
			continue

		_assign_tree_chopper_to_task(i)


func _complete_tree_chop(task_index: int) -> void:
	if task_index < 0 or task_index >= tree_chop_tasks.size():
		return

	var task: Dictionary = tree_chop_tasks[task_index]
	var node: Node2D = task.node
	var entity_index := _placed_entity_index_for_node(node)
	if entity_index != -1:
		var entity: Dictionary = placed_buildings[entity_index]
		placed_buildings.remove_at(entity_index)
		_remove_placed_footprint(entity.footprint)

	if is_instance_valid(node):
		if node.is_inside_tree():
			node.queue_free()
		else:
			node.free()

	var resource_kind: String = task.get("resource_kind", "tree")
	tree_chop_tasks.remove_at(task_index)
	add_gold(game_data.resource_gold_reward(resource_kind))
	if task.get("assigned_worker_id", "") != "":
		_notify_tree_chop_completed(task.assigned_worker_id)


func _notify_tree_chop_completed(worker_id: String) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager != null and npc_manager.has_method("finish_tree_chop_for_worker"):
		npc_manager.finish_tree_chop_for_worker(worker_id)


func _update_player_tree_chop(delta: float) -> void:
	if player_tree_task_id == "":
		return

	if player == null or get_tree_chop_task_for_point(player.global_position) != player_tree_task_id:
		player_tree_task_id = ""
		return

	if advance_tree_chop(player_tree_task_id, delta, resource_player_duration_for_task(player_tree_task_id)):
		player_tree_task_id = ""


func _try_start_player_tree_chop() -> bool:
	var task_id := _tree_task_for_player()
	if task_id == "":
		return false

	player_tree_task_id = task_id
	_update_preview()
	return true


func _tree_task_for_player() -> String:
	if player == null:
		return ""

	return get_tree_chop_task_for_point(player.global_position)


func _tree_chop_progress(task_id: String) -> float:
	var task_index := _tree_chop_task_index(task_id)
	if task_index == -1:
		return 0.0

	return float(tree_chop_tasks[task_index].get("progress", 0.0))


func _tree_chop_task_index(task_id: String) -> int:
	for i in range(tree_chop_tasks.size()):
		if tree_chop_tasks[i].get("task_id", "") == task_id:
			return i

	return -1


func _placed_entity_index_for_node(node: Node2D) -> int:
	for i in range(placed_buildings.size()):
		if placed_buildings[i].get("node") == node:
			return i

	return -1


func _resolved_building_id(entity: Node2D, display_name: String, entity_kind: String, building_id: String) -> String:
	if building_id != "":
		return building_id
	if entity_kind == "tree":
		return "tree"
	if entity_kind == "stone":
		return "stone"
	if entity_kind == "cityhall":
		return "cityhall"
	if entity.name.begins_with("blacksmith"):
		return "blacksmith"
	if entity.name.begins_with("wall"):
		return "wall"
	if entity.name.begins_with("farm"):
		return "farm"
	if entity.name.begins_with("tavern"):
		return "tavern"
	if entity.name.begins_with("lumberyard"):
		return "lumberyard"
	if entity.name.begins_with("quarry"):
		return "quarry"

	match display_name:
		"铁匠铺":
			return "blacksmith"
		"城墙":
			return "wall"
		"农田":
			return "farm"
		"酒馆":
			return "tavern"
		_:
			return ""


func _rect_contains_point_inclusive(rect: Rect2, point: Vector2) -> bool:
	return (
		point.x >= rect.position.x
		and point.x <= rect.position.x + rect.size.x
		and point.y >= rect.position.y
		and point.y <= rect.position.y + rect.size.y
	)


func _remove_placed_footprint(footprint: Rect2) -> void:
	var footprint_index := placed_footprints.find(footprint)
	if footprint_index != -1:
		placed_footprints.remove_at(footprint_index)


func _replace_placed_footprint(old_footprint: Rect2, new_footprint: Rect2) -> void:
	var footprint_index := placed_footprints.find(old_footprint)
	if footprint_index != -1:
		placed_footprints[footprint_index] = new_footprint
	else:
		placed_footprints.append(new_footprint)


func _npc_manager() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("NPCManager")


func _release_worker_from_demolished_entity(entity: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("release_worker_from_demolished_building"):
		return

	var node: Node2D = entity.node
	var spawn_position := Vector2.ZERO
	if is_instance_valid(node):
		spawn_position = node.global_position

	for worker_id in _work_site_workers_inside(entity):
		npc_manager.release_worker_from_demolished_building(str(worker_id), spawn_position)


func _release_worker_from_damaged_entity(entity: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("release_worker_from_damaged_building"):
		return

	var node: Node2D = entity.node
	var spawn_position := Vector2.ZERO
	var workplace_id := ""
	if is_instance_valid(node):
		spawn_position = node.global_position
		workplace_id = node.name

	for worker_id in _work_site_worker_ids(entity):
		npc_manager.release_worker_from_damaged_building(
			str(worker_id),
			spawn_position,
			entity.get("display_name", ""),
			workplace_id
		)


func _return_worker_to_repaired_entity(entity: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("return_worker_to_repaired_building"):
		return

	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return

	for worker_id in _work_site_worker_ids(entity):
		npc_manager.return_worker_to_repaired_building(
			str(worker_id),
			node.global_position,
			entity.get("display_name", ""),
			node.name
		)


func _cancel_worker_assignment_from_demolished_entity(entity: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("cancel_worker_assignment_from_demolished_building"):
		return

	var workers_inside := _work_site_workers_inside(entity)
	for worker_id in _work_site_worker_ids(entity):
		if workers_inside.has(worker_id):
			continue
		npc_manager.cancel_worker_assignment_from_demolished_building(str(worker_id))


func _apply_building_orientation(building: Node2D, building_id: String, building_position: Vector2) -> void:
	if building == null:
		return

	building.scale = game_data.oriented_building_scale(
		building_id,
		building_position,
		_city_hall_position(),
		building.scale
	)


func _building_footprint_size(definition: Dictionary) -> Vector2:
	if game_data.has_method("building_body_size"):
		return game_data.building_body_size(definition)
	return definition.get("size", Vector2.ZERO)


func _get_player_facing_direction() -> int:
	if player != null and player.has_method("get_facing_direction"):
		return player.get_facing_direction()

	return 1


func _has_npc_interaction() -> bool:
	var npc_manager := _npc_manager()
	return npc_manager != null and npc_manager.has_method("has_interactable_homeless") and npc_manager.has_interactable_homeless()


func _refresh_building_choices() -> void:
	var all_buildings := catalog.get_buildings()
	buildings.clear()
	for definition in all_buildings:
		var required_terrain := str(definition.get("terrain_required", ""))
		if required_terrain == "" or required_terrain == city_terrain:
			buildings.append(definition)

	if selected_index >= buildings.size():
		selected_index = -1
	_sync_build_ui_slots()


func _sync_build_ui_slots() -> void:
	if ui_slots.is_empty():
		return

	var bar := get_node_or_null("BuildUI/BuildBar")
	if bar == null:
		return

	for slot in ui_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	ui_slots.clear()

	for i in range(buildings.size()):
		_add_build_slot(bar)


func _add_build_slot(bar: HBoxContainer) -> void:
	var slot := Label.new()
	slot.custom_minimum_size = Vector2(150, 42)
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_theme_font_size_override("font_size", 18)
	bar.add_child(slot)
	ui_slots.append(slot)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "BuildUI"
	add_child(canvas)

	var background := ColorRect.new()
	background.name = "BuildBarBackground"
	background.anchor_left = 0.0
	background.anchor_top = 1.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.offset_top = -88.0
	background.color = Color(0.04, 0.05, 0.05, 0.76)
	canvas.add_child(background)

	var bar := HBoxContainer.new()
	bar.name = "BuildBar"
	bar.anchor_left = 0.0
	bar.anchor_top = 1.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 24.0
	bar.offset_top = -74.0
	bar.offset_right = -24.0
	bar.offset_bottom = -24.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	canvas.add_child(bar)

	for i in range(buildings.size()):
		_add_build_slot(bar)

	status_label = Label.new()
	status_label.name = "BuildStatus"
	status_label.anchor_left = 0.0
	status_label.anchor_top = 1.0
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 1.0
	status_label.offset_top = -104.0
	status_label.offset_bottom = -84.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(status_label)

	gold_label = Label.new()
	gold_label.name = "GoldStatus"
	gold_label.anchor_left = 0.0
	gold_label.anchor_top = 1.0
	gold_label.anchor_right = 0.0
	gold_label.anchor_bottom = 1.0
	gold_label.offset_left = 24.0
	gold_label.offset_top = -106.0
	gold_label.offset_right = 240.0
	gold_label.offset_bottom = -84.0
	gold_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(gold_label)
	_refresh_gold_ui()

	var test_button := Button.new()
	test_button.name = "TestButton"
	test_button.text = "测试"
	test_button.position = Vector2(24, 24)
	test_button.size = Vector2(76, 32)
	_configure_always_clickable_button(test_button)
	test_button.pressed.connect(Callable(self, "_toggle_test_panel"))
	canvas.add_child(test_button)


func _refresh_ui() -> void:
	for i in range(ui_slots.size()):
		var definition: Dictionary = buildings[i]
		var slot: Label = ui_slots[i]
		slot.text = "%d %s %d金" % [i + 1, definition.display_name, int(definition.get("cost", 0))]
		if i == selected_index:
			slot.text = "[%s]" % slot.text
		if not can_build_definition(definition):
			slot.add_theme_color_override("font_color", Color(0.52, 0.56, 0.55, 1))
		elif i == selected_index:
			slot.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1))
		else:
			slot.add_theme_color_override("font_color", Color(0.92, 0.95, 0.94, 1))


func _refresh_gold_ui() -> void:
	if gold_label != null:
		gold_label.text = "金币：%d" % gold


func _toggle_test_panel() -> void:
	if test_panel != null:
		_clear_test_panel()
	else:
		_show_test_panel()


func _show_test_panel() -> void:
	_clear_test_panel()

	var canvas := get_node_or_null("BuildUI")
	if canvas == null:
		return

	test_panel = Control.new()
	test_panel.name = "TestPanel"
	test_panel.position = Vector2(24, 64)
	test_panel.size = Vector2(330, 236)
	test_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(test_panel)

	var background := ColorRect.new()
	background.name = "TestPanelBackground"
	background.color = Color(0.04, 0.05, 0.06, 0.9)
	background.size = test_panel.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	test_panel.add_child(background)

	_add_test_panel_label("测试面板", Vector2(16, 12), 18, Vector2(140, 26))
	_add_test_panel_label("金币数量", Vector2(16, 52), 14, Vector2(90, 24))
	test_gold_amount_spinbox = _add_test_spinbox("GoldAmountSpinBox", Vector2(112, 48), 1, 999, 10)
	_add_test_panel_button("AddGoldButton", "+金币", Vector2(206, 48), Callable(self, "_adjust_test_gold").bind(1), Vector2(92, 28))
	_add_test_panel_button("RemoveGoldButton", "-金币", Vector2(206, 82), Callable(self, "_adjust_test_gold").bind(-1), Vector2(92, 28))

	_add_test_panel_label("怪物数量", Vector2(16, 128), 14, Vector2(90, 24))
	test_monster_count_spinbox = _add_test_spinbox("MonsterCountSpinBox", Vector2(112, 124), 1, 4, 1)
	_add_test_panel_button("SpawnLeftMonsterButton", "左侧怪物", Vector2(16, 166), Callable(self, "test_spawn_monsters").bind("left"), Vector2(92, 28))
	_add_test_panel_button("SpawnRightMonsterButton", "右侧怪物", Vector2(118, 166), Callable(self, "test_spawn_monsters").bind("right"), Vector2(92, 28))
	_add_test_panel_button("SpawnBothMonsterButton", "两侧怪物", Vector2(220, 166), Callable(self, "test_spawn_monsters").bind("both"), Vector2(92, 28))


func _clear_test_panel() -> void:
	if test_panel != null:
		test_panel.queue_free()
	test_panel = null
	test_gold_amount_spinbox = null
	test_monster_count_spinbox = null


func _add_test_panel_label(text: String, position: Vector2, font_size: int, label_size := Vector2(120, 24)) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.96, 1))
	test_panel.add_child(label)
	return label


func _add_test_spinbox(spinbox_name: String, position: Vector2, min_value: int, max_value: int, default_value: int) -> SpinBox:
	var spinbox := SpinBox.new()
	spinbox.name = spinbox_name
	spinbox.position = position
	spinbox.size = Vector2(76, 28)
	spinbox.min_value = min_value
	spinbox.max_value = max_value
	spinbox.step = 1
	spinbox.value = default_value
	spinbox.mouse_filter = Control.MOUSE_FILTER_STOP
	spinbox.focus_mode = Control.FOCUS_ALL
	test_panel.add_child(spinbox)
	return spinbox


func _add_test_panel_button(button_name: String, text: String, position: Vector2, callback: Callable, size := Vector2(92, 28)) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.position = position
	button.size = size
	_configure_always_clickable_button(button)
	button.pressed.connect(callback)
	test_panel.add_child(button)
	return button


func _configure_always_clickable_button(button: Button) -> void:
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 13)


func _adjust_test_gold(sign: int) -> void:
	var amount := 10
	if test_gold_amount_spinbox != null:
		amount = int(test_gold_amount_spinbox.value)

	gold = max(0, gold + sign * amount)
	_refresh_gold_ui()
	_refresh_ui()
	_update_preview()


func test_spawn_monsters(side: String) -> int:
	var count := 1
	if test_monster_count_spinbox != null:
		count = int(test_monster_count_spinbox.value)

	var monster_manager := get_parent().get_node_or_null("MonsterManager") if get_parent() != null else null
	if monster_manager == null or not monster_manager.has_method("spawn_monsters"):
		return 0

	if side == "both":
		monster_manager.spawn_monsters("left", count)
		monster_manager.spawn_monsters("right", count)
		return count * 2
	if side == "left" or side == "right":
		monster_manager.spawn_monsters(side, count)
		return count

	return 0
