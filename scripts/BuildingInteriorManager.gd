extends Node2D

const GameData = preload("res://scripts/GameData.gd")
const CollectionRules = preload("res://scripts/CollectionRules.gd")

var data := GameData.new()
var collection_rules := CollectionRules.new()
var rng := RandomNumberGenerator.new()
var context := {}
var building_id := ""
var building_node_name := ""
var building_display_name := ""
var interior_definition := {}
var interior_state := {}
var workers := []
var unlocked_crops := {}
var gold_delta := 0
var autosave_elapsed := 0.0
var selected_crop_id := "wheat"
var visual_refresh_elapsed := 0.0

var player: Node2D
var worker_visual: Node2D
var door_position := Vector2(160, 792)
var status_label: Label
var detail_label: Label
var progress_label: Label
var crop_button_container: HBoxContainer
var resource_container: Node2D
var plot_container: Node2D
var trainee_container: Node2D


func _ready() -> void:
	rng.randomize()
	_load_context()
	_create_scene_nodes()
	_refresh_visuals()


func _process(delta: float) -> void:
	_update_player(delta)
	_update_production(delta)
	_update_autosave(delta)
	visual_refresh_elapsed += maxf(delta, 0.0)
	if visual_refresh_elapsed >= 0.25:
		visual_refresh_elapsed = 0.0
		_refresh_visuals()
	_refresh_runtime_labels()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_S and _player_at_door():
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		_return_to_main_world()
	elif key_event.keycode == KEY_E and _try_collect_worker_seed():
		get_viewport().set_input_as_handled()


func _load_context() -> void:
	var game_session := _game_session()
	if game_session != null and game_session.has_method("active_interior_context"):
		context = game_session.active_interior_context()

	building_id = str(context.get("building_id", ""))
	building_node_name = str(context.get("building_node_name", ""))
	building_display_name = str(context.get("display_name", building_id))
	interior_definition = data.building_interior_definition(building_id)
	interior_state = (context.get("interior_state", {}) as Dictionary).duplicate(true)
	workers = (context.get("workers", []) as Array).duplicate(true)
	unlocked_crops = collection_rules.normalized_crop_unlocks(context.get("unlocked_crops", {}), data)
	selected_crop_id = str(interior_state.get("selected_crop_id", _first_unlocked_crop_id()))
	if not bool(unlocked_crops.get(selected_crop_id, false)):
		selected_crop_id = _first_unlocked_crop_id()
	_ensure_layout_state()


