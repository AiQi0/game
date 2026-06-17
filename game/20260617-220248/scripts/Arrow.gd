extends Node2D

const FLIGHT_SECONDS := 0.8
const ARC_HEIGHT := 120.0
const LANDED_VISIBLE_SECONDS := 5.0
const FADE_SECONDS := 1.0

var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var damage := 0
var flight_elapsed := 0.0
var landed_elapsed := 0.0
var has_landed := false


func setup(from_position: Vector2, to_position: Vector2, attack_damage: int) -> void:
	start_position = from_position
	target_position = to_position
	damage = attack_damage
	flight_elapsed = 0.0
	landed_elapsed = 0.0
	has_landed = false
	global_position = start_position
	modulate = Color.WHITE
	_create_visual()


func _process(delta: float) -> void:
	if not has_landed:
		flight_elapsed += delta
		var t: float = clamp(flight_elapsed / FLIGHT_SECONDS, 0.0, 1.0)
		var base := start_position.lerp(target_position, t)
		var arc_y: float = -sin(t * PI) * ARC_HEIGHT
		global_position = base + Vector2(0.0, arc_y)
		if t >= 1.0:
			has_landed = true
			global_position = target_position
		return

	landed_elapsed += delta
	if landed_elapsed <= LANDED_VISIBLE_SECONDS:
		modulate.a = 1.0
		return

	var fade_t: float = clamp((landed_elapsed - LANDED_VISIBLE_SECONDS) / FADE_SECONDS, 0.0, 1.0)
	modulate.a = 1.0 - fade_t
	if fade_t >= 1.0:
		queue_free()


func _create_visual() -> void:
	if get_child_count() > 0:
		return

	var shaft := Polygon2D.new()
	shaft.name = "ArrowShaft"
	shaft.color = Color(0.72, 0.5, 0.28, 1)
	shaft.polygon = PackedVector2Array([
		Vector2(-18, -2),
		Vector2(12, -2),
		Vector2(12, 2),
		Vector2(-18, 2),
	])
	add_child(shaft)

	var head := Polygon2D.new()
	head.name = "ArrowHead"
	head.color = Color(0.84, 0.86, 0.82, 1)
	head.polygon = PackedVector2Array([
		Vector2(12, -6),
		Vector2(24, 0),
		Vector2(12, 6),
	])
	add_child(head)
