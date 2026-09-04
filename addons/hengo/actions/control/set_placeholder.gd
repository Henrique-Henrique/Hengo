@tool
class_name HenActionSetPlaceholder extends HenScriptMacroBase


# sets the hint text shown inside an empty LineEdit or TextEdit. Target is bound
# by variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_placeholder'


func get_description() -> String:
	return 'Sets the hint text shown inside a LineEdit or TextEdit while it is empty.'


func get_display_name() -> String:
	return 'Set Placeholder'


func get_icon() -> String:
	return 'type'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'LineEdit',
			id = &'target',
			doc = 'The text field to change. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Text',
			type = 'String',
			id = &'text',
			doc = 'The hint text shown while the field is empty.',
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
	return '{{target}}.placeholder_text = {{text}}'
