extends SceneTree

const V3_ROOT := "res://assets/medieval_pixel_pack_v3_no_outline"

var failures := 0


func _init() -> void:
	var game_data_script := load("res://scripts/GameData.gd")
	var building_factory_script := load("res://scripts/BuildingVisualFactory.gd")
	var npc_factory_script := load("res://scripts/NPCFactory.gd")
	var tree_factory_script := load("res://scripts/TreeFactory.gd")
	var monster_script := load("res://scripts/Monster.gd")
	var day_night_script := load("res://scripts/DayNightManager.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")

	_assert_true(game_data_script != null, "GameData.gd should load")
	_assert_true(building_factory_script != null, "BuildingVisualFactory.gd should load")
	_assert_true(npc_factory_script != null, "NPCFactory.gd should load")
	_assert_true(tree_factory_script != null, "TreeFactory.gd should load")
	_assert_true(monster_script != null, "Monster.gd should load")
	_assert_true(day_night_script != null, "DayNightManager.gd should load")
	_assert_true(build_manager_script != null, "BuildManager.gd should load")

	if game_data_script != null:
		var game_data = game_data_script.new()
		_assert_true(game_data.has_method("art_asset_path"), "GameData exposes art_asset_path")
		if game_data.has_method("art_asset_path"):
			_assert_equal(game_data.art_asset_path("buildings", "blacksmith"), "%s/buildings/blacksmith.png" % V3_ROOT, "blacksmith path is in v3 pack")
			_assert_equal(game_data.art_asset_path("npcs", "villager"), "%s/npcs/villager.png" % V3_ROOT, "villager path is in v3 pack")
			_assert_equal(game_data.art_asset_path("environment", "sun"), "%s/environment/sun.png" % V3_ROOT, "sun path is in v3 pack")
			_assert_equal(game_data.art_asset_path("environment", "river_background"), "%s/environment/river_background.png" % V3_ROOT, "river background path is in v3 pack")
			_assert_equal(game_data.art_asset_path("environment", "river_ground"), "%s/environment/river_ground.png" % V3_ROOT, "river ground path is in v3 pack")
			_assert_equal(game_data.art_asset_path("environment", "foreground_water"), "%s/environment/foreground_water.png" % V3_ROOT, "foreground water path is in v3 pack")
			_assert_equal(game_data.art_asset_path("ui", "gold"), "%s/ui/gold.png" % V3_ROOT, "gold icon path is in v3 pack")
			_assert_true(ResourceLoader.exists(game_data.art_asset_path("tools", "iron_sword")), "iron sword asset exists")

	_test_no_outline_pack_validation()
	if building_factory_script != null:
		_test_building_factory_uses_v3_sprite(building_factory_script)
	if npc_factory_script != null:
		_test_npc_factory_uses_v3_sprites(npc_factory_script)
	if tree_factory_script != null:
		_test_tree_factory_uses_v3_sprites(tree_factory_script)
	if monster_script != null:
		_test_monster_uses_v3_sprite(monster_script)
	if day_night_script != null:
		_test_day_night_uses_v3_celestial_sprites(day_night_script)
	if build_manager_script != null:
		_test_tool_visual_uses_v3_sprite(build_manager_script)
	_test_main_scene_uses_v3_static_sprites()
	_test_river_scene_uses_v3_building_sprites()

	if failures == 0:
		print("ArtAssetImportTest: PASS")
	else:
		push_error("ArtAssetImportTest: %d failure(s)" % failures)

	quit(failures)


