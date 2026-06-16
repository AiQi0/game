extends Node2D

const BuildingCatalog = preload("res://scripts/BuildingCatalog.gd")
const BuildingVisualFactory = preload("res://scripts/BuildingVisualFactory.gd")
const BuildRules = preload("res://scripts/BuildRules.gd")
const TreeFactory = preload("res://scripts/TreeFactory.gd")

const GROUND_MIN_X := 0.0
const GROUND_MAX_X := 9600.0
const GROUND_TOP_Y := 472.0
const AIR_WALL_WIDTH := 96.0
const AIR_WALL_HEIGHT := 1000.0
const CITY_HALL_SIZE := Vector2(400, 334)
const TREE_SIZE := Vector2(64, 120)
const TREE_COUNT := 18
const TREE_RANDOM_SEED := 20260616
const VALID_PREVIEW_COLOR := Color(0.25, 1.0, 0.3, 0.45)
const INVALID_PREVIEW_COLOR := Color(1.0, 0.15, 0.1, 0.45)
const DEMOLITION_PREVIEW_COLOR := Color(1.0, 0.08, 0.05, 0.45)

var catalog := BuildingCatalog.new()
var visual_factory := BuildingVisualFactory.new()
var tree_factory := TreeFactory.new()
var rules := BuildRules.new()

var buildings: Array = []
var placed_buildings: Array = []
var placed_footprints: Array = []
var selected_index := 0
var preview: Node2D
var preview_valid := false
var player: CharacterBody2D
var buildings_container: Node2D
var ui_slots: Array = []
var status_label: Label
var demolition_target_index := -1
var demolition_original_modulate := Color.WHITE


func _ready() -> void:
	player = get_parent().get_node_or_null("Player")
	buildings_container = get_parent().get_node_or_null("Buildings")
	buildings = catalog.get_buildings()

	_seed_existing_buildings()
	_spawn_trees()
	_create_ui()
	_recreate_preview()
	_refresh_ui()
	_update_preview()


func _process(_delta: float) -> void:
	if demolition_target_index != -1 and not _player_inside_demolition_target():
		_cancel_demolition()

	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var requested_index := rules.selected_index_from_key(key_event.keycode)
	if requested_index != -1:
		_select_building(requested_index)
		return

	if key_event.keycode == KEY_E:
		if demolition_target_index != -1:
			_cancel_demolition()
		elif _has_npc_interaction():
			return
		else:
			_try_build()
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
			false
		)


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
			false
		)


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

	preview = visual_factory.create_building_visual(buildings[selected_index])
	preview.name = "BuildPreview"
	preview.z_index = 4
	preview.modulate = VALID_PREVIEW_COLOR
	add_child(preview)


func _clear_preview() -> void:
	if preview != null:
		preview.queue_free()
		preview = null


func _update_preview() -> void:
	if status_label == null:
		return

	if demolition_target_index != -1:
		status_label.text = "Q 拆除 / E 取消"
		return

	if selected_index == -1:
		preview_valid = false
		status_label.text = "1-4 选择建筑 / Q 拆除"
		return

	if player == null or preview == null:
		return

	var definition: Dictionary = buildings[selected_index]
	var build_position := rules.build_position_for_player(
		player.global_position,
		_get_player_facing_direction(),
		definition.size,
		GROUND_TOP_Y
	)
	var footprint := rules.footprint_for_position(build_position, definition.size)

	preview.global_position = build_position
	preview_valid = not rules.has_overlap(footprint, placed_footprints)
	preview.modulate = VALID_PREVIEW_COLOR if preview_valid else INVALID_PREVIEW_COLOR
	status_label.text = "E 建造" if preview_valid else "位置重叠，无法建造"


func _try_build() -> void:
	if selected_index == -1:
		return

	_update_preview()
	if not preview_valid or buildings_container == null:
		return

	var definition: Dictionary = buildings[selected_index]
	var building := visual_factory.create_building_visual(definition)
	building.name = "%s_%d" % [definition.id, placed_footprints.size()]
	building.position = buildings_container.to_local(preview.global_position)
	buildings_container.add_child(building)

	_track_placed_entity(
		building,
		rules.footprint_for_position(preview.global_position, definition.size),
		true,
		definition.display_name,
		"building",
		true
	)
	_update_preview()


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
	var target: Node2D = entity.node
	if entity.get("worker_id", "") != "":
		if entity.get("worker_inside", false):
			_release_worker_from_demolished_entity(entity)
		else:
			_cancel_worker_assignment_from_demolished_entity(entity)

	if is_instance_valid(target):
		target.queue_free()

	placed_buildings.remove_at(demolition_target_index)
	_remove_placed_footprint(entity.footprint)
	demolition_target_index = -1
	demolition_original_modulate = Color.WHITE
	_update_preview()


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
	is_workplace: bool
) -> void:
	placed_buildings.append({
		"node": entity,
		"footprint": footprint,
		"demolishable": demolishable,
		"display_name": display_name,
		"entity_kind": entity_kind,
		"is_workplace": is_workplace,
		"worker_id": "",
		"worker_inside": false,
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

		var node: Node2D = entity.node
		if not is_instance_valid(node):
			continue

		sites.append({
			"entity_index": i,
			"display_name": entity.display_name,
			"workplace_id": node.name,
			"position": node.global_position,
			"is_workplace": true,
			"worker_id": entity.get("worker_id", ""),
			"worker_inside": entity.get("worker_inside", false),
		})

	return sites


func claim_work_site(entity_index: int, worker_id: String) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if not entity.get("is_workplace", false):
		return false
	if entity.get("worker_id", "") != "":
		return false

	entity.worker_id = worker_id
	entity.worker_inside = false
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
		if entity.get("worker_id", "") != worker_id:
			return false

		entity.worker_inside = true
		placed_buildings[i] = entity
		visual_factory.set_occupied(node, true)
		return true

	return false


func _remove_placed_footprint(footprint: Rect2) -> void:
	var footprint_index := placed_footprints.find(footprint)
	if footprint_index != -1:
		placed_footprints.remove_at(footprint_index)


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

	npc_manager.release_worker_from_demolished_building(entity.worker_id, spawn_position)


func _cancel_worker_assignment_from_demolished_entity(entity: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var npc_manager := parent.get_node_or_null("NPCManager")
	if npc_manager == null or not npc_manager.has_method("cancel_worker_assignment_from_demolished_building"):
		return

	npc_manager.cancel_worker_assignment_from_demolished_building(entity.worker_id)


func _get_player_facing_direction() -> int:
	if player != null and player.has_method("get_facing_direction"):
		return player.get_facing_direction()

	return 1


func _has_npc_interaction() -> bool:
	var npc_manager := get_parent().get_node_or_null("NPCManager")
	return npc_manager != null and npc_manager.has_method("has_interactable_homeless") and npc_manager.has_interactable_homeless()


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
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(150, 42)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", 18)
		bar.add_child(slot)
		ui_slots.append(slot)

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


func _refresh_ui() -> void:
	for i in range(ui_slots.size()):
		var definition: Dictionary = buildings[i]
		var slot: Label = ui_slots[i]
		slot.text = "%d %s" % [i + 1, definition.display_name]
		if i == selected_index:
			slot.text = "[%s]" % slot.text
			slot.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1))
		else:
			slot.add_theme_color_override("font_color", Color(0.92, 0.95, 0.94, 1))
