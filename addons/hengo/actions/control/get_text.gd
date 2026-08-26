@tool
class_name HenActionGetText extends HenScriptMacroBase


# reads the text of a bound Control node (LineEdit, Label, Button...) into Store.
# Target is bound by variable or node path; the read is duck-typed.


func get_id() -> StringName:
	return &'get_text'


func get_description() -> String:
	return 'Reads the text of a Control node such as a LineEdit or Label and stores it. Use it to pick up what was typed into a field.'


func get_display_name() -> String:
	return 'Get Text'


func get_icon() -> String:
	return 'type'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Control',
			id = &'target',
			doc = 'The node to read the text from. Leave it empty to read this node.',
			bind_only = true,
			optional = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Text', type = 'String', id = &'text', doc = 'Where to store the text read from the node.'}
	]


func get_output_text() -> String:
	return '{{target}}.text'


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
	return '{{out:text}}'
