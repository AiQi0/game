# Fishing Minigame Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a player-only fishing minigame in the main world where pressing `F` starts fishing, bite chance rises every second, reeling uses repeated `F` presses, and success grants 1 gold.

**Architecture:** Put all tunable values in `scripts/GameData.gd`, pure fishing math in `scripts/FishingRules.gd`, and runtime input/UI/state in `scripts/FishingManager.gd`. Wire `FishingManager` into `scenes/Main.tscn`; `BuildManager` only exposes whether fishing can start and ignores normal inputs while fishing is active.

**Tech Stack:** Godot 4.6, GDScript, headless `SceneTree` tests, existing `BuildManager.add_gold` economy path.

---

## File Structure

- Create `scripts/FishingRules.gd`: pure rule helper for bite probability, bite roll checks, progress gain/decay, and outcome.
- Create `scripts/FishingManager.gd`: main-world runtime node for `F`/`Q` input, fishing state machine, UI, and gold reward.
- Modify `scripts/GameData.gd`: add `FISHING` data and `fishing_value`.
- Modify `scripts/BuildManager.gd`: cache `FishingManager`, expose `can_start_fishing`, and skip normal controls while fishing.
- Modify `scenes/Main.tscn`: add `FishingManager` script resource and node.
- Create `tests/FishingRulesTest.gd`: test pure rules and data values.
- Create `tests/FishingManagerTest.gd`: test runtime state flow, reward, cancel, and scene wiring.
- Modify `tests/GameDataSeparationTest.gd`: assert fishing values are data-driven.
- Modify `GAME_REFERENCE.txt`: record `F` key, fishing UI, scripts, reward, and restrictions.

---

### Task 1: Data Layer And Pure Fishing Rules

**Files:**
- Modify: `scripts/GameData.gd`
- Create: `scripts/FishingRules.gd`
- Create: `tests/FishingRulesTest.gd`
- Modify: `tests/GameDataSeparationTest.gd`

- [ ] **Step 1: Write the failing pure rule test**

Create `tests/FishingRulesTest.gd`:

```gdscript
extends SceneTree

var failures := 0


func _init() -> void:
	var rules_script := load("res://scripts/FishingRules.gd")
	var data_script := load("res://scripts/GameData.gd")
	if rules_script == null:
		_fail("FishingRules.gd should load")
	if data_script == null:
		_fail("GameData.gd should load")

	if rules_script != null and data_script != null:
		var rules = rules_script.new()
		var data = data_script.new()
		_test_bite_chance(rules, data)
		_test_bite_rolls(rules, data)
		_test_reel_progress(rules, data)

	if failures == 0:
		print("FishingRulesTest: PASS")
	else:
		push_error("FishingRulesTest: %d failure(s)" % failures)

	quit(failures)


func _test_bite_chance(rules, data) -> void:
	_assert_approx(rules.bite_chance_for_second(1, data), 0.05, "first second bite chance is five percent")
	_assert_approx(rules.bite_chance_for_second(2, data), 0.10, "second second bite chance is ten percent")
	_assert_approx(rules.bite_chance_for_second(3, data), 0.15, "third second bite chance is fifteen percent")
	_assert_approx(rules.bite_chance_for_second(4, data), 0.20, "fourth second bite chance is twenty percent")
	_assert_approx(rules.bite_chance_for_second(99, data), 0.80, "bite chance is capped")


func _test_bite_rolls(rules, data) -> void:
	_assert_true(rules.should_bite(1, 0.049, data), "roll below chance bites")
	_assert_false(rules.should_bite(1, 0.05, data), "roll equal to chance does not bite")
	_assert_false(rules.should_bite(1, 0.5, data), "roll above chance does not bite")


func _test_reel_progress(rules, data) -> void:
	var progress := float(data.fishing_value("reel_start_progress", 0.0))
	_assert_approx(progress, 0.2, "reeling starts at twenty percent")
	progress = rules.reel_progress_after_press(progress, data)
	_assert_approx(progress, 0.35, "pressing F adds reel progress")
	progress = rules.reel_progress_after_decay(progress, 1.0, data)
	_assert_approx(progress, 0.17, "reel progress decays over time")
	_assert_equal(rules.reel_outcome(1.0), "success", "full progress succeeds")
	_assert_equal(rules.reel_outcome(0.0), "failed", "zero progress fails")
	_assert_equal(rules.reel_outcome(0.5), "active", "middle progress remains active")


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_approx(actual: float, expected: float, message: String) -> void:
	if abs(actual - expected) > 0.001:
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
godot --headless --path . --script res://tests/FishingRulesTest.gd
```

