@tool
class_name HenActionContinue extends HenScriptMacroBase


# skips to the next element of the loop it sits in. only valid inside a For Each
# or Repeat.


func get_id() -> StringName:
	return &'continue_loop'


func get_description() -> String:
	return 'Skips to the next pass of the surrounding loop. Only valid inside a For Each or Repeat.'


func get_display_name() -> String:
	return 'Continue'


func get_icon() -> String:
	return 'fast-forward'


func get_needs_loop() -> bool:
	return true


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return 'continue'


func get_flow_update() -> String:
	return 'continue'


func get_flow_physics() -> String:
	return 'continue'
