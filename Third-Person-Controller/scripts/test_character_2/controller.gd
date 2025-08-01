extends Node

## provides input to Character
## example of player controller

@onready var _character: CharacterBody3D = get_parent()
@onready var _spring_arm_pivot: Node3D = $"../SpringArmPivot"
@onready var _action_container: ActionContainer = $"../ActionContainer"



func _process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var move_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	move_vector = move_vector.rotated(-_spring_arm_pivot.rotation.y)
	_action_container.play_action("MOVE", {"direction":Vector3(move_vector.x, 0, move_vector.y), "speed":_character.variables.speed})

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if event is InputEventMouseMotion:
		_spring_arm_pivot.rotate_view(event.relative)
	
	if event.is_action("run"):
		if event.is_action_pressed("run"):
			_action_container.play_action("RUN")
		else:
			_action_container.stop_action("RUN")
	
	if event.is_action_pressed("jump"):
		_action_container.play_action("JUMP")
	
	if event.is_action_pressed("slide"):
		_action_container.play_action("DASH")
