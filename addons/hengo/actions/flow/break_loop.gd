@tool
class_name HenActionBreak extends HenScriptMacroBase


# leaves the loop it sits in, skipping the rest of the elements. only valid inside
# a For Each or Repeat.


func get_id() -> StringName:
	return &'break_loop'


func get_description() -> String:
	return 'Leaves the surrounding loop and skips the rest of its passes. Only valid inside a For Each or Repeat.'


func get_display_name() -> String:
	return 'Break'


func get_icon() -> String:
	return 'circle-slash'


func get_needs_loop() -> bool:
	return true


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return 'break'


func get_flow_update() -> String:
	return 'break'


func get_flow_physics() -> String:
	return 'break'
