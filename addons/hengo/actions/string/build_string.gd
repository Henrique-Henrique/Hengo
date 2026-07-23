@tool
class_name HenActionBuildString extends HenScriptMacroBase


# joins Prefix + Value + Suffix into Store. Value goes through str(), so any
# type can be pasted into the text.


func get_id() -> StringName:
	return &'build_string'


func get_display_name() -> String:
	return 'Build String'


func get_icon() -> String:
	return 'type'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Prefix',
			type = 'String',
			id = &'prefix',
			default_value = ''
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			default_value = ''
		},
		{
			name = 'Suffix',
			type = 'String',
			id = &'suffix',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result'}
	]


func get_output_result() -> String:
	return '{{prefix}} + str({{value}}) + {{suffix}}'


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
