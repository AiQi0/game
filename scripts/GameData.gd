extends RefCounted

const GROUND_MIN_X := 0.0
const GROUND_MAX_X := 9600.0
const GROUND_TOP_Y := 472.0
const AIR_WALL_WIDTH := 96.0
const AIR_WALL_HEIGHT := 1000.0
const CITY_HALL_SIZE := Vector2(400, 334)
const TREE_SIZE := Vector2(64, 120)
const MOTHER_TREE_SIZE := Vector2(170, 260)
const STONE_SIZE := Vector2(72, 72)
const QUARRY_SIZE := Vector2(180, 120)
const BRIDGE_SIZE := Vector2(260, 16)
const BRIDGE_WATER_SIZE := Vector2(220, 56)
const TREE_COUNT := 18
const TREE_RANDOM_SEED := 20260616
const MOTHER_TREE_COUNT := 3
const MOTHER_TREE_RANDOM_SEED := 20260620
const MOTHER_TREE_GROW_RADIUS := 520.0
const STONE_COUNT := 3
const STONE_RANDOM_SEED := 20260618
const BRIDGE_COUNT := 5
const BRIDGE_RANDOM_SEED := 20260619
const BRIDGE_NEAR_CITY_HALL_OFFSET := 520.0
const BRIDGE_NEAR_CITY_HALL_MAX_DISTANCE := 650.0
const CITY_HALL_FRONT := Vector2(4800, 472)

const STARTING_GOLD := 99
const FARM_INCOME_SECONDS := 60.0
const TOOL_CRAFT_SECONDS := 30.0
const TOOL_CRAFT_COST := 3
const BLACKSMITH_TOOL_LIMIT := 5

const LUMBERYARD_TREE_INTERVAL_SECONDS := 120.0
const LUMBERYARD_TREE_BATCH_COUNT := 3
const LUMBERYARD_TREE_RADIUS := 420.0
const PLAYER_TREE_CHOP_SECONDS := 10.0
const PLAYER_STONE_MINE_SECONDS := 60.0
const NPC_TREE_CHOP_SECONDS := 60.0
const NPC_STONE_MINE_SECONDS := 60.0
const WOOD_TOOL_EFFICIENCY_MULTIPLIER := 1.5
const STONE_TOOL_EFFICIENCY_MULTIPLIER := 2.0
const IRON_TOOL_EFFICIENCY_MULTIPLIER := 3.0
const TOOL_EFFICIENCY_MULTIPLIER := STONE_TOOL_EFFICIENCY_MULTIPLIER
const TREE_GOLD_REWARD := 1
const STONE_GOLD_REWARD := 3
const QUARRY_COST := 20
const QUARRY_INCOME_SECONDS := 60.0
const QUARRY_INCOME_GOLD := 3
const BRIDGE_FARM_COST := 5

const NPC_SPEED := 52.0
const NPC_ARRIVAL_DISTANCE := 6.0
const NPC_INTERACTION_RANGE := 72.0
const NPC_RANDOM_SEED := 20260616
const STARTING_HOMELESS_RANDOM_SEED := NPC_RANDOM_SEED + 101
const WARRIOR_ATTACK_RANGE := 96.0
const WARRIOR_ATTACK_INTERVAL := 1.0
const ARCHER_ATTACK_INTERVAL := 1.0

const MONSTER_MAX_HEALTH := 3
const MONSTER_SPAWN_EDGE_PADDING := 28.0
const MONSTER_SPEED := 70.0
const MONSTER_RETURN_SPEED := 110.0
const MONSTER_DETECTION_RANGE := 86.0
const MONSTER_HIT_RANGE := 44.0
const MONSTER_CHARGE_SECONDS := 1.0
const MONSTER_RANDOM_SEED := 20260617

const ARROW_FLIGHT_SECONDS := 0.8
const ARROW_ARC_HEIGHT := 120.0
const ARROW_LANDED_VISIBLE_SECONDS := 5.0
const ARROW_FADE_SECONDS := 1.0

