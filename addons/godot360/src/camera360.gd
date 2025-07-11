@icon("res://addons/godot360/src/Camera360.svg")
class_name Camera360
extends Camera3D
## Special-purpose camera for omnidirectional rendering
##
## This camera can render 360-degree views and project them onto a fullscreen quad mesh
## using a number of projections, ranging from fisheye to cylindrical projections, and
## also includes the popular Panini projection.[br]
## At this time, only one camera setup is supported, with (up to) 6 cameras forming a cube.
## Ideally, forward-focused setups should be added, to allow e.g. 3 cameras on rectangular
## viewports to cover a 180-degree FoV.

enum Lens {
	RECTILINEAR,
	PANINI,
	FISHEYE,
	STEREOGRAPHIC,
	CYLINDRICAL,
	EQUIRECTANGULAR,
	MERCATOR,
	FULLDOME,
}

## The horizontal FoV of the camera, in degrees.[br]
## [b]Warning:[/b] This value is not accurate for most lenses.
@export_range(10, 360) var fovx := 150.0:
	set(value):
		fovx = value
		if fovx < 10:
			fovx = 10
		if fovx > 360:
			fovx = 360
		mat.set_shader_parameter("fovx", fovx)
## The current lens, which governs how each of the cameras are assembled and deformed
## to produce the final image.
@export var lens := Lens.RECTILINEAR: set = set_lens
## Near clip plane distance for subcameras.
@export_range(0.001, 10) var clip_near := 0.1
## Far clip plane distance for subcameras.
@export_range(0.01, 10000) var clip_far := 1000.0
## The number of subcameras to use for rendering.
@export_range(1, 6) var num_cameras := 6
## The FoV of all subcameras, in degrees. Values above 90 are more expensive to render,
## but can alleviate rendering artifacts near subviewport seams caused by screenspace effects.
@export_range(90, 120) var camera_fov := 100
## The render layer used for rendering of the final image.
@export_range(1, 20) var render_layer := 11
## The [Environment] to use for the subcameras.
@export var camera_environment: Environment = null
## The [SubViewport] to use for all subcameras. Use this to set viewport settings such as
## antialiasing and other quality settings.
@export var subviewport: SubViewport = null

var viewports : Array[SubViewport] = []
var cameras : Array[Camera3D] = []

## The fullscreen quad mesh where the final image is drawn.
var render_quad: MeshInstance3D = null
## The material used to produce the final image.
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

	mat.shader = preload("res://addons/godot360/src/camera360.gdshader")
	mat.set_shader_parameter("fovx", fovx)
	mat.set_shader_parameter("lens", lens)
	@warning_ignore("unsafe_property_access")
	mat.set_shader_parameter("resolution", get_viewport().size)
	mat.set_shader_parameter("subcamera_fov", camera_fov)

	for i in num_cameras:
		var viewport := subviewport.duplicate() as SubViewport
		add_child(viewport)
		viewports.append(viewport)
		mat.set_shader_parameter("Texture%d" % [i], viewport.get_texture())

		var camera := Camera3D.new()
		viewport.add_child(camera)
		camera.fov = camera_fov
		camera.near = clip_near
		camera.far = clip_far
		camera.cull_mask -= render_layer
		camera.environment = camera_environment
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


@warning_ignore("unused_parameter")
func _set_viewport_settings(viewport: SubViewport) -> void:
	pass


func set_lens(l: Lens) -> void:
	lens = l
	if lens > Lens.size() - 1 or lens < 0:
		lens = Lens.RECTILINEAR
	mat.set_shader_parameter("lens", lens)
