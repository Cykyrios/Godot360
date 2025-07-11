extends Node3D


@onready var camera := %Camera360 as Camera360
@onready var projection_label := %ProjectionLabel as Label

var speed := 0.0

@export var show_grid := false:
	set(value):
		show_grid = value
		if not is_inside_tree():
			await ready
		camera.render_quad.mesh.surface_get_material(0).set_shader_parameter("show_grid", show_grid)
var grid := preload("res://demo/assets/grid.png")


func _ready() -> void:
	update_projection_label()

	var mat := camera.render_quad.mesh.surface_get_material(0) as ShaderMaterial
	mat.set_shader_parameter("Grid", grid)
	mat.set_shader_parameter("show_grid", show_grid)


func _input(event: InputEvent) -> void:
	var is_projection_label_outdated := false
	if event is InputEventKey:
		if event.keycode == KEY_G and event.pressed:
			self.show_grid = not show_grid
		elif event.keycode == KEY_L and event.pressed:
			camera.activate_next_lens()
		elif event.keycode == KEY_KP_ADD and event.pressed:
			camera.fovx += 5
		elif event.keycode == KEY_KP_SUBTRACT and event.pressed:
			camera.fovx -= 5
		is_projection_label_outdated = true

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			speed += 0.25
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			speed -= 0.25
		speed = clampf(speed, -1.0, 1.0)

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.fovx -= 5
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.fovx += 5
		is_projection_label_outdated = true

	if is_projection_label_outdated:
		call_deferred("update_projection_label")


func _process(delta: float) -> void:
	camera.rotate(Vector3.UP, speed * delta)


func update_projection_label() -> void:
	var proj := ""
	match camera.lens:
		Camera360.Lens.RECTILINEAR:
			proj = "Rectilinear"
		Camera360.Lens.PANINI:
			proj = "Panini"
		Camera360.Lens.FISHEYE:
			proj = "Fisheye"
		Camera360.Lens.STEREOGRAPHIC:
			proj = "Stereographic"
		Camera360.Lens.CYLINDRICAL:
			proj = "Cylindrical"
		Camera360.Lens.EQUIRECTANGULAR:
			proj = "Equirectangular"
		Camera360.Lens.MERCATOR:
			proj = "Mercator"
		Camera360.Lens.FULLDOME:
			proj = "Fulldome"
	projection_label.text = "Lens: %s\nFoV: %d°" % [proj, camera.fovx]
