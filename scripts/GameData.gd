extends RefCounted

const GROUND_MIN_X := 0.0
const GROUND_MAX_X := 9600.0
const GROUND_TOP_Y := 472.0
const AIR_WALL_WIDTH := 96.0
const AIR_WALL_HEIGHT := 1000.0
const CITY_HALL_SIZE := Vector2(400, 334)
const TREE_SIZE := Vector2(64, 120)
const STONE_SIZE := Vector2(72, 72)
const QUARRY_SIZE := Vector2(180, 120)
const TREE_COUNT := 18
const TREE_RANDOM_SEED := 20260616
const STONE_COUNT := 3
const STONE_RANDOM_SEED := 20260618
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
const TOOL_EFFICIENCY_MULTIPLIER := STONE_TOOL_EFFICIENCY_MULTIPLIER
const TREE_GOLD_REWARD := 1
const STONE_GOLD_REWARD := 3
const QUARRY_COST := 20
const QUARRY_INCOME_SECONDS := 60.0
const QUARRY_INCOME_GOLD := 3

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
	},
	"axe": {
		"display_name": "木斧",
		"color": Color(0.58, 0.38, 0.18, 1),
		"craft_text": "制作木斧 -3金",
		"tier": "wood",
		"resource_kind": "tree",
		"efficiency_multiplier": WOOD_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"sickle": {
		"display_name": "木镰刀",
		"color": Color(0.7, 0.5, 0.24, 1),
		"craft_text": "制作木镰刀 -3金",
		"tier": "wood",
		"resource_kind": "farm",
		"efficiency_multiplier": WOOD_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"bow": {
		"display_name": "弓",
		"color": Color(0.86, 0.62, 0.22, 1),
		"craft_text": "制作弓 -3金",
		"tier": "wood",
	},
	"stone_sword": {
		"display_name": "石剑",
		"color": Color(0.66, 0.68, 0.7, 1),
		"craft_text": "制作石剑 -3金",
		"tier": "stone",
	},
	"stone_pickaxe": {
		"display_name": "石镐",
		"color": Color(0.46, 0.48, 0.5, 1),
		"craft_text": "制作石镐 -3金",
		"tier": "stone",
		"resource_kind": "stone",
		"efficiency_multiplier": STONE_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"stone_sickle": {
		"display_name": "石镰刀",
		"color": Color(0.58, 0.64, 0.6, 1),
		"craft_text": "制作石镰刀 -3金",
		"tier": "stone",
		"resource_kind": "farm",
		"efficiency_multiplier": STONE_TOOL_EFFICIENCY_MULTIPLIER,
	},
	"stone_arrowhead": {
		"display_name": "石箭头",
		"color": Color(0.52, 0.54, 0.56, 1),
		"craft_text": "制作石箭头 -3金",
		"tier": "stone",
		"damage_multiplier": STONE_TOOL_EFFICIENCY_MULTIPLIER,
	},
}

const TOOL_ROLE_PRIORITY := {
	"villager": ["stone_sword", "sword", "bow"],
	"lumberjack": ["axe"],
	"miner": ["stone_pickaxe"],
	"farmer": ["stone_sickle", "sickle"],
	"archer": ["stone_arrowhead"],
}

const BLACKSMITH_CRAFT_TOOLS_BY_LEVEL := {
	1: ["sword", "axe", "sickle", "bow"],
	2: ["stone_sword", "stone_pickaxe", "stone_sickle", "bow", "stone_arrowhead"],
}

const BLACKSMITH_CRAFT_REQUIREMENTS_BY_LEVEL := {
	1: {"lumberyard": 1},
	2: {"quarry": 1},
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
}

const BUILDING_UPGRADES := {
	"cityhall": {
		2: {
			"cost": 50,
			"requires": {},
		},
	},
	"blacksmith": {
		2: {
			"cost": 20,
			"requires": {"cityhall": 2},
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
}

const WORLD := {
	"ground_min_x": GROUND_MIN_X,
	"ground_max_x": GROUND_MAX_X,
	"ground_top_y": GROUND_TOP_Y,
	"air_wall_width": AIR_WALL_WIDTH,
	"air_wall_height": AIR_WALL_HEIGHT,
	"city_hall_size": CITY_HALL_SIZE,
	"tree_size": TREE_SIZE,
	"stone_size": STONE_SIZE,
	"quarry_size": QUARRY_SIZE,
	"tree_count": TREE_COUNT,
	"tree_random_seed": TREE_RANDOM_SEED,
	"stone_count": STONE_COUNT,
	"stone_random_seed": STONE_RANDOM_SEED,
	"city_hall_front": CITY_HALL_FRONT,
}

const ECONOMY := {
	"starting_gold": STARTING_GOLD,
	"farm_income_seconds": FARM_INCOME_SECONDS,
	"tool_craft_seconds": TOOL_CRAFT_SECONDS,
	"tool_craft_cost": TOOL_CRAFT_COST,
	"blacksmith_tool_limit": BLACKSMITH_TOOL_LIMIT,
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


func blacksmith_craft_tool_ids(blacksmith_level: int) -> Array:
	var resolved_level := 2 if blacksmith_level >= 2 else 1
	return (BLACKSMITH_CRAFT_TOOLS_BY_LEVEL.get(resolved_level, []) as Array).duplicate()


func blacksmith_craft_requirements(blacksmith_level: int) -> Dictionary:
	var resolved_level := 2 if blacksmith_level >= 2 else 1
	var requirements: Dictionary = BLACKSMITH_CRAFT_REQUIREMENTS_BY_LEVEL.get(resolved_level, {})
	return requirements.duplicate(true)


func quarry_value(key: String, default_value = null):
	return QUARRY.get(key, default_value)


func quarry_definition() -> Dictionary:
	return QUARRY.duplicate(true)


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