Expected: FAIL because `res://scripts/FishingRules.gd` does not exist.

- [ ] **Step 3: Add fishing data to `GameData.gd`**

Add near the other economy/world configuration dictionaries:

```gdscript
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
}
```

Add beside `economy_value` and other `*_value` accessors:

```gdscript
func fishing_value(key: String, default_value = null):
	return FISHING.get(key, default_value)
```

- [ ] **Step 4: Create `scripts/FishingRules.gd`**

```gdscript
extends RefCounted


func bite_chance_for_second(second_number: int, data) -> float:
	var base := float(data.fishing_value("bite_base_chance", 0.05))
	var step := float(data.fishing_value("bite_chance_step", 0.05))
	var max_chance := float(data.fishing_value("bite_chance_max", 0.8))
	var safe_second := max(1, second_number)
	var chance := base + float(safe_second - 1) * step
	return clampf(chance, 0.0, clampf(max_chance, 0.0, 1.0))


func should_bite(second_number: int, roll: float, data) -> bool:
	return roll < bite_chance_for_second(second_number, data)


func reel_progress_after_press(current_progress: float, data) -> float:
	var gain := float(data.fishing_value("reel_press_gain", 0.15))
	return clampf(current_progress + gain, 0.0, 1.0)


func reel_progress_after_decay(current_progress: float, delta: float, data) -> float:
	var decay := float(data.fishing_value("reel_decay_per_second", 0.18))
	return clampf(current_progress - maxf(delta, 0.0) * decay, 0.0, 1.0)


func reel_outcome(progress: float) -> String:
	if progress >= 1.0:
		return "success"
	if progress <= 0.0:
		return "failed"
	return "active"
```

- [ ] **Step 5: Update data separation test**

Add these assertions to `tests/GameDataSeparationTest.gd` near existing `economy_value` and world value checks:

```gdscript
_assert_equal(data.fishing_value("reward_gold"), 1, "fishing reward is data-driven")
_assert_equal(data.fishing_value("hook_window_seconds"), 1.5, "fishing hook window is data-driven")
_assert_equal(data.fishing_value("bite_base_chance"), 0.05, "fishing bite base chance is data-driven")
_assert_equal(data.fishing_value("reel_start_progress"), 0.2, "fishing start progress is data-driven")
```

- [ ] **Step 6: Run tests and verify they pass**

Run:

```powershell
godot --headless --path . --script res://tests/FishingRulesTest.gd
godot --headless --path . --script res://tests/GameDataSeparationTest.gd
```

Expected: both print `PASS`.

- [ ] **Step 7: Commit**

```powershell
git add scripts/GameData.gd scripts/FishingRules.gd tests/FishingRulesTest.gd tests/GameDataSeparationTest.gd
git commit -m "feat: add fishing rules data"
```

---

### Task 2: Runtime Fishing Manager And UI

**Files:**
- Create: `scripts/FishingManager.gd`
- Create: `tests/FishingManagerTest.gd`

- [ ] **Step 1: Write the failing manager test**

Create `tests/FishingManagerTest.gd`:

```gdscript
extends SceneTree

var failures := 0


func _init() -> void:
	var fishing_manager_script := load("res://scripts/FishingManager.gd")
	var build_manager_script := load("res://scripts/BuildManager.gd")
	if fishing_manager_script == null:
		_fail("FishingManager.gd should load")
	if build_manager_script == null:
		_fail("BuildManager.gd should load")

	if fishing_manager_script != null and build_manager_script != null:
		_test_start_bite_reel_success(fishing_manager_script, build_manager_script)
		_test_hook_timeout_and_cancel(fishing_manager_script, build_manager_script)
		_test_decay_failure(fishing_manager_script, build_manager_script)

	if failures == 0:
		print("FishingManagerTest: PASS")
	else:
		push_error("FishingManagerTest: %d failure(s)" % failures)

	quit(failures)


func _test_start_bite_reel_success(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")
	build_manager.gold = 0

	_assert_true(fishing_manager.try_start_fishing(), "F starts fishing from idle")
	_assert_equal(fishing_manager.state_name(), "waiting_for_bite", "fishing starts waiting for bite")
	fishing_manager._enter_bite_window()
	_assert_equal(fishing_manager.state_name(), "bite_window", "forced bite enters hook window")
	fishing_manager.press_fishing_key()
	_assert_equal(fishing_manager.state_name(), "reeling", "F during hook window starts reeling")
	for i in range(6):
		fishing_manager.press_fishing_key()
	_assert_equal(fishing_manager.state_name(), "success", "reeling reaches success")
	_assert_equal(build_manager.gold, 1, "successful fishing grants one gold")

	root.free()


func _test_hook_timeout_and_cancel(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var fishing_manager: Node = root.get_node("FishingManager")

	_assert_true(fishing_manager.try_start_fishing(), "fishing can start")
	fishing_manager._enter_bite_window()
	fishing_manager._process(1.6)
	_assert_equal(fishing_manager.state_name(), "failed", "hook window expires after one and a half seconds")

	fishing_manager._finish_result()
	_assert_true(fishing_manager.try_start_fishing(), "fishing can restart after result")
	fishing_manager.cancel_fishing()
	_assert_equal(fishing_manager.state_name(), "idle", "Q cancel returns fishing to idle")

	root.free()


func _test_decay_failure(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")
	build_manager.gold = 0

	_assert_true(fishing_manager.try_start_fishing(), "fishing can start")
	fishing_manager._enter_bite_window()
	fishing_manager.press_fishing_key()
	fishing_manager._process(2.0)
	_assert_equal(fishing_manager.state_name(), "failed", "reel progress decays to failure")
	_assert_equal(build_manager.gold, 0, "failed fishing grants no gold")

	root.free()


func _create_root(fishing_manager_script: Script, build_manager_script: Script) -> Node2D:
	var root := Node2D.new()

	var player := CharacterBody2D.new()
	player.name = "Player"
	root.add_child(player)

	var build_manager: Node2D = build_manager_script.new()
	build_manager.name = "BuildManager"
	root.add_child(build_manager)

	var fishing_manager: Node = fishing_manager_script.new()
	fishing_manager.name = "FishingManager"
	root.add_child(fishing_manager)
	fishing_manager.build_manager = build_manager
	fishing_manager.player = player
	fishing_manager._create_ui()

	return root


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail("%s: expected true" % message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
godot --headless --path . --script res://tests/FishingManagerTest.gd
```

Expected: FAIL because `res://scripts/FishingManager.gd` does not exist.

- [ ] **Step 3: Create `scripts/FishingManager.gd`**

