extends Node

# prevents fall anim by tracking when the character is in the air during a step up
var has_stepped: bool = false

@onready var _character: CharacterBody3D = $".."
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
		if has_stepped and _character.is_on_floor():
			has_stepped = false
		
		if _character.is_on_floor():
			_animation_tree.set("parameters/transition_ground_to_fall/transition_request", "grounded")
			if _character.velocity.length() > 0:
				if _character.variables.speed == _character.variables.run_speed:
					_animation_tree.set("parameters/BlendSpace1D/blend_position", 1.0)
				else:
					_animation_tree.set("parameters/BlendSpace1D/blend_position", 0.5)
			else:
				_animation_tree.set("parameters/BlendSpace1D/blend_position", 0.0)
		elif _movement_state.was_on_floor == false and !has_stepped:
			_animation_tree.set("parameters/transition_ground_to_fall/transition_request", "fall")


var play_override_animation_lambda : Callable = func () -> void : _animation_tree.set("parameters/override_node/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
func play_override_animation(anim_path : String, override_node : StringName = "anim_node_override", anim_trigger_lambda : Callable = play_override_animation_lambda) -> void:
	_animation_tree.get_tree_root().get_node(override_node).animation = anim_path
	anim_trigger_lambda.call()


func _on_action_enter(_action_id: StringName) -> void:
	# this helps prevent errors for if a step up is interrupted by an action before the character touches the ground
	if !_action_container._action_dict[_action_id].IS_LAYERED:
		has_stepped = false

func _on_character_step(_step_data: Dictionary) -> void:
	has_stepped = true
