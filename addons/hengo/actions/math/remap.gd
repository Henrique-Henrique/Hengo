@tool
class_name HenActionRemap extends HenScriptMacroBase


# writes Value moved from the In range to the Out range into Store, clamped to
# the Out range. In 0..speed with Out 0..1 turns a raw reading into a 0..1 blend.


func get_id() -> StringName:
	return &'remap'


func get_description() -> String:
	return 'Takes a number that lives in one range and gives the matching number in another range. Health from 0 to 100 with an Out range of 0 to 1 becomes the fill of a health bar, so 30 health gives 0.3. A value outside the In range is held at the closest end.'


func get_display_name() -> String:
	return 'Map Range'


func get_icon() -> String:
	return 'ruler'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'float',
			id = &'value',
			doc = 'The number to rescale.',
			default_value = 0.0
		},
		{
			name = 'In Min',
			type = 'float',
			id = &'in_min',
			doc = 'The lowest value the input can take.',
			default_value = 0.0
		},
		{
			name = 'In Max',
			type = 'float',
			id = &'in_max',
			doc = 'The highest value the input can take.',
			default_value = 1.0
		},
		{
			name = 'Out Min',
			type = 'float',
			id = &'out_min',
			doc = 'The value returned when Value is at In Min.',
			default_value = 0.0
		},
		{
			name = 'Out Max',
			type = 'float',
			id = &'out_max',
			doc = 'The value returned when Value is at In Max.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The rescaled value, clamped to the Out range.'}
	]


func get_output_result() -> String:
	return 'clampf(remap({{value}}, {{in_min}}, {{in_max}}, {{out_min}}, {{out_max}}), minf({{out_min}}, {{out_max}}), maxf({{out_min}}, {{out_max}}))'


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
