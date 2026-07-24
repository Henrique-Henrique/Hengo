@tool
class_name HenActionSetText extends HenScriptMacroBase


# writes Text onto a bound Control node (Label, Button, LineEdit...). Target is
# bound by variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_text'


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
			type = 'Node',
			id = &'target',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Text',
			type = 'String',
			id = &'text',
			default_value = ''
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{target}}.text = {{text}}'