func _test_no_outline_pack_validation() -> void:
	var report_text := FileAccess.get_file_as_string("%s/validation_report.json" % V3_ROOT)
	_assert_true(report_text != "", "v3 no-outline validation report exists")
	if report_text == "":
		return
	var parsed = JSON.parse_string(report_text)
	_assert_true(parsed is Dictionary, "v3 no-outline validation report parses")
	if not (parsed is Dictionary):
		return
	_assert_equal(parsed.get("asset_count"), 52, "v3 no-outline pack has 52 final assets")
	_assert_equal(parsed.get("failure_count"), 0, "v3 no-outline pack validation passed")
	var scene_layers: Array = parsed.get("scene_layer_assets", [])
	_assert_true(scene_layers.has("river_background"), "v3 no-outline pack records river background scene layer")
	_assert_true(scene_layers.has("river_ground"), "v3 no-outline pack records river ground scene layer")
	_assert_true(scene_layers.has("foreground_water"), "v3 no-outline pack records foreground water scene layer")
	var rules: Dictionary = parsed.get("rules", {})
	_assert_equal(rules.get("uses_original_generated_raw_atlases"), true, "v3 no-outline pack uses original raw atlases")
	_assert_equal(rules.get("uses_single_generated_raw_replacements"), true, "v3 no-outline pack records single raw replacements")
	_assert_equal(rules.get("adds_outline_stroke"), false, "v3 no-outline pack does not add outline stroke")
	_assert_equal(rules.get("hard_alpha_only"), true, "v3 no-outline pack uses hard alpha")
	_assert_equal(rules.get("manifest_sizes_preserved"), true, "v3 no-outline pack preserves manifest sizes")
	var regenerations: Array = parsed.get("single_asset_regenerations", [])
	_assert_true(regenerations.has("farm"), "v3 no-outline pack records regenerated field-focused farm")
	_assert_true(regenerations.has("lumberyard"), "v3 no-outline pack records regenerated lumberyard")
	_assert_true(regenerations.has("post_station"), "v3 no-outline pack records regenerated HD post station")
	_assert_true(regenerations.has("quarry"), "v3 no-outline pack records regenerated quarry")
	_assert_true(regenerations.has("wall"), "v3 no-outline pack records regenerated side-view wall")


func _test_building_factory_uses_v3_sprite(factory_script: Script) -> void:
	var factory = factory_script.new()
	var visual: Node2D = factory.create_building_visual({
		"id": "blacksmith",
		"display_name": "铁匠铺",
		"size": Vector2(180, 140),
		"base_color": Color(0.42, 0.36, 0.32, 1),
		"accent_color": Color(0.9, 0.32, 0.18, 1),
	})
	_assert_sprite_texture_path(visual, "GeneratedSprite", "%s/buildings/blacksmith.png" % V3_ROOT, "blacksmith visual uses v3 sprite")
	var fallback_body := visual.get_node_or_null("Body") as CanvasItem
	_assert_true(fallback_body != null, "blacksmith keeps fallback body node")
	if fallback_body != null:
		_assert_false(fallback_body.visible, "blacksmith fallback body is hidden behind sprite")
	visual.queue_free()


func _test_npc_factory_uses_v3_sprites(factory_script: Script) -> void:
	var factory = factory_script.new()
	var npc: Node2D = factory.create_homeless(Vector2(4800, 472), Vector2(4800, 472))
	_assert_sprite_texture_path(npc, "GeneratedSprite", "%s/npcs/homeless.png" % V3_ROOT, "homeless uses v3 sprite")
	npc.interact()
	_assert_sprite_texture_path(npc, "GeneratedSprite", "%s/npcs/villager.png" % V3_ROOT, "villager uses v3 sprite after interaction")
	if npc.has_method("become_farmer"):
		npc.become_farmer()
		_assert_sprite_texture_path(npc, "GeneratedSprite", "%s/npcs/farmer.png" % V3_ROOT, "farmer uses v3 sprite")
	if npc.has_method("equip_tool"):
		npc.equip_tool("bow")
		_assert_sprite_texture_path(npc, "GeneratedSprite", "%s/npcs/archer.png" % V3_ROOT, "archer uses v3 sprite after bow equip")
	npc.queue_free()


func _test_tree_factory_uses_v3_sprites(factory_script: Script) -> void:
	var factory = factory_script.new()
	var tree: Node2D = factory.create_tree_visual()
	_assert_sprite_texture_path(tree, "GeneratedSprite", "%s/environment/tree.png" % V3_ROOT, "tree uses v3 sprite")
	tree.queue_free()
	var mother_tree: Node2D = factory.create_mother_tree_visual()
	_assert_sprite_texture_path(mother_tree, "GeneratedSprite", "%s/environment/mother_tree.png" % V3_ROOT, "mother tree uses v3 sprite")
	mother_tree.queue_free()
	_assert_true(factory.has_method("create_stone_visual"), "tree factory can create stone visual")
	if factory.has_method("create_stone_visual"):
		var stone: Node2D = factory.create_stone_visual()
		_assert_sprite_texture_path(stone, "GeneratedSprite", "%s/environment/stone.png" % V3_ROOT, "stone uses v3 sprite")
		stone.queue_free()


