@tool
class_name HenVirtualCNodeReference extends HenVirtualCNodeIdentity

@export var res_data: Dictionary

var cnode_instance: HenCnode = null


func get_res() -> Resource:
	if res_data.has('id') and res_data.has('type'):
		var global: HenGlobal = Engine.get_singleton(&'Global')
		var list: Array = []

		if res_data.has('save_data_id'):
			var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
			if map_deps.ast_list.has(res_data.save_data_id):
				var ast = map_deps.ast_list[res_data.save_data_id]
				
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
		else:
			match res_data.type:
				HenSideBar.AddType.VAR:
					list = global.SAVE_DATA.variables
				HenSideBar.AddType.FUNC:
					list = global.SAVE_DATA.functions
				HenSideBar.AddType.SIGNAL_CALLBACK:
					list = global.SAVE_DATA.signals_callback
				HenSideBar.AddType.SIGNAL:
					list = global.SAVE_DATA.signals
				HenSideBar.AddType.MACRO:
					list = global.SAVE_DATA.macros
		
		for item in list:
			if item.id == res_data.id:
				return item
				
	return null