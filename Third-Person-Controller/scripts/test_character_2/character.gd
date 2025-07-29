extends CharacterBody3D

## central functionality of Character

const LERP_VALUE : float = 0.15

var variables: CharacterVariables = CharacterVariables.new()
var auto_rotate: bool = true
var mesh_faces_camera_direction: bool = false

@onready var _mesh: Node3D = $Mesh
@onready var _spring_arm_pivot: Node3D = $SpringArmPivot
@onready var _animation_handler: Node = $AnimationHandler
@onready var _collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var _movement_class: MovementClass = $MovementClass

## can have a state change class, like a factory that provides the classes associated with a state
## a "state" is th emovement state: "GROUNDED", "FLYING", or "SWIMMING"
## a state change would change the movement_class, animation_handler, anim tree, character variables, and action container (along with its actions
##  and maybe the controller
## this would allow states to change available actions and how the character moves
##
## this script should stay the same. only the scripts on some nodes should change to swap states

func _ready() -> void:
	if auto_rotate: 
		if mesh_faces_camera_direction:
			var cam_forward : Vector3 = _spring_arm_pivot.get_cam_forward()
			face_point(cam_forward)
		else:
			face_point(_mesh.basis.z)

func _process(_delta: float) -> void:
	# face camera rotation
	if auto_rotate and !_movement_class.root_motion_override: 
		if mesh_faces_camera_direction:
			var cam_forward : Vector3 = _spring_arm_pivot.get_cam_forward()
			face_point(cam_forward, LERP_VALUE)
		else:
			if velocity.length_squared() != 0.0:
				face_point(velocity, LERP_VALUE)
	
	_animation_handler.animate()


func set_collider_height_small() -> void:
	# values set in inspector then coppied here manually
	_collision_shape_3d.shape.height = 1.0
	_collision_shape_3d.position.y = 0.5

func set_collider_height_normal() -> void:
	# values set in inspector then coppied here manually
	_collision_shape_3d.shape.height = 1.843
	_collision_shape_3d.position.y = 0.909

# runs in local space
# only uses x and z of point
func face_point(point: Vector3, lerp_value : float = 0.0) -> void:
	if point.is_equal_approx(Vector3.ZERO):
		return
	
	if !is_equal_approx(lerp_value, 0.0):
		if point != _mesh.position:
			_mesh.rotation.y = lerp_angle(_mesh.rotation.y, atan2(point.x, point.z), lerp_value)
		if point != _collision_shape_3d.position:
			_collision_shape_3d.rotation.y = lerp_angle(_collision_shape_3d.rotation.y, atan2(point.x, point.z), lerp_value)
	else:
		if point != _mesh.position:
			_mesh.transform = _mesh.transform.looking_at(Vector3(point.x, _mesh.position.y, point.z), Vector3.UP, true)
		if point != _collision_shape_3d.position:
			_collision_shape_3d.transform = _collision_shape_3d.transform.looking_at(Vector3(point.x, _collision_shape_3d.position.y, point.z), Vector3.UP, true)
