extends RefCounted

const GameData = preload("res://scripts/GameData.gd")

const WINDOW_DARK := Color(0.08, 0.1, 0.13, 1)
const WINDOW_LIT := Color(1.0, 0.82, 0.24, 1)

var game_data := GameData.new()


func create_building_visual(definition: Dictionary) -> Node2D:
	var root := Node2D.new()
	root.name = definition.get("id", "Building")

	match definition.get("id", ""):
		"blacksmith":
			_add_blacksmith(root, definition)
		"wall":
			_add_wall(root, definition)
		"farm":
			_add_farm(root, definition)
		"tavern":
			_add_tavern(root, definition)
		"quarry":
			_add_quarry(root, definition)
		_:
			_add_box(root, definition)

	_add_generated_sprite(root, definition)
	return root


func set_occupied(building: Node, occupied: bool) -> void:
	var target_color := WINDOW_LIT if occupied else WINDOW_DARK
	for window in _window_nodes(building):
		window.color = target_color


func _add_blacksmith(root: Node2D, definition: Dictionary) -> void:
	var size: Vector2 = definition.size
	var base: Color = definition.base_color
	var accent: Color = definition.accent_color
	var w := size.x
	var h := size.y

	root.add_child(_polygon("Body", base, [
		Vector2(-w * 0.45, -h * 0.72),
		Vector2(w * 0.45, -h * 0.72),
		Vector2(w * 0.45, 0),
		Vector2(-w * 0.45, 0),
	]))
	root.add_child(_polygon("Roof", accent, [
		Vector2(-w * 0.55, -h * 0.72),
		Vector2(0, -h),
		Vector2(w * 0.55, -h * 0.72),
	]))
	root.add_child(_polygon("Chimney", Color(0.18, 0.16, 0.15, 1), [
		Vector2(w * 0.24, -h * 0.98),
		Vector2(w * 0.36, -h * 0.98),
		Vector2(w * 0.36, -h * 0.62),
		Vector2(w * 0.24, -h * 0.62),
	]))
	root.add_child(_polygon("Door", Color(0.15, 0.1, 0.08, 1), [
		Vector2(-w * 0.12, -h * 0.36),
		Vector2(w * 0.12, -h * 0.36),
		Vector2(w * 0.12, 0),
		Vector2(-w * 0.12, 0),
	]))
	root.add_child(_polygon("WindowForge", WINDOW_DARK, [
		Vector2(-w * 0.34, -h * 0.46),
		Vector2(-w * 0.18, -h * 0.46),
		Vector2(-w * 0.18, -h * 0.3),
		Vector2(-w * 0.34, -h * 0.3),
	]))


func _add_wall(root: Node2D, definition: Dictionary) -> void:
	var size: Vector2 = definition.size
	var base: Color = definition.base_color
	var accent: Color = definition.accent_color
	var w := size.x
	var h := size.y

	root.add_child(_polygon("WallBody", base, [
		Vector2(-w * 0.5, -h * 0.78),
		Vector2(w * 0.5, -h * 0.78),
		Vector2(w * 0.5, 0),
		Vector2(-w * 0.5, 0),
	]))

	for i in range(4):
		var left := -w * 0.5 + i * w * 0.25
		root.add_child(_polygon("Crenel%d" % i, accent, [
			Vector2(left, -h),
			Vector2(left + w * 0.16, -h),
			Vector2(left + w * 0.16, -h * 0.78),
			Vector2(left, -h * 0.78),
		]))

	root.add_child(_polygon("Gate", Color(0.18, 0.17, 0.16, 1), [
		Vector2(-w * 0.14, -h * 0.38),
		Vector2(w * 0.14, -h * 0.38),
		Vector2(w * 0.14, 0),
		Vector2(-w * 0.14, 0),
	]))
	root.add_child(_polygon("WindowSlit", WINDOW_DARK, [
		Vector2(-w * 0.36, -h * 0.62),
		Vector2(-w * 0.26, -h * 0.62),
		Vector2(-w * 0.26, -h * 0.44),
		Vector2(-w * 0.36, -h * 0.44),
	]))


func _add_farm(root: Node2D, definition: Dictionary) -> void:
	var size: Vector2 = definition.size
	var base: Color = definition.base_color
	var accent: Color = definition.accent_color
	var w := size.x
	var h := size.y

	root.add_child(_polygon("Soil", base, [
		Vector2(-w * 0.5, -h),
		Vector2(w * 0.5, -h),
		Vector2(w * 0.5, 0),
		Vector2(-w * 0.5, 0),
	]))

	for i in range(4):
		var top := -h + i * h * 0.25 + h * 0.08
		root.add_child(_polygon("CropRow%d" % i, accent, [
			Vector2(-w * 0.45, top),
			Vector2(w * 0.45, top),
			Vector2(w * 0.45, top + h * 0.08),
			Vector2(-w * 0.45, top + h * 0.08),
		]))

	root.add_child(_polygon("Fence", Color(0.72, 0.54, 0.32, 1), [
		Vector2(-w * 0.55, -h * 0.18),
		Vector2(w * 0.55, -h * 0.18),
		Vector2(w * 0.55, -h * 0.08),
		Vector2(-w * 0.55, -h * 0.08),
	]))
	root.add_child(_polygon("WindowLantern", WINDOW_DARK, [
		Vector2(w * 0.28, -h * 0.84),
		Vector2(w * 0.38, -h * 0.84),
		Vector2(w * 0.38, -h * 0.64),
		Vector2(w * 0.28, -h * 0.64),
	]))


