@tool
class_name HenActionSetCollisionBit extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_collision_bit'


func get_description() -> String:
	return 'Switches one collision layer or mask bit of a body on or off. The layer says where the body lives, the mask says what it bumps into.'


func get_display_name() -> String:
	return 'Set Collision Bit'


func get_icon() -> String:
	return 'layers'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The body to change. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Kind',
			type = 'String',
			id = &'kind',
			doc = 'Which side to change.',
			options = ['layer', 'mask'],
			default_value = 'layer'
		},
		{
			name = 'Bit',
			type = 'int',
			id = &'bit',
			doc = 'The bit to change, counting from 1 like the numbers in the inspector.',
			default_value = 1
		},
		{
			name = 'On',
			type = 'bool',
			id = &'on',
			doc = 'True to switch the bit on, false to switch it off.',
			default_value = true
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	if is_bound(&'kind'):
		return 'if str({{kind}}) == "mask":\n' \
			+ '\t{{target}}.set_collision_mask_value({{bit}}, {{on}})\n' \
			+ 'else:\n' \
			+ '\t{{target}}.set_collision_layer_value({{bit}}, {{on}})'

	if str(value_of(&'kind', 'layer')) == 'mask':
		return '{{target}}.set_collision_mask_value({{bit}}, {{on}})'

	return '{{target}}.set_collision_layer_value({{bit}}, {{on}})'
