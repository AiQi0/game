extends RefCounted

const BUILD_GAP := 56.0


func selected_index_from_key(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 0
		KEY_2:
			return 1
		KEY_3:
			return 2
		KEY_4:
			return 3
		KEY_5:
			return 4
		_:
			return -1


func selected_index_after_request(current_index: int, requested_index: int) -> int:
	if current_index == requested_index:
		return -1

	return requested_index


func build_position_for_player(
	player_position: Vector2,
	facing_direction: int,
	building_size: Vector2,
	ground_y: float
) -> Vector2:
	var direction := 1
	if facing_direction < 0:
		direction = -1

	return Vector2(
		player_position.x + direction * (building_size.x * 0.5 + BUILD_GAP),
		ground_y
	)


func footprint_for_position(bottom_center: Vector2, size: Vector2) -> Rect2:
	return Rect2(
		Vector2(bottom_center.x - size.x * 0.5, bottom_center.y - size.y),
		size
	)


func has_overlap(candidate: Rect2, occupied_footprints: Array) -> bool:
	for footprint in occupied_footprints:
		if _rects_overlap(candidate, footprint):
			return true

	return false


func footprint_index_containing_point(point: Vector2, footprints: Array) -> int:
	for i in range(footprints.size()):
		if _rect_contains_point_inclusive(footprints[i], point):
			return i

	return -1


func demolishable_entity_index_containing_point(point: Vector2, entities: Array) -> int:
	for i in range(entities.size()):
		var entity: Dictionary = entities[i]
		if not entity.get("demolishable", true):
			continue

		if _rect_contains_point_inclusive(entity.footprint, point):
			return i

	return -1


func random_tree_positions(
	seed: int,
	count: int,
	ground_min_x: float,
	ground_max_x: float,
	ground_y: float,
	tree_size: Vector2,
	blocked_footprints: Array
) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var positions: Array = []
	var occupied: Array = blocked_footprints.duplicate()
	var attempts: int = 0
	var max_attempts: int = maxi(80, count * 80)
	var min_x: float = ground_min_x + tree_size.x * 0.5
	var max_x: float = ground_max_x - tree_size.x * 0.5

	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var position: Vector2 = Vector2(rng.randf_range(min_x, max_x), ground_y)
		var footprint: Rect2 = footprint_for_position(position, tree_size)
		if has_overlap(footprint, occupied):
			continue

		positions.append(position)
		occupied.append(footprint)

	return positions


func tree_positions_around_source(
	seed: int,
	count: int,
	source_position: Vector2,
	radius: float,
	ground_min_x: float,
	ground_max_x: float,
	ground_y: float,
	tree_size: Vector2,
	blocked_footprints: Array
) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var positions: Array = []
	var occupied: Array = blocked_footprints.duplicate()
	var attempts: int = 0
	var max_attempts: int = maxi(80, count * 80)
	var min_x: float = maxf(ground_min_x + tree_size.x * 0.5, source_position.x - radius)
	var max_x: float = minf(ground_max_x - tree_size.x * 0.5, source_position.x + radius)

	while positions.size() < count and attempts < max_attempts and min_x <= max_x:
		attempts += 1
		var position := Vector2(rng.randf_range(min_x, max_x), ground_y)
		if absf(position.x - source_position.x) > radius:
			continue

		var footprint := footprint_for_position(position, tree_size)
		if has_overlap(footprint, occupied):
			continue

		positions.append(position)
		occupied.append(footprint)

	return positions


func air_wall_footprints(
	ground_min_x: float,
	ground_max_x: float,
	wall_width: float,
	wall_height: float
) -> Array:
	return [
		Rect2(Vector2(ground_min_x - wall_width, -wall_height), Vector2(wall_width, wall_height * 2.0)),
		Rect2(Vector2(ground_max_x, -wall_height), Vector2(wall_width, wall_height * 2.0)),
	]


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return (
		a.position.x < b.position.x + b.size.x
		and a.position.x + a.size.x > b.position.x
		and a.position.y < b.position.y + b.size.y
		and a.position.y + a.size.y > b.position.y
	)


func _rect_contains_point_inclusive(rect: Rect2, point: Vector2) -> bool:
	return (
		point.x >= rect.position.x
		and point.x <= rect.position.x + rect.size.x
		and point.y >= rect.position.y
		and point.y <= rect.position.y + rect.size.y
	)
