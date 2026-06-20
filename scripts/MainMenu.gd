extends Control

const GameData = preload("res://scripts/GameData.gd")
const SaveGameManager = preload("res://scripts/SaveGameManager.gd")

var save_manager = SaveGameManager.new()
var last_requested_scene_path := ""

@onready var continue_button: Button = $MenuPanel/MenuButtons/ContinueButton
@onready var new_game_button: Button = $MenuPanel/MenuButtons/NewGameButton
@onready var saves_button: Button = $MenuPanel/MenuButtons/SavesButton
@onready var settings_button: Button = $MenuPanel/MenuButtons/SettingsButton
@onready var quit_button: Button = $MenuPanel/MenuButtons/QuitButton
@onready var save_list_panel: Control = $SaveListPanel
@onready var save_list_items: VBoxContainer = $SaveListPanel/Panel/ListScroll/SaveListItems
@onready var settings_panel: Control = $SettingsPanel


func _ready() -> void:
	continue_button.pressed.connect(continue_game)
	new_game_button.pressed.connect(new_game)
	saves_button.pressed.connect(show_save_list)
	settings_button.pressed.connect(show_settings)
	quit_button.pressed.connect(quit_game)
	$SaveListPanel/Panel/CloseSavesButton.pressed.connect(hide_save_list)
	$SettingsPanel/Panel/CloseSettingsButton.pressed.connect(hide_settings)
	refresh_menu()


func refresh_menu() -> void:
	continue_button.visible = save_manager.has_last_save()
	save_list_panel.visible = false
	settings_panel.visible = false


func continue_game() -> bool:
	var save_data := save_manager.read_last_save()
	if save_data.is_empty():
		refresh_menu()
		return false

	return load_save(save_data)


func new_game() -> bool:
	save_manager.create_new_game_save()
	return _request_scene_change(GameData.MAIN_SCENE_PATH)


func show_save_list() -> bool:
	_populate_save_list()
	save_list_panel.visible = true
	settings_panel.visible = false
	return true


func hide_save_list() -> void:
	save_list_panel.visible = false


func show_settings() -> bool:
	settings_panel.visible = true
	save_list_panel.visible = false
	return true


func hide_settings() -> void:
	settings_panel.visible = false


func quit_game() -> void:
	if not is_inside_tree():
		return

	var tree := get_tree()
	var game_session := tree.root.get_node_or_null("GameSession")
	if game_session != null and game_session.has_method("autosave_cached_main_scene"):
		game_session.autosave_cached_main_scene("quit")
	tree.quit()


func load_save(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		return false

	var scene_path := str(save_data.get("scene_path", ""))
	if scene_path == "":
		return false

	if save_manager.has_method("activate_save") and not save_manager.activate_save(save_data):
		return false

	if scene_path == GameData.MAIN_SCENE_PATH:
		_set_pending_save_data(save_data)
	elif save_data.has("snapshot") and not _prepare_cached_main_scene_from_save(save_data):
		return false
	return _request_scene_change(scene_path)


func _request_scene_change(scene_path: String) -> bool:
	if scene_path == "":
		return false

	last_requested_scene_path = scene_path
	var tree := get_tree()
	if tree == null:
		return true

	tree.call_deferred("change_scene_to_file", scene_path)
	return true


func _set_pending_save_data(save_data: Dictionary) -> bool:
	if not is_inside_tree():
		return false

	var game_session := get_tree().root.get_node_or_null("GameSession")
	if game_session == null or not game_session.has_method("set_pending_save_data"):
		return false

	return game_session.set_pending_save_data(save_data)


func _prepare_cached_main_scene_from_save(save_data: Dictionary) -> bool:
	if not is_inside_tree():
		return false

	var game_session := get_tree().root.get_node_or_null("GameSession")
	if game_session == null or not game_session.has_method("prepare_cached_main_scene_from_save"):
		return false

	return game_session.prepare_cached_main_scene_from_save(get_tree(), save_data)


func _populate_save_list() -> void:
	for child in save_list_items.get_children():
		child.queue_free()

	var saves := save_manager.list_saves()
	if saves.is_empty():
		var empty_label := Label.new()
		empty_label.name = "EmptySaveLabel"
		empty_label.text = "暂无存档"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_list_items.add_child(empty_label)
		return

	for i in range(saves.size()):
		var save_data: Dictionary = saves[i]
		var button := Button.new()
		button.name = "Save_%02d" % (i + 1)
		button.text = "%s  %s" % [
			str(save_data.get("display_name", "存档")),
			str(save_data.get("updated_at", "")),
		]
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(Callable(self, "load_save").bind(save_data))
		save_list_items.add_child(button)
