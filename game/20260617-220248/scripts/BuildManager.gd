extends Node2D

const BuildingCatalog = preload("res://scripts/BuildingCatalog.gd")
const BuildingVisualFactory = preload("res://scripts/BuildingVisualFactory.gd")
const BuildRules = preload("res://scripts/BuildRules.gd")
const TreeFactory = preload("res://scripts/TreeFactory.gd")
const MonsterRules = preload("res://scripts/MonsterRules.gd")

const GROUND_MIN_X := 0.0
const GROUND_MAX_X := 9600.0
const GROUND_TOP_Y := 472.0
const AIR_WALL_WIDTH := 96.0
const AIR_WALL_HEIGHT := 1000.0
const CITY_HALL_SIZE := Vector2(400, 334)
const TREE_SIZE := Vector2(64, 120)
const TREE_COUNT := 18
const TREE_RANDOM_SEED := 20260616
const STARTING_GOLD := 99
const FARM_INCOME_SECONDS := 60.0
const LUMBERYARD_TREE_INTERVAL_SECONDS := 120.0
const LUMBERYARD_TREE_BATCH_COUNT := 3
const LUMBERYARD_TREE_RADIUS := 420.0
const PLAYER_TREE_CHOP_SECONDS := 10.0
const TOOL_CRAFT_SECONDS := 30.0
const TOOL_CRAFT_COST := 3
const BLACKSMITH_TOOL_LIMIT := 5
const INFO_PANEL_SIZE := Vector2(430, 460)
const VALID_PREVIEW_COLOR := Color(0.25, 1.0, 0.3, 0.45)
const INVALID_PREVIEW_COLOR := Color(1.0, 0.15, 0.1, 0.45)
const DEMOLITION_PREVIEW_COLOR := Color(1.0, 0.08, 0.05, 0.45)

var catalog := BuildingCatalog.new()
var visual_factory := BuildingVisualFactory.new()
var tree_factory := TreeFactory.new()
var rules := BuildRules.new()
var monster_rules := MonsterRules.new()

var buildings: Array = []
var placed_buildings: Array = []
var placed_footprints: Array = []
var tree_chop_tasks: Array = []
var gold := STARTING_GOLD
var selected_index := 0
var preview: Node2D
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


func _process(delta: float) -> void:
	if demolition_target_index != -1 and not _player_inside_demolition_target():
		_cancel_demolition()
	if info_panel != null and player != null and not _player_inside_info_panel_entity():
		_clear_info_panel()

	_update_farm_income(delta)
	_update_blacksmith_crafting(delta)
	_update_lumberyards(delta)
	_assign_waiting_tree_choppers()
	_update_player_tree_chop(delta)
	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if _handle_info_panel_input(key_event.keycode):
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
		elif _try_repair_damaged_building_at_player():
			return
		elif selected_index != -1:
			_try_build()
		elif _try_toggle_building_info_panel():
			return
		elif _try_start_player_tree_chop():
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
			false,
			"cityhall"
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
			false,
			"tree"
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

	_refresh_gold_ui()

	var damaged_entity_index := _damaged_building_index_at_player()
	if damaged_entity_index != -1:
		status_label.text = _repair_prompt_for_entity(damaged_entity_index)
		return

	if player_tree_task_id != "":
		status_label.text = "正在砍树 %d%%" % int(_tree_chop_progress(player_tree_task_id) * 100.0)
		return

	if demolition_target_index != -1:
		status_label.text = "Q 拆除 / E 取消"
		return

	if selected_index == -1:
		preview_valid = false
		var tree_task_id := _tree_task_for_player()
		status_label.text = "E 砍树 / 1-5 选择建筑" if tree_task_id != "" else "1-5 选择建筑 / Q 拆除"
		return

	if player == null or preview == null:
		return

	var definition: Dictionary = buildings[selected_index]
	var can_afford := can_afford_building(definition)
	var build_position := rules.build_position_for_player(
		player.global_position,
		_get_player_facing_direction(),
		definition.size,
		GROUND_TOP_Y
	)
	var footprint := rules.footprint_for_position(build_position, definition.size)

	preview.global_position = build_position
	preview_valid = not rules.has_overlap(footprint, placed_footprints) and can_afford
	preview.modulate = VALID_PREVIEW_COLOR if preview_valid else INVALID_PREVIEW_COLOR
	if preview_valid:
		status_label.text = "E 建造"
	elif not can_afford:
		status_label.text = "金币不足，需要 %d" % int(definition.get("cost", 0))
	else:
		status_label.text = "位置重叠，无法建造"


