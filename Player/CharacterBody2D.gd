class_name Player
extends CharacterBody2D
## Platformer player controller.
##
## Uses the project's input actions (move_left, move_right, jump) and keeps the
## animation state in one place so Jump/Fall/Run/Idle never fight each other.

@export_group("Movement")
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 2400.0
@export var friction: float = 3200.0

@export_group("Jump forgiveness")
@export_range(0.0, 0.5, 0.01) var coyote_time: float = 0.1
@export_range(0.0, 0.5, 0.01) var jump_buffer_time: float = 0.1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if not is_on_floor():
		velocity.y += _gravity * delta

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		_consume_jump()

	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation()


func _tick_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(_coyote_left - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)


func _consume_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_left = 0.0
	_coyote_left = 0.0


func _update_animation() -> void:
	var next_animation: StringName
	if not is_on_floor():
		next_animation = &"Jump" if velocity.y < 0.0 else &"Fall"
	elif absf(velocity.x) > 1.0:
		next_animation = &"Run"
	else:
		next_animation = &"Idle"

	if sprite.animation != next_animation:
		sprite.play(next_animation)
