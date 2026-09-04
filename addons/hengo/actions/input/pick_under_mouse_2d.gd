@tool
class_name HenActionPickUnderMouse2D extends HenScriptMacroBase


# branches on what the cursor is over: it asks the physics world which collider
# sits under the mouse. only offered on the physics phase, which is when the
# collision world is settled.


func get_id() -> StringName:
	return &'pick_under_mouse_2d'


func get_description() -> String:
	return 'Asks the 2D physics world which collider sits under the mouse and branches on whether one is found.'


func get_display_name() -> String:
	return 'Pick Under Mouse'


func get_icon() -> String:
	return 'mouse-pointer'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Collider', type = 'Object', id = &'collider', branch = &'hit', doc = 'Where to store the collider found under the mouse.'}
	]


func get_output_collider() -> String:
	return 'found_{{VCNODE_ID}}[0].collider'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Hit', id = &'hit', doc = 'Where to go when a collider is under the mouse.'},
		{name = 'Miss', id = &'miss', doc = 'Where to go when nothing is under it.'}
	]


func get_flow_physics() -> String:
	return 'var query_{{VCNODE_ID}} := PhysicsPointQueryParameters2D.new()\n' \
		+ 'query_{{VCNODE_ID}}.position = _ref.get_global_mouse_position()\n' \
		+ 'query_{{VCNODE_ID}}.collide_with_areas = true\n' \
		+ 'var found_{{VCNODE_ID}} = _ref.get_world_2d().direct_space_state.intersect_point(query_{{VCNODE_ID}}, 1)\n' \
		+ 'if found_{{VCNODE_ID}}.size() > 0:\n' \
		+ '\t{{out:collider}}\n' \
		+ '\t{{hit}}\n' \
		+ 'else:\n' \
		+ '\t{{miss}}'
