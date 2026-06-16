extends RefCounted

const BUILDINGS := [
	{
		"id": "blacksmith",
		"display_name": "铁匠铺",
		"keycode": KEY_1,
		"size": Vector2(180, 140),
		"base_color": Color(0.42, 0.36, 0.32, 1),
		"accent_color": Color(0.9, 0.32, 0.18, 1),
	},
	{
		"id": "wall",
		"display_name": "城墙",
		"keycode": KEY_2,
		"size": Vector2(120, 100),
		"base_color": Color(0.48, 0.5, 0.5, 1),
		"accent_color": Color(0.32, 0.34, 0.35, 1),
	},
	{
		"id": "farm",
		"display_name": "农田",
		"keycode": KEY_3,
		"size": Vector2(220, 60),
		"base_color": Color(0.55, 0.34, 0.16, 1),
		"accent_color": Color(0.38, 0.72, 0.24, 1),
	},
	{
		"id": "tavern",
		"display_name": "酒馆",
		"keycode": KEY_4,
		"size": Vector2(190, 150),
		"base_color": Color(0.58, 0.34, 0.18, 1),
		"accent_color": Color(0.78, 0.2, 0.16, 1),
	},
]


func get_buildings() -> Array:
	return BUILDINGS.duplicate(true)


func get_building(index: int) -> Dictionary:
	if index < 0 or index >= BUILDINGS.size():
		return {}

	return BUILDINGS[index].duplicate(true)
