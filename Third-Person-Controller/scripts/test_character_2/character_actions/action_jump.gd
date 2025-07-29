extends CharacterAction


@onready var _character: CharacterBody3D = $"../.."
@onready var _animation_handler: Node = $"../../AnimationHandler"
@onready var _movement_class: MovementClass = $"../../MovementClass"


func _init() -> void:
	self.ID = "JUMP"

func can_play() -> bool:
	return _character.is_on_floor()

func play(_params: Dictionary = {}) -> void:
	_animation_handler.play_override_animation("GenericLocamotion/Jump-Start")
	_movement_class.add_impulse(Vector3.UP, _character.variables.jump_strength)
	super.play()

func stop() -> void:
	super.stop()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "GenericLocamotion/Jump-Start":
		stop()