func _create_scene_nodes() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.size = Vector2(1920, 1080)
	background.color = _background_color_for_layout()
	add_child(background)

	var texture := data.art_asset_texture("interiors", str(interior_definition.get("background_asset", "shell_background")))
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.name = "GeneratedBackground"
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(
			1920.0 / maxf(1.0, float(texture.get_width())),
			1080.0 / maxf(1.0, float(texture.get_height()))
		)
		add_child(sprite)

	var floor := ColorRect.new()
	floor.name = "Floor"
	floor.position = Vector2(0, 820)
	floor.size = Vector2(1920, 260)
	floor.color = _floor_color_for_layout()
	add_child(floor)

	var door := ColorRect.new()
	door.name = "ExitDoor"
	door.position = door_position + Vector2(-42, -128)
	door.size = Vector2(84, 128)
	door.color = Color(0.24, 0.12, 0.06, 1)
	add_child(door)

	if str(interior_definition.get("layout", "shell")) == "farm":
		_create_farm_hut()

	player = Node2D.new()
	player.name = "InteriorPlayer"
	player.position = door_position + Vector2(80, 0)
	player.z_index = 8
	add_child(player)
	player.add_child(_character_visual("GeneratedSprite", "player", Vector2(64, 96), Color(0.22, 0.45, 0.95, 1)))

	worker_visual = Node2D.new()
	worker_visual.name = "InteriorWorker"
	worker_visual.position = _worker_position_from_state(data.interior_worker_default_position())
	worker_visual.z_index = 8
	worker_visual.visible = not workers.is_empty()
	add_child(worker_visual)
	worker_visual.add_child(_character_visual("GeneratedSprite", _worker_asset_id(), Vector2(64, 96), Color(0.78, 0.66, 0.28, 1)))
	worker_visual.add_child(_rect_visual("SeedNotice", Vector2(-10, -112), Vector2(20, 20), Color(0.35, 0.9, 0.35, 1)))

	trainee_container = Node2D.new()
	trainee_container.name = "BarracksTrainees"
	trainee_container.z_index = 8
	add_child(trainee_container)
	_refresh_barracks_trainees()

	plot_container = Node2D.new()
	plot_container.name = "Plots"
	plot_container.z_index = 2
	add_child(plot_container)

	resource_container = Node2D.new()
	resource_container.name = "InteriorResources"
	resource_container.z_index = 2
	add_child(resource_container)

	var canvas := CanvasLayer.new()
	canvas.name = "InteriorUI"
	canvas.layer = 35
	add_child(canvas)

	status_label = Label.new()
	status_label.name = "Status"
	status_label.position = Vector2(28, 22)
	status_label.size = Vector2(900, 34)
	status_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(status_label)

	detail_label = Label.new()
	detail_label.name = "Detail"
	detail_label.position = Vector2(28, 60)
	detail_label.size = Vector2(900, 28)
	canvas.add_child(detail_label)

	progress_label = Label.new()
	progress_label.name = "Progress"
	progress_label.position = Vector2(28, 92)
	progress_label.size = Vector2(900, 28)
	canvas.add_child(progress_label)

	crop_button_container = HBoxContainer.new()
	crop_button_container.name = "CropButtons"
	crop_button_container.position = Vector2(28, 126)
	crop_button_container.size = Vector2(980, 44)
	canvas.add_child(crop_button_container)
	_create_crop_buttons()


func _ensure_layout_state() -> void:
	var layout := str(interior_definition.get("layout", "shell"))
	interior_state.layout = layout
	interior_state.selected_crop_id = selected_crop_id
	if layout == "farm":
		if not interior_state.has("plots") or not interior_state.get("plots") is Array:
			var plots := []
			for i in range(int(interior_definition.get("plot_count", 6))):
				plots.append({
					"crop_id": selected_crop_id,
					"stage": "empty",
					"elapsed": 0.0,
					"action_elapsed": 0.0,
				})
			interior_state.plots = plots
		if not interior_state.has("active_farm_task") or not interior_state.get("active_farm_task") is Dictionary:
			interior_state.active_farm_task = {}
	elif layout == "lumberyard" or layout == "quarry":
		if not interior_state.has("resources") or not interior_state.get("resources") is Array:
			interior_state.resources = []
		if not interior_state.has("spawn_elapsed"):
			interior_state.spawn_elapsed = 0.0
	elif layout == "barracks":
		if not interior_state.has("training_workers") or not interior_state.get("training_workers") is Dictionary:
			interior_state.training_workers = {}
	if not interior_state.has("worker_seed_rewards"):
		interior_state.worker_seed_rewards = {}


func _update_player(delta: float) -> void:
	if player == null:
		return

	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	player.position.x = clampf(player.position.x + direction * data.interior_player_speed() * delta, 80.0, 1840.0)


func _update_production(delta: float) -> void:
	match str(interior_definition.get("layout", "shell")):
		"farm":
			_update_farm(delta)
		"lumberyard", "quarry":
			_update_resource_room(delta)
		"barracks":
			_update_barracks_training(delta)


