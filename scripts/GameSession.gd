extends Node

const GameData = preload("res://scripts/GameData.gd")

var cached_main_scene: Node
var pending_save_data := {}


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


func autosave_cached_main_scene(reason := "quit", scene_path := GameData.MAIN_SCENE_PATH) -> bool:
	if not has_cached_main_scene():
		cached_main_scene = null
		return false

	var build_manager := cached_main_scene.get_node_or_null("BuildManager")
	if build_manager == null or not build_manager.has_method("autosave_game"):
		return false

	return build_manager.autosave_game(reason, scene_path)


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


func restore_cached_main_scene(scene_tree: SceneTree) -> bool:
	if scene_tree == null:
		return false

	var main_scene := take_cached_main_scene()
	if main_scene == null:
		return false

	var current_scene := scene_tree.current_scene
	if current_scene != null and current_scene != main_scene:
		scene_tree.root.remove_child(current_scene)
		current_scene.queue_free()

	if main_scene.get_parent() != null:
		main_scene.get_parent().remove_child(main_scene)
	scene_tree.root.add_child(main_scene)
	scene_tree.current_scene = main_scene
	return true
