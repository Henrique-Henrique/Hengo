@tool
class_name HenSaveFunc extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]


func get_new_name() -> String:
	return 'function_' + str(id)


func _get_resource_info() -> Dictionary:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	
	if not map_dep:
		return {name = name, type = &'Variant'}
	
	for project_ast: HenMapDependencies.ProjectAST in map_dep.ast_list.values():
		for func_res: HenSaveFunc in project_ast.functions:
			if func_res.id == id:
				if project_ast.identity:
					return {name = project_ast.identity.name, type = project_ast.identity.type}
				break
	
	return {name = name, type = &'Variant'}
