@tool
class_name HenActionBuildString extends HenScriptMacroBase


# joins Prefix + Value + Suffix into Store. Value goes through str(), so any
# type can be pasted into the text.


func get_id() -> StringName:
	return &'build_string'


func get_description() -> String:
	return 'Joins a prefix, a value, and a suffix into one piece of text and stores it. The value is turned into text first, so any type works.'


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
			doc = 'Text placed before the value.',
			default_value = ''
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to turn into text and place in the middle.',
			default_value = ''
		},
		{
			name = 'Suffix',
			type = 'String',
			id = &'suffix',
			doc = 'Text placed after the value.',
			default_value = ''
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'String', id = &'result', doc = 'Where to store the joined text.'}
	]


func get_output_result() -> String:
	return '{{prefix}} + str({{value}}) + {{suffix}}'


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
