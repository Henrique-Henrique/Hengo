@tool
class_name HenActionArrayRandom extends HenScriptMacroBase


# writes one item picked at random from Array into Store. an empty array gives
# null, so keep the list filled or check the length first.


func get_id() -> StringName:
	return &'array_random'


func get_description() -> String:
	return 'Picks one item at random from an array. An empty array returns null.'


func get_display_name() -> String:
	return 'Array Get Random'


func get_icon() -> String:
	return 'shuffle'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Array',
			type = 'Array',
			id = &'array',
				doc = 'The array to pick from.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the randomly picked item.'}
	]


func get_output_result() -> String:
	return '{{array}}.pick_random()'


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
