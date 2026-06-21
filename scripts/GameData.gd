extends RefCounted

const GROUND_MIN_X := -4000.0
const GROUND_MAX_X := 13600.0
const GROUND_TOP_Y := 472.0
const AIR_WALL_WIDTH := 96.0
const AIR_WALL_HEIGHT := 1000.0
const CITY_HALL_SIZE := Vector2(400, 334)
const RESOURCE_SIZE_MULTIPLIER := 2.0
const BASE_TREE_SIZE := Vector2(64, 120)
const BASE_MOTHER_TREE_SIZE := Vector2(170, 260)
const BASE_STONE_SIZE := Vector2(72, 72)
const TREE_SIZE := BASE_TREE_SIZE * RESOURCE_SIZE_MULTIPLIER
const MOTHER_TREE_SIZE := BASE_MOTHER_TREE_SIZE * RESOURCE_SIZE_MULTIPLIER
const STONE_SIZE := BASE_STONE_SIZE * RESOURCE_SIZE_MULTIPLIER
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
const CITY_HALL_RESOURCE_INNER_RADIUS := 1000.0
const CITY_HALL_RESOURCE_OUTER_RADIUS := 2000.0
const BRIDGE_CITY_HALL_RING_OFFSET := -1300.0
const MOTHER_TREE_CITY_HALL_RING_OFFSET := 1450.0
const STONE_CITY_HALL_RING_OFFSET := 1800.0
const CITY_HALL_FRONT := Vector2(4800, 472)
const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const MAIN_SCENE_PATH := "res://scenes/Main.tscn"
const BUILDING_INTERIOR_SCENE_PATH := "res://scenes/BuildingInterior.tscn"
const SAVE_DIRECTORY := "user://saves"
const LAST_SAVE_FILENAME := "last_save.json"
const AUTOSAVE_SECONDS := 60.0
const ART_ASSET_ROOT := "res://assets/medieval_pixel_pack_v3_no_outline"
const TERRAIN_ASSET_ROOT := "res://assets/world_terrain_v1"
const TERRAIN_TILE_SIZE := Vector2(256, 64)
const VISUAL_CHUNK_WIDTH := 1920
const SKY_BACKGROUND_Z_INDEX := -260
const TERRAIN_BACKGROUND_TOP_Z_INDEX := -80
const CELESTIAL_Z_INDEX := -70
const NON_CITYHALL_BUILDING_SIZE_MULTIPLIER := 2.0
const BUILDING_ORIENTATION_RULES := {
	"wall": {
		"mirror_right_of_cityhall": true,
	},
}

const STARTING_GOLD := 30
const HOMELESS_SPAWN := {
	"interval_seconds": 300.0,
	"early_spawn_chance": 0.3,
	"late_spawn_chance": 0.15,
	"early_count_range": Vector2i(2, 4),
	"late_count_range": Vector2i(1, 2),
	"late_reduction_start_day": 4,
	"starting_villager_count": 3,
	"starting_homeless_count": 5,
	"starting_villager_spacing": 48.0,
}
const TAVERN_ATTRACTION := {
	"homeless_capacity": 3,
	"wander_radius": 90.0,
}
const WALL_HEALTH_BY_LEVEL := {
	1: 20,
	2: 40,
}
const FARM_INCOME_SECONDS := 60.0
const TOOL_CRAFT_SECONDS := 30.0
const TOOL_CRAFT_COST := 3
const BLACKSMITH_TOOL_LIMIT := 5

const LUMBERYARD_TREE_INTERVAL_SECONDS := 120.0
const LUMBERYARD_TREE_BATCH_COUNT := 3
const LUMBERYARD_TREE_RADIUS := 420.0
const LUMBERJACK_TREE_SEARCH_RADIUS := LUMBERYARD_TREE_RADIUS * 2.0
const MOTHER_TREE_LUMBERJACK_SEARCH_RADIUS := MOTHER_TREE_GROW_RADIUS * 2.0
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
const INTERIOR_PLAYER_SPEED := 240.0
const INTERIOR_NPC_SPEED := 220.0
const INTERIOR_DOOR_RANGE := 96.0
const INTERIOR_AUTOSAVE_SECONDS := 60.0
const INTERIOR_FARM_CYCLE_SECONDS := 300.0
const INTERIOR_FARM_ACTION_SECONDS := 2.0
const INTERIOR_SEED_DROP_CHANCE := 0.02
const INTERIOR_WORKER_DEFAULT_POSITION := Vector2(360.0, 792.0)
const INTERIOR_FARM_PLOT_ORIGIN := Vector2(260.0, 740.0)
const INTERIOR_FARM_PLOT_SPACING_X := 150.0
const INTERIOR_FARM_WORKER_OFFSET := Vector2(0.0, 8.0)
const INTERIOR_RESOURCE_WORKER_Y := 792.0
const BARRACKS_CAPACITY_BY_LEVEL := {
	1: 10,
	2: 15,
	3: 20,
}
const BARRACKS_TRAINING_LEVELS := [
	{"level": 1, "duration_seconds": 3600.0, "stat_multiplier": 2.0},
	{"level": 2, "duration_seconds": 7200.0, "stat_multiplier": 3.0},
	{"level": 3, "duration_seconds": 14400.0, "stat_multiplier": 4.0},
]
const BARRACKS_TRAINING_COLUMNS := 5
const BARRACKS_TRAINING_ROWS := 4
const BARRACKS_TRAINING_ORIGIN := Vector2(440.0, 460.0)
const BARRACKS_TRAINING_SPACING := Vector2(150.0, 86.0)

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
const MONSTER_SPEED := 105.0
const MONSTER_RETURN_SPEED := 110.0
const MONSTER_DETECTION_RANGE := 86.0
const MONSTER_HIT_RANGE := 44.0
const MONSTER_DASH_DISTANCE := 132.0
const MONSTER_DASH_SPEED_MULTIPLIER := 5.0
const MONSTER_CHARGE_SECONDS := 1.0
const MONSTER_SPAWN_INTERVAL_SECONDS := 1.0
const MONSTER_RANDOM_SEED := 20260617

