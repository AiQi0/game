extends CharacterBody2D

const SPEED := 260.0
const GRAVITY := 1200.0

var facing_direction := 1


func _physics_process(delta: float) -> void:
	var direction := 0.0

	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction += 1.0

	if direction < 0.0:
		facing_direction = -1
	elif direction > 0.0:
		facing_direction = 1

	velocity.x = direction * SPEED

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * delta

	move_and_slide()


func get_facing_direction() -> int:
	return facing_direction