```gdscript
extends Node

const GameData = preload("res://scripts/GameData.gd")
const FishingRules = preload("res://scripts/FishingRules.gd")

enum FishingState {
	IDLE,
	WAITING_FOR_BITE,
	BITE_WINDOW,
	REELING,
	SUCCESS,
	FAILED,
}

var data := GameData.new()
var rules := FishingRules.new()
var rng := RandomNumberGenerator.new()
var state := FishingState.IDLE
var build_manager: Node
var player: Node

var bite_elapsed := 0.0
var bite_check_elapsed := 0.0
var bite_second := 0
var hook_elapsed := 0.0
var reel_progress := 0.0
var result_elapsed := 0.0

var ui_canvas: CanvasLayer
var status_label: Label
var detail_label: Label
var progress_bar: ProgressBar


func _ready() -> void:
	rng.randomize()
	if build_manager == null:
		build_manager = get_parent().get_node_or_null("BuildManager")
	if player == null:
		player = get_parent().get_node_or_null("Player")
	_create_ui()
	_refresh_ui()


func _process(delta: float) -> void:
	if _should_cancel_for_context():
		cancel_fishing()
		return

	match state:
		FishingState.WAITING_FOR_BITE:
			_update_waiting_for_bite(delta)
		FishingState.BITE_WINDOW:
			_update_bite_window(delta)
		FishingState.REELING:
			_update_reeling(delta)
		FishingState.SUCCESS, FishingState.FAILED:
			_update_result(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F:
		press_fishing_key()
		_mark_input_handled()
	elif key_event.keycode == KEY_Q and is_fishing():
		cancel_fishing()
		_mark_input_handled()


func try_start_fishing() -> bool:
	if state != FishingState.IDLE:
		return false
	if not _can_start_fishing():
		return false

	state = FishingState.WAITING_FOR_BITE
	bite_elapsed = 0.0
	bite_check_elapsed = 0.0
	bite_second = 0
	hook_elapsed = 0.0
	reel_progress = 0.0
	result_elapsed = 0.0
	_refresh_ui()
	return true


func press_fishing_key() -> void:
	if state == FishingState.IDLE:
		try_start_fishing()
	elif state == FishingState.BITE_WINDOW:
		_start_reeling()
	elif state == FishingState.REELING:
		reel_progress = rules.reel_progress_after_press(reel_progress, data)
		_check_reel_outcome()
		_refresh_ui()


func cancel_fishing() -> void:
	if state == FishingState.IDLE:
		return
	state = FishingState.IDLE
	bite_elapsed = 0.0
	bite_check_elapsed = 0.0
	bite_second = 0
	hook_elapsed = 0.0
	reel_progress = 0.0
	result_elapsed = 0.0
	_refresh_ui()


func is_fishing() -> bool:
	return state in [
		FishingState.WAITING_FOR_BITE,
		FishingState.BITE_WINDOW,
		FishingState.REELING,
	]


func state_name() -> String:
	match state:
		FishingState.IDLE:
			return "idle"
		FishingState.WAITING_FOR_BITE:
			return "waiting_for_bite"
		FishingState.BITE_WINDOW:
			return "bite_window"
		FishingState.REELING:
			return "reeling"
		FishingState.SUCCESS:
			return "success"
		FishingState.FAILED:
			return "failed"
	return "idle"


func _update_waiting_for_bite(delta: float) -> void:
	bite_elapsed += delta
	bite_check_elapsed += delta
	var check_seconds := float(data.fishing_value("bite_check_seconds", 1.0))
	while bite_check_elapsed >= check_seconds and state == FishingState.WAITING_FOR_BITE:
		bite_check_elapsed -= check_seconds
		bite_second += 1
		if rules.should_bite(bite_second, rng.randf(), data):
			_enter_bite_window()
	_refresh_ui()


func _enter_bite_window() -> void:
	state = FishingState.BITE_WINDOW
	hook_elapsed = 0.0
	_refresh_ui()


func _update_bite_window(delta: float) -> void:
	hook_elapsed += delta
	if hook_elapsed >= float(data.fishing_value("hook_window_seconds", 1.5)):
		_fail_fishing()
	else:
		_refresh_ui()


func _start_reeling() -> void:
	state = FishingState.REELING
	reel_progress = float(data.fishing_value("reel_start_progress", 0.2))
	_check_reel_outcome()
	_refresh_ui()


func _update_reeling(delta: float) -> void:
	reel_progress = rules.reel_progress_after_decay(reel_progress, delta, data)
	_check_reel_outcome()
	_refresh_ui()


func _check_reel_outcome() -> void:
	var outcome := rules.reel_outcome(reel_progress)
	if outcome == "success":
		_succeed_fishing()
	elif outcome == "failed":
		_fail_fishing()


func _succeed_fishing() -> void:
	state = FishingState.SUCCESS
	result_elapsed = 0.0
	if build_manager != null and build_manager.has_method("add_gold"):
		build_manager.add_gold(int(data.fishing_value("reward_gold", 1)))
	else:
		push_warning("FishingManager could not find BuildManager.add_gold")
	_refresh_ui()


func _fail_fishing() -> void:
	state = FishingState.FAILED
	result_elapsed = 0.0
	_refresh_ui()


func _update_result(delta: float) -> void:
	result_elapsed += delta
	if result_elapsed >= float(data.fishing_value("result_visible_seconds", 1.2)):
		_finish_result()


func _finish_result() -> void:
	state = FishingState.IDLE
	_refresh_ui()


func _can_start_fishing() -> bool:
	if build_manager != null and build_manager.has_method("can_start_fishing"):
		return build_manager.can_start_fishing()
	if get_tree() != null and get_tree().paused:
		return false
	return true


func _should_cancel_for_context() -> bool:
	if state == FishingState.IDLE:
		return false
	if get_tree() != null and get_tree().paused:
		return true
	if build_manager != null and bool(build_manager.get("player_dead")):
		return true
	return false


func _create_ui() -> void:
	if ui_canvas != null:
		return

	ui_canvas = CanvasLayer.new()
	ui_canvas.name = "FishingUI"
	add_child(ui_canvas)

	var panel := ColorRect.new()
	panel.name = "FishingPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 1.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 1.0
	panel.offset_left = -210.0
	panel.offset_top = -190.0
	panel.offset_right = 210.0
	panel.offset_bottom = -118.0
	panel.color = Color(0.03, 0.07, 0.09, 0.82)
	ui_canvas.add_child(panel)

	status_label = Label.new()
	status_label.name = "FishingStatus"
	status_label.position = Vector2(16, 10)
	status_label.size = Vector2(388, 22)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(status_label)

	detail_label = Label.new()
	detail_label.name = "FishingDetail"
	detail_label.position = Vector2(16, 34)
	detail_label.size = Vector2(388, 18)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(detail_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "FishingProgress"
	progress_bar.position = Vector2(26, 54)
	progress_bar.size = Vector2(368, 12)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	panel.add_child(progress_bar)


func _refresh_ui() -> void:
	if ui_canvas == null:
		return
	ui_canvas.visible = state != FishingState.IDLE
	if status_label == null or detail_label == null or progress_bar == null:
		return

	match state:
		FishingState.WAITING_FOR_BITE:
			status_label.text = "正在钓鱼"
			detail_label.text = "等待咬钩... 已等待 %.1f秒" % bite_elapsed
			progress_bar.value = 0.0
		FishingState.BITE_WINDOW:
			status_label.text = "咬钩了！按 F 收杆"
			var remaining := maxf(0.0, float(data.fishing_value("hook_window_seconds", 1.5)) - hook_elapsed)
			detail_label.text = "剩余 %.1f秒" % remaining
			progress_bar.value = remaining / float(data.fishing_value("hook_window_seconds", 1.5)) * 100.0
		FishingState.REELING:
			status_label.text = "连续按 F 拉杆"
			detail_label.text = "进度满时钓鱼成功"
			progress_bar.value = reel_progress * 100.0
		FishingState.SUCCESS:
			status_label.text = "钓鱼成功 +%d金币" % int(data.fishing_value("reward_gold", 1))
			detail_label.text = ""
			progress_bar.value = 100.0
		FishingState.FAILED:
			status_label.text = "钓鱼失败"
			detail_label.text = ""
			progress_bar.value = 0.0


func _mark_input_handled() -> void:
	if is_inside_tree() and get_viewport() != null:
		get_viewport().set_input_as_handled()
```

