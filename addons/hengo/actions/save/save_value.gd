@tool
class_name HenActionSaveValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'save_value'


func get_description() -> String:
	return 'Stores a value on disk under a name, so it survives closing the game. Use it for a high score, the current level or a menu option.'


func get_display_name() -> String:
	return 'Save Value'


func get_icon() -> String:
	return 'save'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Key',
			type = 'String',
			id = &'key',
			doc = 'The name this value is stored under, used again to load it.',
			default_value = 'score'
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to write, such as a number, a text or a true or false flag.',
			default_value = 0
		}
	]


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


# load() fails until the first save creates the file
func _body() -> String:
	return 'var cfg_{{VCNODE_ID}} = ConfigFile.new()\n' \
		+ 'cfg_{{VCNODE_ID}}.load("user://hengo_save.cfg")\n' \
		+ 'cfg_{{VCNODE_ID}}.set_value("data", {{key}}, {{value}})\n' \
		+ 'cfg_{{VCNODE_ID}}.save("user://hengo_save.cfg")'
