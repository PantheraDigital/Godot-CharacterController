extends CharacterAction


@onready var _character: CharacterBody3D = $"../.."
@onready var _animation_handler: Node = $"../../AnimationHandler"
@onready var _movement_class: MovementClass = $"../../MovementClass"


func _init() -> void:
	self.ID = "CLIMB"

func can_play() -> bool:
	return true # trusting in movement_class to call at the right time

func play(ledge_data: Dictionary = {}) -> void:
	# this is a two part animation
	# the second is triggered in the animation. alternatively this may be done in _on_animation_tree_animation_finished
	
	# force character to face wall
	_character.auto_rotate = false
	if ledge_data: 
		_character.face_point(-ledge_data["ray_cast_normal"])
	_character.velocity = Vector3.ZERO
	_animation_handler.play_override_animation("Ledge/Jump-ToLedge")
	super.play()
		
		
	## move state triggers climb signal to action container
	## action container plays climb action
	##
	## climb is an action due to how much it effects the character
	## this also lets it easily be played and prevent other actions
	## this action is not directly playable from controller as it is context specific

func stop() -> void:
	_movement_class.enable_all_movement()
	_movement_class.disable_gravity = false
	_character.auto_rotate = true
	super.stop()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Ledge/Climb-UpLedge": # a new animation is triggered during climb making this the true end
		stop()
	# alternate two part anim without trigger in anim track
	#if anim_name == "Ledge/Jump-ToLedge":
		#_animation_handler.play_override_animation("Ledge/Climb-UpLedge")
	#if anim_name == "Ledge/Jump-ToLedge":
		#stop()
