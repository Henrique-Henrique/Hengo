@tool
class_name HenSideBar extends PanelContainer

var list_data: SideBarList

@onready var name_label: Label = %Name
@onready var list: ItemList = %List

enum AddType {VAR, FUNC, SIGNAL}

const NAME = {
	AddType.VAR: 'Variables',
	AddType.FUNC: 'Functions',
	AddType.SIGNAL: 'Signals',
}

class SideBarList:
	var type: AddType

	var var_list: Array
	var func_list: Array

	signal list_changed

	func clear() -> void:
		var_list.clear()
		func_list.clear()

		list_changed.emit()

	func add() -> void:
		match type:
			AddType.FUNC:
				func_list.append(FuncData.new())
			
		list_changed.emit()

	func change(_type: AddType) -> void:
		type = _type
		list_changed.emit()

	func get_list_to_draw() -> Array:
		match type:
			AddType.FUNC:
				return func_list.map(func(x: FuncData): return {name = x.name})
			
		return []
	
	func on_click(_index: int) -> void:
		var inspector_item_arr: Array
		var name: String = ''

		match type:
			AddType.FUNC:
				var item: FuncData = func_list[_index]
				name = item.name
				inspector_item_arr = [
					HenInspector.InspectorItem.new({
						name = 'name',
						type = &'String',
						value = item.name,
						ref = item
					}),
					HenInspector.InspectorItem.new({
						name = 'inputs',
						type = &'Array',
						value = item.inputs,
						item_creation_callback = item.create_param.bind(FuncData.ParamType.INPUT),
						field = {name = '', type = '@Param'}
					}),
					HenInspector.InspectorItem.new({
						name = 'outputs',
						type = &'Array',
						value = item.outputs,
						item_creation_callback = item.create_param.bind(FuncData.ParamType.OUTPUT),
						field = {name = '', type = '@Param'}
					})
				]


		var state_inspector: HenInspector = HenInspector.start(inspector_item_arr)

		state_inspector.item_changed.connect(_on_config_changed)

		HenGlobal.GENERAL_POPUP.get_parent().show_content(
			state_inspector,
			name,
			HenGlobal.CNODE_CONTAINER.get_global_mouse_position()
		)

	func _on_config_changed() -> void:
		list_changed.emit()


class FuncData:
	class Param:
		var name: String
		var type: String = &'Variant'

	var name: String = 'func ' + str(Time.get_ticks_usec())
	var inputs: Array
	var outputs: Array
	
	enum ParamType {INPUT, OUTPUT}

	func create_param(_type: ParamType) -> void:
		match _type:
			ParamType.INPUT:
				inputs.append(Param.new())
			ParamType.OUTPUT:
				outputs.append(Param.new())


func _ready() -> void:
	list_data = SideBarList.new()
	list_data.list_changed.connect(_on_list_changed)

	_on_change_list(AddType.VAR)

	HenGlobal.SIDE_BAR = self
	HenGlobal.SIDE_BAR_LIST = list_data

	(get_node('%Add') as Button).pressed.connect(_on_add)

	# change list
	(get_node('%Var') as Button).pressed.connect(_on_change_list.bind(AddType.VAR))
	(get_node('%Func') as Button).pressed.connect(_on_change_list.bind(AddType.FUNC))
	(get_node('%Signal') as Button).pressed.connect(_on_change_list.bind(AddType.SIGNAL))

	list.item_clicked.connect(_on_click)


func _on_click(_index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if _mouse_button_index == MOUSE_BUTTON_RIGHT:
		list_data.on_click(_index)


func update_list() -> void:
	list.clear()

	for item_data: Dictionary in HenGlobal.SIDE_BAR_LIST.get_list_to_draw():
		list.add_item(item_data.name)


func _on_add() -> void:
	HenGlobal.SIDE_BAR_LIST.add()


func _on_change_list(_type: AddType) -> void:
	HenGlobal.SIDE_BAR_LIST.change(_type)
	name_label.text = NAME[_type]


func _on_list_changed() -> void:
	update_list()