const NPC_ROLES := {
	"homeless": {
		"color": Color(0.56, 0.44, 0.36, 1),
	},
	"villager": {
		"color": Color(0.26, 0.5, 0.92, 1),
	},
	"lumberjack": {
		"color": Color(0.28, 0.62, 0.28, 1),
	},
	"farmer": {
		"color": Color(0.86, 0.68, 0.22, 1),
	},
	"miner": {
		"color": Color(0.44, 0.48, 0.52, 1),
	},
	"merchant": {
		"color": Color(0.9, 0.76, 0.28, 1),
	},
	"shield_guard": {
		"color": Color(0.3, 0.38, 0.54, 1),
		"attack_power": 1,
		"defense_power": 4,
		"expedition_loss_reduction": 0.2,
	},
	"warrior": {
		"color": Color(0.62, 0.18, 0.24, 1),
		"attack_power": 2,
		"attack_range": WARRIOR_ATTACK_RANGE,
	},
	"archer": {
		"color": Color(0.22, 0.58, 0.44, 1),
		"attack_power": 1,
		"attack_range": 600.0,
		"wall_attack_range": 900.0,
	},
}

const TOOLS := {
	"sword": {
		"display_name": "木剑",
		"color": Color(0.64, 0.42, 0.2, 1),
		"craft_text": "制作木剑 -3金",
		"tier": "wood",
		"tool_class": "sword",
	},
	"axe": {
		"display_name": "木斧",
		"color": Color(0.58, 0.38, 0.18, 1),
		"craft_text": "制作木斧 -3金",
		"tier": "wood",
		"tool_class": "axe",
		"resource_kind": "tree",
		"efficiency_multiplier": WOOD_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"sickle": {
		"display_name": "木镰刀",
		"color": Color(0.7, 0.5, 0.24, 1),
		"craft_text": "制作木镰刀 -3金",
		"tier": "wood",
		"tool_class": "sickle",
		"resource_kind": "farm",
		"efficiency_multiplier": WOOD_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"bow": {
		"display_name": "弓",
		"color": Color(0.86, 0.62, 0.22, 1),
		"craft_text": "制作弓 -3金",
		"tier": "wood",
		"tool_class": "bow",
	},
	"stone_sword": {
		"display_name": "石剑",
		"color": Color(0.66, 0.68, 0.7, 1),
		"craft_text": "制作石剑 -3金",
		"tier": "stone",
		"tool_class": "sword",
	},
	"stone_pickaxe": {
		"display_name": "石镐",
		"color": Color(0.46, 0.48, 0.5, 1),
		"craft_text": "制作石镐 -3金",
		"tier": "stone",
		"tool_class": "axe",
		"resource_kind": "stone",
		"efficiency_multiplier": STONE_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"stone_sickle": {
		"display_name": "石镰刀",
		"color": Color(0.58, 0.64, 0.6, 1),
		"craft_text": "制作石镰刀 -3金",
		"tier": "stone",
		"tool_class": "sickle",
		"resource_kind": "farm",
		"efficiency_multiplier": STONE_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"stone_arrowhead": {
		"display_name": "石箭头",
		"color": Color(0.52, 0.54, 0.56, 1),
		"craft_text": "制作石箭头 -3金",
		"tier": "stone",
		"tool_class": "arrowhead",
		"damage_multiplier": STONE_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"iron_sword": {
		"display_name": "铁剑",
		"color": Color(0.78, 0.78, 0.72, 1),
		"craft_text": "制作铁剑 -3金",
		"tier": "iron",
		"tool_class": "sword",
		"requires_building": "iron_mine",
		"requires_blacksmith_level": 3,
		"attack_power": 3,
	},
	"iron_pickaxe": {
		"display_name": "铁镐",
		"color": Color(0.58, 0.58, 0.54, 1),
		"craft_text": "制作铁镐 -3金",
		"tier": "iron",
		"tool_class": "axe",
		"requires_building": "iron_mine",
		"requires_blacksmith_level": 3,
		"resource_kind": "stone",
		"efficiency_multiplier": IRON_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"iron_sickle": {
		"display_name": "铁镰刀",
		"color": Color(0.64, 0.68, 0.62, 1),
		"craft_text": "制作铁镰刀 -3金",
		"tier": "iron",
		"tool_class": "sickle",
		"requires_building": "iron_mine",
		"requires_blacksmith_level": 3,
		"resource_kind": "farm",
		"efficiency_multiplier": IRON_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"iron_arrowhead": {
		"display_name": "铁箭头",
		"color": Color(0.7, 0.7, 0.66, 1),
		"craft_text": "制作铁箭头 -3金",
		"tier": "iron",
		"tool_class": "arrowhead",
		"requires_building": "iron_mine",
		"requires_blacksmith_level": 3,
		"damage_multiplier": IRON_TOOL_EFFICIENCY_MULTIPLIER,
	},
}

const TOOL_ROLE_PRIORITY := {
	"villager": ["iron_sword", "stone_sword", "sword", "bow"],
	"lumberjack": ["axe"],
	"miner": ["iron_pickaxe", "stone_pickaxe"],
	"farmer": ["iron_sickle", "stone_sickle", "sickle"],
	"archer": ["iron_arrowhead", "stone_arrowhead"],
}

const BLACKSMITH_CRAFT_TOOLS_BY_LEVEL := {
	1: ["sword", "axe", "sickle", "bow"],
	2: ["stone_sword", "stone_pickaxe", "stone_sickle", "bow", "stone_arrowhead"],
	3: ["iron_sword", "iron_pickaxe", "iron_sickle", "bow", "iron_arrowhead"],
}

const BLACKSMITH_CRAFT_REQUIREMENTS_BY_LEVEL := {
	1: {"lumberyard": 1},
	2: {"quarry": 1},
	3: {"iron_mine": 1},
}

const TERRAIN_BUILDINGS := {
	"river": [
		{
			"id": "river_port",
			"display_name": "河港",
			"cost": 35,
			"size": Vector2(220, 130),
			"terrain_required": "river",
			"exclusive_to_terrain": true,
			"unlock_cityhall_level": 3,
			"work_role": "merchant",
			"income_seconds": 60.0,
			"income_gold": 4,
			"trade_bonus_gold": 2,
			"base_color": Color(0.18, 0.36, 0.48, 1),
			"accent_color": Color(0.76, 0.62, 0.32, 1),
		},
	],
	"northern": [
		{
			"id": "beacon_tower",
			"display_name": "烽火台",
			"cost": 40,
			"size": Vector2(110, 190),
			"terrain_required": "northern",
			"exclusive_to_terrain": true,
			"unlock_cityhall_level": 3,
			"required_role": "archer",
			"work_role": "archer",
			"defense_score": 18,
			"damage_reduction": 0.2,
			"base_color": Color(0.44, 0.48, 0.54, 1),
			"accent_color": Color(0.92, 0.42, 0.18, 1),
		},
		{
			"id": "shield_barracks",
			"display_name": "盾卫营",
			"cost": 70,
			"size": Vector2(220, 150),
			"terrain_required": "northern",
			"exclusive_to_terrain": true,
			"unlock_cityhall_level": 4,
			"requires_buildings": {"barracks": 1},
			"is_workplace": false,
			"trained_role": "shield_guard",
			"defense_score": 24,
			"base_color": Color(0.36, 0.42, 0.5, 1),
			"accent_color": Color(0.68, 0.72, 0.76, 1),
		},
	],
	"mountain": [
		{
			"id": "iron_mine",
			"display_name": "铁矿",
			"cost": 65,
			"size": Vector2(190, 130),
			"terrain_required": "mountain",
			"exclusive_to_terrain": true,
			"unlock_cityhall_level": 3,
			"requires_buildings": {"quarry": 1},
			"max_count_per_city": 2,
			"work_role": "miner",
			"income_seconds": 60.0,
			"income_gold": 4,
			"unlocks_equipment_tier": "iron",
			"base_color": Color(0.28, 0.28, 0.3, 1),
			"accent_color": Color(0.66, 0.58, 0.48, 1),
		},
		{
			"id": "cliff_fort",
			"display_name": "山崖堡垒",
			"cost": 80,
			"size": Vector2(210, 170),
			"terrain_required": "mountain",
			"exclusive_to_terrain": true,
			"unlock_cityhall_level": 4,
			"work_role": "guard",
			"required_roles": ["archer", "warrior"],
			"defense_score": 32,
			"archer_range_bonus": 250.0,
			"charge_block_chance": 0.35,
			"base_color": Color(0.34, 0.34, 0.32, 1),
			"accent_color": Color(0.5, 0.48, 0.42, 1),
		},
	],
}

const QUARRY := {
	"id": "quarry",
	"display_name": "采石场",
	"cost": QUARRY_COST,
	"size": QUARRY_SIZE,
	"requires_worker": true,
	"worker_role": "miner",
	"income_seconds": QUARRY_INCOME_SECONDS,
	"income_gold": QUARRY_INCOME_GOLD,
	"base_color": Color(0.38, 0.38, 0.4, 1),
	"accent_color": Color(0.58, 0.58, 0.62, 1),
}

const FARM := {
	"id": "farm",
	"display_name": "农田",
	"cost": BRIDGE_FARM_COST,
	"size": Vector2(220, 60),
	"base_color": Color(0.55, 0.34, 0.16, 1),
	"accent_color": Color(0.38, 0.72, 0.24, 1),
}

const LUMBERYARD := {
	"id": "lumberyard",
	"display_name": "伐木场",
	"cost": 10,
	"size": Vector2(200, 130),
	"base_color": Color(0.44, 0.32, 0.2, 1),
	"accent_color": Color(0.22, 0.52, 0.24, 1),
}

const RESOURCES := {
	"tree": {
		"display_name": "树",
		"size": TREE_SIZE,
		"gold_reward": TREE_GOLD_REWARD,
		"player_seconds": PLAYER_TREE_CHOP_SECONDS,
		"npc_seconds": NPC_TREE_CHOP_SECONDS,
	},
	"stone": {
		"display_name": "石头",
		"size": STONE_SIZE,
		"gold_reward": STONE_GOLD_REWARD,
		"player_seconds": PLAYER_STONE_MINE_SECONDS,
		"npc_seconds": NPC_STONE_MINE_SECONDS,
	},
	"mother_tree": {
		"display_name": "巨大母树",
		"size": MOTHER_TREE_SIZE,
	},
}

const BUILDING_UPGRADES := {
	"cityhall": {
		2: {
			"cost": 50,
			"requires": {},
		},
		3: {
			"cost": 100,
			"requires": {},
		},
		4: {
			"cost": 180,
			"requires": {},
		},
	},
	"blacksmith": {
		2: {
			"cost": 20,
			"requires": {"cityhall": 2},
		},
		3: {
			"cost": 40,
			"requires": {"cityhall": 3},
		},
	},
	"wall": {
		2: {
			"cost": 15,
			"requires": {"cityhall": 2},
		},
	},
	"farm": {
		2: {
			"cost": 15,
			"requires": {"cityhall": 2},
		},
	},
	"lumberyard": {
		2: {
			"cost": 30,
			"requires": {"cityhall": 2},
		},
	},
	"post_station": {
		2: {
			"cost": 35,
			"requires": {"cityhall": 4},
		},
	},
	"barracks": {
		2: {
			"cost": 45,
			"requires": {"cityhall": 4},
		},
	},
}

const WORLD := {
	"ground_min_x": GROUND_MIN_X,
	"ground_max_x": GROUND_MAX_X,
	"ground_top_y": GROUND_TOP_Y,
	"air_wall_width": AIR_WALL_WIDTH,
	"air_wall_height": AIR_WALL_HEIGHT,
	"city_hall_size": CITY_HALL_SIZE,
	"tree_size": TREE_SIZE,
	"mother_tree_size": MOTHER_TREE_SIZE,
	"stone_size": STONE_SIZE,
	"quarry_size": QUARRY_SIZE,
	"bridge_size": BRIDGE_SIZE,
	"bridge_water_size": BRIDGE_WATER_SIZE,
	"tree_count": TREE_COUNT,
	"tree_random_seed": TREE_RANDOM_SEED,
	"mother_tree_count": MOTHER_TREE_COUNT,
	"mother_tree_random_seed": MOTHER_TREE_RANDOM_SEED,
	"mother_tree_grow_radius": MOTHER_TREE_GROW_RADIUS,
	"stone_count": STONE_COUNT,
	"stone_random_seed": STONE_RANDOM_SEED,
	"bridge_count": BRIDGE_COUNT,
	"bridge_random_seed": BRIDGE_RANDOM_SEED,
	"bridge_near_city_hall_offset": BRIDGE_NEAR_CITY_HALL_OFFSET,
	"bridge_near_city_hall_max_distance": BRIDGE_NEAR_CITY_HALL_MAX_DISTANCE,
	"city_hall_front": CITY_HALL_FRONT,
}

const ECONOMY := {
	"starting_gold": STARTING_GOLD,
	"farm_income_seconds": FARM_INCOME_SECONDS,
	"tool_craft_seconds": TOOL_CRAFT_SECONDS,
	"tool_craft_cost": TOOL_CRAFT_COST,
	"blacksmith_tool_limit": BLACKSMITH_TOOL_LIMIT,
	"bridge_farm_cost": BRIDGE_FARM_COST,
}

const TRADE := {
	"horse_base_price": 30,
	"horse_treaty_price": 20,
}

const TRAVEL_DESTINATIONS := {
	"river": {
		"display_name": "河湾商盟",
		"scene_path": "res://scenes/RiverMerchantAlliance.tscn",
	},
}

const TRAINING := {
	"shield_guard_cost": 25,
}

const DEFENSE := {
	"max_building_damage_reduction": 0.6,
	"max_expedition_loss_reduction": 0.6,
}

const ARROW := {
	"flight_seconds": ARROW_FLIGHT_SECONDS,
	"arc_height": ARROW_ARC_HEIGHT,
	"landed_visible_seconds": ARROW_LANDED_VISIBLE_SECONDS,
	"fade_seconds": ARROW_FADE_SECONDS,
}


func world_value(key: String, default_value = null):
	return WORLD.get(key, default_value)


func economy_value(key: String, default_value = null):
	return ECONOMY.get(key, default_value)


func trade_value(key: String, default_value = null):
	return TRADE.get(key, default_value)


func travel_destination_value(terrain: String, key: String, default_value = null):
	var destination: Dictionary = TRAVEL_DESTINATIONS.get(terrain, {})
	return destination.get(key, default_value)


func travel_destination_scene_path(terrain: String) -> String:
	return str(travel_destination_value(terrain, "scene_path", ""))


func travel_destination_display_name(terrain: String) -> String:
	return str(travel_destination_value(terrain, "display_name", terrain))


func training_value(key: String, default_value = null):
	return TRAINING.get(key, default_value)


func defense_value(key: String, default_value = null):
	return DEFENSE.get(key, default_value)


func arrow_value(key: String, default_value = null):
	return ARROW.get(key, default_value)


func has_building_upgrade(building_id: String, target_level: int) -> bool:
	var levels: Dictionary = BUILDING_UPGRADES.get(building_id, {})
	return levels.has(target_level)


func building_upgrade_cost(building_id: String, target_level: int) -> int:
	var upgrade_data := building_upgrade_data(building_id, target_level)
	return int(upgrade_data.get("cost", 0))


func building_upgrade_requirements(building_id: String, target_level: int) -> Dictionary:
	var upgrade_data := building_upgrade_data(building_id, target_level)
	var requirements: Dictionary = upgrade_data.get("requires", {})
	return requirements.duplicate(true)


func max_building_level(building_id: String) -> int:
	var levels: Dictionary = BUILDING_UPGRADES.get(building_id, {})
	var max_level := 1
	for level in levels.keys():
		max_level = maxi(max_level, int(level))
	return max_level


func building_upgrade_data(building_id: String, target_level: int) -> Dictionary:
	var levels: Dictionary = BUILDING_UPGRADES.get(building_id, {})
	var upgrade_data: Dictionary = levels.get(target_level, {})
	return upgrade_data.duplicate(true)


func npc_role_value(role: String, key: String, default_value = null):
	var role_data: Dictionary = NPC_ROLES.get(role, {})
	return role_data.get(key, default_value)


func tool_ids() -> Array:
	return TOOLS.keys()


func is_valid_tool_id(tool_id: String) -> bool:
	return TOOLS.has(tool_id)


func tool_ids_for_role(role: String) -> Array:
	return (TOOL_ROLE_PRIORITY.get(role, []) as Array).duplicate()


func tool_value(tool_id: String, key: String, default_value = null):
	var tool_data: Dictionary = TOOLS.get(tool_id, {})
	return tool_data.get(key, default_value)


func tool_display_name(tool_id: String) -> String:
	return str(tool_value(tool_id, "display_name", tool_id))


func tool_color(tool_id: String) -> Color:
	return tool_value(tool_id, "color", Color.WHITE)


func tool_craft_text(tool_id: String) -> String:
	return str(tool_value(tool_id, "craft_text", tool_id))


func tool_efficiency_multiplier(tool_id: String, default_value := 1.0) -> float:
	return float(tool_value(tool_id, "efficiency_multiplier", default_value))


func tool_damage_multiplier(tool_id: String, default_value := 1.0) -> float:
	return float(tool_value(tool_id, "damage_multiplier", default_value))


func tool_resource_kind(tool_id: String) -> String:
	return str(tool_value(tool_id, "resource_kind", ""))


func tool_tier(tool_id: String) -> String:
	return str(tool_value(tool_id, "tier", ""))


func tool_class(tool_id: String) -> String:
	return str(tool_value(tool_id, "tool_class", tool_id))


func tool_required_building(tool_id: String) -> String:
	return str(tool_value(tool_id, "requires_building", ""))


func tool_required_blacksmith_level(tool_id: String) -> int:
	return int(tool_value(tool_id, "requires_blacksmith_level", 1))


func blacksmith_craft_tool_ids(blacksmith_level: int) -> Array:
	var resolved_level := clampi(blacksmith_level, 1, 3)
	return (BLACKSMITH_CRAFT_TOOLS_BY_LEVEL.get(resolved_level, []) as Array).duplicate()


func blacksmith_craft_requirements(blacksmith_level: int) -> Dictionary:
	var resolved_level := clampi(blacksmith_level, 1, 3)
	var requirements: Dictionary = BLACKSMITH_CRAFT_REQUIREMENTS_BY_LEVEL.get(resolved_level, {})
	return requirements.duplicate(true)


func terrain_building_ids(terrain: String) -> Array:
	var ids: Array = []
	for definition in TERRAIN_BUILDINGS.get(terrain, []):
		ids.append(str(definition.get("id", "")))
	return ids


func terrain_building_definitions(terrain := "") -> Array:
	var definitions: Array = []
	if terrain != "":
		for definition in TERRAIN_BUILDINGS.get(terrain, []):
			definitions.append((definition as Dictionary).duplicate(true))
		return definitions

	for terrain_id in TERRAIN_BUILDINGS.keys():
		for definition in TERRAIN_BUILDINGS[terrain_id]:
			definitions.append((definition as Dictionary).duplicate(true))
	return definitions


func terrain_building_definition(building_id: String) -> Dictionary:
	for definition in terrain_building_definitions():
		if definition.get("id", "") == building_id:
			return definition.duplicate(true)
	return {}


func quarry_value(key: String, default_value = null):
	return QUARRY.get(key, default_value)


func quarry_definition() -> Dictionary:
	return QUARRY.duplicate(true)


func farm_value(key: String, default_value = null):
	return FARM.get(key, default_value)


func farm_definition() -> Dictionary:
	return FARM.duplicate(true)


func lumberyard_value(key: String, default_value = null):
	return LUMBERYARD.get(key, default_value)


func lumberyard_definition() -> Dictionary:
	return LUMBERYARD.duplicate(true)


func resource_value(resource_kind: String, key: String, default_value = null):
	var resource_data: Dictionary = RESOURCES.get(resource_kind, {})
	return resource_data.get(key, default_value)


func resource_size(resource_kind: String) -> Vector2:
	return resource_value(resource_kind, "size", TREE_SIZE)


func resource_display_name(resource_kind: String) -> String:
	return str(resource_value(resource_kind, "display_name", resource_kind))


func resource_gold_reward(resource_kind: String) -> int:
	return int(resource_value(resource_kind, "gold_reward", 0))


func resource_player_seconds(resource_kind: String) -> float:
	return float(resource_value(resource_kind, "player_seconds", PLAYER_TREE_CHOP_SECONDS))


func resource_npc_seconds(resource_kind: String) -> float:
	return float(resource_value(resource_kind, "npc_seconds", NPC_TREE_CHOP_SECONDS))


func lumberyard_resource_kind(level: int) -> String:
	return "tree"


func lumberyard_worker_role(level: int) -> String:
	return "lumberjack"


func lumberyard_display_name(level: int) -> String:
	return "2级伐木场" if level >= 2 else "伐木场"
