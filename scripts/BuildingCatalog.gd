extends RefCounted

const GameData = preload("res://scripts/GameData.gd")

const BUILDINGS := [
	{
		"id": "blacksmith",
		"display_name": "铁匠铺",
		"keycode": KEY_1,
		"cost": 10,
		"size": Vector2(180, 140),
		"base_color": Color(0.42, 0.36, 0.32, 1),
		"accent_color": Color(0.9, 0.32, 0.18, 1),
	},
	{
		"id": "wall",
		"display_name": "城墙",
		"keycode": KEY_2,
		"cost": 5,
		"size": Vector2(120, 100),
		"base_color": Color(0.48, 0.5, 0.5, 1),
		"accent_color": Color(0.32, 0.34, 0.35, 1),
	},
	{
		"id": "tavern",
		"display_name": "酒馆",
		"keycode": KEY_3,
		"cost": 20,
		"size": Vector2(190, 150),
		"base_color": Color(0.58, 0.34, 0.18, 1),
		"accent_color": Color(0.78, 0.2, 0.16, 1),
	},
	{
		"id": "post_station",
		"display_name": "驿站",
		"keycode": KEY_4,
		"cost": 40,
		"size": Vector2(190, 130),
		"unlock_cityhall_level": 4,
		"is_workplace": false,
		"provides_horse_purchase": true,
		"horse_offer_seconds": 180.0,
		"base_color": Color(0.34, 0.27, 0.18, 1),
		"accent_color": Color(0.74, 0.52, 0.26, 1),
	},
	{
		"id": "barracks",
		"display_name": "军营",
		"keycode": KEY_5,
		"cost": 60,
		"size": Vector2(220, 150),
		"unlock_cityhall_level": 4,
		"is_workplace": true,
		"work_role": "soldier",
		"worker_capacity_by_level": GameData.BARRACKS_CAPACITY_BY_LEVEL,
		"base_color": Color(0.36, 0.36, 0.42, 1),
		"accent_color": Color(0.58, 0.58, 0.64, 1),
	},
]

var game_data := GameData.new()


func get_buildings() -> Array:
	var definitions := game_data.scaled_building_definitions(BUILDINGS.duplicate(true))
	definitions.append_array(game_data.terrain_building_definitions())
	return definitions


func get_building(index: int) -> Dictionary:
	var definitions := get_buildings()
	if index < 0 or index >= definitions.size():
		return {}

	return definitions[index].duplicate(true)
