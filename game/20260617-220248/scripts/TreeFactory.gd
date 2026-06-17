extends RefCounted


func create_tree_visual() -> Node2D:
	var root := Node2D.new()
	root.name = "Tree"

	root.add_child(_polygon("Trunk", Color(0.38, 0.22, 0.1, 1), [
		Vector2(-9, -52),
		Vector2(9, -52),
		Vector2(9, 0),
		Vector2(-9, 0),
	]))
	root.add_child(_polygon("LowerLeaves", Color(0.18, 0.5, 0.23, 1), [
		Vector2(-34, -48),
		Vector2(0, -92),
		Vector2(34, -48),
	]))
	root.add_child(_polygon("UpperLeaves", Color(0.24, 0.62, 0.28, 1), [
		Vector2(-28, -74),
		Vector2(0, -120),
		Vector2(28, -74),
	]))

	return root


func _polygon(node_name: String, color: Color, points: Array) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array(points)
	return polygon
