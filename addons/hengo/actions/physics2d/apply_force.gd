@tool
class_name HenActionApplyForce extends HenScriptMacroBase


# a continuous push, applied every physics frame while the state runs — thrust,
# wind, magnet. leave Offset at zero to push through the center.


func get_id() -> StringName:
	return &'apply_force'


func get_description() -> String:
	return 'Pushes a physics body continuously every physics frame while the state runs, such as thrust or wind. For a one-shot push use Apply Impulse.'


func get_display_name() -> String:
	return 'Apply Force'


func get_icon() -> String:
	return 'wind'


func get_target_classes() -> Array[StringName]:
	return [&'RigidBody2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to push. Leave it empty to push this node.'),
		{
			name = 'Force',
			type = 'Vector2',
			id = &'force',
			doc = 'The push to apply each frame, in pixels times mass per second squared.',
			default_value = Vector2.ZERO
		},
		{
			name = 'Offset',
			type = 'Vector2',
			id = &'offset',
			doc = 'Where the push is applied, relative to the center. Zero pushes through the center.',
			default_value = Vector2.ZERO
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{ref}}.apply_force({{force}}, {{offset}})'