func _update_barracks_training(delta: float) -> void:
	var training_workers: Dictionary = interior_state.get("training_workers", {})
	for worker in workers:
		if not (worker is Dictionary):
			continue
		var worker_id := str((worker as Dictionary).get("worker_id", ""))
		if worker_id == "":
			continue
		var record: Dictionary = training_workers.get(worker_id, {})
		var elapsed := float(record.get("elapsed", 0.0)) + maxf(delta, 0.0)
		record.elapsed = elapsed
		record.level = data.barracks_training_level_for_elapsed(elapsed)
		training_workers[worker_id] = record
	for worker_id in training_workers.keys():
		if not _has_worker(str(worker_id)):
			training_workers.erase(worker_id)
	interior_state.training_workers = training_workers
	_refresh_barracks_trainees()


func _update_farm(delta: float) -> void:
	var plots: Array = interior_state.get("plots", [])
	var cycle_seconds := float(interior_definition.get("cycle_seconds", 300.0))
	var sow_seconds := float(interior_definition.get("sow_action_seconds", 2.0))
	var harvest_seconds := float(interior_definition.get("harvest_action_seconds", 2.0))
	var grow_seconds := maxf(0.0, cycle_seconds - sow_seconds - harvest_seconds)
	var worker_multiplier := _best_worker_multiplier()
	var production_delta := delta * worker_multiplier

	_advance_farm_growth(plots, grow_seconds, production_delta)
	if workers.is_empty():
		interior_state.plots = plots
		return

	var active_task = interior_state.get("active_farm_task", {})
	if not (active_task is Dictionary):
		active_task = {}
	var task: Dictionary = active_task
	if task.is_empty():
		task = _next_farm_task(plots)
	if not task.is_empty():
		if _advance_farm_task(task, plots, production_delta, sow_seconds, harvest_seconds, delta):
			task = {}
	interior_state.active_farm_task = task
	interior_state.plots = plots


func _update_resource_room(delta: float) -> void:
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
				"id": "%s_%d" % [resource_kind, int(Time.get_ticks_msec()) + resources.size()],
				"kind": resource_kind,
				"progress": 0.0,
				"x": 520.0 + float(resources.size() % max_resources) * 180.0,
			})
	interior_state.spawn_elapsed = spawn_elapsed

	if not workers.is_empty() and not resources.is_empty():
		var target: Dictionary = resources[0]
		var duration := data.resource_npc_seconds(resource_kind) / maxf(0.01, _best_worker_multiplier())
		target.progress = float(target.get("progress", 0.0)) + delta / maxf(0.01, duration)
		_move_worker_to(data.interior_resource_worker_position(float(target.get("x", 520.0))), delta)
		if float(target.progress) >= 1.0:
			_complete_resource_work(resource_kind)
			resources.remove_at(0)
		else:
			resources[0] = target
	interior_state.resources = resources


func _complete_crop_harvest(crop_id: String) -> void:
	gold_delta += int(data.crop_value(crop_id, "reward_gold", 1))
	_try_award_worker_seed("harvest")


func _complete_resource_work(resource_kind: String) -> void:
	gold_delta += data.resource_gold_reward(resource_kind)
	_try_award_worker_seed("tree_chop" if resource_kind == "tree" else "stone_mine")


func _try_award_worker_seed(activity_id: String) -> void:
	var seed_id := collection_rules.seed_drop_from_rolls(
		activity_id,
		rng.randf(),
		rng.randf(),
		unlocked_crops,
		data
	)
	if seed_id == "" or workers.is_empty():
		return

	var rewards: Dictionary = interior_state.get("worker_seed_rewards", {})
	var worker_id := str(workers[0].get("worker_id", "worker"))
	if str(rewards.get(worker_id, "")) == "":
		rewards[worker_id] = seed_id
	interior_state.worker_seed_rewards = rewards


func _try_collect_worker_seed() -> bool:
	if worker_visual == null or player == null:
		return false
	if player.position.distance_to(worker_visual.position) > 96.0:
		return false

	var rewards: Dictionary = interior_state.get("worker_seed_rewards", {})
	var collected := false
	for worker_id in rewards.keys():
		var seed_id := str(rewards.get(worker_id, ""))
		if seed_id == "":
			continue
		unlocked_crops[seed_id] = true
		rewards[worker_id] = ""
		collected = true
	interior_state.worker_seed_rewards = rewards
	if collected:
		_create_crop_buttons()
	return collected


