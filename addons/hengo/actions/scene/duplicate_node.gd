@tool
class_name HenActionDuplicateNode extends HenScriptMacroBase


func get_id() -> StringName:
	return &'duplicate_node'


func get_description() -> String:
	return 'Makes a copy of a node that is already in the scene and adds it next to the original. It suits repeating a card or an item that is already set up.'


func get_display_name() -> String:
	return 'Clone Node'


func get_icon() -> String:
	return 'copy'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Node',
			type = 'Node',
			id = &'node',
			doc = 'The node to copy. Leave it empty to copy this node.',
			bind_only = true,
			optional = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Clone', type = 'Variant', id = &'clone', doc = 'The copy that was just created, ready to be set up with Set Property.'}
	]


func get_output_clone() -> String:
	return 'clone_{{VCNODE_ID}}'


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
	return 'var clone_{{VCNODE_ID}} = {{node}}.duplicate()\n' \
		+ '{{node}}.get_parent().add_child.call_deferred(clone_{{VCNODE_ID}})\n' \
		+ '{{out:clone}}'
