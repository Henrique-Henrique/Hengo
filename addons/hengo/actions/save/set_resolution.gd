@tool
class_name HenActionSetResolution extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_resolution'


func get_description() -> String:
	return 'Resizes the game window and puts it back at the center of the screen. It only changes anything while the game runs in a window, not in fullscreen.'


func get_display_name() -> String:
	return 'Set Resolution'


func get_icon() -> String:
	return 'monitor-cog'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Width',
			type = 'int',
			id = &'width',
			doc = 'The new window width in pixels.',
			default_value = 1280
		},
		{
			name = 'Height',
			type = 'int',
			id = &'height',
			doc = 'The new window height in pixels.',
			default_value = 720
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


func _body() -> String:
	return 'var size_{{VCNODE_ID}} = Vector2i({{width}}, {{height}})\n' \
		+ 'DisplayServer.window_set_size(size_{{VCNODE_ID}})\n' \
		+ 'DisplayServer.window_set_position(DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() - size_{{VCNODE_ID}}) / 2)'