func _refresh_visuals() -> void:
	_clear_children(plot_container)
	_clear_children(resource_container)
	match str(interior_definition.get("layout", "shell")):
		"farm":
			_refresh_plot_visuals()
		"lumberyard", "quarry":
			_refresh_resource_visuals()
		"barracks":
			_refresh_barracks_trainees()


func _refresh_plot_visuals() -> void:
	var plots: Array = interior_state.get("plots", [])
	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		var plot_node := Node2D.new()
		plot_node.name = "Plot_%02d" % [i + 1]
		plot_node.position = _plot_position(i)
		plot_container.add_child(plot_node)
		plot_node.add_child(_rect_visual("Soil", Vector2(-70, -22), Vector2(140, 44), Color(0.45, 0.28, 0.12, 1)))
		var stage := str(plot.get("stage", "empty"))
		if stage != "empty":
			plot_node.add_child(_crop_visual(str(plot.get("crop_id", selected_crop_id)), _crop_asset_stage(stage)))


func _refresh_resource_visuals() -> void:
	var resources: Array = interior_state.get("resources", [])
	var resource_kind := str(interior_definition.get("resource_kind", "tree"))
	for i in range(resources.size()):
		var resource: Dictionary = resources[i]
		var node := Node2D.new()
		node.name = "Resource_%02d" % [i + 1]
		node.position = Vector2(float(resource.get("x", 520.0)), 792.0)
		resource_container.add_child(node)
		var asset_id := "interior_tree" if resource_kind == "tree" else "interior_stone"
		var texture := data.art_asset_texture("interiors", asset_id)
		if texture != null:
			var sprite := Sprite2D.new()
			sprite.name = "GeneratedSprite"
			sprite.texture = texture
			sprite.centered = false
			var target := Vector2(96, 128) if resource_kind == "tree" else Vector2(92, 78)
			var scale_factor = minf(target.x / maxf(1.0, float(texture.get_width())), target.y / maxf(1.0, float(texture.get_height())))
			sprite.scale = Vector2(scale_factor, scale_factor)
			sprite.position = Vector2(-float(texture.get_width()) * scale_factor * 0.5, -float(texture.get_height()) * scale_factor)
			node.add_child(sprite)
		else:
			node.add_child(_rect_visual("Fallback", Vector2(-32, -96), Vector2(64, 96), Color(0.18, 0.46, 0.18, 1)))


func _refresh_runtime_labels() -> void:
	if status_label == null:
		return

	status_label.text = "%s  |  门口按 S 返回" % building_display_name
	var layout := str(interior_definition.get("layout", "shell"))
	var pending_seed_count := _pending_seed_count()
	detail_label.text = "本室内获得金币：%d  |  待领取种子：%d" % [gold_delta, pending_seed_count]
	match layout:
		"farm":
			progress_label.text = "农田作物：%s  |  周期：%d秒" % [
				str(data.crop_value(selected_crop_id, "display_name", selected_crop_id)),
				int(interior_definition.get("cycle_seconds", 300.0)),
			]
		"lumberyard", "quarry":
			var resources: Array = interior_state.get("resources", [])
			progress_label.text = "资源：%d/%d" % [resources.size(), int(interior_definition.get("max_resources", 3))]
		"barracks":
			progress_label.text = "training soldiers: %d/%d" % [workers.size(), data.barracks_capacity_for_level(3)]
		_:
			progress_label.text = "空壳室内"

	if worker_visual != null:
		var notice := worker_visual.get_node_or_null("SeedNotice") as CanvasItem
		if notice != null:
			notice.visible = pending_seed_count > 0


