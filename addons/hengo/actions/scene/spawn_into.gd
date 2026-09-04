@tool
class_name HenActionSpawnInto extends HenScriptMacroBase


func get_id() -> StringName:
	return &'spawn_into'


func get_description() -> String:
	return 'Loads a scene file and adds a copy of it as a child of the chosen node. It fits filling a list, an inventory or a hand of cards.'


func get_display_name() -> String:
	return 'Spawn Into'


func get_icon() -> String:
	return 'list-plus'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Scene Path',
			type = 'String',
			id = &'path',
			picker = 'scene_path',
			doc = 'The path to the scene file to spawn.',
			default_value = 'res://scenes/bullet.tscn'
		},
		{
			name = 'Parent',
			type = 'Node',
			id = &'parent',
			doc = 'The node the copy becomes a child of, such as a VBoxContainer.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Spawned', type = 'Variant', id = &'spawned', doc = 'The copy that was just created, ready to be set up with Set Property.'}
	]


func get_output_spawned() -> String:
	return 'spawned_{{VCNODE_ID}}'


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
	return 'var spawned_{{VCNODE_ID}} = load({{path}}).instantiate()\n' \
		+ '{{parent}}.add_child.call_deferred(spawned_{{VCNODE_ID}})\n' \
		+ '{{out:spawned}}'
