class_name Camera360
extends Camera3D


enum Lens {RECTILINEAR, PANINI, FISHEYE, STEREOGRAPHIC, CYLINDRICAL, EQUIRECTANGULAR, MERCATOR, FULLDOME}

@export_range(10, 360) var fovx := 150.0: set = set_fovx
@export var lens := Lens.RECTILINEAR: set = set_lens
@export_range(1, 16384) var camera_resolution := 1080
@export_range(0.001, 10) var clip_near := 0.1
@export_range(0.01, 10000) var clip_far := 1000.0
@export_range(1, 6) var num_cameras := 6
@export_range(90, 120) var camera_fov := 100
@export_range(1, 20) var render_layer := 11
@export var camera_environment: Environment = null

var viewports : Array[SubViewport] = []
var cameras : Array[Camera3D] = []

var render_quad: MeshInstance3D = null
var mat := ShaderMaterial.new()


func _ready() -> void:
	render_layer = int(pow(2, render_layer - 1))
	cull_mask = render_layer

	render_quad = MeshInstance3D.new()
	add_child(render_quad)
	render_quad.translate_object_local(Vector3.FORWARD * (near + 0.1 * (far - near)))
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(2, 2)
	render_quad.mesh = quad_mesh
	render_quad.layers = render_layer
	render_quad.mesh.surface_set_material(0, mat)

	mat.shader = preload("res://src/camera360/camera360.gdshader")
	mat.set_shader_parameter("fovx", fovx)
	mat.set_shader_parameter("lens", lens)
	mat.set_shader_parameter("resolution", get_viewport().size)
	mat.set_shader_parameter("subcamera_fov", camera_fov)

	for i in num_cameras:
		var viewport := SubViewport.new()
		add_child(viewport)
		viewport.size = camera_resolution * Vector2.ONE
		viewport.positional_shadow_atlas_size = 4096
		viewport.msaa_3d = SubViewport.MSAA_4X
		viewports.append(viewport)
		mat.set_shader_parameter("Texture%d" % [i], viewport.get_texture())

		var camera := Camera3D.new()
		viewport.add_child(camera)
		camera.fov = camera_fov
		camera.near = clip_near
		camera.far = clip_far
		camera.cull_mask -= render_layer
		cameras.append(camera)

	if num_cameras < 6:
		for i in range(num_cameras + 1, 6):
			mat.set_shader_parameter("Texture%d" % [i], Texture2D.new())


func _process(_delta: float) -> void:
	for camera in cameras:
		camera.global_transform = global_transform
	if num_cameras >= 2:
		cameras[1].rotate_object_local(Vector3.UP, PI/2)
	if num_cameras >= 3:
		cameras[2].rotate_object_local(Vector3.UP, -PI/2)
	if num_cameras >= 4:
		cameras[3].rotate_object_local(Vector3.RIGHT, -PI/2)
	if num_cameras >= 5:
		cameras[4].rotate_object_local(Vector3.RIGHT, PI/2)
	if num_cameras >= 6:
		cameras[5].rotate_object_local(Vector3.UP, PI)


func set_fovx(x: float) -> void:
	fovx = x
	if fovx < 10:
		fovx = 10
	if fovx > 360:
		fovx = 360
	mat.set_shader_parameter("fovx", fovx)


func set_lens(l: Lens) -> void:
	lens = l
	if lens > Lens.size() - 1:
		lens = Lens.RECTILINEAR
	mat.set_shader_parameter("lens", lens)


func activate_next_lens() -> void:
	var next_lens := Lens.values().find(lens) + 1
	if next_lens >= Lens.values().size():
		next_lens = 0
	set_lens(Lens.values()[next_lens])