- [ ] **Step 4: Run manager tests and verify they pass**

Run:

```powershell
godot --headless --path . --script res://tests/FishingRulesTest.gd
godot --headless --path . --script res://tests/FishingManagerTest.gd
```

Expected: both print `PASS`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/FishingManager.gd tests/FishingManagerTest.gd
git commit -m "feat: add fishing manager"
```

---

### Task 3: Main Scene Wiring And Input Guard

**Files:**
- Modify: `scenes/Main.tscn`
- Modify: `scripts/BuildManager.gd`
- Modify: `tests/FishingManagerTest.gd`

- [ ] **Step 1: Add failing scene wiring assertions**

Append this call inside `tests/FishingManagerTest.gd` after the existing manager tests:

```gdscript
_test_main_scene_wiring()
```

Add this test function:

```gdscript
func _test_main_scene_wiring() -> void:
	var packed_scene := load("res://scenes/Main.tscn")
	_assert_true(packed_scene != null, "Main scene should load")
	if packed_scene == null:
		return

	var scene: Node = packed_scene.instantiate()
	var fishing_manager := scene.get_node_or_null("FishingManager")
	_assert_true(fishing_manager != null, "Main scene has FishingManager node")
	if fishing_manager != null:
		_assert_equal(fishing_manager.get_script().resource_path, "res://scripts/FishingManager.gd", "FishingManager uses fishing script")

	scene.free()