func _create_crop_buttons() -> void:
	if crop_button_container == null:
		return
	_clear_children(crop_button_container)
	for crop_id in data.crop_ids():
		var button := Button.new()
		button.name = "Crop_%s" % crop_id
		button.text = str(data.crop_value(str(crop_id), "display_name", crop_id))
		button.disabled = not bool(unlocked_crops.get(str(crop_id), false))
		button.toggle_mode = true
		button.button_pressed = str(crop_id) == selected_crop_id
		button.custom_minimum_size = Vector2(130, 38)
		button.pressed.connect(Callable(self, "_select_crop").bind(str(crop_id)))
		crop_button_container.add_child(button)
	crop_button_container.visible = str(interior_definition.get("layout", "shell")) == "farm"


func _select_crop(crop_id: String) -> void:
	if not bool(unlocked_crops.get(crop_id, false)):
		return
	selected_crop_id = crop_id
	interior_state.selected_crop_id = crop_id
	_create_crop_buttons()


func _update_autosave(delta: float) -> void:
	autosave_elapsed += maxf(delta, 0.0)
	if autosave_elapsed < data.interior_autosave_seconds():
		return
	autosave_elapsed = 0.0
	var game_session := _game_session()
	if game_session != null and game_session.has_method("autosave_cached_main_scene_with_interior_result"):
		game_session.autosave_cached_main_scene_with_interior_result(_result_snapshot(), "interior")
		gold_delta = 0


func _return_to_main_world() -> void:
	var game_session := _game_session()
	if game_session == null:
		get_tree().change_scene_to_file(data.travel_destination_scene_path("main"))
		return

	var result := _result_snapshot()
	if game_session.has_method("set_pending_interior_result"):
		game_session.set_pending_interior_result(result)
	if game_session.has_method("clear_active_interior_context"):
		game_session.clear_active_interior_context()
	if game_session.has_method("restore_cached_main_scene") and game_session.restore_cached_main_scene(get_tree()):
		return
	get_tree().change_scene_to_file(data.travel_destination_scene_path("main"))


func _result_snapshot() -> Dictionary:
	_store_worker_position()
	interior_state.selected_crop_id = selected_crop_id
	return {
		"building_node_name": building_node_name,
		"building_id": building_id,
		"interior_state": interior_state.duplicate(true),
		"gold_delta": gold_delta,
		"unlocked_crops": unlocked_crops.duplicate(true),
	}


func _first_unlocked_crop_id() -> String:
	for crop_id in data.crop_ids():
		if bool(unlocked_crops.get(str(crop_id), false)):
			return str(crop_id)
	return "wheat"


func _best_worker_multiplier() -> float:
	var best := 1.0
	for worker in workers:
		if worker is Dictionary:
			best = maxf(best, float(worker.get("tool_multiplier", 1.0)))
	return best


func _advance_farm_growth(plots: Array, grow_seconds: float, production_delta: float) -> void:
	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		if str(plot.get("stage", "empty")) != "growing":
			continue
		plot.elapsed = float(plot.get("elapsed", 0.0)) + production_delta
		if float(plot.elapsed) >= grow_seconds:
			plot.stage = "harvesting"
			plot.action_elapsed = 0.0
		plots[i] = plot


func _next_farm_task(plots: Array) -> Dictionary:
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


func _advance_farm_task(task: Dictionary, plots: Array, production_delta: float, sow_seconds: float, harvest_seconds: float, movement_delta: float) -> bool:
	var plot_index := int(task.get("plot_index", -1))
	if plot_index < 0 or plot_index >= plots.size():
		return true

	var target_position := data.interior_farm_worker_position(plot_index)
	var was_at_target := _worker_at(target_position)
	_move_worker_to(target_position, movement_delta)
	if not was_at_target:
		return false

	var plot: Dictionary = plots[plot_index]
	var task_type := str(task.get("type", ""))
	if task_type == "":
		task_type = "harvest" if str(plot.get("stage", "empty")) == "harvesting" else "sow"
	var action_seconds := harvest_seconds if task_type == "harvest" else sow_seconds
	plot.action_elapsed = float(plot.get("action_elapsed", 0.0)) + production_delta
	if float(plot.action_elapsed) >= action_seconds:
		if task_type == "harvest":
			_complete_crop_harvest(str(plot.get("crop_id", selected_crop_id)))
			plot.crop_id = selected_crop_id
			plot.stage = "empty"
		else:
			plot.stage = "growing"
		plot.elapsed = 0.0
		plot.action_elapsed = 0.0
		plots[plot_index] = plot
		return true

	plots[plot_index] = plot
	return false


