extends RefCounted

const SPAWN_INTERVAL_SECONDS := 300.0
const HOMELESS_SPAWN_CHANCE := 0.3
const MIN_HOMELESS_COUNT := 2
const MAX_HOMELESS_COUNT := 4
const STARTING_VILLAGER_COUNT := 3
const STARTING_HOMELESS_COUNT := 5
const STARTING_VILLAGER_SPACING := 48.0


func spawn_interval_seconds() -> float:
	return SPAWN_INTERVAL_SECONDS


func starting_villager_count() -> int:
	return STARTING_VILLAGER_COUNT


func starting_homeless_count() -> int:
	return STARTING_HOMELESS_COUNT


func starting_villager_positions(city_hall_front: Vector2) -> Array:
	var positions: Array = []
	var first_offset := -STARTING_VILLAGER_SPACING * float(STARTING_VILLAGER_COUNT - 1) / 2.0

	for i in range(STARTING_VILLAGER_COUNT):
		positions.append(Vector2(city_hall_front.x + first_offset + STARTING_VILLAGER_SPACING * i, city_hall_front.y))

	return positions


func should_spawn_from_roll(roll: float) -> bool:
	return roll < HOMELESS_SPAWN_CHANCE


func spawn_count_from_seed(seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng.randi_range(MIN_HOMELESS_COUNT, MAX_HOMELESS_COUNT)


func spawn_positions_from_seed(
	seed: int,
	count: int,
	ground_min_x: float,
	ground_max_x: float,
	ground_y: float
) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var positions: Array = []
	for _i in range(count):
		positions.append(Vector2(rng.randf_range(ground_min_x, ground_max_x), ground_y))

	return positions


func nearest_available_work_site_index(origin: Vector2, sites: Array) -> int:
	var nearest_index := -1
	var nearest_distance := INF

	for i in range(sites.size()):
		var site: Dictionary = sites[i]
		if not site.get("is_workplace", false):
			continue
		if site.has("worker_capacity") or site.has("worker_count"):
			if int(site.get("worker_count", 0)) >= int(site.get("worker_capacity", 1)):
				continue
		else:
			if site.get("worker_id", "") != "":
				continue

		var distance := origin.distance_to(site.position)
		if distance < nearest_distance:
			nearest_index = i
			nearest_distance = distance

	return nearest_index