```

- [ ] **Step 2: Run the scene wiring test and verify it fails**

Run:

```powershell
godot --headless --path . --script res://tests/FishingManagerTest.gd
```

Expected: FAIL because `Main.tscn` has no `FishingManager` node.

- [ ] **Step 3: Wire `FishingManager` into `scenes/Main.tscn`**

Add an ext resource after the terrain manager resource:

```ini
[ext_resource type="Script" path="res://scripts/FishingManager.gd" id="9_fishing_manager"]
```

Add the node near other manager nodes:

```ini
[node name="FishingManager" type="Node" parent="."]
script = ExtResource("9_fishing_manager")
```

- [ ] **Step 4: Add input guard to `BuildManager.gd`**

Add a variable beside `pause_panel`:

```gdscript
var fishing_manager: Node
```

In `_ready`, after `buildings_container = get_parent().get_node_or_null("Buildings")`, add:

```gdscript
fishing_manager = get_parent().get_node_or_null("FishingManager")
```

In `_unhandled_input`, after the paused check and before `_handle_info_panel_input`, add:

```gdscript
if fishing_manager != null and fishing_manager.has_method("is_fishing") and fishing_manager.is_fishing():
	return
```

Add this public method near the other public helpers such as `add_gold`:

```gdscript
func can_start_fishing() -> bool:
	if player_dead:
		return false
	if _is_tree_paused():
		return false
	if pause_panel != null:
		return false
	if test_panel != null:
		return false
	if info_panel != null:
		return false
	if demolition_target_index != -1:
		return false
	if player_tree_task_id != "":
		return false
	return true
```

- [ ] **Step 5: Add guard assertions to `FishingManagerTest.gd`**

Add this function and call it from `_init`:

```gdscript
func _test_build_manager_blocks_fishing_when_busy(fishing_manager_script: Script, build_manager_script: Script) -> void:
	var root := _create_root(fishing_manager_script, build_manager_script)
	var build_manager: Node2D = root.get_node("BuildManager")
	var fishing_manager: Node = root.get_node("FishingManager")

	_assert_true(build_manager.can_start_fishing(), "idle BuildManager allows fishing")
	_assert_true(fishing_manager.try_start_fishing(), "fishing starts when BuildManager allows it")
	fishing_manager.cancel_fishing()

	build_manager.player_dead = true
	_assert_false(build_manager.can_start_fishing(), "dead player cannot start fishing")
	build_manager.player_dead = false

	build_manager.demolition_target_index = 0
	_assert_false(build_manager.can_start_fishing(), "demolition confirmation blocks fishing")
	build_manager.demolition_target_index = -1

	build_manager.player_tree_task_id = "TreeTask_01"
	_assert_false(build_manager.can_start_fishing(), "active player tree chop blocks fishing")

	root.free()
