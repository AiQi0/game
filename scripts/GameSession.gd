extends Node

const GameData = preload("res://scripts/GameData.gd")

var cached_main_scene: Node
var pending_save_data := {}
var _active_interior_context := {}
var pending_interior_result := {}
var _cached_main_scene_root_visible := true
var _cached_main_scene_canvas_layer_visibility := {}


func cache_main_scene(scene: Node) -> bool:
	if scene == null:
		return false

	if cached_main_scene != null and cached_main_scene != scene and is_instance_valid(cached_main_scene):
		cached_main_scene.queue_free()
	cached_main_scene = scene
	return true


func has_cached_main_scene() -> bool:
	return cached_main_scene != null and is_instance_valid(cached_main_scene)


func take_cached_main_scene() -> Node:
	if not has_cached_main_scene():
		cached_main_scene = null
		return null

	var scene := cached_main_scene
	cached_main_scene = null
	return scene


func clear_cached_main_scene() -> void:
	if cached_main_scene != null and is_instance_valid(cached_main_scene):
		cached_main_scene.queue_free()
	cached_main_scene = null


func set_pending_save_data(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		return false

	pending_save_data = save_data.duplicate(true)
	return true


func consume_pending_save_data() -> Dictionary:
	var save_data := pending_save_data.duplicate(true)
	pending_save_data.clear()
	return save_data


func set_active_interior_context(context: Dictionary) -> bool:
	if context.is_empty():
		return false

	_active_interior_context = context.duplicate(true)
	return true


func active_interior_context() -> Dictionary:
	return _active_interior_context.duplicate(true)


func clear_active_interior_context() -> void:
	_active_interior_context.clear()


func set_pending_interior_result(result: Dictionary) -> bool:
	if result.is_empty():
		return false

	pending_interior_result = result.duplicate(true)
	return true


func consume_pending_interior_result() -> Dictionary:
	var result := pending_interior_result.duplicate(true)
	pending_interior_result.clear()
	return result


func autosave_cached_main_scene(reason := "quit", scene_path := GameData.MAIN_SCENE_PATH) -> bool:
	if not has_cached_main_scene():
		cached_main_scene = null
		return false

	var build_manager := cached_main_scene.get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("autosave_game"):
		return false

	return build_manager.autosave_game(reason, scene_path)


func apply_interior_result_to_cached_main(result: Dictionary) -> bool:
	if result.is_empty() or not has_cached_main_scene():
		return false

	var build_manager := cached_main_scene.get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("apply_interior_result"):
		return false

	return build_manager.apply_interior_result(result)


func autosave_cached_main_scene_with_interior_result(
	result: Dictionary,
	reason := "interior",
	scene_path := GameData.MAIN_SCENE_PATH
) -> bool:
	if not result.is_empty():
		apply_interior_result_to_cached_main(result)
	return autosave_cached_main_scene(reason, scene_path)


func prepare_cached_main_scene_from_save(scene_tree: SceneTree, save_data: Dictionary) -> bool:
	if scene_tree == null or save_data.is_empty():
		return false

	var snapshot: Dictionary = save_data.get("snapshot", {})
	if snapshot.is_empty():
		return false

	clear_cached_main_scene()

	var packed_scene: PackedScene = load(GameData.MAIN_SCENE_PATH)
	if packed_scene == null:
		return false

	var main_scene := packed_scene.instantiate()
	scene_tree.root.add_child(main_scene)

	var build_manager := main_scene.get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("apply_save_data"):
		scene_tree.root.remove_child(main_scene)
		main_scene.queue_free()
		return false

	if not build_manager.apply_save_data(save_data):
		scene_tree.root.remove_child(main_scene)
		main_scene.queue_free()
		return false

	scene_tree.root.remove_child(main_scene)
	return cache_main_scene(main_scene)


func prepare_cached_main_scene_from_pending_save(scene_tree: SceneTree) -> bool:
	var save_data := consume_pending_save_data()
	if save_data.is_empty():
		return false

	return prepare_cached_main_scene_from_save(scene_tree, save_data)


func switch_to_scene_preserving_current(scene_tree: SceneTree, scene_path: String, cache_current_as_main := false) -> bool:
	if scene_tree == null or scene_path == "":
		return false

	var packed_scene: PackedScene = load(scene_path)
	if packed_scene == null:
		return false

	var current_scene := scene_tree.current_scene
	var next_scene := packed_scene.instantiate()
	if current_scene != null:
		scene_tree.root.remove_child(current_scene)
		if cache_current_as_main:
			cache_main_scene(current_scene)
		else:
			current_scene.queue_free()

	scene_tree.root.add_child(next_scene)
	scene_tree.current_scene = next_scene
	return true


func switch_to_scene_overlaying_current(scene_tree: SceneTree, scene_path: String, cache_current_as_main := false) -> bool:
	if scene_tree == null or scene_path == "":
		return false

	var packed_scene: PackedScene = load(scene_path)
	if packed_scene == null:
		return false

	var current_scene := scene_tree.current_scene
	var next_scene := packed_scene.instantiate()
	if current_scene != null and cache_current_as_main:
		cache_main_scene(current_scene)
		_set_main_scene_visuals_visible(current_scene, false)
		_set_main_scene_view_controls_enabled(current_scene, false)

	scene_tree.root.add_child(next_scene)
	scene_tree.current_scene = next_scene
	return true


func restore_cached_main_scene(scene_tree: SceneTree) -> bool:
	if scene_tree == null:
		return false

	var main_scene := take_cached_main_scene()
	if main_scene == null:
		return false

	var current_scene := scene_tree.current_scene
	if current_scene != null and current_scene != main_scene and is_instance_valid(current_scene):
		if current_scene.get_parent() != null:
			current_scene.get_parent().remove_child(current_scene)
		current_scene.queue_free()

	if main_scene.get_parent() != null:
		main_scene.get_parent().remove_child(main_scene)
	scene_tree.root.add_child(main_scene)
	scene_tree.current_scene = main_scene
	_set_main_scene_visuals_visible(main_scene, true)
	_set_main_scene_view_controls_enabled(main_scene, true)
	_apply_pending_interior_result(main_scene)
	return true


func _apply_pending_interior_result(main_scene: Node) -> void:
	var result := consume_pending_interior_result()
	if result.is_empty() or main_scene == null:
		return

	var build_manager := main_scene.get_node_or_null("BuildManager")
	if build_manager != null and build_manager.has_method("apply_interior_result"):
		build_manager.apply_interior_result(result)


func _set_main_scene_visuals_visible(main_scene: Node, visible: bool) -> void:
	if main_scene == null or not is_instance_valid(main_scene):
		return

	if main_scene is CanvasItem:
		var root_canvas_item := main_scene as CanvasItem
		if visible:
			root_canvas_item.visible = _cached_main_scene_root_visible
		else:
			_cached_main_scene_root_visible = root_canvas_item.visible
			root_canvas_item.visible = false

	_set_main_scene_canvas_layers_visible(main_scene, visible)


func _set_main_scene_canvas_layers_visible(main_scene: Node, visible: bool) -> void:
	if main_scene == null or not is_instance_valid(main_scene):
		return

	if not visible:
		_cached_main_scene_canvas_layer_visibility.clear()

	var pending: Array = [main_scene]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is CanvasLayer:
			var layer := current as CanvasLayer
			var layer_path := str(main_scene.get_path_to(layer))
			if visible:
				if _cached_main_scene_canvas_layer_visibility.has(layer_path):
					layer.visible = bool(_cached_main_scene_canvas_layer_visibility.get(layer_path, true))
			else:
				_cached_main_scene_canvas_layer_visibility[layer_path] = layer.visible
				layer.visible = false

		for child in current.get_children():
			if child is Node:
				pending.append(child)

	if visible:
		_cached_main_scene_canvas_layer_visibility.clear()


func _set_main_scene_view_controls_enabled(main_scene: Node, enabled: bool) -> void:
	if main_scene == null or not is_instance_valid(main_scene):
		return

	var player := main_scene.get_node_or_null("Player")
	if player == null:
		return

	player.set_physics_process(enabled)
	var camera := player.get_node_or_null("Camera2D")
	if camera is Camera2D:
		camera.enabled = enabled
		if enabled:
			camera.make_current()
