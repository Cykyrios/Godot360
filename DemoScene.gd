extends Spatial


onready var camera = $Camera360

var speed = 0.0


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			speed += 0.25
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			speed -= 0.25
		speed = clamp(speed, -1.0, 1.0)
		
		if event.button_index == BUTTON_WHEEL_UP:
			camera.fovx -= 5
		elif event.button_index == BUTTON_WHEEL_DOWN:
			camera.fovx += 5


func _process(delta):
	camera.rotate(Vector3.UP, speed * delta)
