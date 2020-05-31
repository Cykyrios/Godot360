extends Spatial


onready var camera = $Camera360

var speed = 0.0

export (bool) var show_grid = false setget set_show_grid
var grid = load("res://assets/Grid.png")


func _ready():
	update_projection_label()
	
	var mat = camera.render_quad.mesh.surface_get_material(0)
	mat.set_shader_param("Grid", grid)
	mat.set_shader_param("show_grid", show_grid)


func _input(event):
	var is_projection_label_outdated := false
	if event is InputEventKey:
		if event.scancode == KEY_C and event.pressed:
			self.show_grid = !show_grid
		elif event.scancode == KEY_L and event.pressed:
			camera.lens += 1
		elif event.scancode == KEY_G and event.pressed:
			camera.globe += 1
		elif event.scancode == KEY_KP_ADD and event.pressed:
			camera.fovx += 5
		elif event.scancode == KEY_KP_SUBTRACT and event.pressed:
			camera.fovx -= 5
		is_projection_label_outdated = true
	
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			speed += 0.25
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			speed -= 0.25
		speed = clamp(speed, -1.0, 1.0)
		
		if event.button_index == BUTTON_WHEEL_UP:
			camera.fovx -= 5
		elif event.button_index == BUTTON_WHEEL_DOWN:
			camera.fovx += 5
		is_projection_label_outdated = true
	
	if is_projection_label_outdated:
		call_deferred("update_projection_label")


func _process(delta):
	camera.rotate(Vector3.UP, speed * delta)


func set_show_grid(show: bool):
	show_grid = show
	if not is_inside_tree():
		yield(self, "ready")
	camera.render_quad.mesh.surface_get_material(0).set_shader_param("show_grid", show_grid)


func update_projection_label():
	var proj: String
	match camera.lens:
		0:
			proj = "Rectilinear"
		1:
			proj = "Panini"
		2:
			proj = "Fisheye"
		3:
			proj = "Stereographic"
		4:
			proj = "Cylindrical"
		5:
			proj = "Equirectangular"
		6:
			proj = "Mercator"
	$ProjectionLabel.text = "Lens: %s\nFoV: %d°" % [proj, camera.fovx]
