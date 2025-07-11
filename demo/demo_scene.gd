extends Node3D


@onready var camera := %Camera360 as Camera360
@onready var projection_label := %ProjectionLabel as Label

var speed := 0.0

@export var show_grid := false:
	set(value):
		show_grid = value
		if not is_inside_tree():
			await ready
		var camera_material := camera.render_quad.mesh.surface_get_material(0) as ShaderMaterial
		camera_material.set_shader_parameter("show_grid", show_grid)
var grid := preload("res://demo/assets/grid.png")


func _ready() -> void:
	update_projection_label()

	var mat := camera.render_quad.mesh.surface_get_material(0) as ShaderMaterial
	mat.set_shader_parameter("Grid", grid)
	mat.set_shader_parameter("show_grid", show_grid)


func _input(event: InputEvent) -> void:
	var is_projection_label_outdated := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_G and key_event.pressed:
			self.show_grid = not show_grid
		elif key_event.keycode == KEY_L and key_event.pressed:
			if key_event.shift_pressed:
				activate_previous_lens()
			else:
				activate_next_lens()
		elif key_event.keycode == KEY_KP_ADD and key_event.pressed:
			camera.fovx += 5
		elif key_event.keycode == KEY_KP_SUBTRACT and key_event.pressed:
			camera.fovx -= 5
		is_projection_label_outdated = true

	elif event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT and button_event.pressed:
			speed += 0.25
		elif button_event.button_index == MOUSE_BUTTON_RIGHT and button_event.pressed:
			speed -= 0.25
		speed = clampf(speed, -1.0, 1.0)

		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.fovx -= 5
		elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.fovx += 5
		is_projection_label_outdated = true

	if is_projection_label_outdated:
		call_deferred("update_projection_label")


func _process(delta: float) -> void:
	camera.rotate(Vector3.UP, speed * delta)


func activate_next_lens() -> void:
	var idx := Camera360.Lens.values().find(camera.lens) + 1
	if idx >= Camera360.Lens.values().size():
		idx = 0
	camera.set_lens(Camera360.Lens.values()[idx] as Camera360.Lens)


func activate_previous_lens() -> void:
	var idx := Camera360.Lens.values().find(camera.lens) - 1
	if idx < 0:
		idx = Camera360.Lens.values().size() - 1
	camera.set_lens(Camera360.Lens.values()[idx] as Camera360.Lens)


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
