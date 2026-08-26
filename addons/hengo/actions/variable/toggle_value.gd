@tool
class_name HenActionToggleValue extends HenScriptMacroBase


# flips a boolean. Target must be BOUND to a variable/property (it becomes the
# assignment lvalue `_ref.<name>`). body has no delta, so it works in every phase.


func get_id() -> StringName:
	return &'toggle_value'


func get_description() -> String:
	return 'Flips a boolean variable or property between true and false.'


func get_icon() -> String:
	return 'toggle-right'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
				doc = 'The boolean variable or property to flip.',
			lvalue = true,
			default_value = null
		}
	]


# lifecycle phases this action supports
func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '{{target}} = not {{target}}'


func get_flow_update() -> String:
	return '{{target}} = not {{target}}'


func get_flow_physics() -> String:
	return '{{target}} = not {{target}}'


func get_flow_exit() -> String:
	return '{{target}} = not {{target}}'
