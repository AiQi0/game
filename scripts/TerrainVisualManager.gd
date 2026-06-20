extends Node2D

const GameData = preload("res://scripts/GameData.gd")

@export var terrain_set_id := "main_grass"

var game_data := GameData.new()
var camera: Camera2D
var water_spans: Array = []

var _initialized := false
var _background_layers := []


func _ready() -> void:
	if _initialized:
		return

	_initialized = true
	_resolve_camera()
	rebuild_visuals()
	set_process(true)


func _process(_delta: float) -> void:
	_update_background_positions()


func rebuild_visuals() -> void:
	_clear_children()
	_background_layers.clear()
	_create_backgrounds()
	_create_ground_tiles()
	_create_water_tiles()
	_update_background_positions()


func set_water_spans(spans: Array) -> void:
	water_spans = spans.duplicate(true)
	if _initialized:
		_create_water_tiles()


func _resolve_camera() -> void:
	camera = get_node_or_null("../Player/Camera2D") as Camera2D
	if camera == null:
		camera = get_viewport().get_camera_2d()


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


func _create_backgrounds() -> void:
	var backgrounds := Node2D.new()
	backgrounds.name = "Backgrounds"
	backgrounds.z_index = -120
	add_child(backgrounds)

	var terrain_data := game_data.terrain_set(terrain_set_id)
	for layer_data in terrain_data.get("background_layers", []):
		var layer := _create_background_layer(layer_data)
		if layer != null:
			backgrounds.add_child(layer)
			_background_layers.append(layer)


func _create_background_layer(layer_data: Dictionary) -> Node2D:
	var asset_id := str(layer_data.get("asset", ""))
	var texture := game_data.terrain_asset_texture(asset_id)
	if texture == null:
		return null

	var layer := Node2D.new()
	layer.name = str(layer_data.get("id", asset_id))
	layer.z_index = int(layer_data.get("z_index", 0))
	layer.set_meta("parallax", float(layer_data.get("parallax", 0.0)))
	layer.set_meta("base_position", layer_data.get("position", Vector2.ZERO))
	layer.set_meta("repeat", bool(layer_data.get("repeat", true)))
	layer.set_meta("texture_width", float(texture.get_width()))

	var repeat_count := 5 if bool(layer_data.get("repeat", true)) else 1
	for i in range(repeat_count):
		var sprite := Sprite2D.new()
		sprite.name = "Sprite_%02d" % i
		sprite.centered = false
		sprite.texture = texture
		layer.add_child(sprite)

	return layer


func _create_ground_tiles() -> void:
	var terrain_data := game_data.terrain_set(terrain_set_id)
	var tile_ids: Array = terrain_data.get("ground_tiles", [])
	if tile_ids.is_empty():
		return

	var tile_size := game_data.terrain_tile_size()
	var start_x := GameData.GROUND_MIN_X - game_data.visual_chunk_width()
	var end_x := GameData.GROUND_MAX_X + game_data.visual_chunk_width()
	var tile_count := int(ceil((end_x - start_x) / tile_size.x))

	var ground_tiles := Node2D.new()
	ground_tiles.name = "GroundTiles"
	ground_tiles.z_index = 0
	add_child(ground_tiles)

	var fill_tiles := Node2D.new()
	fill_tiles.name = "GroundFillTiles"
	fill_tiles.z_index = -1
	add_child(fill_tiles)

	var fill_texture := game_data.terrain_asset_texture(str(terrain_data.get("ground_fill", "")))
	for i in range(tile_count):
		var ground_texture := game_data.terrain_asset_texture(str(tile_ids[i % tile_ids.size()]))
		if ground_texture != null:
			var tile := _create_sprite("GroundTile_%03d" % i, ground_texture, Vector2(start_x + i * tile_size.x, GameData.GROUND_TOP_Y))
			ground_tiles.add_child(tile)

		if fill_texture != null:
			var fill := _create_sprite("GroundFill_%03d" % i, fill_texture, Vector2(start_x + i * tile_size.x, GameData.GROUND_TOP_Y + tile_size.y))
			fill_tiles.add_child(fill)


func _create_water_tiles() -> void:
	var existing := get_node_or_null("WaterTiles")
	if existing != null:
		remove_child(existing)
		existing.free()

	var water_tiles := Node2D.new()
	water_tiles.name = "WaterTiles"
	water_tiles.z_index = -2
	add_child(water_tiles)

	var terrain_data := game_data.terrain_set(terrain_set_id)
	var water_texture := game_data.terrain_asset_texture(str(terrain_data.get("water_tile", "")))
	if water_texture == null:
		return

	var tile_width := maxf(1.0, float(water_texture.get_width()))
	for span_index in range(water_spans.size()):
		var span: Rect2 = water_spans[span_index]
		var tile_count := int(ceil(span.size.x / tile_width))
		for tile_index in range(tile_count):
			var x := span.position.x + tile_index * tile_width
			var tile := _create_sprite("Water_%02d_%03d" % [span_index, tile_index], water_texture, Vector2(x, span.position.y))
			water_tiles.add_child(tile)


func _create_sprite(sprite_name: String, texture: Texture2D, sprite_position: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.centered = false
	sprite.texture = texture
	sprite.position = sprite_position
	return sprite


func _update_background_positions() -> void:
	var camera_x := _camera_x()
	for layer in _background_layers:
		if not is_instance_valid(layer):
			continue

		var base_position: Vector2 = layer.get_meta("base_position", Vector2.ZERO)
		layer.position.y = base_position.y
		if not bool(layer.get_meta("repeat", true)):
			layer.position.x = camera_x + base_position.x - float(layer.get_meta("texture_width", 1920.0)) * 0.5
			continue

		var texture_width := maxf(1.0, float(layer.get_meta("texture_width", 1920.0)))
		var parallax := float(layer.get_meta("parallax", 0.0))
		var scroll_origin := camera_x * (1.0 - parallax)
		var start_x: float = floor((camera_x - scroll_origin - texture_width * 2.0) / texture_width) * texture_width + scroll_origin + base_position.x
		for i in range(layer.get_child_count()):
			var sprite := layer.get_child(i) as Sprite2D
			if sprite != null:
				sprite.position.x = start_x + i * texture_width
				sprite.position.y = 0.0


func _camera_x() -> float:
	if camera != null and is_instance_valid(camera):
		return camera.global_position.x
	return (GameData.GROUND_MIN_X + GameData.GROUND_MAX_X) * 0.5
