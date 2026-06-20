extends RefCounted

const GameData = preload("res://scripts/GameData.gd")

var save_root_path := GameData.SAVE_DIRECTORY
var last_save_filename := GameData.LAST_SAVE_FILENAME


func has_last_save() -> bool:
	return FileAccess.file_exists(last_save_path())


func last_save_path() -> String:
	return _join_path(save_root_path, last_save_filename)


func last_played_scene_path() -> String:
	var save_data := read_last_save()
	if save_data.is_empty():
		return ""

	return str(save_data.get("scene_path", GameData.MAIN_SCENE_PATH))


func read_last_save() -> Dictionary:
	if not has_last_save():
		return {}

	var file := FileAccess.open(last_save_path(), FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}

	return parsed


func list_saves() -> Array:
	var saves := []
	var dir := DirAccess.open(save_root_path)
	if dir == null:
		return saves

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
			var save_data := _read_save_file(_join_path(save_root_path, file_name))
			if not save_data.is_empty():
				save_data.file_name = file_name
				saves.append(save_data)
		file_name = dir.get_next()
	dir.list_dir_end()
	saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("updated_at", "")) > str(b.get("updated_at", ""))
	)
	return saves


func record_last_played_save(slot_id: String, display_name: String, scene_path: String) -> bool:
	if slot_id == "" or scene_path == "":
		return false
	if not _ensure_save_directory():
		return false

	var save_data := {
		"slot_id": slot_id,
		"display_name": display_name if display_name != "" else slot_id,
		"scene_path": scene_path,
		"updated_at": Time.get_datetime_string_from_system(),
	}
	var file := FileAccess.open(last_save_path(), FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	return true


func create_new_game_save() -> bool:
	return record_last_played_save("autosave", "自动存档", GameData.MAIN_SCENE_PATH)


func activate_save(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		return false
	if str(save_data.get("scene_path", "")) == "":
		return false
	if not _ensure_save_directory():
		return false

	var active_save := save_data.duplicate(true)
	active_save.erase("file_name")
	var file := FileAccess.open(last_save_path(), FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(active_save, "\t"))
	return true


func record_autosave(scene_path: String, snapshot: Dictionary, reason := "interval") -> bool:
	if scene_path == "":
		return false
	if not _ensure_save_directory():
		return false

	var save_data := {
		"slot_id": "autosave",
		"display_name": "自动存档",
		"scene_path": scene_path,
		"updated_at": Time.get_datetime_string_from_system(),
		"autosave": true,
		"autosave_reason": reason,
		"snapshot": snapshot.duplicate(true),
	}
	var file := FileAccess.open(last_save_path(), FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	return true


func _read_save_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}

	return parsed


func _ensure_save_directory() -> bool:
	if DirAccess.dir_exists_absolute(save_root_path):
		return true

	return DirAccess.make_dir_recursive_absolute(save_root_path) == OK


func _join_path(base_path: String, file_name: String) -> String:
	return "%s/%s" % [base_path.trim_suffix("/"), file_name]