func _move_worker_to_plot(plot_index: int, delta := 0.0) -> void:
	_move_worker_to(data.interior_farm_worker_position(plot_index), delta)


func _move_worker_to(position: Vector2, delta := 0.0) -> void:
	if worker_visual == null:
		return
	var move_distance := data.interior_npc_speed() * maxf(delta, 0.0)
	if move_distance <= 0.0:
		worker_visual.position = worker_visual.position.lerp(position, 0.14)
	else:
		worker_visual.position = worker_visual.position.move_toward(position, move_distance)
	_store_worker_position()


func _worker_at(position: Vector2) -> bool:
	return worker_visual != null and worker_visual.position.distance_to(position) <= 8.0


func _refresh_barracks_trainees() -> void:
	if trainee_container == null:
		return
	_clear_children(trainee_container)
	var is_barracks := str(interior_definition.get("layout", "shell")) == "barracks"
	trainee_container.visible = is_barracks
	if worker_visual != null and is_barracks:
		worker_visual.visible = false
	if not is_barracks:
		return

	var training_workers: Dictionary = interior_state.get("training_workers", {})
	var count := mini(workers.size(), data.barracks_capacity_for_level(3))
	for i in range(count):
		var worker: Dictionary = workers[i] if workers[i] is Dictionary else {}
		var worker_id := str(worker.get("worker_id", "Soldier_%02d" % i))
		var record: Dictionary = training_workers.get(worker_id, {})
		var trainee := Node2D.new()
		trainee.name = "Trainee_%02d" % [i + 1]
		trainee.position = data.barracks_training_position(i)
		trainee.add_child(_character_visual("GeneratedSprite", "soldier", Vector2(64, 96), Color(0.54, 0.48, 0.36, 1)))
		var label := Label.new()
		label.name = "LevelLabel"
		label.text = "L%d" % int(record.get("level", 0))
		label.position = Vector2(-18, -118)
		label.add_theme_font_size_override("font_size", 14)
		trainee.add_child(label)
		trainee_container.add_child(trainee)


func _has_worker(worker_id: String) -> bool:
	for worker in workers:
		if worker is Dictionary and str((worker as Dictionary).get("worker_id", "")) == worker_id:
			return true
	return false


func _worker_position_from_state(default_position: Vector2) -> Vector2:
	var saved = interior_state.get("worker_position", null)
	if saved is Vector2:
		return saved
	if saved is Dictionary:
		return Vector2(
			float(saved.get("x", default_position.x)),
			float(saved.get("y", default_position.y))
		)
	if saved is Array and saved.size() >= 2:
		return Vector2(float(saved[0]), float(saved[1]))
	return default_position


func _store_worker_position() -> void:
	if worker_visual == null:
		return
	interior_state.worker_position = [worker_visual.position.x, worker_visual.position.y]


func _plot_position(plot_index: int) -> Vector2:
	return data.interior_farm_plot_position(plot_index)


func _player_at_door() -> bool:
	return player != null and player.position.distance_to(door_position) <= data.interior_door_range()


func _pending_seed_count() -> int:
	var rewards: Dictionary = interior_state.get("worker_seed_rewards", {})
	var count := 0
	for worker_id in rewards.keys():
		if str(rewards.get(worker_id, "")) != "":
			count += 1
	return count


