@tool
class_name HenSaveVar extends HenSaveResType

@export_custom(PROPERTY_HINT_NONE, 'all_godot_classes') var type: StringName
@export var is_export: bool

static func create() -> HenSaveVar:
	var v: HenSaveVar = HenSaveVar.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()
	type = &'Variant'


func get_new_name() -> String:
	return 'variable_' + str(id)


func get_data() -> Dictionary:
	return {
		name = name,
		type = type,
		id = id,
		export = is_export
	}


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	match _type:
		HenVirtualCNode.SubType.SET_VAR:
			return [
				{
					id = 0,
					name = name,
					type = type,
				}
			]
		HenVirtualCNode.SubType.SET_VAR_FROM:
			var info: Dictionary = _get_resource_info()

			return [
				{
					id = 0,
					name = info.name,
					type = info.type,
					is_ref = true
				},
				{
					id = 1,
					name = name,
					type = type,
				}
			]
		HenVirtualCNode.SubType.VAR_FROM:
			var info: Dictionary = _get_resource_info()

			return [
				{
					id = 0,
					name = info.name,
					type = info.type,
					is_ref = true
				}
			]
	
	return []


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	match _type:
		HenVirtualCNode.SubType.VAR, HenVirtualCNode.SubType.VAR_FROM:
			return [
				{
					id = 0,
					name = name,
					type = type,
				}
			]
	
	return []


func get_getter_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = 'Get ' + name,
		sub_type = HenVirtualCNode.SubType.VAR if not _from_another_script else HenVirtualCNode.SubType.VAR_FROM,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.VAR, _save_data_id)
	}


func get_setter_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
		name = 'Set ' + name,
		sub_type = HenVirtualCNode.SubType.SET_VAR if not _from_another_script else HenVirtualCNode.SubType.SET_VAR_FROM,
		route = router.current_route,
		res_data = get_res_data(HenSideBar.AddType.VAR, _save_data_id)
	}


func _get_resource_info() -> Dictionary:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	
	if not map_dep:
		return {name = name, type = &'Variant'}
	
	for project_ast: HenMapDependencies.ProjectAST in map_dep.ast_list.values():
		for var_res: HenSaveVar in project_ast.variables:
			if var_res.id == id:
				if project_ast.identity:
					return {name = project_ast.identity.name, type = project_ast.identity.type}
				break
	
	return {name = name, type = &'Variant'}