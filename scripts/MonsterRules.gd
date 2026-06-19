extends RefCounted

const FIRST_MONSTER_NIGHT := 3
const SIDE_SPAWN_CHANCE := 0.2
const MIN_MONSTERS_PER_SIDE := 1
const MAX_MONSTERS_PER_SIDE := 4
const MIN_PLAYER_GOLD_LOSS := 50


func should_spawn_side(night_number: int, roll: float, safe_nights_remaining := 0) -> bool:
	if safe_nights_remaining > 0:
		return false
	if night_number < FIRST_MONSTER_NIGHT:
		return false

	return roll < SIDE_SPAWN_CHANCE


func spawn_count_from_seed(seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng.randi_range(MIN_MONSTERS_PER_SIDE, MAX_MONSTERS_PER_SIDE)


func gold_loss_for_player_hit(current_gold: int) -> int:
	return max(int(ceil(float(current_gold) * 0.5)), MIN_PLAYER_GOLD_LOSS)


func player_dies_from_gold_hit(current_gold: int) -> bool:
	return current_gold < gold_loss_for_player_hit(current_gold)
