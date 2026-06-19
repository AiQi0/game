extends RefCounted

const DAY_SECONDS := 300.0
const NIGHT_SECONDS := 300.0
const CYCLE_SECONDS := DAY_SECONDS + NIGHT_SECONDS


func phase_for_time(elapsed_seconds: float) -> String:
	var cycle_time := fposmod(elapsed_seconds, CYCLE_SECONDS)
	if cycle_time < DAY_SECONDS:
		return "day"

	return "night"


func phase_progress(elapsed_seconds: float) -> float:
	var cycle_time := fposmod(elapsed_seconds, CYCLE_SECONDS)
	if cycle_time < DAY_SECONDS:
		return cycle_time / DAY_SECONDS

	return (cycle_time - DAY_SECONDS) / NIGHT_SECONDS


func celestial_arc_position(progress: float, viewport_size: Vector2) -> Vector2:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var start_x := viewport_size.x * 0.0833333333
	var end_x := viewport_size.x * 0.9166666667
	var horizon_y := viewport_size.y * 0.2777777778
	var arc_height := viewport_size.y * 0.1888888889

	return Vector2(
		lerpf(start_x, end_x, clamped_progress),
		horizon_y - sin(clamped_progress * PI) * arc_height
	)
