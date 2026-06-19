# Godot 2D Platformer Prototype Design

## Goal

Create a minimal Godot 4.6 side-scroller project with one ground platform and one controllable character.

## Scope

The prototype includes a single playable scene. The character can move left and right with arrow keys or A/D. Gravity keeps the character on the ground. Jumping, enemies, animation, camera bounds, menus, and art assets are outside this first scaffold.

## Architecture

The project uses `project.godot` to point to `res://scenes/Main.tscn` as the main scene. The scene contains a `StaticBody2D` ground and a `CharacterBody2D` player. Player movement is isolated in `scripts/Player.gd` so the scene remains simple and the movement behavior is easy to replace later.

## Validation

The project should open in Godot 4.6. Running the main scene should show a colored ground rectangle and a colored player rectangle. Pressing Left/A moves the player left, and pressing Right/D moves the player right.
