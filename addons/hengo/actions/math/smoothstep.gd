@tool
class_name HenActionSmoothStep extends HenScriptMacroBase


# writes an eased 0 to 1 ramp of Value between From and To into Store: 0 below
# From, 1 above To, an S-curve in between. use it for smooth fades and reveals.


func get_id() -> StringName:
	return &'smoothstep'


func get_description() -> String:
	return 'Turns a number into a 0 to 1 amount that starts slow, speeds up in the middle and eases out at the end. With From = 0 and To = 100, a value of 50 gives 0.5, anything below 0 gives 0 and anything above 100 gives 1. Use it instead of Map Range when a fade should not start and stop abruptly.'


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
			doc = 'The value that gives 0. Anything below it also gives 0.',
			default_value = 0.0
		},
		{
			name = 'To',
			type = 'float',
			id = &'to',
			doc = 'The value that gives 1. Anything above it also gives 1.',
			default_value = 1.0
		},
		{
			name = 'Value',
			type = 'float',
			id = &'value',
			doc = 'The number to turn into an amount, such as a distance or a timer.',
			default_value = 0.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The eased amount, always between 0 and 1.'}
	]


func get_output_result() -> String:
	return 'smoothstep({{from}}, {{to}}, {{value}})'


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
	return '{{out:result}}'