```

Add `_assert_false` to the test file:

```gdscript
func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail("%s: expected false" % message)
```

- [ ] **Step 6: Run scene and manager tests**

Run:

```powershell
godot --headless --path . --script res://tests/FishingManagerTest.gd
godot --headless --path . res://scenes/Main.tscn --quit-after 2
```

Expected: `FishingManagerTest: PASS`; main scene loads for 2 seconds without errors.

- [ ] **Step 7: Commit**

```powershell
git add scenes/Main.tscn scripts/BuildManager.gd tests/FishingManagerTest.gd
git commit -m "feat: wire fishing into main world"
```

---

### Task 4: Documentation And Regression

**Files:**
- Modify: `GAME_REFERENCE.txt`

- [ ] **Step 1: Update `GAME_REFERENCE.txt`**

Add a new section near the latest 2026-06-20 entries:

```text
2026-06-20 新增：玩家手动钓鱼小游戏
- 新增按键 F：主世界任意位置按 F 开始钓鱼；咬钩后 1.5 秒内再次按 F 收杆；拉杆阶段连续按 F 推进进度。
- 新增 scripts/FishingRules.gd：集中处理咬钩概率、roll 判定、拉杆进度增加/衰减和成功失败结果。
- 新增 scripts/FishingManager.gd：挂载在 scenes/Main.tscn 的 FishingManager 节点，负责钓鱼状态机、FishingUI、输入和成功奖励。
- 钓鱼等待阶段每 1 秒判定一次：第 1 秒 5%、第 2 秒 10%、第 3 秒 15%、第 4 秒 20%，之后每秒增加 5%，最高 80%。
- 拉杆阶段初始进度 20%；每次按 F 增加 15%；进度每秒降低 18%；满 100% 成功，降到 0 失败。
- 钓鱼成功调用 BuildManager.add_gold(1)，因此金币 UI 和建筑栏灰色状态会自动刷新。
- 钓鱼期间 BuildManager 不处理普通建造、拆除、建筑面板、修复、资源点和流浪汉交互；按 Q 取消钓鱼。
- 钓鱼不写入存档；读档后始终处于未钓鱼状态。
- tests/FishingRulesTest.gd 覆盖钓鱼纯规则；tests/FishingManagerTest.gd 覆盖开始、咬钩、收杆、成功、失败、取消、主场景接线和 BuildManager 忙碌状态拦截；tests/GameDataSeparationTest.gd 覆盖钓鱼数值来自 GameData。
```

Also add `F` to the key list and mention the new `FishingUI` entity if the document has nearby input/UI sections.

- [ ] **Step 2: Run focused regression tests**

Run:

```powershell
$tests = @(
  'res://tests/FishingRulesTest.gd',
  'res://tests/FishingManagerTest.gd',
  'res://tests/GameDataSeparationTest.gd',
  'res://tests/EconomyTest.gd',
  'res://tests/BuildRulesTest.gd'
)
foreach ($test in $tests) {
  godot --headless --path . --script $test
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
godot --headless --path . res://scenes/Main.tscn --quit-after 2
```

Expected: all listed tests print `PASS`; main scene loads without errors.

- [ ] **Step 3: Check changed file status**

Run:

```powershell
git status --short -- scripts/FishingRules.gd scripts/FishingManager.gd scripts/GameData.gd scripts/BuildManager.gd scenes/Main.tscn tests/FishingRulesTest.gd tests/FishingManagerTest.gd tests/GameDataSeparationTest.gd GAME_REFERENCE.txt
```

Expected: only the fishing feature files and documentation are listed for this task.

- [ ] **Step 4: Commit**

```powershell
git add GAME_REFERENCE.txt
git commit -m "docs: document fishing minigame"
```

---

## Final Verification

- [ ] Run the complete focused command from Task 4 Step 2 once more after all commits.
- [ ] Confirm `FishingRulesTest`, `FishingManagerTest`, `GameDataSeparationTest`, `EconomyTest`, and `BuildRulesTest` pass.
- [ ] Confirm `scenes/Main.tscn` loads headlessly for 2 seconds.
- [ ] Report any broader dirty worktree entries as pre-existing if they are unrelated to this implementation.

## Self-Review

- Spec coverage: this plan implements player-only fishing, `F` start/reel input, rising bite chance, 1.5 second hook window, repeated `F` progress, progress decay, 1 gold reward, cancellation, data separation, UI, main-world-only wiring, and `GAME_REFERENCE.txt` updates.
- Scope check: no fish inventory, no fishing profession, no new buildings, no river/bridge location check, and no save data changes.
- Type consistency: `FishingManager` exposes `try_start_fishing`, `press_fishing_key`, `cancel_fishing`, `is_fishing`, and `state_name`; tests call those exact methods. `BuildManager` exposes `can_start_fishing`; `FishingManager` calls that exact method.
