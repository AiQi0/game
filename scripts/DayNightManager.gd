extends Node

const DayNightRules = preload("res://scripts/DayNightRules.gd")
const GameData = preload("res://scripts/GameData.gd")

const VIEWPORT_SIZE := Vector2(1920, 1080)
const DAY_SKY := Color(0.52, 0.78, 1.0, 1)
const NIGHT_SKY := Color(0.05, 0.07, 0.16, 1)

var rules := DayNightRules.new()
var game_data := GameData.new()
var elapsed_seconds := 0.0
var sky: ColorRect
var sun: Node2D
var moon: Node2D


func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "SkyLayer"
	canvas.layer = -100
	add_child(canvas)

	sky = ColorRect.new()
	sky.name = "SkyBackground"
	sky.size = VIEWPORT_SIZE
	canvas.add_child(sky)

	sun = _celestial_visual("Sun", "sun", 88.0, Color(1.0, 0.82, 0.22, 1))
	canvas.add_child(sun)

	moon = _celestial_visual("Moon", "moon", 68.0, Color(0.82, 0.88, 1.0, 1))
	canvas.add_child(moon)

	_update_visuals()


func _process(delta: float) -> void:
	elapsed_seconds += delta
	_update_visuals()


func _update_visuals() -> void:
	var phase := rules.phase_for_time(elapsed_seconds)
	var progress := rules.phase_progress(elapsed_seconds)
	var position := rules.celestial_arc_position(progress, VIEWPORT_SIZE)

	sky.color = DAY_SKY if phase == "day" else NIGHT_SKY
	sun.visible = phase == "day"
	moon.visible = phase == "night"
	sun.position = position
	moon.position = position


func _circle_polygon(node_name: String, radius: float, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	polygon.name = node_name
	polygon.color = color
	polygon.polygon = points
	return polygon


func _celestial_visual(node_name: String, asset_id: String, diameter: float, fallback_color: Color) -> Node2D:
	var texture := game_data.art_asset_texture("environment", asset_id)
	if texture == null:
		return _circle_polygon(node_name, diameter * 0.5, fallback_color)

	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = true
	var scale_factor = diameter / maxf(float(texture.get_width()), float(texture.get_height()))
	sprite.scale = Vector2(scale_factor, scale_factor)
	return sprite
