@tool
class_name HenActionAccelerate3D extends HenScriptMacroBase


func get_id() -> StringName:
	return &'accelerate_3d'


func get_description() -> String:
	return 'Pushes the body a little further in a direction every frame, adding to the speed it already carries instead of replacing it. With Amount = 30 toward a grapple point, the body builds up a swing and keeps it after the pull stops.'


func get_display_name() -> String:
	return 'Accelerate'


func get_icon() -> String:
	return 'gauge'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody3D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to push. Leave it empty to push this node.'),
		{
			name = 'Direction',
			type = 'Vector3',
			id = &'direction',
			doc = 'Which way to push. Only the direction is used, the length is ignored.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Amount',
			type = 'float',
			id = &'amount',
			doc = 'How much speed to add per second.',
			default_value = 30.0
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
	return '{{ref}}.velocity += {{direction}}.normalized() * {{amount}} * delta'
