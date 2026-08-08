@tool
class_name HenActionRollChance extends HenScriptMacroBase


func get_id() -> StringName:
	return &'roll_chance'


func get_description() -> String:
	return 'Rolls a percentage once and stores whether it succeeded. It is the Chance answer as a value, to feed Do If or Combine Checks.'


func get_display_name() -> String:
	return 'Roll Chance'


func get_icon() -> String:
	return 'dice-5'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Chance %',
			type = 'float',
			id = &'chance',
			doc = 'How often it succeeds, where 50 is about half the time.',
			default_value = 50.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'bool', id = &'result', doc = 'True when the roll succeeded.'}
	]


func get_output_result() -> String:
	return '(randf() * 100.0 < {{chance}})'


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
