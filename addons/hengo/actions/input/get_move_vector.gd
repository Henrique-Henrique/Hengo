@tool
class_name HenActionGetMoveVector extends HenScriptMacroBase


# writes the -1..1 direction of four input actions into Store, already normalized
# by the engine. it is what feeds a walk: x is sideways, y is forward.


func get_id() -> StringName:
	return &'get_move_vector'


func get_description() -> String:
	return 'Reads four movement input actions and stores their direction as a Vector2, already normalized for even diagonal speed.'


func get_display_name() -> String:
	return 'Get Move Vector'


func get_icon() -> String:
	return 'move'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Left',
			type = 'StringName',
			id = &'left',
			picker = 'input_action',
			doc = 'The input action for moving left.',
			default_value = 'ui_left'
		},
		{
			name = 'Right',
			type = 'StringName',
			id = &'right',
			picker = 'input_action',
			doc = 'The input action for moving right.',
			default_value = 'ui_right'
		},
		{
			name = 'Forward',
			type = 'StringName',
			id = &'forward',
			picker = 'input_action',
			doc = 'The input action for moving forward.',
			default_value = 'ui_up'
		},
		{
			name = 'Back',
			type = 'StringName',
			id = &'back',
			picker = 'input_action',
			doc = 'The input action for moving back.',
			default_value = 'ui_down'
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Vector2', id = &'result', doc = 'Where to store the movement direction.'}
	]


func get_output_result() -> String:
	return 'Input.get_vector({{left}}, {{right}}, {{forward}}, {{back}})'


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
