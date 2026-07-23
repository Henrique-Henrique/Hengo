@tool
class_name HenActionQuitGame extends HenScriptMacroBase


# closes the game. it does nothing in the web export.


func get_id() -> StringName:
	return &'quit_game'


func get_display_name() -> String:
	return 'Quit Game'


func get_icon() -> String:
	return 'power'


func get_default_phase() -> StringName:
	return &'enter'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func _body() -> String:
	return '_ref.get_tree().quit()'
