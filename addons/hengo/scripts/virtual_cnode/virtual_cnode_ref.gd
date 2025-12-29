@tool
@abstract
class_name HenVirtualCNodeReference extends HenVirtualCNodeIdentity

@export var res_data: Dictionary

var cnode_instance: HenCnode = null


func get_res(_save_data: HenSaveData) -> Resource:
	if res_data.has('id') and res_data.has('type'):
		var list: Array = []

		if res_data.has('save_data_id'):
			var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
			
			if map_deps.ast_list.has(res_data.save_data_id):
				var ast: HenMapDependencies.ProjectAST = map_deps.ast_list[res_data.save_data_id]
				
				match res_data.type:
					HenSideBar.AddType.VAR:
						list = ast.variables
					HenSideBar.AddType.FUNC:
						list = ast.functions
					HenSideBar.AddType.SIGNAL_CALLBACK:
						list = ast.signals_callback
					HenSideBar.AddType.SIGNAL:
						list = ast.signals
					HenSideBar.AddType.MACRO:
						list = ast.macros
					HenSideBar.AddType.STATE:
						list = ast.states
		else:
			match res_data.type:
				HenSideBar.AddType.VAR:
					list = _save_data.variables
				HenSideBar.AddType.FUNC:
					list = _save_data.functions
				HenSideBar.AddType.SIGNAL_CALLBACK:
					list = _save_data.signals_callback
				HenSideBar.AddType.SIGNAL:
					list = _save_data.signals
				HenSideBar.AddType.MACRO:
					list = _save_data.macros
				HenSideBar.AddType.STATE:
					list = _save_data.states
		
		for item in list:
			if item.id == res_data.id:
				return item
		
	return null