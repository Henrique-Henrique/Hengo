@tool
class_name HenActionRandomFloat extends HenScriptMacroBase


# writes a random decimal between Min and Max into Store. for a plain 0-1 value
# with no limits, bind a slot to the Random Float source instead.


func get_id() -> StringName:
	return &'random_float'


func get_description() -> String:
	return 'Picks a random decimal number between Min and Max.'


func get_display_name() -> String:
	return 'Random Float'


func get_icon() -> String:
	return 'dice-5'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Min',
			type = 'float',
			id = &'min',
			doc = 'The lowest possible value.',
			default_value = 0.0
		},
		{
			name = 'Max',
			type = 'float',
			id = &'max',
			doc = 'The highest possible value.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The random number.'}
	]


func get_output_result() -> String:
	return 'randf_range({{min}}, {{max}})'


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
