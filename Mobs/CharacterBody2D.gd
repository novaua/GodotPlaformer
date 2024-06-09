extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var chase = false
var speed = 100

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var player = $"../../Node2D/Player"
	var direction = (player.position - self.position).normalized()
	if chase == true:
		velocity.x = direction.x * speed
	else: 
		velocity.x = 0
		
	move_and_slide()

func _on_detector_body_entered(body):
	if body.name == "Player":
		chase = true
		


func _on_detector_body_exited(body):
	if body.name == "Player":
		chase = false
