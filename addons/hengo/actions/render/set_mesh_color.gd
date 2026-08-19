@tool
class_name HenActionSetMeshColor extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_mesh_color'


func get_description() -> String:
	return 'Paints a 3D mesh of the scene with a color, creating the material it needs when the mesh has none. Change Color only paints the node the script sits on.'


func get_display_name() -> String:
	return 'Set Mesh Color'


func get_icon() -> String:
	return 'paint-bucket'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The mesh to paint, such as a MeshInstance3D.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			doc = 'The color to apply.',
			default_value = Color(1, 1, 1, 1)
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
	return 'var mesh_{{VCNODE_ID}} = {{target}}\n' \
		+ 'if mesh_{{VCNODE_ID}} is GeometryInstance3D:\n' \
		+ '\tif (mesh_{{VCNODE_ID}} as GeometryInstance3D).material_override == null:\n' \
		+ '\t\t(mesh_{{VCNODE_ID}} as GeometryInstance3D).material_override = StandardMaterial3D.new()\n' \
		+ '\tvar material_{{VCNODE_ID}} := (mesh_{{VCNODE_ID}} as GeometryInstance3D).material_override as StandardMaterial3D\n' \
		+ '\tif material_{{VCNODE_ID}}:\n' \
		+ '\t\tmaterial_{{VCNODE_ID}}.albedo_color = {{color}}'
