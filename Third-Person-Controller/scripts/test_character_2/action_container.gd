extends Node
class_name ActionContainer

## manage active actions

var _action_dict: Dictionary[StringName, CharacterAction]
var _active_action: StringName = ""


func _ready() -> void:
	for child in get_children():
		if child is CharacterAction:
			_action_dict[child.ID] = child
			child.exit.connect(_on_action_exit)
	
	var movement_class: MovementClass = $"../MovementClass"
	movement_class.climb_ledge.connect(func(step_data: Dictionary): play_action("CLIMB", step_data))


func play_action(action_name : StringName, params: Dictionary = {}) -> void:
	if action_name in _action_dict:
		if !_active_action.is_empty() and !_action_dict[_active_action].interrupt_whitelist.has(action_name):
			return
	
		if _action_dict[action_name].IS_LAYERED:
			if _action_dict[action_name].can_play():
				_action_dict[action_name].play(params)
		else:
			if _action_dict[action_name].can_play():
				if _active_action:
					_action_dict[_active_action].stop()
				_active_action = action_name
				_action_dict[action_name].play(params)

func stop_action(action_name : StringName) -> void:
	if action_name in _action_dict:
		if _action_dict[action_name].IS_LAYERED:
			_action_dict[action_name].stop()
		else:
			if action_name == _active_action:
				_action_dict[_active_action].stop()


func _on_action_exit(action_id : StringName) -> void:
	if action_id == _active_action:
		_active_action = ""
