@tool
class_name HenActionChangeScene extends HenScriptMacroBase


# swaps the running scene for another one. everything in the current scene is
# freed, including the node this script is on.


func get_id() -> StringName:
	return &'change_scene'


func get_description() -> String:
	return 'Replaces the running scene with another one. The current scene is freed, including the node this action runs on.'


func get_display_name() -> String:
	return 'Change Scene'


func get_icon() -> String:
	return 'replace'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Scene Path',
			type = 'String',
			id = &'path',
			picker = 'scene_path',
			doc = 'The path to the scene file to load.',
			default_value = 'res://scenes/main.tscn'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '_ref.get_tree().change_scene_to_file({{path}})'
