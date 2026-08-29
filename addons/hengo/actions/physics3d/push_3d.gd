@tool
class_name HenActionPush3D extends HenScriptMacroBase


func get_id() -> StringName:
	return &'push_3d'


func get_description() -> String:
	return 'Shoves the body once, adding the whole Amount to its speed in one shot, while Accelerate adds Amount per second for as long as it runs. With Amount = 12 pointing away from an attacker it reads as knockback, and the same shove drives a jump pad or an explosion.'


func get_display_name() -> String:
	return 'Push'


func get_icon() -> String:
	return 'zap'


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
			doc = 'Which way to shove. Only the direction is used, the length is ignored.',
			default_value = Vector3.ZERO
		},
		{
			name = 'Amount',
			type = 'float',
			id = &'amount',
			doc = 'How much speed the shove adds, all at once.',
			default_value = 12.0
		}
	]


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
	return '{{ref}}.velocity += {{direction}}.normalized() * {{amount}}'
