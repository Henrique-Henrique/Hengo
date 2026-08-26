@tool
class_name HenActionMoveAndCollide extends HenScriptMacroBase


# moves the body by Motion and stops at the first thing it hits, branching on the
# result. use it when a single swept move needs the exact contact, unlike Move
# And Slide which resolves sliding on its own.


func get_id() -> StringName:
	return &'move_and_collide'


func get_description() -> String:
	return 'Moves the body by an amount and stops at the first obstacle, then branches on whether it hit. On a hit it reports the collider, the contact point and the surface normal.'


func get_display_name() -> String:
	return 'Move And Collide'


func get_icon() -> String:
	return 'crosshair'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to move. Leave it empty to move this node.'),
		{
			name = 'Motion',
			type = 'Vector2',
			id = &'motion',
			doc = 'How far to move this step, in pixels.',
			default_value = Vector2.ZERO
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Collider', type = 'Object', id = &'collider', branch = &'hit', doc = 'The node the body hit.'},
		{name = 'Point', type = 'Vector2', id = &'point', branch = &'hit', doc = 'The position where the contact happened.'},
		{name = 'Normal', type = 'Vector2', id = &'normal', branch = &'hit', doc = 'The direction the hit surface faces.'}
	]


func get_output_collider() -> String:
	return 'col_{{VCNODE_ID}}.get_collider()'


func get_output_point() -> String:
	return 'col_{{VCNODE_ID}}.get_position()'


func get_output_normal() -> String:
	return 'col_{{VCNODE_ID}}.get_normal()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Hit', id = &'hit', doc = 'Where to go when the move hits something.'},
		{name = 'Miss', id = &'miss', doc = 'Where to go when the move hits nothing.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# the outputs land inside the hit branch, so an unbound one just drops its line
func _body() -> String:
	return 'var col_{{VCNODE_ID}} = {{ref}}.move_and_collide({{motion}})\n' \
		+ 'if col_{{VCNODE_ID}}:\n' \
		+ '\t{{out:collider}}\n' \
		+ '\t{{out:point}}\n' \
		+ '\t{{out:normal}}\n' \
		+ '\t{{hit}}\n' \
		+ 'else:\n' \
		+ '\t{{miss}}'
