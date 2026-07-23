@tool
class_name HenActionArrayRandom extends HenScriptMacroBase


# writes one item picked at random from Array into Store. an empty array gives
# null, so keep the list filled or check the length first.


func get_id() -> StringName:
	return &'array_random'


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
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result'}
	]


func get_output_result() -> String:
	return '{{array}}.pick_random()'


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
