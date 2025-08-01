extends CharacterAction


@onready var _character: CharacterBody3D = $"../.."
@onready var _animation_handler: Node = $"../../AnimationHandler"
@onready var _movement_class: MovementClass = $"../../MovementClass"


func _init() -> void:
	self.ID = "CLIMB"

func can_play() -> bool:
	return true # trusting in movement_class to call at the right time

func play(ledge_data: Dictionary = {}) -> void:
	if !ledge_data:
		return
	
	# force character to face wall
	_character.auto_rotate = false
	
	if ledge_data.has("ray_cast_normal"): 
		_character.face_point(-ledge_data["ray_cast_normal"])
		# this is a two part animation
		# the second is triggered in the animation. alternatively this may be done in _on_animation_tree_animation_finished
		_animation_handler.play_override_animation("Ledge/Jump-ToLedge")
		
	elif ledge_data.has("step_point"):
		var query = PhysicsRayQueryParameters3D.create(_character.global_position, Vector3(ledge_data["step_point"].x, ledge_data["step_point"].y - 0.01, ledge_data["step_point"].z))
		query.exclude = [_character.get_rid()]
		var query_result: Dictionary = _character.get_world_3d().direct_space_state.intersect_ray(query)
		if query_result:
			_character.face_point(-query_result["normal"])
			_animation_handler.play_override_animation("Ledge/Climb-UpLedge")
	else:
		return
	
	_character.velocity = Vector3.ZERO
	super.play()
		
		
	## move state triggers climb signal to action container
	## action container plays climb action
	##
	## climb is an action due to how much it effects the character
	## this also lets it easily be played and prevent other actions
	## this action is not directly playable from controller as it is context specific

func stop() -> void:
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