func _try_build() -> void:
	if selected_index == -1:
		return

	_update_preview()
	if not preview_valid or buildings_container == null:
		return

	var definition: Dictionary = buildings[selected_index]
	if not spend_gold_for_building(definition):
		_update_preview()
		return

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
		true,
		definition.id
	)
	_refresh_ui()
	_update_preview()


func _handle_info_panel_input(keycode: Key) -> bool:
	if info_panel == null:
		return false

	if keycode == KEY_E:
		_clear_info_panel()
		return true

	var tool_id := ""
	match keycode:
		KEY_1:
			tool_id = "sword"
		KEY_2:
			tool_id = "axe"
		KEY_3:
			tool_id = "sickle"
		KEY_4:
			tool_id = "bow"

	if tool_id == "":
		return false

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
	var lines := [
		"名字: %s" % entity.get("display_name", "建筑"),
		"等级: 1",
		"人员: %s" % worker_text,
		"功能: %s" % _building_function_text(building_id),
		"数值: %s" % _building_value_text(entity_index),
	]

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
	_add_panel_button("CraftSwordButton", "制作剑 -3金", Vector2(20, craft_y), Callable(self, "start_blacksmith_craft").bind(entity_index, "sword"), Vector2(122, 30), 10)
	_add_panel_button("CraftAxeButton", "制作斧 -3金", Vector2(154, craft_y), Callable(self, "start_blacksmith_craft").bind(entity_index, "axe"), Vector2(122, 30), 10)
	_add_panel_button("CraftSickleButton", "制作镰刀 -3金", Vector2(288, craft_y), Callable(self, "start_blacksmith_craft").bind(entity_index, "sickle"), Vector2(122, 30), 10)
	_add_panel_button("CraftBowButton", "制作弓 -3金", Vector2(20, craft_y + 34.0), Callable(self, "start_blacksmith_craft").bind(entity_index, "bow"), Vector2(122, 26), 10)

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
		"tavern":
			return "容纳村民工作"
		"wall":
			return "防御岗位"
		"cityhall":
			return "村民聚集地"
		_:
			return "工作建筑"


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
			return "120秒长3树；斧头砍树加倍"
		_:
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

	var counts := {
		"sword": 0,
		"axe": 0,
		"sickle": 0,
		"bow": 0,
	}
	for item in stock:
		var tool_id: String = item.get("tool_id", "")
		if counts.has(tool_id):
			counts[tool_id] += 1

	return "%d/%d 剑%d 斧%d 镰刀%d 弓%d" % [
		stock.size(),
		BLACKSMITH_TOOL_LIMIT,
		counts.sword,
		counts.axe,
		counts.sickle,
		counts.bow,
	]


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
		"cityhall":
			return Color(0.78, 0.78, 0.72, 1)
		_:
			return Color(0.48, 0.5, 0.5, 1)


func start_blacksmith_craft(entity_index: int, tool_id: String) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false
	if not _is_valid_tool_id(tool_id):
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	if entity.get("building_id", "") != "blacksmith":
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


func _create_tool_visual(tool_id: String) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = "ToolVisual"
	polygon.color = _tool_color(tool_id)
	match tool_id:
		"sword":
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
		"sickle":
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
	match role:
		"villager":
			return ["sword", "bow"]
		"lumberjack":
			return ["axe"]
		"farmer":
			return ["sickle"]
		_:
			return []


func _is_valid_tool_id(tool_id: String) -> bool:
	return tool_id == "sword" or tool_id == "axe" or tool_id == "sickle" or tool_id == "bow"


func _tool_color(tool_id: String) -> Color:
	match tool_id:
		"sword":
			return Color(0.74, 0.78, 0.82, 1)
		"axe":
			return Color(0.62, 0.56, 0.48, 1)
		"sickle":
			return Color(0.72, 0.8, 0.72, 1)
		"bow":
			return Color(0.86, 0.62, 0.22, 1)
		_:
			return Color.WHITE


