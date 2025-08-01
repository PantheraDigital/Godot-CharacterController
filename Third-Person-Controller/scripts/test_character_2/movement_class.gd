extends Node
class_name MovementClass

## implementation of Character movement and movement state

signal step(step_data: Dictionary)
signal climb_ledge(step_data: Dictionary)

const ID: StringName = "GROUNDED"
const CLIMBABLE_LEDGE: float = 2.3

enum EnabledMovement{
	MOVE = 1 << 0, # int 1
	IMPULSE = 1 << 1, # int 2
	STEP = 1 << 2, # int 4
	ROOT_MOTION = 1 << 3, # int 8
	
	ALL = MOVE | IMPULSE | STEP | ROOT_MOTION
}
var _enabled_movement: int = EnabledMovement.ALL

@export var max_step_up: float = 1.0
@export var max_step_down: float = 1.0
@export var disable_gravity: bool = false
@export var disable_floor_snap: bool = false # reset to false at end of phys process

var was_on_floor: bool
var root_motion_override: bool = false

var _input_vector: Vector3
var _impulse_vector: Vector3

@onready var _character: CharacterBody3D = $".."
@onready var _collision_shape_3d: CollisionShape3D = $"../CollisionShape3D"
@onready var _animation_tree: AnimationTree = $"../AnimationTree"


func move(direction: Vector3, speed: float) -> void:
	if !direction.is_normalized():
		direction = direction.normalized()
	_input_vector = direction * speed

func add_impulse(direction: Vector3, power: float) -> void:
	if !direction.is_normalized():
		direction = direction.normalized()
	_impulse_vector = direction * power

func _physics_process(delta: float) -> void:
	was_on_floor = _character.is_on_floor() # save state before moving the character
	
	root_motion_override = false
	if (_enabled_movement & EnabledMovement.ROOT_MOTION) and _animation_tree.get_root_motion_position() != Vector3.ZERO:
		var vel: Vector3 = (_animation_tree.get_root_motion_position() / delta).rotated(Vector3.UP, _animation_tree.get_root_motion_rotation().y + _collision_shape_3d.rotation.y)
		if !disable_gravity:
			_character.velocity = Vector3(vel.x, _character.velocity.y, vel.z)
		else:
			_character.velocity = vel
		
		if _character.velocity.y > 0:
			disable_floor_snap = true
		root_motion_override = true
	elif (_enabled_movement & EnabledMovement.MOVE):
		_character.velocity = Vector3(_input_vector.x, _character.velocity.y, _input_vector.z)
	
	if (_enabled_movement & EnabledMovement.IMPULSE) and _impulse_vector != Vector3.ZERO:
		_character.velocity += _impulse_vector
		_impulse_vector = Vector3.ZERO
		disable_floor_snap = true
	
	if !_character.is_on_floor() and !disable_gravity:
		_character.velocity += (_character.get_gravity() * _character.variables.mass) * delta
	
	
	# ledge step up correction
	var stepped_up: bool = false # reduces step down calls
	if (_enabled_movement & EnabledMovement.STEP) and (!_input_vector.is_zero_approx() or root_motion_override):
		var found_ledge: bool = false
		# set up variables for ledge detection
		var start: Vector3 = _character.global_position
		var start_offset: Vector3 = Vector3.ZERO
		var direction: Vector3 = Vector3(_character.velocity.x, 0.0, _character.velocity.z).normalized()
		var half_width: float = _collision_shape_3d.shape.radius * 0.5
		var full_width: float = _collision_shape_3d.shape.radius + 0.1
		var hit_result: Dictionary
		
		for i in range(3):
			if i == 1: # offset left
				start_offset = ((direction.rotated(Vector3.UP, deg_to_rad(90))).normalized() * half_width)
			elif i == 2: # offset right
				start_offset = ((direction.rotated(Vector3.UP, deg_to_rad(-90))).normalized() * half_width)
				
			hit_result = CharacterStep3D.snapped_intersect_ray(_character.get_world_3d().direct_space_state, start + start_offset, direction, full_width, false, [_character])
			if hit_result.has("normal"):
				found_ledge = hit_result.normal.angle_to(Vector3.UP) > _character.floor_max_angle
			
			if found_ledge:
				break
		
		if !found_ledge and _character.get_floor_normal().angle_to(Vector3.UP) <= _character.floor_max_angle:
			found_ledge = true
		
		if found_ledge:
			var step_data: Dictionary = CharacterStep3D.step_up(_character.get_rid(), _character.global_transform, CLIMBABLE_LEDGE, Vector3(_character.velocity.x, 0.0, _character.velocity.z).normalized(), _collision_shape_3d.shape.radius * 0.5, 0.25)
			if !step_data.is_empty() and step_data["normal"].angle_to(Vector3.UP) <= _character.floor_max_angle:
				var step_height: float = step_data["point"].y - _character.global_position.y
				var result_data: \
					Dictionary = {"step_point":step_data["point"], "step_normal":step_data["normal"], "ray_cast_point":hit_result["position"], "ray_cast_normal":hit_result["normal"]} \
					if hit_result.has("normal") else {"step_point":step_data["point"], "step_normal":step_data["normal"]}
				# float is an arbitrary number I chose to allow a small range in height for this climb anim
				if (CLIMBABLE_LEDGE - 0.04) <= step_height and step_height <= CLIMBABLE_LEDGE:
					stepped_up = true
					climb_ledge.emit(result_data)
				if step_height <= max_step_up:
					_character.global_position.y = step_data["point"].y
					stepped_up = true
					step.emit(result_data)
	
	_character.move_and_slide()
	
	# ledge step down correction
	if (_enabled_movement & EnabledMovement.STEP) and !stepped_up and !_character.is_on_floor() and _character.velocity.y <= 0 and was_on_floor:
		var ground_validation: Callable = func(_point: Vector3, _normal: Vector3) -> bool : return _normal.angle_to(Vector3.UP) <= _character.floor_max_angle
		var step_data: Dictionary = CharacterStep3D.step_down(_character.get_rid(), _character.global_transform, max_step_down, Vector3(_character.velocity.x, 0.0, _character.velocity.z).normalized(), _collision_shape_3d.shape.radius, ground_validation)
		if !step_data.is_empty():
			_character.global_position = step_data["point"]
	
	if !disable_floor_snap:
		_character.apply_floor_snap()
	else:
		disable_floor_snap = false

#region Movement Modification
# https://mplnet.gsfc.nasa.gov/about-flags
func disable_all_movement() -> void:
	disable_movement(EnabledMovement.ALL)

func enable_all_movement() -> void:
	enabled_movement(EnabledMovement.ALL)

# example inputs:
# enabled_movement(EnabledMovement.MOVE) # enable move
# enabled_movement(EnabledMovement.MOVE | EnabledMovement.IMPULSE) # enable move and impulse
func enabled_movement(actions: int) -> void:
	_enabled_movement |= actions

# example inputs:
# disable_movement(EnabledMovement.MOVE) # disable only move
# disable_movement(EnabledMovement.MOVE | EnabledMovement.IMPULSE) # disable move and impulse
func disable_movement(actions: int) -> void:
	_enabled_movement &= ~actions
#endregion
