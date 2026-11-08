extends ParallaxBackground
## Reusable parallax backdrop.
##
## In the level an active Camera2D drives ParallaxBackground automatically, so
## this script does nothing there. In the menu there is no camera, so the
## background drifts slowly to keep the screen alive.

@export var scroll_speed: float = 100.0


func _process(delta: float) -> void:
	if get_viewport().get_camera_2d() == null:
		scroll_offset.x -= scroll_speed * delta
