extends Node2D

const GameData = preload("res://scripts/GameData.gd")
const SaveGameManager = preload("res://scripts/SaveGameManager.gd")
const RIVER_MIRROR_WATER_SHADER = preload("res://shaders/river_mirror_water.gdshader")

const RETURN_INTERACTION_RANGE := GameData.NPC_INTERACTION_RANGE

var game_data := GameData.new()
var save_manager = SaveGameManager.new()
var autosave_elapsed := 0.0
var pause_canvas: CanvasLayer
var pause_panel: Control
var player: Node2D
var post_station: Node2D


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_scene_nodes()
	_ensure_mirror_water_surface()
	apply_non_cityhall_building_scale()
	_prepare_cached_main_from_pending_save()


func _process(delta: float) -> void:
	if _is_tree_paused():
		return

	_update_autosave(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		return

	if _is_tree_paused():
		return

	if key_event.keycode == KEY_E:
		var viewport := get_viewport()
		if return_to_main_world() and viewport != null:
			viewport.set_input_as_handled()


func main_world_scene_path() -> String:
	return game_data.travel_destination_scene_path("main")


func river_scene_path() -> String:
	return game_data.travel_destination_scene_path("river")


func apply_non_cityhall_building_scale() -> void:
	var building_scale := Vector2(
		GameData.NON_CITYHALL_BUILDING_SIZE_MULTIPLIER,
		GameData.NON_CITYHALL_BUILDING_SIZE_MULTIPLIER
	)
	var fixed_building_ids := {
		"PostStation": "post_station",
		"LeftWall": "wall",
		"RightWall": "wall",
	}
	for node_path in fixed_building_ids.keys():
		var building := get_node_or_null(node_path) as Node2D
		if building != null:
			building.scale = game_data.oriented_building_scale(
				str(fixed_building_ids[node_path]),
				building.global_position,
				_city_hall_position(),
				building_scale
			)

	for container_path in ["Farms", "Lumberyards", "Quarries", "Blacksmiths"]:
		var container := get_node_or_null(container_path)
		if container == null:
			continue
		for child in container.get_children():
			if child is Node2D:
				(child as Node2D).scale = building_scale


func _city_hall_position() -> Vector2:
	var city_hall := get_node_or_null("CityHall") as Node2D
	if city_hall != null:
		return city_hall.global_position
	return GameData.CITY_HALL_FRONT


func can_return_to_main_world() -> bool:
	_resolve_scene_nodes()
	if player == null or post_station == null:
		return false

	return player.global_position.distance_to(post_station.global_position) <= RETURN_INTERACTION_RANGE


func return_to_main_world() -> bool:
	if not can_return_to_main_world():
		return false

	var scene_path := main_world_scene_path()
	if scene_path == "":
		return false

	return _request_scene_change(scene_path)


func save_game_from_pause() -> bool:
	return _autosave_cached_main_scene("manual")


func load_game_from_pause() -> bool:
	if save_manager == null:
		return false

	var save_data := save_manager.read_last_save()
	if save_data.is_empty():
		return false

	var scene_path := str(save_data.get("scene_path", ""))
	if scene_path == "":
		return false

	if save_manager.has_method("activate_save") and not save_manager.activate_save(save_data):
		return false

	if save_data.has("snapshot") and not _prepare_cached_main_scene_from_save(save_data):
		return false

	resume_game()
	if scene_path == river_scene_path():
		return true

	return _request_scene_change(scene_path)


func return_to_main_menu_from_pause() -> void:
	_autosave_cached_main_scene("manual")
	resume_game()
	var tree := _scene_tree()
	if tree == null:
		return

	var game_session := _game_session()
	if game_session != null and game_session.has_method("clear_cached_main_scene"):
		game_session.clear_cached_main_scene()
	tree.change_scene_to_file(GameData.MAIN_MENU_SCENE_PATH)


func resume_game() -> void:
	var tree := _scene_tree()
	if tree != null:
		tree.paused = false
	_clear_pause_menu()


func _resolve_scene_nodes() -> void:
	if player == null:
		player = get_node_or_null("Player") as Node2D
	if post_station == null:
		post_station = get_node_or_null("PostStation") as Node2D


func _update_autosave(delta: float) -> void:
	if delta <= 0.0:
		return

	autosave_elapsed += delta
	while autosave_elapsed >= GameData.AUTOSAVE_SECONDS:
		autosave_elapsed -= GameData.AUTOSAVE_SECONDS
		_autosave_cached_main_scene("interval")


func _toggle_pause_menu() -> void:
	if pause_panel != null:
		resume_game()
	else:
		_show_pause_menu()


func _is_tree_paused() -> bool:
	var tree := _scene_tree()
	return tree != null and tree.paused


func _show_pause_menu() -> void:
	if pause_panel != null:
		return

	var tree := _scene_tree()
	if tree != null:
		tree.paused = true

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
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.disabled = false
	button.pressed.connect(callback)
	pause_panel.add_child(button)
	return button


func _clear_pause_menu() -> void:
	if pause_canvas != null:
		pause_canvas.queue_free()
	pause_canvas = null
	pause_panel = null


func _autosave_cached_main_scene(reason := "interval") -> bool:
	var game_session := _game_session()
	if game_session == null or not game_session.has_method("autosave_cached_main_scene"):
		return false

	return game_session.autosave_cached_main_scene(reason, river_scene_path())


func _prepare_cached_main_from_pending_save() -> bool:
	var tree := _scene_tree()
	var game_session := _game_session()
	if tree == null or game_session == null or not game_session.has_method("prepare_cached_main_scene_from_pending_save"):
		return false

	return game_session.prepare_cached_main_scene_from_pending_save(tree)


func _prepare_cached_main_scene_from_save(save_data: Dictionary) -> bool:
	var tree := _scene_tree()
	var game_session := _game_session()
	if tree == null or game_session == null or not game_session.has_method("prepare_cached_main_scene_from_save"):
		return false

	return game_session.prepare_cached_main_scene_from_save(tree, save_data)


func _game_session() -> Node:
	var tree := _scene_tree()
	if tree == null:
		return null

	return tree.root.get_node_or_null("GameSession")


func _scene_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()

	return Engine.get_main_loop() as SceneTree


func _ensure_mirror_water_surface() -> void:
	var scene_art := get_node_or_null("SceneArt") as Node2D
	if scene_art == null:
		return

	var legacy_water := scene_art.get_node_or_null("ForegroundWaterTiles") as CanvasItem
	if legacy_water != null:
		legacy_water.visible = false

	var old_3d_water := scene_art.get_node_or_null("Water3D")
	if old_3d_water != null:
		scene_art.remove_child(old_3d_water)
		old_3d_water.queue_free()

	if scene_art.get_node_or_null("WaterReflection") != null:
		return

	var water_root := Node2D.new()
	water_root.name = "WaterReflection"
	water_root.z_as_relative = false
	water_root.z_index = 4
	scene_art.add_child(water_root)

	var water_visual := game_data.river_mirror_water_visual()
	var tile_width := float(water_visual.get("tile_width", 1920.0))
	var tile_count := int(water_visual.get("tile_count", 5))
	var waterline_y := float(water_visual.get("waterline_y", 420.0))
	var reflection_height := float(water_visual.get("reflection_height_pixels", 660.0))
	var tile_size := Vector2(tile_width, reflection_height)
	for i in range(tile_count):
		var tile := ColorRect.new()
		tile.name = "WaterReflectionTile%d" % i
		tile.position = Vector2(tile_width * float(i), waterline_y)
		tile.size = tile_size
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var material := ShaderMaterial.new()
		material.shader = RIVER_MIRROR_WATER_SHADER
		for parameter_name in [
			"reflection_height_pixels",
			"ripple_amplitude_pixels",
			"ripple_frequency",
			"ripple_speed",
			"shimmer_strength",
			"top_blur_fraction",
			"top_blur_radius_pixels",
		]:
			material.set_shader_parameter(str(parameter_name), water_visual.get(parameter_name))
		tile.material = material
		water_root.add_child(tile)


func _request_scene_change(scene_path: String) -> bool:
	if scene_path == "":
		return false

	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false

	var game_session := tree.root.get_node_or_null("GameSession")
	if (
		scene_path == main_world_scene_path()
		and game_session != null
		and game_session.has_method("restore_cached_main_scene")
		and game_session.restore_cached_main_scene(tree)
	):
		return true

	tree.call_deferred("change_scene_to_file", scene_path)
	return true
