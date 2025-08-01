extends CharacterAction


@onready var _character: CharacterBody3D = $"../.."
@onready var _animation_handler: Node = $"../../AnimationHandler"
@onready var _movement_class: MovementClass = $"../../MovementClass"

# plays one of two possible anims based on move speed
var _roll: bool = false

## see animation tracks for example of dynamic changes to character 

func _init() -> void:
	self.ID = "DASH"

func can_play() -> bool:
	return _character.is_on_floor()

func play(_params: Dictionary = {}) -> void:
	# See anim tracks to see how character is changed 
	if _character.variables.speed == _character.variables.run_speed:
		_animation_handler.play_override_animation("GenericLocamotion/Run-ToSlide")
		_roll = false
	else:
		_animation_handler.play_override_animation("GenericLocamotion/Roll")
		_roll = true
	super.play()

func stop() -> void: 
	# clean up any changes if action is interrupted 
	_animation_handler.play_collider_crouch(true)
	if !_roll:
		_movement_class.enable_movement(_movement_class.EnabledMovement.STEP)
	super.stop()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name in ["GenericLocamotion/Run-ToSlide", "GenericLocamotion/Roll"]:
		stop()
