@tool
class_name HenActionSpawnScene extends HenScriptMacroBase


# loads a scene file and adds a copy of it next to the owner, at Position.
# leave Store unbound when the new node does not need to be kept around.


func get_id() -> StringName:
	return &'spawn_scene'


func get_description() -> String:
	return 'Loads a scene file and adds a copy of it next to this node, placed at the given position.'


func get_display_name() -> String:
	return 'Spawn Scene'


func get_icon() -> String:
	return 'copy-plus'


# the position it writes is a Vector2, so a 3D owner would get the 3D file instead
func get_target_classes() -> Array[StringName]:
	return [&'CanvasItem']


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
			name = 'Position',
			type = 'Vector2',
			id = &'position',
			doc = 'Where to place the new copy.',
			default_value = Vector2.ZERO
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


# added to the parent so the copy is a sibling, not a child that moves along.
# deferred because spawning in enter runs during _ready, where add_child is refused
func _body() -> String:
	return 'var spawned_{{VCNODE_ID}} = load({{path}}).instantiate()\nspawned_{{VCNODE_ID}}.position = {{position}}\n_ref.get_parent().add_child.call_deferred(spawned_{{VCNODE_ID}})\n{{out:spawned}}'
