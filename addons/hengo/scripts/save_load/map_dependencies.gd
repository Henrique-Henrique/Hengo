@tool
class_name HenMapDependencies extends Node

var ast_list: Dictionary[StringName, ProjectAST] = {}

class ProjectAST:
	var identity: HenSaveDataIdentity
	var macros: Array[HenSaveMacro]
	var variables: Array[HenSaveVar]
	var functions: Array[HenSaveFunc]
	var signals: Array[HenSaveSignal]
	var signals_callback: Array[HenSaveSignalCallback]


# iterates over project directories to build the dependency map
func start_map() -> void:
	var start: int = Time.get_ticks_usec()
	ast_list.clear()
	var root_dir: DirAccess = DirAccess.open(HenEnums.HENGO_SAVE_PATH)
	
	if not root_dir:
		push_error('Failed to access save path.')
		return

	for id_dir: String in root_dir.get_directories():
		_map_project_data(id_dir)

	var end: int = Time.get_ticks_usec()

	print('Project mapped in ', (end - start) / 1000., 'ms')
	get_real_ast_size()


# this is a test, I don't know if its works properly
func get_real_ast_size() -> void:
	var total_bytes: int = 0
	
	# loop through all projects in the dictionary
	for id: StringName in ast_list:
		var project: ProjectAST = ast_list[id]
		
		var all_lists: Array = [
			project.variables,
			project.functions,
			project.signals,
			project.signals_callback,
			project.macros
		]
		
		for list: Array in all_lists:
			for res: Resource in list:
				if res:
					# duplicate to detach from disk and force data serialization
					var temp_res: Resource = res.duplicate(true)
					temp_res.resource_path = ''
					total_bytes += var_to_bytes(temp_res).size()

	print('Real Data Payload: ', snappedf(total_bytes / 1024.0, 0.01), ' KB')


# iterates through all sidebar types to load resources into ast
func _map_project_data(_id: StringName) -> void:
	var ast: ProjectAST = ProjectAST.new()

	for type: int in HenSideBar.SideBarItem.values():
		var path: String = HenUtils.get_side_bar_item_path(_id, type)
		
		if not DirAccess.dir_exists_absolute(path):
			print(path)
			continue
		
		var dir: DirAccess = DirAccess.open(path)
		var res_identity: HenSaveDataIdentity = load(HenEnums.HENGO_SAVE_PATH.path_join(_id).path_join('identity.tres'))

		if res_identity:
			ast.identity = res_identity
		else:
			push_error('Error loading AST identity')

		for file: String in dir.get_files():
			if file.get_extension() == 'tres':
				var res: Resource = load(path.path_join(file))
				
				# match type to append resource to the correct ast array
				match type:
					HenSideBar.SideBarItem.VARIABLES:
						ast.variables.append(res)
					HenSideBar.SideBarItem.FUNCTIONS:
						ast.functions.append(res)
					HenSideBar.SideBarItem.SIGNALS:
						ast.signals.append(res)
					HenSideBar.SideBarItem.SIGNALS_CALLBACK:
						ast.signals_callback.append(res)
					HenSideBar.SideBarItem.MACROS:
						ast.macros.append(res)

	ast_list.set(_id, ast)


func get_code_search_list() -> Dictionary:
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
			
			(all_scripts.method_list as Array).append(
				{
					_class_name = v.identity.name.to_pascal_case(),
					categories = api.get_side_bar_categories(v, true)
				}
			)

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
			HenEnums.DependencyType.FUNC:
				for f: HenSaveFunc in _updated_ast.functions:
					if f.id == dep.id:
						if HenUtils.get_dependency_hash(f) == dep.hash:
							changed = false
						break
			HenEnums.DependencyType.SIGNAL:
				for s: HenSaveSignal in _updated_ast.signals:
					if s.id == dep.id:
						if HenUtils.get_dependency_hash(s) == dep.hash:
							changed = false
						break
			HenEnums.DependencyType.MACRO:
				for m: HenSaveMacro in _updated_ast.macros:
					if m.id == dep.id:
						if HenUtils.get_dependency_hash(m) == dep.hash:
							changed = false
						break
		
		if changed:
			return true
			
	return false


func update_project_data(_id: StringName) -> void:
	_map_project_data(_id)