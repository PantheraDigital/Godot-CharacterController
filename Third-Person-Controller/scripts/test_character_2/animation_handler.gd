extends Node

# prevents fall anim by tracking when the character is in the air during a step up
var has_stepped: bool = false

@onready var _character: CharacterBody3D = get_parent()
@onready var _animation_tree: AnimationTree = $"../AnimationTree"
@onready var _movement_state: MovementClass = $"../MovementClass"
@onready var _action_container: ActionContainer = $"../ActionContainer"


func _ready() -> void:
	var action_container: ActionContainer = $"../ActionContainer"
	for child in action_container.get_children():
		if child is CharacterAction:
			child.enter.connect(_on_action_enter)
	
	_movement_state.step.connect(_on_character_step)


func animate() -> void:
	if _movement_state.ID == "GROUNDED":
		if _character.is_on_floor():
			has_stepped = false
			_animation_tree.set("parameters/transition_ground_to_fall/transition_request", "grounded")
			
			var blend_pos: float =  0.0
			if _character.velocity.length_squared() > 0:
				blend_pos = 1.0 if _character.variables.speed == _character.variables.run_speed else 0.5
			_animation_tree.set("parameters/BlendSpace1D/blend_position", blend_pos)
			return
			
		if _movement_state.was_on_floor == false and !has_stepped:
			_animation_tree.set("parameters/transition_ground_to_fall/transition_request", "fall")


func play_override_animation(anim_path : String, override_node : StringName = "anim_node_override", \
		anim_trigger_lambda : Callable = func () -> void : _animation_tree.set("parameters/override_node/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE) \
		) -> void:
	_animation_tree.get_tree_root().get_node(override_node).animation = anim_path
	anim_trigger_lambda.call()

func play_collider_crouch(reverse : bool = false) -> void:
	if (reverse and _animation_tree.get("parameters/TimeScale/scale") == -1.0) or \
			(!reverse and _animation_tree.get("parameters/TimeScale/scale") == 1.0):
		return
	
	_animation_tree.set("parameters/TimeScale/scale", -1.0 if reverse else 1.0)
		
	_animation_tree.set("parameters/add_collider_change/add_amount", 1.0)
	_animation_tree.animation_finished.connect(\
		func(anim_name: StringName):
		if anim_name == "Collider/Crouch":
			_animation_tree.set("parameters/add_collider_change/add_amount", 0.0)
		)

func _on_action_enter(_action_id: StringName) -> void:
	# this helps prevent errors for if a step up is interrupted by an action before the character touches the ground
	if !_action_container._action_dict[_action_id].IS_LAYERED:
		has_stepped = false

func _on_character_step(_step_data: Dictionary) -> void:
	has_stepped = true
