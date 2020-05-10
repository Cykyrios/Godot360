extends Camera
class_name Camera360


export (float, 10, 360) var fovx = 150 setget set_fovx
export (int, "Rectilinear", "Panini", "Fisheye", "Stereographic", "Cylindrical",
		"Equirectangular", "Mercator") var camera_projection = 0 setget set_camera_projection
export (bool) var show_grid = false setget set_show_grid
export (int, 1, 16384) var camera_resolution = 1080
export (float, 0.001, 10) var clip_near = 0.1
export (float, 0.01, 10000) var clip_far = 1000
export (int, 3, 6) var num_cameras = 6
export (Environment) var camera_environment

var viewports = []
var cameras = []

var render_quad: MeshInstance = null
var mat = load("res://Camera360/Camera360.tres")

var grid = load("res://Camera360/Grid.png")


func _ready():
	render_quad = MeshInstance.new()
	add_child(render_quad)
	render_quad.translate_object_local(Vector3.FORWARD * (near + 0.1 * (far - near)))
	render_quad.rotate_object_local(Vector3.RIGHT, PI / 2)
	render_quad.mesh = QuadMesh.new()
	render_quad.mesh.size = Vector2(2, 2)
	render_quad.layers = 1024
	render_quad.mesh.surface_set_material(0, mat)
	
	mat.set_shader_param("fovx", fovx)
	mat.set_shader_param("projection", camera_projection)
	mat.set_shader_param("resolution", get_viewport().size)
	mat.set_shader_param("Grid", grid)
	mat.set_shader_param("show_grid", show_grid)
	
	for i in range(num_cameras):
		var viewport = Viewport.new()
		add_child(viewport)
		viewport.size = camera_resolution * Vector2.ONE
		viewport.shadow_atlas_size = 4096
		viewport.msaa = Viewport.MSAA_4X
		viewports.append(viewport)
		mat.set_shader_param("Texture%d" % [i], viewport.get_texture())
		
		var camera = Camera.new()
		viewport.add_child(camera)
		camera.fov = 90
		camera.near = clip_near
		camera.far = clip_far
		camera.cull_mask -= 1024
		cameras.append(camera)
	
	if num_cameras < 6:
		for i in range(num_cameras + 1, 6):
			mat.set_shader_param("Texture%d" % [i], Texture.new())
	
	update_projection_label()


func _process(delta):
	for camera in cameras:
		camera.global_transform = global_transform
	cameras[1].rotate_object_local(Vector3.UP, PI/2)
	if num_cameras >= 3:
		cameras[2].rotate_object_local(Vector3.UP, -PI/2)
	if num_cameras >= 4:
		cameras[3].rotate_object_local(Vector3.RIGHT, -PI/2)
	if num_cameras >= 5:
		cameras[4].rotate_object_local(Vector3.RIGHT, PI/2)
	if num_cameras >= 6:
		cameras[5].rotate_object_local(Vector3.UP, PI)


func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_G and event.pressed:
			self.show_grid = !show_grid
		elif event.scancode == KEY_P and event.pressed:
			self.camera_projection = camera_projection + 1
		elif event.scancode == KEY_KP_ADD and event.pressed:
			self.fovx = fovx + 5
		elif event.scancode == KEY_KP_SUBTRACT and event.pressed:
			self.fovx = fovx - 5


func set_fovx(x: float):
	fovx = x
	if fovx < 10:
		fovx = 10
	if fovx > 360:
		fovx = 360
	mat.set_shader_param("fovx", fovx)
	call_deferred("update_projection_label")


func set_show_grid(show: bool):
	show_grid = show
	mat.set_shader_param("show_grid", show_grid)


func set_camera_projection(proj: int):
	camera_projection = proj
	if camera_projection > 6:
		camera_projection = 0
	mat.set_shader_param("projection", camera_projection)
	call_deferred("update_projection_label")


func update_projection_label():
	var proj: String
	match camera_projection:
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
	$ProjectionLabel.text = "Projection: %s\nFoV: %d°" % [proj, fovx]