func _tool_display_name(tool_id: String) -> String:
	match tool_id:
		"sword":
			return "剑"
		"axe":
			return "斧"
		"sickle":
			return "镰刀"
		"bow":
			return "弓"
		_:
			return tool_id


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
	if entity.get("entity_kind", "") == "tree":
		_start_tree_chop_task(demolition_target_index)
		demolition_target_index = -1
		demolition_original_modulate = Color.WHITE
		_update_preview()
		return

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
	is_workplace: bool,
	building_id := ""
) -> void:
	var resolved_building_id := _resolved_building_id(entity, display_name, entity_kind, building_id)
	placed_buildings.append({
		"node": entity,
		"footprint": footprint,
		"demolishable": demolishable,
		"display_name": display_name,
		"entity_kind": entity_kind,
		"building_id": resolved_building_id,
		"level": 1,
		"damaged": false,
		"is_workplace": is_workplace,
		"worker_id": "",
		"worker_inside": false,
		"farm_income_elapsed": 0.0,
		"crafting_tool": "",
		"craft_elapsed": 0.0,
		"craft_queue": [],
		"lumberyard_tree_elapsed": 0.0,
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
			"display_name": entity.display_name,
			"workplace_id": node.name,
			"position": node.global_position,
			"building_id": entity.get("building_id", ""),
			"required_role": _required_role_for_work_site(entity),
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
	if entity.get("damaged", false):
		return false
	if entity.get("worker_id", "") != "":
		return false
	if not _worker_can_use_work_site(entity, worker_id):
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
		if entity.get("damaged", false):
			return false
		if entity.get("worker_id", "") != worker_id:
			return false
		if not _worker_can_use_work_site(entity, worker_id):
			return false

		entity.worker_inside = true
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
		if entity.get("worker_id", "") != worker_id:
			return false

		entity.worker_inside = false
		placed_buildings[i] = entity
		visual_factory.set_occupied(node, false)
		return true

	return false


func release_work_site_for_worker(worker_id: String) -> bool:
	if worker_id == "":
		return false

	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if not entity.get("is_workplace", false):
			continue
		if entity.get("worker_id", "") != worker_id:
			continue

		var node: Node2D = entity.node
		entity.worker_id = ""
		entity.worker_inside = false
		placed_buildings[i] = entity
		if is_instance_valid(node):
			visual_factory.set_occupied(node, false)
		return true

	return false


func _required_role_for_work_site(entity: Dictionary) -> String:
	if entity.get("building_id", "") == "wall":
		return "archer"
	return ""


func _worker_can_use_work_site(entity: Dictionary, worker_id: String) -> bool:
	var required_role := _required_role_for_work_site(entity)
	if required_role == "":
		return true
	return _worker_role_for_id(worker_id) == required_role


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


func spend_gold_for_building(definition: Dictionary) -> bool:
	var cost := int(definition.get("cost", 0))
	if gold < cost:
		return false

	gold -= cost
	_refresh_gold_ui()
	return true


func add_gold(amount: int) -> void:
	gold += amount
	_refresh_gold_ui()


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

	var target_count := int(ceil(float(candidates.size()) * 0.5))
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
	placed_buildings[entity_index] = entity
	var node: Node2D = entity.node
	if is_instance_valid(node):
		node.modulate = Color.WHITE
		visual_factory.set_occupied(node, false)
	if entity.get("worker_id", "") != "":
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
	_add_death_button(panel, "MainMenuButton", "退出到主菜单", Vector2(50, 116), Callable(self, "_return_to_main_menu"))
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
	if get_tree() != null:
		get_tree().reload_current_scene()


func _quit_game() -> void:
	if get_tree() != null:
		get_tree().quit()


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
	entity.worker_inside = false
	placed_buildings[entity_index] = entity

	var node: Node2D = entity.node
	if is_instance_valid(node):
		node.modulate = Color(0.48, 0.34, 0.34, 1)
		visual_factory.set_occupied(node, false)

	if entity.get("worker_id", "") != "":
		_release_worker_from_damaged_entity(entity)


func _is_repairable_damage(entity_index: int) -> bool:
	if entity_index < 0 or entity_index >= placed_buildings.size():
		return false

	var entity: Dictionary = placed_buildings[entity_index]
	return entity.get("entity_kind", "") == "building" and entity.get("damaged", false)


func _building_base_cost(building_id: String) -> int:
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
		if entity.get("damaged", false):
			continue
		if not entity.get("worker_inside", false):
			continue

		entity.farm_income_elapsed = float(entity.get("farm_income_elapsed", 0.0)) + delta
		var income_seconds := _farm_income_seconds_for_worker(entity.get("worker_id", ""))
		while entity.farm_income_elapsed >= income_seconds:
			entity.farm_income_elapsed -= income_seconds
			add_gold(1)
		placed_buildings[i] = entity


func _farm_income_seconds_for_worker(worker_id: String) -> float:
	if _worker_has_tool(worker_id, "sickle"):
		return FARM_INCOME_SECONDS * 0.5

	return FARM_INCOME_SECONDS


func _worker_has_tool(worker_id: String, tool_id: String) -> bool:
	var parent := get_parent()
	if parent == null:
		return false

	var npc_manager := parent.get_node_or_null("NPCManager")
	return npc_manager != null and npc_manager.has_method("worker_has_tool") and npc_manager.worker_has_tool(worker_id, tool_id)


func _update_lumberyards(delta: float) -> void:
	var initial_count := placed_buildings.size()
	for i in range(initial_count):
		if i >= placed_buildings.size():
			break

		var entity: Dictionary = placed_buildings[i]
		if entity.get("building_id", "") != "lumberyard":
			continue
		if entity.get("damaged", false):
			continue

		entity.lumberyard_tree_elapsed = float(entity.get("lumberyard_tree_elapsed", 0.0)) + delta
		while entity.lumberyard_tree_elapsed >= LUMBERYARD_TREE_INTERVAL_SECONDS:
			entity.lumberyard_tree_elapsed -= LUMBERYARD_TREE_INTERVAL_SECONDS
			_spawn_lumberyard_trees(i)
		placed_buildings[i] = entity

	_dispatch_lumberjacks()


func _spawn_lumberyard_trees(lumberyard_index: int) -> int:
	if lumberyard_index < 0 or lumberyard_index >= placed_buildings.size() or buildings_container == null:
		return 0

	var entity: Dictionary = placed_buildings[lumberyard_index]
	var node: Node2D = entity.node
	if not is_instance_valid(node):
		return 0

	var positions: Array = rules.tree_positions_around_source(
		TREE_RANDOM_SEED + tree_sequence + lumberyard_index + 1,
		LUMBERYARD_TREE_BATCH_COUNT,
		node.global_position,
		LUMBERYARD_TREE_RADIUS,
		GROUND_MIN_X,
		GROUND_MAX_X,
		GROUND_TOP_Y,
		TREE_SIZE,
		placed_footprints
	)

	for position in positions:
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
		"tree"
	)
	return tree


func _next_tree_name() -> String:
	while true:
		tree_sequence += 1
		var candidate := "Tree_%02d" % tree_sequence
		if not _building_container_has_node_name(candidate):
			return candidate

	return "Tree_%02d" % tree_sequence


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


func _nearest_tree_index_near_lumberyard(lumberyard_index: int) -> int:
	if lumberyard_index < 0 or lumberyard_index >= placed_buildings.size():
		return -1

	var lumberyard: Dictionary = placed_buildings[lumberyard_index]
	var lumberyard_node: Node2D = lumberyard.node
	if not is_instance_valid(lumberyard_node):
		return -1

	var nearest_index := -1
	var nearest_distance := INF
	for i in range(placed_buildings.size()):
		var entity: Dictionary = placed_buildings[i]
		if entity.get("entity_kind", "") != "tree":
			continue

		var tree_node: Node2D = entity.node
		if not is_instance_valid(tree_node):
			continue
		if _tree_chop_task_index(tree_node.name) != -1:
			continue

		var distance := lumberyard_node.global_position.distance_to(tree_node.global_position)
		if distance > LUMBERYARD_TREE_RADIUS:
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

	if not npc_manager.assign_lumberjack_tree_chop(
		worker_id,
		task_id,
		tree_node.global_position,
		lumberyard_node.global_position,
		lumberyard.get("display_name", "伐木场"),
		lumberyard_node.name
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
	})
	lumberyard.worker_inside = false
	placed_buildings[lumberyard_index] = lumberyard
	visual_factory.set_occupied(lumberyard_node, false)


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

	tree_chop_tasks.remove_at(task_index)
	add_gold(1)
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

	if advance_tree_chop(player_tree_task_id, delta, PLAYER_TREE_CHOP_SECONDS):
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

	npc_manager.release_worker_from_damaged_building(
		entity.worker_id,
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

	npc_manager.return_worker_to_repaired_building(
		entity.worker_id,
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
			slot.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1))
		elif not can_afford_building(definition):
			slot.add_theme_color_override("font_color", Color(0.52, 0.56, 0.55, 1))
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
