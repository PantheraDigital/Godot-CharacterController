extends CharacterAction



@onready var _movement_class: MovementClass = $"../../MovementClass"


func _init() -> void:
	self.ID = "MOVE"
	self.IS_LAYERED = true

func can_play() -> bool:
	return true

func play(_params: Dictionary = {}) -> void:
	if _params.has("direction") and _params.has("speed"):
		_movement_class.move(_params["direction"], _params["speed"])
		super.play()
