extends RefCounted

const NPCScript = preload("res://scripts/NPC.gd")


func create_homeless(start_position: Vector2, city_hall_front: Vector2) -> Node2D:
	var npc := Node2D.new()
	npc.name = "Homeless"
	npc.set_script(NPCScript)

	var body := _polygon("Body", NPCScript.HOMELESS_COLOR, [
		Vector2(-10, -42),
		Vector2(10, -42),
		Vector2(12, 0),
		Vector2(-12, 0),
	])
	var head := _polygon("Head", Color(0.82, 0.62, 0.46, 1), [
		Vector2(-8, -58),
		Vector2(8, -58),
		Vector2(8, -42),
		Vector2(-8, -42),
	])
	var pack := _polygon("Pack", Color(0.24, 0.18, 0.13, 1), [
		Vector2(8, -36),
		Vector2(18, -34),
		Vector2(18, -8),
		Vector2(10, -6),
	])

	npc.add_child(body)
	npc.add_child(head)
	npc.add_child(pack)
	npc.body = body
	npc.setup(start_position, city_hall_front)
	return npc


func _polygon(node_name: String, color: Color, points: Array) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array(points)
	return polygon
