@tool
class_name HenActionSpawnScene3D extends HenScriptMacroBase


func get_id() -> StringName:
	return &'spawn_scene_3d'


func get_description() -> String:
	return 'Loads a scene file and adds a copy of it next to this node, placed at the given position.'


func get_display_name() -> String:
	return 'Spawn Scene'


func get_icon() -> String:
	return 'copy-plus'


func get_target_classes() -> Array[StringName]:
	return [&'Node3D']


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
			default_value = 'res://scenes/hit.tscn'
		},
		{
			name = 'Position',
			type = 'Vector3',
			id = &'position',
			doc = 'Where to place the new copy, in world space.',
			default_value = Vector3.ZERO
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


# placed before it is added, or a copy that emits on its first frame does it at the
# origin: top_level is what makes the placement read as world space
func _body() -> String:
	return 'var spawned_{{VCNODE_ID}} = load({{path}}).instantiate()\n' \
		+ 'spawned_{{VCNODE_ID}}.top_level = true\n' \
		+ 'spawned_{{VCNODE_ID}}.position = {{position}}\n' \
		+ '_ref.get_parent().add_child.call_deferred(spawned_{{VCNODE_ID}})\n' \
		+ '{{out:spawned}}'
