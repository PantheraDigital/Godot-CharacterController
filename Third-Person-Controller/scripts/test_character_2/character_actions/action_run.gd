extends CharacterAction



@onready var _character: CharacterBody3D = $"../.."


func _init() -> void:
	self.ID = "RUN"
	self.IS_LAYERED = true

func can_play() -> bool:
	return _character.is_on_floor()

func play(_params: Dictionary = {}) -> void:
	_character.variables.speed = _character.variables.run_speed
	super.play()

func stop() -> void:
	_character.variables.speed = _character.variables.walk_speed
	super.stop()
