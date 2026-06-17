# Godot 2D Platformer Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal Godot 4.6 side-scroller project with one ground platform and one character that moves left and right.

**Architecture:** `project.godot` loads `scenes/Main.tscn`. The scene owns static level geometry and the player instance. `scripts/Player.gd` owns all player movement behavior.

**Tech Stack:** Godot 4.6, GDScript, built-in 2D physics nodes.

---

### Task 1: Project Files

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `README.md`

- [x] **Step 1: Create the Godot project configuration**

```ini
config_version=5

[application]

config/name="New Project"
run/main_scene="res://scenes/Main.tscn"
```

- [x] **Step 2: Ignore generated Godot files**

```gitignore
.godot/
.import/
export.cfg
export_presets.cfg
*.tmp
*.translation
```

- [x] **Step 3: Document how to run and control the prototype**

```markdown
# New Project

A minimal Godot 4.6 2D side-scroller prototype.
```

### Task 2: Main Scene

**Files:**
- Create: `scenes/Main.tscn`

- [x] **Step 1: Create a root `Node2D` scene**

```text
[node name="Main" type="Node2D"]
```

- [x] **Step 2: Add a static ground**

```text
[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(480, 496)
```

- [x] **Step 3: Add a character body player**

```text
[node name="Player" type="CharacterBody2D" parent="."]
position = Vector2(160, 472)
script = ExtResource("1_player")
```

### Task 3: Player Movement

**Files:**
- Create: `scripts/Player.gd`

- [x] **Step 1: Read left and right keyboard input**

```gdscript
if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
	direction -= 1.0
if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
	direction += 1.0
```

- [x] **Step 2: Apply horizontal speed and gravity**

```gdscript
velocity.x = direction * SPEED

if is_on_floor():
	velocity.y = 0.0
else:
	velocity.y += GRAVITY * delta
```

- [x] **Step 3: Move the character with Godot physics**

```gdscript
move_and_slide()
```

### Task 4: Verification

**Files:**
- Verify: `project.godot`
- Verify: `scenes/Main.tscn`
- Verify: `scripts/Player.gd`

- [ ] **Step 1: Run Godot in headless mode to validate project loading**

Run: `godot --headless --path . --quit`

Expected: Godot exits successfully after loading the project.