func _crop_asset_stage(stage: String) -> String:
	if stage == "sowing":
		return "seeded"
	if stage == "harvesting":
		return "ready"
	return stage


func _crop_visual(crop_id: String, stage: String) -> Node:
	var texture := data.art_asset_texture("crops", data.crop_stage_asset_id(crop_id, stage))
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.name = "GeneratedCrop"
		sprite.texture = texture
		sprite.centered = false
		var target := Vector2(100, 72)
		var scale_factor = minf(target.x / maxf(1.0, float(texture.get_width())), target.y / maxf(1.0, float(texture.get_height())))
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2(-float(texture.get_width()) * scale_factor * 0.5, -float(texture.get_height()) * scale_factor)
		return sprite
	return _rect_visual("CropFallback", Vector2(-18, -46), Vector2(36, 44), Color(0.26, 0.72, 0.24, 1))


func _create_farm_hut() -> void:
	var hut := Node2D.new()
	hut.name = "FarmHut"
	hut.position = Vector2(1480, 792)
	add_child(hut)

	var roof := Polygon2D.new()
	roof.name = "Roof"
	roof.color = Color(0.64, 0.25, 0.12, 1)
	roof.polygon = PackedVector2Array([
		Vector2(-190, -130),
		Vector2(0, -230),
		Vector2(190, -130),
	])
	hut.add_child(roof)
	hut.add_child(_rect_visual("Body", Vector2(-145, -130), Vector2(290, 130), Color(0.55, 0.42, 0.28, 1)))
	hut.add_child(_rect_visual("Door", Vector2(-34, -78), Vector2(68, 78), Color(0.24, 0.13, 0.07, 1)))
	hut.add_child(_rect_visual("WindowLeft", Vector2(-108, -94), Vector2(42, 38), Color(0.96, 0.82, 0.36, 1)))
	hut.add_child(_rect_visual("WindowRight", Vector2(66, -94), Vector2(42, 38), Color(0.96, 0.82, 0.36, 1)))
	hut.add_child(_rect_visual("Chimney", Vector2(86, -214), Vector2(34, 78), Color(0.28, 0.22, 0.18, 1)))


func _character_visual(node_name: String, asset_id: String, target_size: Vector2, fallback_color: Color) -> CanvasItem:
	var texture := data.art_asset_texture("npcs", asset_id)
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.name = node_name
		sprite.texture = texture
		sprite.centered = false
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
	return _rect_visual("Body", Vector2(-16, -70), Vector2(32, 70), fallback_color)


func _worker_asset_id() -> String:
	if not workers.is_empty() and workers[0] is Dictionary:
		var worker: Dictionary = workers[0]
		var explicit_role := str(worker.get("role", ""))
		if explicit_role != "":
			return explicit_role
	var role := str(interior_definition.get("worker_role", "villager"))
	if role == "":
		return "villager"
	return role


func _background_color_for_layout() -> Color:
	match str(interior_definition.get("layout", "shell")):
		"farm":
			return Color(0.42, 0.62, 0.46, 1)
		"lumberyard":
			return Color(0.18, 0.26, 0.18, 1)
		"quarry":
			return Color(0.22, 0.22, 0.24, 1)
		"barracks":
			return Color(0.18, 0.16, 0.14, 1)
	return Color(0.16, 0.14, 0.18, 1)


func _floor_color_for_layout() -> Color:
	match str(interior_definition.get("layout", "shell")):
		"farm":
			return Color(0.24, 0.5, 0.22, 1)
		"lumberyard":
			return Color(0.2, 0.28, 0.16, 1)
		"quarry":
			return Color(0.23, 0.23, 0.24, 1)
		"barracks":
			return Color(0.24, 0.2, 0.16, 1)
	return Color(0.18, 0.13, 0.09, 1)


func _rect_visual(node_name: String, position: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = position
	rect.size = size
	rect.color = color
	return rect


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()


func _game_session() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("GameSession")
