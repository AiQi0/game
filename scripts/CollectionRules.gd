extends RefCounted


func fish_catch_from_rolls(species_roll: float, weight_roll: float, data) -> Dictionary:
	var species := _fish_species_for_roll(species_roll, data)
	if species.is_empty():
		return {}

	var min_weight := float(species.get("min_weight", 0.0))
	var max_weight := float(species.get("max_weight", min_weight))
	var clamped_weight_roll := clampf(weight_roll, 0.0, 1.0)
	var weight := snappedf(lerpf(min_weight, max_weight, clamped_weight_roll), 0.01)
	return {
		"id": str(species.get("id", "")),
		"display_name": str(species.get("display_name", "")),
		"rarity": str(species.get("rarity", "")),
		"weight": weight,
		"min_weight": min_weight,
		"max_weight": max_weight,
	}


func record_fish_catch(existing_codex: Dictionary, catch_data: Dictionary) -> Dictionary:
	var fish_id := str(catch_data.get("id", ""))
	if fish_id == "":
		return {
			"codex": existing_codex.duplicate(true),
			"is_new": false,
			"new_min": false,
			"new_max": false,
		}

	var codex := existing_codex.duplicate(true)
	var entry: Dictionary = codex.get(fish_id, {})
	var is_new := not bool(entry.get("caught", false))
	var weight := float(catch_data.get("weight", 0.0))
	var previous_min := float(entry.get("min_weight", weight))
	var previous_max := float(entry.get("max_weight", weight))
	var new_min := is_new or weight < previous_min
	var new_max := is_new or weight > previous_max

	entry.caught = true
	entry.display_name = str(catch_data.get("display_name", fish_id))
	entry.rarity = str(catch_data.get("rarity", ""))
	entry.min_weight = weight if new_min else previous_min
	entry.max_weight = weight if new_max else previous_max
	codex[fish_id] = entry

	return {
		"codex": codex,
		"is_new": is_new,
		"new_min": new_min,
		"new_max": new_max,
	}


func seed_drop_from_rolls(
	activity_id: String,
	drop_roll: float,
	choice_roll: float,
	unlocked_crops: Dictionary,
	data
) -> String:
	if data == null or not data.has_method("seed_drop_activities") or not data.has_method("seed_drop_chance"):
		return ""
	if not data.seed_drop_activities().has(activity_id):
		return ""
	if drop_roll >= float(data.seed_drop_chance()):
		return ""

	var locked := locked_crop_ids(unlocked_crops, data)
	if locked.is_empty():
		return ""

	var index := clampi(int(floor(clampf(choice_roll, 0.0, 0.999999) * float(locked.size()))), 0, locked.size() - 1)
	return str(locked[index])


func locked_crop_ids(unlocked_crops: Dictionary, data) -> Array:
	if data == null or not data.has_method("crop_ids"):
		return []

	var locked := []
	for crop_id in data.crop_ids():
		if not bool(unlocked_crops.get(str(crop_id), false)):
			locked.append(str(crop_id))
	return locked


func normalized_crop_unlocks(saved_unlocks: Dictionary, data) -> Dictionary:
	var unlocked := {}
	if data != null and data.has_method("default_unlocked_crops"):
		unlocked = data.default_unlocked_crops()
	for crop_id in saved_unlocks.keys():
		if bool(saved_unlocks.get(crop_id, false)):
			unlocked[str(crop_id)] = true
	return unlocked


func fish_codex_with_all_species(existing_codex: Dictionary, data) -> Dictionary:
	var codex := existing_codex.duplicate(true)
	if data == null or not data.has_method("fish_species"):
		return codex

	for fish in data.fish_species():
		var fish_id := str(fish.get("id", ""))
		if fish_id == "":
			continue
		if codex.has(fish_id):
			continue
		codex[fish_id] = {
			"caught": false,
			"display_name": str(fish.get("display_name", fish_id)),
			"rarity": str(fish.get("rarity", "")),
		}
	return codex


func _fish_species_for_roll(species_roll: float, data) -> Dictionary:
	if data == null or not data.has_method("fish_species"):
		return {}

	var roll := clampf(species_roll, 0.0, 0.999999)
	var accumulated := 0.0
	var last_species := {}
	for species in data.fish_species():
		last_species = species
		accumulated += float(species.get("probability", 0.0))
		if roll < accumulated:
			return species.duplicate(true)
	return last_species.duplicate(true)
