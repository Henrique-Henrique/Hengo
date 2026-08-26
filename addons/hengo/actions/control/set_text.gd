@tool
class_name HenActionSetText extends HenScriptMacroBase


# writes Text onto a bound Control node (Label, Button, LineEdit...). Target is
# bound by variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_text'


func get_description() -> String:
	return 'Sets the text shown by a Control node such as a Label or Button.'


func get_display_name() -> String:
	return 'Set Text'


func get_icon() -> String:
	return 'type'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Control',
			id = &'target',
				doc = 'The node to write text to, such as a Label or Button. Leave it empty to write to this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Text',
			type = 'String',
			id = &'text',
				doc = 'The text to display.',
			default_value = ''
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
	return '{{target}}.text = {{text}}'