func _test_monster_uses_v3_sprite(monster_script: Script) -> void:
	var monster: Node2D = monster_script.new()
	monster.setup("left", Vector2(100, 472))
	_assert_sprite_texture_path(monster, "GeneratedSprite", "%s/npcs/monster.png" % V3_ROOT, "monster uses v3 sprite")
	monster.free()


func _test_day_night_uses_v3_celestial_sprites(day_night_script: Script) -> void:
	var manager: Node = day_night_script.new()
	get_root().add_child(manager)
	manager._ready()
	var sun := manager.get_node_or_null("SkyLayer/Sun")
	var moon := manager.get_node_or_null("SkyLayer/Moon")
	_assert_sprite_texture_path(sun, ".", "%s/environment/sun.png" % V3_ROOT, "sun uses v3 sprite")
	_assert_sprite_texture_path(moon, ".", "%s/environment/moon.png" % V3_ROOT, "moon uses v3 sprite")
	manager.queue_free()


func _test_river_scene_uses_v3_building_sprites() -> void:
	var packed_scene := load("res://scenes/RiverMerchantAlliance.tscn") as PackedScene
	_assert_true(packed_scene != null, "river scene should load")
	if packed_scene == null:
		return
	var scene := packed_scene.instantiate()
	_assert_sprite_texture_path(scene.get_node_or_null("CityHall"), "GeneratedSprite", "%s/buildings/cityhall.png" % V3_ROOT, "river city hall uses v3 sprite")
	_assert_sprite_texture_path(scene.get_node_or_null("PostStation"), "GeneratedSprite", "%s/buildings/post_station.png" % V3_ROOT, "river post station uses v3 sprite")
	_assert_sprite_texture_path(scene.get_node_or_null("Farms/Farm_01"), "GeneratedSprite", "%s/buildings/farm.png" % V3_ROOT, "river farm uses v3 sprite")
	scene.queue_free()


func _test_tool_visual_uses_v3_sprite(build_manager_script: Script) -> void:
	var manager: Node2D = build_manager_script.new()
	var visual: Node = manager._create_tool_visual("iron_sword")
	_assert_true(visual is Sprite2D, "spawned iron sword tool visual is Sprite2D")
	if visual is Sprite2D:
		_assert_sprite_texture_path(visual, ".", "%s/tools/iron_sword.png" % V3_ROOT, "spawned iron sword uses v3 sprite")
	visual.queue_free()
	manager.free()


func _test_main_scene_uses_v3_static_sprites() -> void:
	var packed_scene := load("res://scenes/Main.tscn") as PackedScene
	_assert_true(packed_scene != null, "main scene should load")
	if packed_scene == null:
		return
	var scene := packed_scene.instantiate()
	_assert_sprite_texture_path(scene.get_node_or_null("CityHall"), "GeneratedSprite", "%s/buildings/cityhall.png" % V3_ROOT, "main city hall uses v3 sprite")
	_assert_sprite_texture_path(scene.get_node_or_null("Player"), "GeneratedSprite", "%s/npcs/player.png" % V3_ROOT, "main player uses v3 sprite")
	scene.queue_free()


func _assert_sprite_texture_path(owner: Node, node_path: String, expected_path: String, message: String) -> void:
	_assert_true(owner != null, "%s owner exists" % message)
	if owner == null:
		return
	var node := owner if node_path == "." else owner.get_node_or_null(node_path)
	_assert_true(node is Sprite2D, "%s is Sprite2D" % message)
	if not (node is Sprite2D):
		return
	var sprite := node as Sprite2D
	_assert_true(sprite.texture != null, "%s has texture" % message)
	if sprite.texture == null:
		return
	_assert_equal(sprite.texture.resource_path, expected_path, message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
