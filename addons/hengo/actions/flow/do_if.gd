@tool
class_name HenActionDoIf extends HenScriptMacroBase


func get_id() -> StringName:
	return &'do_if'


func get_description() -> String:
	return 'Runs the actions inside it only when the condition is true, staying in the same state. It is the plain if: nothing here jumps to another state.'


func get_display_name() -> String:
	return 'Do If'


func get_icon() -> String:
	return 'git-branch'


func get_has_body() -> bool:
	return true


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test to run, such as a comparison kept in a variable or a Compare action placed right here.',
			default_value = true
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{condition}}:\n\t{{loop_body}}'
