extends Camera
class_name Camera360


enum Lens {RECTILINEAR, PANINI, FISHEYE, STEREOGRAPHIC, CYLINDRICAL,
		EQUIRECTANGULAR, MERCATOR}
enum Globe {CUBE_FACE, CUBE_EDGE, CUBE_CORNER}


export (float, 10, 360) var fovx = 150 setget set_fovx
export (Lens) var lens = 0 setget set_lens
export (Globe) var globe = 0 setget set_globe
export (int, 1, 16384) var camera_resolution = 1080
export (float, 0.001, 10) var clip_near = 0.1
export (float, 0.01, 10000) var clip_far = 1000
export (int, 3, 6) var num_cameras = 6
export (Environment) var camera_environment

var viewports = []
var cameras = []

var render_quad: MeshInstance = null
var mat = load("res://src/Camera360/Camera360.tres")


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
	mat.set_shader_param("lens", lens)
	mat.set_shader_param("globe", globe)
	mat.set_shader_param("resolution", get_viewport().size)
	
	for i in range(num_cameras):
		var viewport = Viewport.new()
		add_child(viewport)
		viewport.size = camera_resolution * Vector2.ONE
		viewport.keep_3d_linear = true
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
	
	if globe == Globe.CUBE_EDGE:
		for camera in cameras:
			camera.rotate(global_transform.basis.y, PI / 4)
	elif globe == Globe.CUBE_CORNER:
		for camera in cameras:
			camera.rotate(global_transform.basis.y, PI / 4)
			camera.rotate(global_transform.basis.x, -atan(sqrt(2)/2))


func set_fovx(x: float):
	fovx = x
	if fovx < 10:
		fovx = 10
	if fovx > 360:
		fovx = 360
	mat.set_shader_param("fovx", fovx)


func set_lens(l: int):
	lens = l
	if lens > Lens.size() - 1:
		lens = 0
	mat.set_shader_param("lens", lens)


func set_globe(g: int):
	globe = g
	if globe > Globe.size() - 1:
		globe = 0
	mat.set_shader_param("globe", globe)
