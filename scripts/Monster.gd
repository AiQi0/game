extends Node2D

const GameData = preload("res://scripts/GameData.gd")

const MAX_HEALTH := GameData.MONSTER_MAX_HEALTH

var health := MAX_HEALTH
var side := "left"
var direction := 1
var state := "advance"
var charge_elapsed := 0.0
var dash_remaining := 0.0
var dash_start_position := Vector2.ZERO
var attack_target: Node2D
var carried_tool := ""
var stolen_gold := 0
var game_data := GameData.new()


func setup(spawn_side: String, spawn_position: Vector2) -> void:
	side = spawn_side
	direction = 1 if side == "left" else -1
	global_position = spawn_position
	_create_visual()


func take_damage(amount: int) -> bool:
	health -= amount
	modulate = Color(1.0, 0.45, 0.45, 1)
	if health <= 0:
		queue_free()
		return true

	return false


func begin_return(tool_id := "", gold_amount := 0) -> void:
	carried_tool = tool_id
	stolen_gold = gold_amount
	state = "returning"
	attack_target = null
	charge_elapsed = 0.0
	dash_remaining = 0.0
	_update_loot_visual()


func _create_visual() -> void:
	if get_child_count() > 0:
		return

	var body := Polygon2D.new()
	body.name = "MonsterBody"
	body.color = Color(0.25, 0.08, 0.12, 1)
	body.polygon = PackedVector2Array([
		Vector2(-16, -54),
		Vector2(16, -54),
		Vector2(20, 0),
		Vector2(-20, 0),
	])
	add_child(body)

	var eye := Polygon2D.new()
	eye.name = "MonsterEye"
	eye.color = Color(1.0, 0.1, 0.08, 1)
	eye.polygon = PackedVector2Array([
		Vector2(-8, -42),
		Vector2(8, -42),
		Vector2(8, -34),
		Vector2(-8, -34),
	])
	add_child(eye)

	_add_generated_sprite()


func _update_loot_visual() -> void:
	var old_loot := get_node_or_null("LootVisual")
	if old_loot != null:
		if old_loot.is_inside_tree():
			old_loot.queue_free()
		else:
			old_loot.free()

	if carried_tool == "" and stolen_gold <= 0:
		return

	var loot := Polygon2D.new()
	loot.name = "LootVisual"
	loot.position = Vector2(0, -76)
	if carried_tool != "":
		loot.color = _tool_color(carried_tool)
		loot.polygon = _tool_loot_polygon(carried_tool)
	else:
		loot.color = Color(1.0, 0.82, 0.22, 1)
		loot.polygon = PackedVector2Array([
			Vector2(-10, -10),
			Vector2(10, -10),
			Vector2(10, 10),
			Vector2(-10, 10),
		])
	add_child(loot)


func _add_generated_sprite() -> void:
	var texture := game_data.art_asset_texture("npcs", "monster")
	if texture == null:
		return

	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false

	var sprite := Sprite2D.new()
	sprite.name = "GeneratedSprite"
	sprite.texture = texture
	sprite.centered = false
	var target_size := Vector2(64, 96)
	var scale_factor = minf(
		target_size.x / maxf(1.0, float(texture.get_width())),
		target_size.y / maxf(1.0, float(texture.get_height()))
	)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(
		-float(texture.get_width()) * scale_factor * 0.5,
		-float(texture.get_height()) * scale_factor
	)
	add_child(sprite)


func _tool_color(tool_id: String) -> Color:
	return game_data.tool_color(tool_id)


func _tool_loot_polygon(tool_id: String) -> PackedVector2Array:
	match tool_id:
		"axe":
			return PackedVector2Array([
				Vector2(-4, -18),
				Vector2(4, -18),
				Vector2(4, 14),
				Vector2(-4, 14),
				Vector2(4, -14),
				Vector2(18, -8),
				Vector2(4, -2),
			])
		"sickle":
			return PackedVector2Array([
				Vector2(-4, -14),
				Vector2(4, -14),
				Vector2(4, 14),
				Vector2(-4, 14),
				Vector2(4, -14),
				Vector2(18, -8),
				Vector2(12, -2),
			])
		"bow":
			return PackedVector2Array([
				Vector2(-12, -18),
				Vector2(2, -14),
				Vector2(10, 0),
				Vector2(2, 14),
				Vector2(-12, 18),
				Vector2(-6, 0),
			])
		_:
			return PackedVector2Array([
				Vector2(-4, -20),
				Vector2(4, -20),
				Vector2(4, 14),
				Vector2(-4, 14),
			])
