@tool
class_name HenActionSetControlValue extends HenScriptMacroBase


# writes Value onto a bound Range node (ProgressBar, Slider, SpinBox). Target is
# bound by variable or node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_control_value'


func get_description() -> String:
	return 'Sets the value of a Range node such as a ProgressBar, Slider or SpinBox.'


func get_display_name() -> String:
	return 'Set Control Value'


func get_icon() -> String:
	return 'sliders-horizontal'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Range',
			id = &'target',
				doc = 'The slider or bar to change. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Value',
			type = 'float',
			id = &'value',
				doc = 'The value to set, within the node min and max.',
			default_value = 0.0
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
	return '{{target}}.value = {{value}}'
