@tool
class_name HenActionLerp extends HenScriptMacroBase


# writes the interpolation between From and To at Weight (0..1) into Store.


func get_id() -> StringName:
	return &'lerp'


func get_display_name() -> String:
	return 'Lerp'


func get_icon() -> String:
	return 'spline'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'Variant',
			id = &'from',
			type_from = &'result',
			default_value = 0.0
		},
		{
			name = 'To',
			type = 'Variant',
			id = &'to',
			type_from = &'result',
			default_value = 1.0
		},
		{
			name = 'Weight',
			type = 'float',
			id = &'weight',
			default_value = 0.5
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result'}
	]


func get_output_result() -> String:
	return 'lerp({{from}}, {{to}}, {{weight}})'


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
