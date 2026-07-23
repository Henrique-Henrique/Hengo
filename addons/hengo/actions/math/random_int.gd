@tool
class_name HenActionRandomInt extends HenScriptMacroBase


# produces a random whole number. both Min and Max can come out, so 1 to 6
# behaves like a dice. store the Result output in a variable.


func get_id() -> StringName:
	return &'random_int'


func get_display_name() -> String:
	return 'Random Int'


func get_icon() -> String:
	return 'dice-5'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Min',
			type = 'int',
			id = &'min',
			default_value = 1
		},
		{
			name = 'Max',
			type = 'int',
			id = &'max',
			default_value = 6
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'int', id = &'result'}
	]


func get_output_result() -> String:
	return 'randi_range({{min}}, {{max}})'


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