func _add_tavern(root: Node2D, definition: Dictionary) -> void:
	var size: Vector2 = definition.size
	var base: Color = definition.base_color
	var accent: Color = definition.accent_color
	var w := size.x
	var h := size.y

	root.add_child(_polygon("Body", base, [
		Vector2(-w * 0.44, -h * 0.7),
		Vector2(w * 0.44, -h * 0.7),
		Vector2(w * 0.44, 0),
		Vector2(-w * 0.44, 0),
	]))
	root.add_child(_polygon("Roof", accent, [
		Vector2(-w * 0.55, -h * 0.7),
		Vector2(0, -h),
		Vector2(w * 0.55, -h * 0.7),
	]))
	root.add_child(_polygon("Door", Color(0.2, 0.11, 0.06, 1), [
		Vector2(-w * 0.12, -h * 0.38),
		Vector2(w * 0.12, -h * 0.38),
		Vector2(w * 0.12, 0),
		Vector2(-w * 0.12, 0),
	]))
	root.add_child(_polygon("Sign", Color(0.95, 0.78, 0.34, 1), [
		Vector2(w * 0.18, -h * 0.6),
		Vector2(w * 0.42, -h * 0.6),
		Vector2(w * 0.42, -h * 0.42),
		Vector2(w * 0.18, -h * 0.42),
	]))
	root.add_child(_polygon("WindowLeft", WINDOW_DARK, [
		Vector2(-w * 0.32, -h * 0.5),
		Vector2(-w * 0.16, -h * 0.5),
		Vector2(-w * 0.16, -h * 0.34),
		Vector2(-w * 0.32, -h * 0.34),
	]))


func _add_quarry(root: Node2D, definition: Dictionary) -> void:
	var size: Vector2 = definition.size
	var base: Color = definition.base_color
	var accent: Color = definition.accent_color
	var w := size.x
	var h := size.y

	root.add_child(_polygon("RockPile", base, [
		Vector2(-w * 0.48, 0),
		Vector2(-w * 0.36, -h * 0.52),
		Vector2(-w * 0.12, -h * 0.82),
		Vector2(w * 0.16, -h * 0.68),
		Vector2(w * 0.46, -h * 0.28),
		Vector2(w * 0.42, 0),
	]))
	root.add_child(_polygon("CutFace", accent, [
		Vector2(-w * 0.12, -h * 0.78),
		Vector2(w * 0.16, -h * 0.68),
		Vector2(w * 0.04, -h * 0.32),
		Vector2(-w * 0.28, -h * 0.38),
	]))
	root.add_child(_polygon("WindowMain", WINDOW_DARK, [
		Vector2(w * 0.16, -h * 0.44),
		Vector2(w * 0.32, -h * 0.44),
		Vector2(w * 0.32, -h * 0.26),
		Vector2(w * 0.16, -h * 0.26),
	]))


func _add_box(root: Node2D, definition: Dictionary) -> void:
	var size: Vector2 = definition.get("size", Vector2(120, 120))
	var color: Color = definition.get("base_color", Color(0.7, 0.7, 0.7, 1))

	root.add_child(_polygon("Body", color, [
		Vector2(-size.x * 0.5, -size.y),
		Vector2(size.x * 0.5, -size.y),
		Vector2(size.x * 0.5, 0),
		Vector2(-size.x * 0.5, 0),
	]))
	root.add_child(_polygon("WindowMain", WINDOW_DARK, [
		Vector2(-size.x * 0.16, -size.y * 0.55),
		Vector2(size.x * 0.16, -size.y * 0.55),
		Vector2(size.x * 0.16, -size.y * 0.35),
		Vector2(-size.x * 0.16, -size.y * 0.35),
	]))


func _polygon(node_name: String, color: Color, points: Array) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array(points)
	return polygon


func _add_generated_sprite(root: Node2D, definition: Dictionary) -> void:
	var building_id := str(definition.get("id", ""))
	var texture := game_data.art_asset_texture("buildings", building_id)
	if texture == null:
		return

	_hide_canvas_children(root)
	var sprite := Sprite2D.new()
	sprite.name = "GeneratedSprite"
	sprite.texture = texture
	sprite.centered = false
	var target_size: Vector2 = definition.get("size", Vector2(texture.get_width(), texture.get_height()))
	var scale_factor = minf(
		target_size.x / maxf(1.0, float(texture.get_width())),
		target_size.y / maxf(1.0, float(texture.get_height()))
	)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(
		-float(texture.get_width()) * scale_factor * 0.5,
		-float(texture.get_height()) * scale_factor
	)
	root.add_child(sprite)


func _hide_canvas_children(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		_hide_canvas_children(child)


func _window_nodes(node: Node) -> Array:
	var windows: Array = []
	if node is Polygon2D and node.name.begins_with("Window"):
		windows.append(node)

	for child in node.get_children():
		windows.append_array(_window_nodes(child))

	return windows
