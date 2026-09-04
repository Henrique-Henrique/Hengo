@tool
class_name HenActionSetPaused extends HenScriptMacroBase


# pauses or resumes the whole game. paused nodes stop processing unless their
# process mode is set to keep running.


func get_id() -> StringName:
	return &'set_paused'


func get_description() -> String:
	return 'Pauses or resumes the whole game. Paused nodes stop updating unless their process mode is set to always run.'


func get_display_name() -> String:
	return 'Pause Game'


func get_icon() -> String:
	return 'circle-pause'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Paused',
			type = 'bool',
			id = &'paused',
			doc = 'True to pause the game, false to resume it.',
			default_value = true
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '_ref.get_tree().paused = {{paused}}'
