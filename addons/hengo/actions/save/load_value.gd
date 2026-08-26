@tool
class_name HenActionLoadValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'load_value'


func get_description() -> String:
	return 'Reads a value saved earlier under a name and stores it. When nothing was saved under that name yet, the default value is used instead.'


func get_display_name() -> String:
	return 'Load Value'


func get_icon() -> String:
	return 'download'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The name the value was saved under.',
			default_value = 'score'
		},
		{
			name = 'Default',
			type = 'Variant',
			id = &'default',
			doc = 'The value to use when nothing was saved under that name.',
			default_value = 0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Variant', id = &'result', doc = 'Where to store the value that was read.'}
	]


func get_output_result() -> String:
	return 'cfg_{{VCNODE_ID}}.get_value("data", {{key}}, {{default}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Found',
			id = &'found',
			optional = true,
			doc = 'Where to go when a value was saved under that name.'
		},
		{
			name = 'Missing',
			id = &'missing',
			optional = true,
			doc = 'Where to go when nothing was saved under that name, which is when the default is stored.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


# has_section_key pushes an error when the section is missing, so it is guarded
func _body() -> String:
	var body: String = 'var cfg_{{VCNODE_ID}} = ConfigFile.new()\n' \
		+ 'cfg_{{VCNODE_ID}}.load("user://hengo_save.cfg")\n' \
		+ '{{out:result}}'

	if not any_flow_connected():
		return body

	return body + '\n' \
		+ 'if cfg_{{VCNODE_ID}}.has_section("data") and cfg_{{VCNODE_ID}}.has_section_key("data", {{key}}):\n' \
		+ '\t{{found}}\n' \
		+ 'else:\n' \
		+ '\t{{missing}}'
