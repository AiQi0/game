extends RefCounted

const FIRST_MONSTER_NIGHT := 3
const SIDE_SPAWN_CHANCE := 0.4
const MIN_MONSTERS_PER_SIDE := 3
const MAX_MONSTERS_PER_SIDE := 6
const MIN_PLAYER_GOLD_LOSS := 50


func should_spawn_side(night_number: int, roll: float, safe_nights_remaining := 0) -> bool:
	if safe_nights_remaining > 0:
		return false
	if night_number == 1 or night_number == 2:
		return true
	if night_number < FIRST_MONSTER_NIGHT:
		return false

	return roll < SIDE_SPAWN_CHANCE


func spawn_count_from_seed(seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng.randi_range(MIN_MONSTERS_PER_SIDE, MAX_MONSTERS_PER_SIDE)


func spawn_count_for_side(night_number: int, side: String, roll: float, rng_source, safe_nights_remaining := 0) -> int:
	if safe_nights_remaining > 0:
		return 0
	if side != "left" and side != "right":
		return 0
	if night_number == 1 or night_number == 2:
		return 1
	if night_number < FIRST_MONSTER_NIGHT:
		return 0
	if roll >= SIDE_SPAWN_CHANCE:
		return 0

	return _spawn_count_from_source(rng_source)


func _spawn_count_from_source(rng_source) -> int:
	if rng_source is RandomNumberGenerator:
		return rng_source.randi_range(MIN_MONSTERS_PER_SIDE, MAX_MONSTERS_PER_SIDE)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(rng_source)
	return rng.randi_range(MIN_MONSTERS_PER_SIDE, MAX_MONSTERS_PER_SIDE)


func gold_loss_for_player_hit(current_gold: int) -> int:
	return max(int(ceil(float(current_gold) * 0.5)), MIN_PLAYER_GOLD_LOSS)


func player_dies_from_gold_hit(current_gold: int) -> bool:
	return current_gold < gold_loss_for_player_hit(current_gold)
