@tool
class_name HenSaveMacro extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_inputs: Array[HenSaveFlowParam]
@export var flow_outputs: Array[HenSaveFlowParam]
@export var script_path: String
@export var is_script_macro: bool = false
# presentation, mirroring the native_items vocabulary: icon name + category color
@export var icon: String
@export var color: String
# one-line documentation shown as a tooltip on hover
@export var description: String
# folder the definition lives in; empty means uncategorized
@export var category: String
# lifecycle phase a new action of this macro lands on; empty picks it from the
# declared flow inputs
@export var default_phase: StringName
# native classes this macro serves; empty means every class
@export var target_classes: Array[StringName]
# the action owns a nested action list run per iteration (a loop)
@export var has_body: bool


# a macro is offered to a script when its base inherits from one of the targets
func serves_class(_class: StringName) -> bool:
	if target_classes.is_empty() or not ClassDB.class_exists(_class):
		return true

	for target: StringName in target_classes:
		if ClassDB.class_exists(target) and ClassDB.is_parent_class(_class, target):
			return true

	return false


static func create() -> HenSaveMacro:
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	macro.name = macro.get_new_name()

	var route: HenRouteData = macro.create_route(HenRouter.ROUTE_TYPE.MACRO)

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'input',
		type = HenVirtualCNode.Type.MACRO_INPUT,
		sub_type = HenVirtualCNode.SubType.MACRO_INPUT,
		route = route,
		position = Vector2.ZERO,
		res_data = macro.get_res_data(HenSideBar.AddType.MACRO),
		can_delete = false
	})

	HenVirtualCNode.instantiate_virtual_cnode({
		name = 'output',
		type = HenVirtualCNode.Type.MACRO_OUTPUT,
		sub_type = HenVirtualCNode.SubType.MACRO_OUTPUT,
		route = route,
		position = Vector2(400, 0),
		res_data = macro.get_res_data(HenSideBar.AddType.MACRO),
		can_delete = false
	})

	return macro


func get_new_name() -> String:
	return 'macro_' + str(id)


func get_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			for param: HenSaveParam in outputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.MACRO, HenVirtualCNode.SubType.SCRIPT_MACRO:
			for param: HenSaveParam in inputs:
				arr.append(param.get_data())

	return arr


func get_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.MACRO_INPUT:
			for param: HenSaveParam in inputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.MACRO, HenVirtualCNode.SubType.SCRIPT_MACRO:
			for param: HenSaveParam in outputs:
				arr.append(param.get_data())

	return arr


func get_flow_inputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.MACRO_OUTPUT:
			for param: HenSaveParam in flow_outputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.MACRO, HenVirtualCNode.SubType.SCRIPT_MACRO:
			for param: HenSaveParam in flow_inputs:
				arr.append(param.get_data())

	return arr


func get_flow_outputs(_type: HenVirtualCNode.SubType) -> Array[Dictionary]:
	var arr: Array[Dictionary] = []

	match _type:
		HenVirtualCNode.SubType.MACRO_INPUT:
			for param: HenSaveParam in flow_inputs:
				arr.append(param.get_data())
		HenVirtualCNode.SubType.MACRO, HenVirtualCNode.SubType.SCRIPT_MACRO:
			for param: HenSaveParam in flow_outputs:
				arr.append(param.get_data())

	return arr


func get_cnode_data(_save_data_id: StringName, _from_another_script: bool = false) -> Dictionary:
	var router: HenRouter = Engine.get_singleton(&'Router')

	return {
			name = name,
			type = HenVirtualCNode.Type.MACRO,
			sub_type = HenVirtualCNode.SubType.SCRIPT_MACRO if is_script_macro else HenVirtualCNode.SubType.MACRO,
			route = router.current_route,
			res_data = get_res_data(HenSideBar.AddType.MACRO, _save_data_id)
	}