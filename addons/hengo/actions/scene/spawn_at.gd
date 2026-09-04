@tool
class_name HenActionSpawnAt extends HenScriptMacroBase


func get_id() -> StringName:
	return &'spawn_at'


func get_description() -> String:
	return 'Loads a scene file and adds a copy of it next to this node, placed on top of another node. It works the same in 2D and 3D.'


func get_display_name() -> String:
	return 'Spawn At Node'


func get_icon() -> String:
	return 'package-plus'


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
			name = 'At',
			type = 'Node',
			id = &'at',
			doc = 'The node the copy is placed on, such as a muzzle marker or a spawn point.',
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


# set_deferred because global_position only applies once the copy is in the tree
func _body() -> String:
	return 'var spawned_{{VCNODE_ID}} = load({{path}}).instantiate()\n' \
		+ '_ref.get_parent().add_child.call_deferred(spawned_{{VCNODE_ID}})\n' \
		+ 'spawned_{{VCNODE_ID}}.set_deferred("global_position", {{at}}.global_position)\n' \
		+ '{{out:spawned}}'