const ARROW_FLIGHT_SECONDS := 0.8
const ARROW_ARC_HEIGHT := 120.0
const ARROW_LANDED_VISIBLE_SECONDS := 5.0
const ARROW_FADE_SECONDS := 1.0

var _art_asset_visible_rect_cache := {}

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
	"soldier": {
		"color": Color(0.54, 0.48, 0.36, 1),
		"attack_power": 2,
		"max_health": 10,
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
	"stone_spear": {
		"display_name": "stone spear",
		"color": Color(0.58, 0.58, 0.54, 1),
		"craft_text": "craft stone spear -3",
		"tier": "stone",
		"tool_class": "spear",
		"soldier_attack_bonus": 0.3,
		"soldier_health_bonus": 0.3,
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
	"iron_spear": {
		"display_name": "iron spear",
		"color": Color(0.72, 0.72, 0.66, 1),
		"craft_text": "craft iron spear -3",
		"tier": "iron",
		"tool_class": "spear",
		"requires_building": "iron_mine",
		"requires_blacksmith_level": 3,
		"soldier_attack_bonus": 0.5,
		"soldier_health_bonus": 0.5,
	},
}

const TOOL_ROLE_PRIORITY := {
	"villager": ["iron_sword", "stone_sword", "sword", "bow"],
	"lumberjack": ["axe"],
	"miner": ["iron_pickaxe", "stone_pickaxe"],
	"farmer": ["iron_sickle", "stone_sickle", "sickle"],
	"archer": ["iron_arrowhead", "stone_arrowhead"],
	"soldier": ["iron_spear", "stone_spear"],
}

const BLACKSMITH_CRAFT_TOOLS_BY_LEVEL := {
	1: ["sword", "axe", "sickle", "bow"],
	2: ["stone_sword", "stone_pickaxe", "stone_sickle", "bow", "stone_arrowhead", "stone_spear"],
	3: ["iron_sword", "iron_pickaxe", "iron_sickle", "bow", "iron_arrowhead", "iron_spear"],
}

const BLACKSMITH_CRAFT_REQUIREMENTS_BY_LEVEL := {
	1: {"lumberyard": 1},
	2: {"quarry": 1},
	3: {"iron_mine": 1},
}

const ART_ASSETS := {
	"buildings": {
		"cityhall": "cityhall.png",
		"blacksmith": "blacksmith.png",
		"wall": "wall.png",
		"farm": "farm.png",
		"tavern": "tavern.png",
		"post_station": "post_station.png",
		"lumberyard": "lumberyard.png",
		"quarry": "quarry.png",
		"barracks": "barracks.png",
		"river_port": "river_port.png",
		"beacon_tower": "beacon_tower.png",
		"iron_mine": "iron_mine.png",
	},
	"npcs": {
		"player": "player.png",
		"villager": "villager.png",
		"homeless": "homeless.png",
		"farmer": "farmer.png",
		"lumberjack": "lumberjack.png",
		"miner": "miner.png",
		"merchant": "villager.png",
		"shield_guard": "warrior.png",
		"soldier": "soldier.png",
		"warrior": "warrior.png",
		"archer": "archer.png",
		"monster": "monster.png",
	},
	"tools": {
		"sword": "wooden_sword.png",
		"axe": "wooden_axe.png",
		"sickle": "wooden_sickle.png",
		"bow": "bow.png",
		"stone_sword": "stone_sword.png",
		"stone_pickaxe": "stone_pickaxe.png",
		"stone_sickle": "stone_sickle.png",
		"stone_arrowhead": "stone_arrowhead.png",
		"stone_spear": "stone_spear.png",
		"iron_sword": "iron_sword.png",
		"iron_pickaxe": "iron_pickaxe.png",
		"iron_sickle": "iron_sickle.png",
		"iron_arrowhead": "iron_arrowhead.png",
		"iron_spear": "iron_spear.png",
	},
	"crops": {
		"wheat_seeded": "wheat_seeded.png",
		"wheat_growing": "wheat_growing.png",
		"wheat_ready": "wheat_ready.png",
		"carrot_seeded": "carrot_seeded.png",
		"carrot_growing": "carrot_growing.png",
		"carrot_ready": "carrot_ready.png",
		"cabbage_seeded": "cabbage_seeded.png",
		"cabbage_growing": "cabbage_growing.png",
		"cabbage_ready": "cabbage_ready.png",
		"pumpkin_seeded": "pumpkin_seeded.png",
		"pumpkin_growing": "pumpkin_growing.png",
		"pumpkin_ready": "pumpkin_ready.png",
		"blueberry_seeded": "blueberry_seeded.png",
		"blueberry_growing": "blueberry_growing.png",
		"blueberry_ready": "blueberry_ready.png",
		"moon_mushroom_seeded": "moon_mushroom_seeded.png",
		"moon_mushroom_growing": "moon_mushroom_growing.png",
		"moon_mushroom_ready": "moon_mushroom_ready.png",
	},
	"seeds": {
		"wheat": "wheat_seed.png",
		"carrot": "carrot_seed.png",
		"cabbage": "cabbage_seed.png",
		"pumpkin": "pumpkin_seed.png",
		"blueberry": "blueberry_seed.png",
		"moon_mushroom": "moon_mushroom_seed.png",
	},
	"fish": {
		"silver_crucian": "silver_crucian.png",
		"river_bass": "river_bass.png",
		"mud_catfish": "mud_catfish.png",
		"golden_trout": "golden_trout.png",
		"crystal_eel": "crystal_eel.png",
		"moon_kingfish": "moon_kingfish.png",
		"silhouette": "fish_silhouette.png",
	},
	"interiors": {
		"farm_background": "farm_background.png",
		"lumberyard_background": "lumberyard_background.png",
		"quarry_background": "quarry_background.png",
		"shell_background": "shell_background.png",
		"interior_tree": "interior_tree.png",
		"interior_stone": "interior_stone.png",
		"door": "interior_door.png",
	},
	"environment": {
		"tree": "tree.png",
		"mother_tree": "mother_tree.png",
		"stone": "stone.png",
		"water": "water.png",
		"short_bridge": "short_bridge.png",
		"river_background": "river_background.png",
		"river_ground": "river_ground.png",
		"foreground_water": "foreground_water.png",
		"moon": "moon.png",
		"sun": "sun.png",
	},
	"ui": {
		"gold": "gold.png",
		"build": "build.png",
		"upgrade": "upgrade.png",
		"repair": "repair.png",
		"demolish": "demolish.png",
		"travel": "travel.png",
		"diplomacy": "diplomacy.png",
		"train": "train.png",
		"death": "death.png",
		"fish_codex": "fish_codex.png",
		"crop_codex": "crop_codex.png",
		"seed_notice": "seed_notice.png",
	},
}

const RIVER_MIRROR_WATER_VISUAL := {
	"tile_width": 1920.0,
	"tile_count": 5,
	"waterline_y": 520.0,
	"reflection_height_pixels": 560.0,
	"ripple_amplitude_pixels": 8.0,
	"ripple_frequency": 18.0,
	"ripple_speed": 0.65,
	"shimmer_strength": 0.08,
	"top_blur_fraction": 0.25,
	"top_blur_radius_pixels": 6.0,
	"water_grass_count": 24,
	"water_grass_random_seed": 20260620,
	"water_grass_x_min": 160.0,
	"water_grass_x_max": 9440.0,
	"water_grass_y_min": 560.0,
	"water_grass_y_max": 1010.0,
	"water_grass_min_blades": 3,
	"water_grass_max_blades": 5,
	"water_grass_min_height": 24.0,
	"water_grass_max_height": 58.0,
	"water_grass_blade_width": 8.0,
	"water_grass_color": Color(0.12, 0.38, 0.26, 0.78),
	"water_grass_tip_color": Color(0.28, 0.62, 0.38, 0.68),
}

const DAY_NIGHT_VISUAL := {
	"sky_layer_z_index": 0,
	"sky_background_z_index": SKY_BACKGROUND_Z_INDEX,
	"terrain_background_top_z_index": TERRAIN_BACKGROUND_TOP_Z_INDEX,
	"celestial_z_index": CELESTIAL_Z_INDEX,
}

const TERRAIN_ASSETS := {
	"grass_ground_tile": "ground/grass_ground_tile.png",
	"grass_ground_variant_01": "ground/grass_ground_variant_01.png",
	"grass_ground_variant_02": "ground/grass_ground_variant_02.png",
	"ground_fill": "ground/ground_fill.png",
	"water_tile": "water/water_tile.png",
	"short_bridge_tile": "bridges/short_bridge_tile.png",
	"bridge_support": "bridges/bridge_support.png",
	"sky_gradient": "backgrounds/sky_gradient.png",
	"far_hills_loop": "backgrounds/far_hills_loop.png",
	"far_forest_loop": "backgrounds/far_forest_loop.png",
	"cloud_loop_01": "backgrounds/cloud_loop_01.png",
	"cloud_loop_02": "backgrounds/cloud_loop_02.png",
	"tree_variant_01": "resources/tree_variant_01.png",
	"tree_variant_02": "resources/tree_variant_02.png",
	"mother_tree_variant_01": "resources/mother_tree_variant_01.png",
	"mother_tree_variant_02": "resources/mother_tree_variant_02.png",
	"stone_variant_01": "resources/stone_variant_01.png",
	"stone_variant_02": "resources/stone_variant_02.png",
}

const TERRAIN_SETS := {
	"main_grass": {
		"ground_tiles": ["grass_ground_tile", "grass_ground_variant_01", "grass_ground_variant_02"],
		"ground_fill": "ground_fill",
		"water_tile": "water_tile",
		"short_bridge_tile": "short_bridge_tile",
		"bridge_support": "bridge_support",
		"background_layers": [
			{"id": "SkyGradient", "asset": "sky_gradient", "z_index": -120, "parallax": 0.0, "position": Vector2(0, -608), "repeat": false},
			{"id": "FarHills", "asset": "far_hills_loop", "z_index": -90, "parallax": 0.12, "position": Vector2(0, 96), "repeat": true},
			{"id": "FarForest", "asset": "far_forest_loop", "z_index": -80, "parallax": 0.18, "position": Vector2(0, 220), "repeat": true},
			{"id": "CloudsA", "asset": "cloud_loop_01", "z_index": -100, "parallax": 0.05, "position": Vector2(0, -360), "repeat": true},
			{"id": "CloudsB", "asset": "cloud_loop_02", "z_index": -99, "parallax": 0.08, "position": Vector2(0, -260), "repeat": true},
		],
		"resource_variants": {
			"tree": ["tree_variant_01", "tree_variant_02"],
			"mother_tree": ["mother_tree_variant_01", "mother_tree_variant_02"],
			"stone": ["stone_variant_01", "stone_variant_02"],
		},
	},
}

const BUILDING_INTERIORS := {
	"default": {
		"layout": "shell",
		"display_name": "室内",
		"background_asset": "shell_background",
	},
	"farm": {
		"layout": "farm",
		"display_name": "农田室内",
		"background_asset": "farm_background",
		"worker_role": "farmer",
		"plot_count": 6,
		"cycle_seconds": INTERIOR_FARM_CYCLE_SECONDS,
		"sow_action_seconds": INTERIOR_FARM_ACTION_SECONDS,
		"harvest_action_seconds": INTERIOR_FARM_ACTION_SECONDS,
		"reward_gold": 1,
	},
	"lumberyard": {
		"layout": "lumberyard",
		"display_name": "伐木场室内",
		"background_asset": "lumberyard_background",
		"worker_role": "lumberjack",
		"resource_kind": "tree",
		"spawn_seconds": LUMBERYARD_TREE_INTERVAL_SECONDS,
		"spawn_count": LUMBERYARD_TREE_BATCH_COUNT,
		"max_resources": 6,
	},
	"quarry": {
		"layout": "quarry",
		"display_name": "采石场室内",
		"background_asset": "quarry_background",
		"worker_role": "miner",
		"resource_kind": "stone",
		"spawn_seconds": 60.0,
		"spawn_count": 1,
		"max_resources": 3,
	},
	"barracks": {
		"layout": "barracks",
		"display_name": "barracks interior",
		"background_asset": "shell_background",
		"worker_role": "soldier",
		"columns": BARRACKS_TRAINING_COLUMNS,
		"rows": BARRACKS_TRAINING_ROWS,
		"capacity_by_level": BARRACKS_CAPACITY_BY_LEVEL,
	},
}

const CROPS := {
	"wheat": {
		"display_name": "小麦",
		"seed_display_name": "小麦种子",
		"reward_gold": 1,
		"default_unlocked": true,
	},
	"carrot": {
		"display_name": "胡萝卜",
		"seed_display_name": "胡萝卜种子",
		"reward_gold": 1,
		"default_unlocked": false,
	},
	"cabbage": {
		"display_name": "卷心菜",
		"seed_display_name": "卷心菜种子",
		"reward_gold": 1,
		"default_unlocked": false,
	},
	"pumpkin": {
		"display_name": "南瓜",
		"seed_display_name": "南瓜种子",
		"reward_gold": 1,
		"default_unlocked": false,
	},
	"blueberry": {
		"display_name": "蓝莓",
		"seed_display_name": "蓝莓种子",
		"reward_gold": 1,
		"default_unlocked": false,
	},
	"moon_mushroom": {
		"display_name": "月光蘑菇",
		"seed_display_name": "月光蘑菇种子",
		"reward_gold": 1,
		"default_unlocked": false,
	},
}

const SEED_DROP_RULES := {
	"chance": INTERIOR_SEED_DROP_CHANCE,
	"activities": ["harvest", "tree_chop", "stone_mine", "fishing"],
}

const FISH_SPECIES := [
	{
		"id": "silver_crucian",
		"display_name": "银鳞鲫",
		"rarity": "common",
		"probability": 0.34,
		"min_weight": 0.2,
		"max_weight": 1.2,
	},
	{
		"id": "river_bass",
		"display_name": "河湾鲈",
		"rarity": "common",
		"probability": 0.30,
		"min_weight": 0.4,
		"max_weight": 2.0,
	},
	{
		"id": "mud_catfish",
		"display_name": "泥须鲶",
		"rarity": "common",
		"probability": 0.20,
		"min_weight": 0.8,
		"max_weight": 4.0,
	},
	{
		"id": "golden_trout",
		"display_name": "金鳟",
		"rarity": "rare",
		"probability": 0.08,
		"min_weight": 1.0,
		"max_weight": 3.5,
	},
	{
		"id": "crystal_eel",
		"display_name": "水晶鳗",
		"rarity": "rare",
		"probability": 0.06,
		"min_weight": 0.5,
		"max_weight": 2.5,
	},
	{
		"id": "moon_kingfish",
		"display_name": "月辉王鱼",
		"rarity": "legendary",
		"probability": 0.02,
		"min_weight": 3.0,
		"max_weight": 12.0,
	},
]

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
	"worker_capacity": 1,
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
			"requires": {"cityhall": 2, "quarry": 1},
		},
		3: {
			"cost": 40,
			"requires": {"cityhall": 3, "iron_mine": 1},
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
		3: {
			"cost": 90,
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
	"resource_size_multiplier": RESOURCE_SIZE_MULTIPLIER,
	"quarry_size": QUARRY_SIZE,
	"bridge_size": BRIDGE_SIZE,
	"bridge_water_size": BRIDGE_WATER_SIZE,
	"tree_count": TREE_COUNT,
	"tree_random_seed": TREE_RANDOM_SEED,
	"mother_tree_count": MOTHER_TREE_COUNT,
	"mother_tree_random_seed": MOTHER_TREE_RANDOM_SEED,
	"mother_tree_grow_radius": MOTHER_TREE_GROW_RADIUS,
	"lumberjack_tree_search_radius": LUMBERJACK_TREE_SEARCH_RADIUS,
	"mother_tree_lumberjack_search_radius": MOTHER_TREE_LUMBERJACK_SEARCH_RADIUS,
	"stone_count": STONE_COUNT,
	"stone_random_seed": STONE_RANDOM_SEED,
	"bridge_count": BRIDGE_COUNT,
	"bridge_random_seed": BRIDGE_RANDOM_SEED,
	"city_hall_resource_inner_radius": CITY_HALL_RESOURCE_INNER_RADIUS,
	"city_hall_resource_outer_radius": CITY_HALL_RESOURCE_OUTER_RADIUS,
	"bridge_city_hall_ring_offset": BRIDGE_CITY_HALL_RING_OFFSET,
	"mother_tree_city_hall_ring_offset": MOTHER_TREE_CITY_HALL_RING_OFFSET,
	"stone_city_hall_ring_offset": STONE_CITY_HALL_RING_OFFSET,
	"autosave_seconds": AUTOSAVE_SECONDS,
	"non_cityhall_building_size_multiplier": NON_CITYHALL_BUILDING_SIZE_MULTIPLIER,
	"city_hall_front": CITY_HALL_FRONT,
	"terrain_tile_size": TERRAIN_TILE_SIZE,
	"visual_chunk_width": VISUAL_CHUNK_WIDTH,
}

const ECONOMY := {
	"starting_gold": STARTING_GOLD,
	"farm_income_seconds": FARM_INCOME_SECONDS,
	"tool_craft_seconds": TOOL_CRAFT_SECONDS,
	"tool_craft_cost": TOOL_CRAFT_COST,
	"blacksmith_tool_limit": BLACKSMITH_TOOL_LIMIT,
	"bridge_farm_cost": BRIDGE_FARM_COST,
}

const FISHING := {
	"bite_base_chance": 0.05,
	"bite_chance_step": 0.05,
	"bite_chance_max": 0.8,
	"bite_check_seconds": 1.0,
	"hook_window_seconds": 1.5,
	"reel_start_progress": 0.2,
	"reel_press_gain": 0.15,
	"reel_decay_per_second": 0.18,
	"result_visible_seconds": 1.2,
	"reward_gold": 1,
	"movement_cancel_distance": 4.0,
}

const TRADE := {
	"horse_base_price": 30,
	"horse_treaty_price": 20,
}

const TRAVEL_DESTINATIONS := {
	"main": {
		"display_name": "main",
		"scene_path": MAIN_SCENE_PATH,
	},
	"river": {
		"display_name": "河湾商盟",
		"scene_path": "res://scenes/RiverMerchantAlliance.tscn",
	},
}

const POST_STATION_PANEL_TRAVEL_DESTINATIONS := ["river"]

const RIVER_MERCHANT_ALLIANCE_NPC_LAYOUT := [
	{"name": "Farmer_01", "role": "farmer", "position": Vector2(1600, GROUND_TOP_Y), "home_position": Vector2(1600, GROUND_TOP_Y), "home_id": "farm_1", "home_name": "farm", "enters_building": true},
	{"name": "Farmer_02", "role": "farmer", "position": Vector2(1840, GROUND_TOP_Y), "home_position": Vector2(1840, GROUND_TOP_Y), "home_id": "farm_2", "home_name": "farm", "enters_building": true},
	{"name": "Farmer_03", "role": "farmer", "position": Vector2(2080, GROUND_TOP_Y), "home_position": Vector2(2080, GROUND_TOP_Y), "home_id": "farm_3", "home_name": "farm", "enters_building": true},
	{"name": "Farmer_04", "role": "farmer", "position": Vector2(2320, GROUND_TOP_Y), "home_position": Vector2(2320, GROUND_TOP_Y), "home_id": "farm_4", "home_name": "farm", "enters_building": true},
	{"name": "Farmer_05", "role": "farmer", "position": Vector2(2560, GROUND_TOP_Y), "home_position": Vector2(2560, GROUND_TOP_Y), "home_id": "farm_5", "home_name": "farm", "enters_building": true},
	{"name": "Lumberjack_01", "role": "lumberjack", "position": Vector2(3100, GROUND_TOP_Y), "home_position": Vector2(3100, GROUND_TOP_Y), "home_id": "lumberyard_1", "home_name": "lumberyard", "enters_building": true},
	{"name": "Lumberjack_02", "role": "lumberjack", "position": Vector2(3340, GROUND_TOP_Y), "home_position": Vector2(3340, GROUND_TOP_Y), "home_id": "lumberyard_2", "home_name": "lumberyard", "enters_building": true},
	{"name": "Lumberjack_03", "role": "lumberjack", "position": Vector2(3580, GROUND_TOP_Y), "home_position": Vector2(3580, GROUND_TOP_Y), "home_id": "lumberyard_3", "home_name": "lumberyard", "enters_building": true},
	{"name": "Miner_01", "role": "miner", "position": Vector2(6050, GROUND_TOP_Y), "home_position": Vector2(6050, GROUND_TOP_Y), "home_id": "quarry_1", "home_name": "quarry", "enters_building": true},
	{"name": "Miner_02", "role": "miner", "position": Vector2(6280, GROUND_TOP_Y), "home_position": Vector2(6280, GROUND_TOP_Y), "home_id": "quarry_2", "home_name": "quarry", "enters_building": true},
	{"name": "Miner_03", "role": "miner", "position": Vector2(6510, GROUND_TOP_Y), "home_position": Vector2(6510, GROUND_TOP_Y), "home_id": "quarry_3", "home_name": "quarry", "enters_building": true},
	{"name": "SmithVillager_01", "role": "villager", "position": Vector2(7100, GROUND_TOP_Y), "home_position": Vector2(7100, GROUND_TOP_Y), "home_id": "blacksmith_1", "home_name": "blacksmith", "enters_building": true},
	{"name": "SmithVillager_02", "role": "villager", "position": Vector2(7330, GROUND_TOP_Y), "home_position": Vector2(7330, GROUND_TOP_Y), "home_id": "blacksmith_2", "home_name": "blacksmith", "enters_building": true},
	{"name": "Warrior_01", "role": "warrior", "position": Vector2(650, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Warrior_02", "role": "warrior", "position": Vector2(710, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Warrior_03", "role": "warrior", "position": Vector2(770, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Warrior_04", "role": "warrior", "position": Vector2(830, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Warrior_05", "role": "warrior", "position": Vector2(890, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Warrior_06", "role": "warrior", "position": Vector2(8710, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Warrior_07", "role": "warrior", "position": Vector2(8770, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Warrior_08", "role": "warrior", "position": Vector2(8830, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Warrior_09", "role": "warrior", "position": Vector2(8890, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Warrior_10", "role": "warrior", "position": Vector2(8950, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Archer_01", "role": "archer", "position": Vector2(700, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Archer_02", "role": "archer", "position": Vector2(760, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Archer_03", "role": "archer", "position": Vector2(820, GROUND_TOP_Y), "patrol_side": "left", "patrol_anchor": Vector2(760, GROUND_TOP_Y)},
	{"name": "Archer_04", "role": "archer", "position": Vector2(8780, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Archer_05", "role": "archer", "position": Vector2(8840, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
	{"name": "Archer_06", "role": "archer", "position": Vector2(8900, GROUND_TOP_Y), "patrol_side": "right", "patrol_anchor": Vector2(8840, GROUND_TOP_Y)},
]

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


func homeless_spawn_value(key: String, default_value = null):
	return HOMELESS_SPAWN.get(key, default_value)


func tavern_attraction_value(key: String, default_value = null):
	return TAVERN_ATTRACTION.get(key, default_value)


func wall_health_for_level(level: int) -> int:
	var normalized_level := maxi(1, level)
	var best_health := int(WALL_HEALTH_BY_LEVEL.get(1, 20))
	for health_level in WALL_HEALTH_BY_LEVEL.keys():
		var numeric_level := int(health_level)
		if normalized_level >= numeric_level:
			best_health = int(WALL_HEALTH_BY_LEVEL[health_level])
	return best_health


func monster_value(key: String, default_value = null):
	var monster := {
		"max_health": MONSTER_MAX_HEALTH,
		"spawn_edge_padding": MONSTER_SPAWN_EDGE_PADDING,
		"speed": MONSTER_SPEED,
		"return_speed": MONSTER_RETURN_SPEED,
		"detection_range": MONSTER_DETECTION_RANGE,
		"hit_range": MONSTER_HIT_RANGE,
		"dash_distance": MONSTER_DASH_DISTANCE,
		"dash_speed_multiplier": MONSTER_DASH_SPEED_MULTIPLIER,
		"charge_seconds": MONSTER_CHARGE_SECONDS,
		"spawn_interval_seconds": MONSTER_SPAWN_INTERVAL_SECONDS,
		"random_seed": MONSTER_RANDOM_SEED,
	}
	return monster.get(key, default_value)


func economy_value(key: String, default_value = null):
	return ECONOMY.get(key, default_value)


func fishing_value(key: String, default_value = null):
	return FISHING.get(key, default_value)


func trade_value(key: String, default_value = null):
	return TRADE.get(key, default_value)


func travel_destination_value(terrain: String, key: String, default_value = null):
	var destination: Dictionary = TRAVEL_DESTINATIONS.get(terrain, {})
	return destination.get(key, default_value)


func travel_destination_scene_path(terrain: String) -> String:
	return str(travel_destination_value(terrain, "scene_path", ""))


func travel_destination_display_name(terrain: String) -> String:
	return str(travel_destination_value(terrain, "display_name", terrain))


func post_station_panel_travel_destinations() -> Array:
	return POST_STATION_PANEL_TRAVEL_DESTINATIONS.duplicate()


func river_merchant_alliance_npc_layout() -> Array:
	var layout: Array = []
	for definition in RIVER_MERCHANT_ALLIANCE_NPC_LAYOUT:
		layout.append((definition as Dictionary).duplicate(true))
	return layout


func river_mirror_water_visual() -> Dictionary:
	return RIVER_MIRROR_WATER_VISUAL.duplicate(true)


func day_night_visual() -> Dictionary:
	return DAY_NIGHT_VISUAL.duplicate(true)


func training_value(key: String, default_value = null):
	return TRAINING.get(key, default_value)


func defense_value(key: String, default_value = null):
	return DEFENSE.get(key, default_value)


func arrow_value(key: String, default_value = null):
	return ARROW.get(key, default_value)


func art_asset_path(category: String, asset_id: String) -> String:
	var category_assets: Dictionary = ART_ASSETS.get(category, {})
	var filename := str(category_assets.get(asset_id, ""))
	if filename == "":
		return ""
	return "%s/%s/%s" % [ART_ASSET_ROOT, category, filename]


func art_asset_texture(category: String, asset_id: String) -> Texture2D:
	var path := art_asset_path(category, asset_id)
	if path == "":
		return null
	return load(path) as Texture2D


func art_asset_visible_rect(category: String, asset_id: String) -> Rect2:
	var cache_key := "%s:%s" % [category, asset_id]
	if _art_asset_visible_rect_cache.has(cache_key):
		return _art_asset_visible_rect_cache[cache_key]

	var texture := art_asset_texture(category, asset_id)
	if texture == null:
		return Rect2()

	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	var image := texture.get_image()
	if image == null:
		var full_rect := Rect2(Vector2.ZERO, texture_size)
		_art_asset_visible_rect_cache[cache_key] = full_rect
		return full_rect
	if image.is_compressed():
		image.decompress()

	var min_x := int(texture_size.x)
	var min_y := int(texture_size.y)
	var max_x := -1
	var max_y := -1
	for y in range(int(texture_size.y)):
		for x in range(int(texture_size.x)):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	var visible_rect := Rect2(Vector2.ZERO, texture_size)
	if max_x >= min_x and max_y >= min_y:
		visible_rect = Rect2(
			Vector2(float(min_x), float(min_y)),
			Vector2(float(max_x - min_x + 1), float(max_y - min_y + 1))
		)
	_art_asset_visible_rect_cache[cache_key] = visible_rect
	return visible_rect


func building_body_size(definition: Dictionary) -> Vector2:
	var target_size: Vector2 = definition.get("size", Vector2.ZERO)
	var building_id := str(definition.get("id", ""))
	if target_size == Vector2.ZERO or building_id == "":
		return target_size

	var texture := art_asset_texture("buildings", building_id)
	if texture == null:
		return target_size

	var canvas_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	var visible_rect := art_asset_visible_rect("buildings", building_id)
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0 or visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
		return target_size

	var scale_factor := minf(
		target_size.x / maxf(1.0, canvas_size.x),
		target_size.y / maxf(1.0, canvas_size.y)
	)
	return visible_rect.size * scale_factor


func art_asset_root() -> String:
	return ART_ASSET_ROOT


func terrain_asset_root() -> String:
	return TERRAIN_ASSET_ROOT


func terrain_asset_path(asset_id: String) -> String:
	var relative_path := str(TERRAIN_ASSETS.get(asset_id, ""))
	if relative_path == "":
		return ""
	return "%s/%s" % [TERRAIN_ASSET_ROOT, relative_path]


func terrain_asset_texture(asset_id: String) -> Texture2D:
	var path := terrain_asset_path(asset_id)
	if path == "":
		return null
	return load(path) as Texture2D


func terrain_set(set_id := "main_grass") -> Dictionary:
	var terrain_data: Dictionary = TERRAIN_SETS.get(set_id, {})
	return terrain_data.duplicate(true)


func terrain_tile_size() -> Vector2:
	return TERRAIN_TILE_SIZE


func visual_chunk_width() -> float:
	return float(VISUAL_CHUNK_WIDTH)


func building_interior_scene_path() -> String:
	return BUILDING_INTERIOR_SCENE_PATH


func building_interior_definition(building_id: String) -> Dictionary:
	var definition: Dictionary = BUILDING_INTERIORS.get(building_id, BUILDING_INTERIORS.get("default", {}))
	return definition.duplicate(true)


func building_interior_value(building_id: String, key: String, default_value = null):
	var definition := building_interior_definition(building_id)
	return definition.get(key, default_value)


func interior_player_speed() -> float:
	return INTERIOR_PLAYER_SPEED


func interior_npc_speed() -> float:
	return INTERIOR_NPC_SPEED


func interior_door_range() -> float:
	return INTERIOR_DOOR_RANGE


func interior_autosave_seconds() -> float:
	return INTERIOR_AUTOSAVE_SECONDS


func interior_worker_default_position() -> Vector2:
	return INTERIOR_WORKER_DEFAULT_POSITION


func interior_farm_plot_position(plot_index: int) -> Vector2:
	return INTERIOR_FARM_PLOT_ORIGIN + Vector2(float(plot_index) * INTERIOR_FARM_PLOT_SPACING_X, 0.0)


func interior_farm_worker_position(plot_index: int) -> Vector2:
	return interior_farm_plot_position(plot_index) + INTERIOR_FARM_WORKER_OFFSET


func interior_resource_worker_position(resource_x: float) -> Vector2:
	return Vector2(resource_x, INTERIOR_RESOURCE_WORKER_Y)


func barracks_capacity_for_level(level: int) -> int:
	var resolved_level := clampi(level, 1, 3)
	return int(BARRACKS_CAPACITY_BY_LEVEL.get(resolved_level, BARRACKS_CAPACITY_BY_LEVEL.get(1, 10)))


func barracks_training_level_for_elapsed(elapsed_seconds: float) -> int:
	var accumulated := 0.0
	var current_level := 0
	for level_data in BARRACKS_TRAINING_LEVELS:
		var duration := float(level_data.get("duration_seconds", 0.0))
		accumulated += duration
		if elapsed_seconds + 0.001 >= accumulated:
			current_level = int(level_data.get("level", current_level))
		else:
			break
	return current_level


func barracks_stat_multiplier_for_level(level: int) -> float:
	if level <= 0:
		return 1.0
	for level_data in BARRACKS_TRAINING_LEVELS:
		if int(level_data.get("level", 0)) == level:
			return float(level_data.get("stat_multiplier", 1.0))
	return float(BARRACKS_TRAINING_LEVELS[BARRACKS_TRAINING_LEVELS.size() - 1].get("stat_multiplier", 1.0))


func barracks_training_position(index: int) -> Vector2:
	var columns := maxi(1, BARRACKS_TRAINING_COLUMNS)
	return BARRACKS_TRAINING_ORIGIN + Vector2(
		float(index % columns) * BARRACKS_TRAINING_SPACING.x,
		float(index / columns) * BARRACKS_TRAINING_SPACING.y
	)


func barracks_training_rows() -> int:
	return BARRACKS_TRAINING_ROWS


func crop_ids() -> Array:
	return CROPS.keys()


func crop_definition(crop_id: String) -> Dictionary:
	var definition: Dictionary = CROPS.get(crop_id, {})
	return definition.duplicate(true)


func crop_value(crop_id: String, key: String, default_value = null):
	var definition: Dictionary = CROPS.get(crop_id, {})
	return definition.get(key, default_value)


func crop_stage_asset_id(crop_id: String, stage: String) -> String:
	return "%s_%s" % [crop_id, stage]


func default_unlocked_crops() -> Dictionary:
	var unlocked := {}
	for crop_id in CROPS.keys():
		if bool(crop_value(crop_id, "default_unlocked", false)):
			unlocked[crop_id] = true
	return unlocked


func seed_drop_chance() -> float:
	return float(SEED_DROP_RULES.get("chance", 0.0))


func seed_drop_activities() -> Array:
	return (SEED_DROP_RULES.get("activities", []) as Array).duplicate()


func fish_species() -> Array:
	return FISH_SPECIES.duplicate(true)


func fish_species_ids() -> Array:
	var ids := []
	for fish in FISH_SPECIES:
		ids.append(str(fish.get("id", "")))
	return ids


func fish_species_definition(fish_id: String) -> Dictionary:
	for fish in FISH_SPECIES:
		if str(fish.get("id", "")) == fish_id:
			return fish.duplicate(true)
	return {}


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


func scaled_building_definition(definition: Dictionary) -> Dictionary:
	var scaled_definition := definition.duplicate(true)
	if str(scaled_definition.get("id", "")) == "cityhall":
		return scaled_definition
	if scaled_definition.has("size"):
		var base_size: Vector2 = scaled_definition.get("size", Vector2.ZERO)
		scaled_definition.size = base_size * NON_CITYHALL_BUILDING_SIZE_MULTIPLIER
	return scaled_definition


func scaled_building_definitions(definitions: Array) -> Array:
	var scaled_definitions: Array = []
	for definition in definitions:
		if definition is Dictionary:
			scaled_definitions.append(scaled_building_definition(definition))
	return scaled_definitions


func building_orientation_rule(building_id: String) -> Dictionary:
	var rule: Dictionary = BUILDING_ORIENTATION_RULES.get(building_id, {})
	return rule.duplicate(true)


func oriented_building_scale(
	building_id: String,
	building_position: Vector2,
	city_hall_position: Vector2,
	base_scale := Vector2.ONE
) -> Vector2:
	var oriented_scale := Vector2(absf(base_scale.x), absf(base_scale.y))
	var rule := building_orientation_rule(building_id)
	if bool(rule.get("mirror_right_of_cityhall", false)) and building_position.x > city_hall_position.x:
		oriented_scale.x = -absf(base_scale.x)
	return oriented_scale


func terrain_building_ids(terrain: String) -> Array:
	var ids: Array = []
	for definition in TERRAIN_BUILDINGS.get(terrain, []):
		ids.append(str(definition.get("id", "")))
	return ids


func terrain_building_definitions(terrain := "") -> Array:
	var definitions: Array = []
	if terrain != "":
		for definition in TERRAIN_BUILDINGS.get(terrain, []):
			definitions.append(scaled_building_definition(definition))
		return definitions

	for terrain_id in TERRAIN_BUILDINGS.keys():
		for definition in TERRAIN_BUILDINGS[terrain_id]:
			definitions.append(scaled_building_definition(definition))
	return definitions


func terrain_building_definition(building_id: String) -> Dictionary:
	for definition in terrain_building_definitions():
		if definition.get("id", "") == building_id:
			return definition.duplicate(true)
	return {}


func quarry_value(key: String, default_value = null):
	if key == "size":
		return quarry_definition().get("size", default_value)
	return QUARRY.get(key, default_value)


func quarry_definition() -> Dictionary:
	return scaled_building_definition(QUARRY)


func farm_value(key: String, default_value = null):
	if key == "size":
		return farm_definition().get("size", default_value)
	return FARM.get(key, default_value)


func farm_definition() -> Dictionary:
	return scaled_building_definition(FARM)


func lumberyard_value(key: String, default_value = null):
	if key == "size":
		return lumberyard_definition().get("size", default_value)
	return LUMBERYARD.get(key, default_value)


func lumberyard_definition() -> Dictionary:
	return scaled_building_definition(LUMBERYARD)


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
