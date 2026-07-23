@tool
class_name HenActionGetAxis extends HenScriptMacroBase


# writes the -1..1 strength between two input actions into Store.


func get_id() -> StringName:
	return &'get_axis'


func get_display_name() -> String:
	return 'Get Axis'


func get_icon() -> String:
	return 'move-horizontal'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Negative',
			type = 'StringName',
			id = &'negative',
			default_value = 'ui_left'
		},
		{
			name = 'Positive',
			type = 'StringName',
			id = &'positive',
			default_value = 'ui_right'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result'}
	]


func get_output_result() -> String:
	return 'Input.get_axis({{negative}}, {{positive}})'


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
	return '{{out:result}}'
