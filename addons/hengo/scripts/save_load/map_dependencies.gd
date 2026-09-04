@tool
class_name HenMapDependencies extends Node

var ast_list: Dictionary[StringName, ProjectAST] = {}

class ProjectAST:
	var identity: HenSaveDataIdentity
	var macros: Array[HenSaveMacro]
	var variables: Array[HenSaveVar]
	var states: Array[HenSaveState]


# iterates over every script of every collection to build the dependency map
func start_map() -> void:
	var start: int = Time.get_ticks_usec()
	ast_list.clear()

	for id_dir: StringName in HenUtils.get_all_script_ids():
		_map_project_data(id_dir)

	var end: int = Time.get_ticks_usec()

	print('Project mapped in ', (end - start) / 1000., 'ms')


# iterates through all sidebar types to load resources into ast
func _map_project_data(_id: StringName) -> void:
	var ast: ProjectAST = ProjectAST.new()

	var identity_path = HenUtils.get_script_dir(_id).path_join(HenEnums.IDENTITY_FILE)
	if FileAccess.file_exists(identity_path):
		var res_identity: HenSaveDataIdentity = load(identity_path)

		if res_identity:
			ast.identity = res_identity
		else:
			push_error('Error loading AST identity: ' + identity_path)
	else:
		push_error('Identity file not found: ' + identity_path)

	for type: int in HenSideBar.SideBarItem.values():
		var path: String = HenUtils.get_side_bar_item_path(_id, type)
		
		if not DirAccess.dir_exists_absolute(path):
			continue
		
		var dir: DirAccess = DirAccess.open(path)

		for file: String in dir.get_files():
			if file.ends_with(HenEnums.SAVE_EXTENSION):
				var res: Resource = load(path.path_join(file))
				
				# match type to append resource to the correct ast array
				match type:
					HenSideBar.SideBarItem.VARIABLES:
						ast.variables.append(res)

	ast_list.set(_id, ast)


func get_code_search_list(_io_type: StringName = '', _type: StringName = '') -> Dictionary:
	var api: HenApi = Engine.get_singleton(&'API')
	var global: HenGlobal = Engine.get_singleton(&'Global')

	var dt: Dictionary = {_class_name = 'Scripts', categories = []}
	var all_scripts: Dictionary = {
		name = 'All',
		icon = 'variable',
		color = '#509fa6',
		show_category = true,
		method_list = []
	}


	for v: ProjectAST in ast_list.values():
		if v.identity:
			if v.identity.id == global.SAVE_DATA.identity.id:
				continue

			var categories: Array = api.get_side_bar_categories(v, true, _io_type, _type)

			if not categories.is_empty():
				(all_scripts.method_list as Array).append(
					{
						_class_name = v.identity.name.to_pascal_case(),
						categories = categories
					}
				)

	if not (all_scripts.method_list as Array).is_empty():
		(dt.categories as Array).append(all_scripts)

	# categories
	# TODO

	return dt


func check_dependencies(_updated_script_id: StringName) -> Array[StringName]:
	var scripts_to_recompile: Array[StringName] = []
	var updated_ast: ProjectAST = ast_list.get(_updated_script_id)
	

	if not updated_ast:
		return []
		
	for script_id: StringName in ast_list:
		if script_id == _updated_script_id:
			continue
			
		var ast: ProjectAST = ast_list[script_id]

		if not ast.identity or not ast.identity.detailed_deps.has(_updated_script_id):
			if ast.identity and ast.identity.deps.has(_updated_script_id):
				scripts_to_recompile.append(script_id)
			continue
			
		var deps: Array = ast.identity.detailed_deps[_updated_script_id]
		if _has_dependency_changed(deps, updated_ast):
			scripts_to_recompile.append(script_id)
			
	return scripts_to_recompile


func _has_dependency_changed(_deps: Array, _updated_ast: ProjectAST) -> bool:
	for dep: Dictionary in _deps:
		var changed: bool = true
		
		if not dep.has('hash'):
			return true

		match dep.type:
			HenEnums.DependencyType.VAR:
				for v: HenSaveVar in _updated_ast.variables:
					if v.id == dep.id:
						if HenUtils.get_dependency_hash(v) == dep.hash:
							changed = false
						break
		
		if changed:
			return true
			
	return false


func update_project_data(_id: StringName) -> void:
	_map_project_data(_id)


# builds ast from in-memory save data, no disk I/O
func update_project_data_from_save(_id: StringName, _save_data: HenSaveData) -> void:
	var ast: ProjectAST = ProjectAST.new()
	ast.identity = _save_data.identity
	ast.variables = _save_data.variables
	ast.states = _save_data.states
	ast_list.set(_id, ast)