class_name SkeletonEnemy
extends CharacterBody2D
## Skeleton enemy: waits until the player enters its detector, then walks
## toward the player. The player is found through the "player" group instead
## of a hard-coded scene path, so this scene can be reused anywhere.

@export var speed: float = 90.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
var _target: Node2D = null
var _chasing: bool = false


func _ready() -> void:
	add_to_group("enemies")
	_target = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

	var direction := 0.0
	if _chasing and is_instance_valid(_target):
		direction = signf(_target.global_position.x - global_position.x)

	if is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		_play_animation(&"Idle")
	else:
		velocity.x = direction * speed
		sprite.flip_h = direction < 0.0
		_play_animation(&"Walk")

	move_and_slide()


func _play_animation(animation: StringName) -> void:
	if sprite.animation != animation:
		sprite.play(animation)


func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_chasing = true


func _on_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_chasing = false
