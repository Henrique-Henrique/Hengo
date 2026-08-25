@tool
class_name HenActionSetShaderParam extends HenScriptMacroBase


# writes a uniform on the ShaderMaterial of a bound node, driving effects like a
# dissolve amount or a hit flash. the node must carry a ShaderMaterial.


func get_id() -> StringName:
	return &'set_shader_param'


func get_description() -> String:
	return 'Sets a uniform on the ShaderMaterial of a node, driving an effect such as a dissolve amount or a flash. The node must carry a ShaderMaterial.'


func get_display_name() -> String:
	return 'Set Shader Value'


func get_icon() -> String:
	return 'palette'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node whose shader is changed. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Name',
			type = 'String',
			id = &'name',
			doc = 'The shader uniform to set, without the u prefix.',
			default_value = ''
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value written to the uniform.',
			default_value = 0.0
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
	return '{{target}}.material.set_shader_parameter({{name}}, {{value}})'
