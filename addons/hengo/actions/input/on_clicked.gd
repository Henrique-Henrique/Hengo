@tool
class_name HenActionOnClicked extends HenScriptMacroBase


# only offered on the physics phase: the point query needs the collision world
# settled, same as Pick Under Mouse.


func get_id() -> StringName:
	return &'on_clicked'


func get_description() -> String:
	return 'Checks whether a mouse click landed on this node and branches on the answer. It asks the 2D physics world what sits under the cursor, so the node needs a collision shape, and it only fires on the frame the button goes down.'


func get_display_name() -> String:
	return 'On Clicked'


func get_icon() -> String:
	return 'square-mouse-pointer'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Button',
			type = 'String',
			id = &'button',
			doc = 'Which mouse button has to go down.',
			options = ['left', 'right', 'middle'],
			default_value = 'left'
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Clicked', id = &'clicked', doc = 'Where to go when the click landed on this node.'},
		{name = 'Not Clicked', id = &'not_clicked', doc = 'Where to go on every other frame.'}
	]


# entering the state with the button already down must not read as a click, so
# the flag starts as if the press had already been seen
func get_script_base() -> String:
	return 'var was_down_{{VCNODE_ID}}: bool = true'


func get_flow_reset() -> String:
	return 'was_down_{{VCNODE_ID}} = true'


func get_flow_physics() -> String:
	return 'var hit_{{VCNODE_ID}}: bool = false\n' \
		+ 'var down_{{VCNODE_ID}}: bool = Input.is_mouse_button_pressed(' + _button_code() + ')\n' \
		+ 'if down_{{VCNODE_ID}} and not was_down_{{VCNODE_ID}}:\n' \
		+ '\tvar query_{{VCNODE_ID}} := PhysicsPointQueryParameters2D.new()\n' \
		+ '\tquery_{{VCNODE_ID}}.position = _ref.get_global_mouse_position()\n' \
		+ '\tquery_{{VCNODE_ID}}.collide_with_areas = true\n' \
		+ '\tvar found_{{VCNODE_ID}} = _ref.get_world_2d().direct_space_state.intersect_point(query_{{VCNODE_ID}}, 32)\n' \
		+ '\tfor result_{{VCNODE_ID}} in found_{{VCNODE_ID}}:\n' \
		+ '\t\tif result_{{VCNODE_ID}}.collider == _ref or _ref.is_ancestor_of(result_{{VCNODE_ID}}.collider):\n' \
		+ '\t\t\thit_{{VCNODE_ID}} = true\n' \
		+ '\t\t\tbreak\n' \
		+ 'was_down_{{VCNODE_ID}} = down_{{VCNODE_ID}}\n' \
		+ 'if hit_{{VCNODE_ID}}:\n' \
		+ '\t{{clicked}}\n' \
		+ 'else:\n' \
		+ '\t{{not_clicked}}'


func _button_code() -> String:
	if is_bound(&'button'):
		return 'MOUSE_BUTTON_RIGHT if str({{button}}) == "right" else (MOUSE_BUTTON_MIDDLE if str({{button}}) == "middle" else MOUSE_BUTTON_LEFT)'

	match str(value_of(&'button', 'left')):
		'right':
			return 'MOUSE_BUTTON_RIGHT'
		'middle':
			return 'MOUSE_BUTTON_MIDDLE'

	return 'MOUSE_BUTTON_LEFT'
