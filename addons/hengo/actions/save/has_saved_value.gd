@tool
class_name HenActionHasSavedValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'has_saved_value'


func get_description() -> String:
	return 'Checks whether something was already saved under a name and branches on the answer. It is how a title screen tells a new game from a saved one.'


func get_display_name() -> String:
	return 'Has Saved Value'


func get_icon() -> String:
	return 'file-search'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The name to look for, the same one used to save it.',
			default_value = 'score'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when a value was saved under that name.'},
		{name = 'False', id = &'false', doc = 'Where to go when nothing was saved under that name.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'var cfg_{{VCNODE_ID}} = ConfigFile.new()\n' \
		+ 'cfg_{{VCNODE_ID}}.load("user://hengo_save.cfg")\n' \
		+ 'if cfg_{{VCNODE_ID}}.has_section("data") and cfg_{{VCNODE_ID}}.has_section_key("data", {{key}}):\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
