extends RefCounted


func bite_chance_for_second(second_number: int, data) -> float:
	var base := _fishing_float(data, "bite_base_chance")
	var step := _fishing_float(data, "bite_chance_step")
	var max_chance := _fishing_float(data, "bite_chance_max")
	var safe_second := maxi(1, second_number)
	var chance := base + float(safe_second - 1) * step
	return clampf(chance, 0.0, clampf(max_chance, 0.0, 1.0))


func should_bite(second_number: int, roll: float, data) -> bool:
	return roll < bite_chance_for_second(second_number, data)


func reel_progress_after_press(current_progress: float, data) -> float:
	var gain := _fishing_float(data, "reel_press_gain")
	return clampf(current_progress + gain, 0.0, 1.0)


func reel_progress_after_decay(current_progress: float, delta: float, data) -> float:
	var decay := _fishing_float(data, "reel_decay_per_second")
	return clampf(current_progress - maxf(delta, 0.0) * decay, 0.0, 1.0)


func reel_outcome(progress: float) -> String:
	if progress >= 1.0:
		return "success"
	if progress <= 0.0:
		return "failed"
	return "active"


func _fishing_float(data, key: String) -> float:
	if data == null or not data.has_method("fishing_value"):
		push_error("Fishing config source is missing fishing_value() for key '%s'" % key)
		return 0.0

	var value = data.fishing_value(key)
	if value == null:
		push_error("Missing fishing config value: '%s'" % key)
		return 0.0
	if not (value is int or value is float):
		push_error("Fishing config value '%s' must be numeric, got %s" % [key, typeof(value)])
		return 0.0
	return float(value)
