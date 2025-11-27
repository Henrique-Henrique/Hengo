@tool
class_name HenMapDependencies extends Node

const SAVE_PATH: String = 'res://hengo/save_2/'
var dependencies: Dictionary[StringName, ProjectAST] = {}

class ProjectAST:
	var variables: Array[HenSaveVar] = []


# iterates over project directories to build the dependency map
func start_map() -> void:
	pass
	# dependencies.clear()
	# var root_dir: DirAccess = DirAccess.open(SAVE_PATH)
	
	# if not root_dir:
	# 	push_error('Failed to access save path.')
	# 	return

	# for id_dir: String in root_dir.get_directories():
	# 	_map_project_variables(id_dir)

	
	# print(dependencies.values())


# loads variable resources for a specific project id
func _map_project_variables(id: String) -> void:
	var variables_path: String = SAVE_PATH.path_join(id).path_join('variables')
	var var_dir: DirAccess = DirAccess.open(variables_path)
	
	if not var_dir:
		return
		
	var ast: ProjectAST = ProjectAST.new()
	
	for file: String in var_dir.get_files():
		if file.get_extension() == 'tres':
			var resource: Resource = load(variables_path.path_join(file))
			if resource is HenSaveVar:
				ast.variables.append(resource)
	
	dependencies[StringName(id)] = ast


# get all dependencies for a given script
func get_dependencies(_script_id: StringName) -> Array:
	return []
