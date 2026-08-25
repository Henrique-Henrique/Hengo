@tool
class_name HenActionOnChildrenPressed extends HenScriptMacroBase


# listens to every child button of Container at once and reports which one was
# pressed by its index. it collapses a per-button listener and a state each into
# one action: wire Received to a state that reads Store Index.
# connections are made on entry and dropped on exit, like the other events.


const INDEX_SLOT: StringName = &'store_index'


func get_id() -> StringName:
	return &'on_children_pressed'


func get_description() -> String:
	return 'Watches every child button of a container at once and reports which one was pressed by its index. It replaces one listener and one state per button with a single action.'


func get_display_name() -> String:
	return 'On Any Button Pressed'


func get_icon() -> String:
	return 'square-mouse-pointer'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Container',
			type = 'Container',
			id = &'container',
			doc = 'The node whose buttons are watched. Leave it empty to watch the children of this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Store Index',
			type = 'int',
			id = INDEX_SLOT,
			doc = 'Variable that receives the child index that was pressed. Optional.',
			lvalue = true,
			optional = true,
			default_value = null
		}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Received', id = &'received', doc = 'Where to go when any child button is pressed.'}
	]


# a flag is only useful while the state runs, so no enter and no exit phase
func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


# state-class vars plus the shared callback; the index is bound per child at
# connect time, so one callback tells every button apart
func get_script_base() -> String:
	return 'var child_conns_{{VCNODE_ID}}: Array = []\n' \
		+ 'var pressed_index_{{VCNODE_ID}}: int = -1\n' \
		+ '\n' \
		+ 'func _on_child_pressed_{{VCNODE_ID}}(_idx: int) -> void:\n' \
		+ '\tpressed_index_{{VCNODE_ID}} = _idx'


# connects on entry: {{container}} resolves here (script base never sees inputs)
func get_flow_reset() -> String:
	return 'pressed_index_{{VCNODE_ID}} = -1\n' \
		+ 'child_conns_{{VCNODE_ID}} = []\n' \
		+ 'var _cont_{{VCNODE_ID}} = {{container}}\n' \
		+ 'if is_instance_valid(_cont_{{VCNODE_ID}}):\n' \
		+ '\tfor _i in _cont_{{VCNODE_ID}}.get_child_count():\n' \
		+ '\t\tvar _child = _cont_{{VCNODE_ID}}.get_child(_i)\n' \
		+ '\t\tif _child.has_signal(&\'pressed\'):\n' \
		+ '\t\t\tvar _cb = _on_child_pressed_{{VCNODE_ID}}.bind(_i)\n' \
		+ '\t\t\tif not _child.pressed.is_connected(_cb):\n' \
		+ '\t\t\t\t_child.pressed.connect(_cb)\n' \
		+ '\t\t\t\tchild_conns_{{VCNODE_ID}}.append([_child, _cb])'


func get_flow_teardown() -> String:
	return 'for _pair in child_conns_{{VCNODE_ID}}:\n' \
		+ '\tif is_instance_valid(_pair[0]) and _pair[0].pressed.is_connected(_pair[1]):\n' \
		+ '\t\t_pair[0].pressed.disconnect(_pair[1])\n' \
		+ 'child_conns_{{VCNODE_ID}} = []'


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the store line runs through input substitution here, so {{store_index}} lands
# on the user variable; dropped when nothing is bound to it
func _body() -> String:
	var lines: PackedStringArray = [
		'if pressed_index_{{VCNODE_ID}} != -1:'
	]

	if is_bound(INDEX_SLOT):
		lines.append('\t{{' + str(INDEX_SLOT) + '}} = pressed_index_{{VCNODE_ID}}')

	lines.append('\tpressed_index_{{VCNODE_ID}} = -1')
	lines.append('\t{{received}}')

	return '\n'.join(lines)
