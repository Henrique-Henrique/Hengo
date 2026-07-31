@tool
class_name HenActionSmoothStep extends HenScriptMacroBase


# writes an eased 0 to 1 ramp of Value between From and To into Store: 0 below
# From, 1 above To, an S-curve in between. use it for smooth fades and reveals.


func get_id() -> StringName:
	return &'smoothstep'


func get_description() -> String:
	return 'Returns an eased 0 to 1 ramp of a value between two edges, flat outside them and an S-curve in between. Smoother than Map Range for fades and reveals.'


func get_display_name() -> String:
	return 'Smooth Step'


func get_icon() -> String:
	return 'spline'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'From',
			type = 'float',
			id = &'from',
			doc = 'The edge where the ramp starts leaving 0.',
			default_value = 0.0
		},
		{
			name = 'To',
			type = 'float',
			id = &'to',
			doc = 'The edge where the ramp reaches 1.',
			default_value = 1.0
		},
		{
			name = 'Value',
			type = 'float',
			id = &'value',
			doc = 'The number to ramp.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The eased value, between 0 and 1.'}
	]


func get_output_result() -> String:
	return 'smoothstep({{from}}, {{to}}, {{value}})'


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
