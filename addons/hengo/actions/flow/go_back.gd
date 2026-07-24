@tool
class_name HenActionGoBack extends HenScriptMacroBase


# hands control back to whoever was running before this state took over. a
# sub-state returns to its sibling, a top level state to the previous top level
# one. use it so a short state does not need to know where it came from.


func get_id() -> StringName:
	return &'go_back'


func get_description() -> String:
	return 'Returns control to whichever state was running before this one took over.'


func get_display_name() -> String:
	return 'Go Back'


func get_icon() -> String:
	return 'rotate-ccw'


func get_default_phase() -> StringName:
	return &'enter'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


# no flow output on purpose: the target is whatever ran before, so there is
# nothing to pick. called on the state itself, which knows its own parent
func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'go_back()'
