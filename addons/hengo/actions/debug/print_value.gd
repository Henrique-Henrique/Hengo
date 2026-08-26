@tool
class_name HenActionPrintValue extends HenScriptMacroBase


# native test action: prints a value. the Value input is Variant so it can be
# bound to anything (a variable, or a node property like rotation).
# body has no delta, so it works in every lifecycle phase.


func get_id() -> StringName:
	return &'print_value'


func get_description() -> String:
	return 'Prints a value to the output console for debugging.'


func get_icon() -> String:
	return 'terminal'


# Variant so the binding picker accepts any variable/property
func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
				doc = 'The value to print.',
			default_value = 'hello'
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
	return 'print({{value}})'


func get_flow_update() -> String:
	return 'print({{value}})'


func get_flow_physics() -> String:
	return 'print({{value}})'


func get_flow_exit() -> String:
	return 'print({{value}})'
