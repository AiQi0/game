extends Node

const GameData = preload("res://scripts/GameData.gd")
const FishingRules = preload("res://scripts/FishingRules.gd")

enum {
	IDLE,
	WAITING_FOR_BITE,
	BITE_WINDOW,
	REELING,
	SUCCESS,
	FAILED,
}

var data := GameData.new()
var rules = FishingRules.new()
var rng := RandomNumberGenerator.new()
var state := IDLE
var build_manager: Node
var player: Node2D
var waiting_elapsed := 0.0
var bite_second := 0
var hook_elapsed := 0.0
var reel_progress := 0.0
var result_elapsed := 0.0
var ui_canvas: CanvasLayer
var ui_panel: ColorRect
var status_label: Label
var detail_label: Label
var progress_bar: ProgressBar
var codex_button: Button
var last_catch_result := {}
var fishing_start_position := Vector2.ZERO
var has_fishing_start_position := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_resolve_scene_references()
	_create_ui()
	_refresh_ui()


func _process(delta: float) -> void:
	if _should_cancel_for_context():
		if state != IDLE:
			cancel_fishing()
		return
	if _should_cancel_for_movement():
		cancel_fishing()
		return

	match state:
		WAITING_FOR_BITE:
			_update_waiting_for_bite(delta)
		BITE_WINDOW:
			_update_bite_window(delta)
		REELING:
			_update_reeling(delta)
		SUCCESS, FAILED:
			_update_result(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_F:
		if press_fishing_key():
			_mark_input_handled()
	elif key_event.keycode == KEY_Q and is_fishing():
		cancel_fishing()
		_mark_input_handled()


func try_start_fishing() -> bool:
	if state != IDLE:
		return false
	if not _can_start_fishing():
		return false

	state = WAITING_FOR_BITE
	waiting_elapsed = 0.0
	bite_second = 0
	hook_elapsed = 0.0
	reel_progress = 0.0
	result_elapsed = 0.0
	_store_fishing_start_position()
	_refresh_ui()
	return true


func press_fishing_key() -> bool:
	if state != IDLE and (_should_cancel_for_context() or _should_cancel_for_movement()):
		cancel_fishing()
		return false

	match state:
		IDLE:
			return try_start_fishing()
		BITE_WINDOW:
			_start_reeling()
			return true
		REELING:
			reel_progress = rules.reel_progress_after_press(reel_progress, data)
			_apply_reel_outcome()
			_refresh_ui()
			return true
	return false


func cancel_fishing() -> void:
	state = IDLE
	waiting_elapsed = 0.0
	bite_second = 0
	hook_elapsed = 0.0
	reel_progress = 0.0
	result_elapsed = 0.0
	has_fishing_start_position = false
	_refresh_ui()


func is_fishing() -> bool:
	return state == WAITING_FOR_BITE or state == BITE_WINDOW or state == REELING


func state_name() -> String:
	match state:
		IDLE:
			return "idle"
		WAITING_FOR_BITE:
			return "waiting_for_bite"
		BITE_WINDOW:
			return "bite_window"
		REELING:
			return "reeling"
		SUCCESS:
			return "success"
		FAILED:
			return "failed"
	return "idle"


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _enter_bite_window() -> void:
	state = BITE_WINDOW
	waiting_elapsed = 0.0
	hook_elapsed = 0.0
	_refresh_ui()


func _finish_result() -> void:
	cancel_fishing()


func _resolve_scene_references() -> void:
	var parent := get_parent()
	if parent == null:
		return

	if build_manager == null:
		build_manager = parent.get_node_or_null("BuildManager")
	if player == null:
		player = parent.get_node_or_null("Player") as Node2D


func _can_start_fishing() -> bool:
	_resolve_scene_references()
	if player == null:
		return false
	if build_manager != null and is_instance_valid(build_manager) and build_manager.has_method("can_start_fishing"):
		return build_manager.can_start_fishing()
	return not _should_cancel_for_context()


func _should_cancel_for_context() -> bool:
	if is_inside_tree() and get_tree().paused:
		return true
	if build_manager != null and is_instance_valid(build_manager) and build_manager.get("player_dead") == true:
		return true
	if player != null and is_instance_valid(player):
		if player.has_method("is_dead") and player.is_dead():
			return true
		if player.get("player_dead") == true or player.get("dead") == true:
			return true
	return false


func _store_fishing_start_position() -> void:
	if player != null and is_instance_valid(player):
		fishing_start_position = player.global_position
		has_fishing_start_position = true
	else:
		has_fishing_start_position = false


func _should_cancel_for_movement() -> bool:
	if not is_fishing() or not has_fishing_start_position:
		return false
	if player == null or not is_instance_valid(player):
		return false

	var cancel_distance := _fishing_float("movement_cancel_distance")
	if cancel_distance <= 0.0:
		return false
	return player.global_position.distance_to(fishing_start_position) > cancel_distance


func _update_waiting_for_bite(delta: float) -> void:
	waiting_elapsed += maxf(delta, 0.0)
	var bite_check_seconds := _fishing_float("bite_check_seconds")
	if bite_check_seconds <= 0.0:
		push_error("Fishing config value 'bite_check_seconds' must be greater than zero")
		return

	while waiting_elapsed >= bite_check_seconds and state == WAITING_FOR_BITE:
		waiting_elapsed -= bite_check_seconds
		bite_second += 1
		if rules.should_bite(bite_second, rng.randf(), data):
			_enter_bite_window()


func _update_bite_window(delta: float) -> void:
	hook_elapsed += maxf(delta, 0.0)
	if hook_elapsed >= _fishing_float("hook_window_seconds"):
		_fail_fishing()


func _start_reeling() -> void:
	state = REELING
	hook_elapsed = 0.0
	reel_progress = clampf(_fishing_float("reel_start_progress"), 0.0, 1.0)
	_apply_reel_outcome()
	_refresh_ui()


func _update_reeling(delta: float) -> void:
	reel_progress = rules.reel_progress_after_decay(reel_progress, delta, data)
	_apply_reel_outcome()
	_refresh_ui()


func _apply_reel_outcome() -> void:
	match rules.reel_outcome(reel_progress):
		"success":
			_succeed_fishing()
		"failed":
			_fail_fishing()


func _succeed_fishing() -> void:
	if state == SUCCESS:
		return

	state = SUCCESS
	result_elapsed = 0.0
	_grant_reward()
	_refresh_ui()


func _fail_fishing() -> void:
	if state == FAILED:
		return

	state = FAILED
	result_elapsed = 0.0
	_refresh_ui()


func _update_result(delta: float) -> void:
	result_elapsed += maxf(delta, 0.0)
	if result_elapsed >= _fishing_float("result_visible_seconds"):
		_finish_result()
	else:
		_refresh_ui()


func _grant_reward() -> void:
	var reward_gold := _fishing_int("reward_gold")
	if build_manager != null and is_instance_valid(build_manager) and build_manager.has_method("add_gold"):
		build_manager.add_gold(reward_gold)
	else:
		push_warning("Fishing reward could not be granted because BuildManager.add_gold() is unavailable")

	last_catch_result.clear()
	if build_manager != null and is_instance_valid(build_manager) and build_manager.has_method("record_random_fishing_catch"):
		last_catch_result = build_manager.record_random_fishing_catch(
			rng.randf(),
			rng.randf(),
			rng.randf(),
			rng.randf()
		)


func _success_detail_text() -> String:
	var catch_data: Dictionary = last_catch_result.get("catch", {})
	if catch_data.is_empty():
		return "+%d 金币" % _fishing_int("reward_gold")

	var detail := "%s %.2fkg  +%d 金币" % [
		str(catch_data.get("display_name", "鱼")),
		float(catch_data.get("weight", 0.0)),
		_fishing_int("reward_gold"),
	]
	var seed_id := str(last_catch_result.get("seed_id", ""))
	if seed_id != "":
		detail += "  种子：%s" % seed_id
	return detail


func _open_fish_codex() -> void:
	if build_manager != null and is_instance_valid(build_manager) and build_manager.has_method("toggle_fish_codex_panel"):
		build_manager.toggle_fish_codex_panel()


func _create_ui() -> void:
	if ui_canvas != null and is_instance_valid(ui_canvas):
		return

	ui_canvas = CanvasLayer.new()
	ui_canvas.name = "FishingUI"
	ui_canvas.layer = 25
	add_child(ui_canvas)

	ui_panel = ColorRect.new()
	ui_panel.name = "FishingPanel"
	ui_panel.anchor_left = 0.5
	ui_panel.anchor_top = 1.0
	ui_panel.anchor_right = 0.5
	ui_panel.anchor_bottom = 1.0
	ui_panel.offset_left = -180.0
	ui_panel.offset_top = -220.0
	ui_panel.offset_right = 180.0
	ui_panel.offset_bottom = -120.0
	ui_panel.color = Color(0.04, 0.06, 0.08, 0.82)
	ui_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_canvas.add_child(ui_panel)

	status_label = Label.new()
	status_label.name = "FishingStatus"
	status_label.position = Vector2(16, 10)
	status_label.size = Vector2(328, 26)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.94, 0.97, 0.96, 1))
	ui_panel.add_child(status_label)

	detail_label = Label.new()
	detail_label.name = "FishingDetail"
	detail_label.position = Vector2(16, 38)
	detail_label.size = Vector2(328, 22)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Color(0.76, 0.84, 0.86, 1))
	ui_panel.add_child(detail_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "FishingProgress"
	progress_bar.position = Vector2(16, 68)
	progress_bar.size = Vector2(328, 16)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.show_percentage = false
	ui_panel.add_child(progress_bar)

	codex_button = Button.new()
	codex_button.name = "FishCodexButton"
	codex_button.text = "鱼图鉴"
	codex_button.position = Vector2(126, 88)
	codex_button.size = Vector2(108, 28)
	codex_button.focus_mode = Control.FOCUS_NONE
	codex_button.pressed.connect(Callable(self, "_open_fish_codex"))
	ui_panel.add_child(codex_button)

	_refresh_ui()


func _refresh_ui() -> void:
	if ui_panel == null:
		return

	ui_panel.visible = state != IDLE
	if not ui_panel.visible:
		return

	match state:
		WAITING_FOR_BITE:
			status_label.text = "钓鱼中"
			detail_label.text = "等待咬钩..."
			progress_bar.value = 0.0
		BITE_WINDOW:
			status_label.text = "咬钩了！"
			detail_label.text = "按 F 收杆"
			progress_bar.value = clampf(1.0 - hook_elapsed / maxf(_fishing_float("hook_window_seconds"), 0.001), 0.0, 1.0)
		REELING:
			status_label.text = "收杆中"
			detail_label.text = "连续按 F 填满进度条"
			progress_bar.value = reel_progress
		SUCCESS:
			status_label.text = "钓到了！"
			detail_label.text = _success_detail_text()
			progress_bar.value = 1.0
		FAILED:
			status_label.text = "鱼跑掉了"
			detail_label.text = "再试一次"
			progress_bar.value = 0.0


func _fishing_float(key: String) -> float:
	if data == null or not data.has_method("fishing_value"):
		push_error("Fishing config source is missing fishing_value() for key '%s'" % key)
		return 0.0

	var value = data.fishing_value(key)
	if value == null:
		push_error("Missing fishing config value: '%s'" % key)
		return 0.0
	if not (value is int or value is float):
		push_error("Fishing config value '%s' must be numeric, got %s" % [key, typeof(value)])
		return 0.0
	return float(value)


func _fishing_int(key: String) -> int:
	return int(round(_fishing_float(key)))
