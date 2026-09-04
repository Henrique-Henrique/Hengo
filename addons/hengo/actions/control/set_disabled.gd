@tool
class_name HenActionSetDisabled extends HenScriptMacroBase


# toggles the disabled flag of a bound Control node (Button, Slider...). Target is
# bound by variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_disabled'


func get_description() -> String:
	return 'Enables or disables a Control node such as a Button or Slider.'


func get_display_name() -> String:
	return 'Set Disabled'


func get_icon() -> String:
	return 'toggle-left'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'BaseButton',
			id = &'target',
				doc = 'The button to enable or disable. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Disabled',
			type = 'bool',
			id = &'disabled',
				doc = 'True to disable the node, false to enable it.',
			default_value = true
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
	return '{{target}}.disabled = {{disabled}}'
