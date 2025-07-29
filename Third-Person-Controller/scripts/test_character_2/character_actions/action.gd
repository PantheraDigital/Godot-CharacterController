extends Node
class_name CharacterAction

## performs a change on Character

signal enter(action_id: StringName)
signal exit(action_id: StringName)

# is var so subclass can change but should not be changed after that
var ID: StringName = ""
var IS_LAYERED = false # non-layered actions can only have one active at a time

# allows other actions to stop this one while it is active
@export var interrupt_whitelist: Array[StringName]


func can_play() -> bool:
	return false

func play(_params: Dictionary = {}) -> void:
	enter.emit(ID)

func stop() -> void:
	exit.emit(ID)
