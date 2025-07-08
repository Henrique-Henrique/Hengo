class_name HenMacroData extends RefCounted

signal name_changed
signal flow_added(_is_input: bool, _data: Dictionary)
signal in_out_added(_is_input: bool, _data: Dictionary)
signal deleted(_deleted: bool)

var id: int = HenGlobal.get_new_node_counter()
var name: String = 'macro ' + str(Time.get_ticks_usec()): set = on_change_name
var route: Dictionary
var virtual_cnode_list: Array = []
var inputs: Array
var outputs: Array
var inputs_value: Array
var outputs_value: Array
var input_ref: HenVirtualCNode
var output_ref: HenVirtualCNode
var local_vars: Array
var cnode_list_to_load: Array

class MacroInOut:
    var id: int = HenGlobal.get_new_node_counter()
    var name: String: set = on_change_name

    signal data_changed(_property: String, _value)
    signal moved
    signal deleted

    func on_change_name(_name: String) -> void:
        name = _name
        data_changed.emit('name', _name)

    func get_data() -> Dictionary:
        return {id = id, name = name, ref = self}
    
    func get_save() -> Dictionary:
        return {
            name = name,
            id = id
        }
    
    func load_save(_data: Dictionary) -> void:
        id = _data.id
        name = _data.name
        
        HenGlobal.SIDE_BAR_LIST_CACHE[id] = self


func _init(_load_vc: bool = true) -> void:
    route = {
        name = name,
        type = HenRouter.ROUTE_TYPE.MACRO,
        id = HenUtilsName.get_unique_name(),
        ref = self
    }

    HenRouter.line_route_reference[route.id] = []
    HenRouter.comment_reference[route.id] = []

    if _load_vc:
        HenVirtualCNode.instantiate_virtual_cnode({
            name = 'input',
            type = HenVirtualCNode.Type.MACRO_INPUT,
            sub_type = HenVirtualCNode.SubType.MACRO_INPUT,
            route = route,
            position = Vector2.ZERO,
            ref = self,
            can_delete = false
        })

        HenVirtualCNode.instantiate_virtual_cnode({
            name = 'output',
            type = HenVirtualCNode.Type.MACRO_OUTPUT,
            sub_type = HenVirtualCNode.SubType.MACRO_OUTPUT,
            route = route,
            position = Vector2(400, 0),
            ref = self,
            can_delete = false
        })


func on_change_name(_name: String) -> void:
    name = _name
    name_changed.emit(_name)
    HenGlobal.SIDE_BAR_LIST.list_changed.emit()


func create_flow(_type: HenSideBar.ParamType, _custom_id: int = -1) -> MacroInOut:
    var flow: MacroInOut = MacroInOut.new()

    if _custom_id >= 0:
        flow.id = _custom_id

    match _type:
        HenSideBar.ParamType.INPUT:
            flow.name = 'Flow ' + str(inputs.size())
            inputs.append(flow)
            flow_added.emit(true, flow.get_data())
        HenSideBar.ParamType.OUTPUT:
            flow.name = 'Flow ' + str(outputs.size())
            outputs.append(flow)
            flow_added.emit(false, flow.get_data())
    
    return flow


func create_param(_type: HenSideBar.ParamType) -> HenParamData:
    var in_out: HenParamData = HenParamData.new()

    match _type:
        HenSideBar.ParamType.INPUT:
            in_out.name = 'name ' + str(inputs_value.size())
            inputs_value.append(in_out)
            in_out_added.emit(true, in_out.get_data_with_id())
        HenSideBar.ParamType.OUTPUT:
            in_out.name = 'name ' + str(outputs_value.size())
            outputs_value.append(in_out)
            in_out_added.emit(false, in_out.get_data_with_id())
        
    return in_out
    

func move_param(_direction: HenArrayItem.ArrayMove, _ref: HenParamData, _type: HenSideBar.ParamType) -> void:
    var can_move: bool = false
    var arr: Array

    match _type:
        HenSideBar.ParamType.INPUT:
            arr = inputs_value
        HenSideBar.ParamType.OUTPUT:
            arr = outputs_value

    match _direction:
        HenArrayItem.ArrayMove.UP:
            can_move = HenUtils.move_array_item(arr, _ref, 1)
        HenArrayItem.ArrayMove.DOWN:
            can_move = HenUtils.move_array_item(arr, _ref, -1)

    if can_move: _ref.moved.emit(_type == HenSideBar.ParamType.INPUT, arr.find(_ref))


func delete_param(_ref: HenParamData, _type: HenSideBar.ParamType) -> void:
    match _type:
        HenSideBar.ParamType.INPUT:
            inputs_value.erase(_ref)
        HenSideBar.ParamType.OUTPUT:
            outputs_value.erase(_ref)

    _ref.deleted.emit(_type == HenSideBar.ParamType.INPUT)


func move_flow(_direction: HenArrayItem.ArrayMove, _ref: MacroInOut, _type: HenSideBar.ParamType) -> void:
    var can_move: bool = false
    var arr: Array

    match _type:
        HenSideBar.ParamType.INPUT:
            arr = inputs
        HenSideBar.ParamType.OUTPUT:
            arr = outputs

    match _direction:
        HenArrayItem.ArrayMove.UP:
            can_move = HenUtils.move_array_item(arr, _ref, 1)
        HenArrayItem.ArrayMove.DOWN:
            can_move = HenUtils.move_array_item(arr, _ref, -1)

    if can_move: _ref.moved.emit(arr.find(_ref))


func delete_flow(_ref: MacroInOut, _type: HenSideBar.ParamType) -> void:
    match _type:
        HenSideBar.ParamType.INPUT:
            inputs.erase(_ref)
        HenSideBar.ParamType.OUTPUT:
            outputs.erase(_ref)

    _ref.deleted.emit()


func get_cnode_data() -> Dictionary:
    return {
            name = name,
            type = HenVirtualCNode.Type.MACRO,
            sub_type = HenVirtualCNode.SubType.MACRO,
            inputs = inputs_value.map(func(x: HenParamData) -> Dictionary: return x.get_data_with_id()),
            outputs = outputs_value.map(func(x: HenParamData) -> Dictionary: return x.get_data_with_id()),
            route = HenRouter.current_route,
            ref = self
    }

func delete() -> void:
    var item_cache: HenSideBar.DeleteItemCache = HenSideBar.DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.macro_list)

    HenGlobal.history.create_action('Delete Macro')
    HenGlobal.history.add_do_method(item_cache.remove)
    HenGlobal.history.add_undo_reference(item_cache)
    HenGlobal.history.add_undo_method(item_cache.add)
    HenGlobal.history.commit_action()

    HenGlobal.GENERAL_POPUP.get_parent().hide_popup()


func get_inspector_array_list() -> Array[HenPropEditor.Prop]:
    return [
        HenPropEditor.Prop.new({
            name = 'name',
            type = HenPropEditor.Prop.Type.STRING,
            default_value = name,
            on_value_changed = on_change_name
        }),
        HenPropEditor.Prop.new({
            name = 'Flow Input',
            type = HenPropEditor.Prop.Type.ARRAY,
            on_item_create = create_flow.bind(HenSideBar.ParamType.INPUT),
            prop_list = inputs.map(func(x: MacroInOut) -> HenPropEditor.Prop: return HenPropEditor.Prop.new({
                name = 'name',
                type = HenPropEditor.Prop.Type.STRING,
                default_value = x.name,
                on_value_changed = x.on_change_name,
                on_item_delete = delete_flow.bind(x, HenSideBar.ParamType.INPUT),
                on_item_move = move_flow.bind(x, HenSideBar.ParamType.INPUT),
            })),
        }),
        HenPropEditor.Prop.new({
            name = 'Flow Output',
            type = HenPropEditor.Prop.Type.ARRAY,
            on_item_create = create_flow.bind(HenSideBar.ParamType.OUTPUT),
            prop_list = outputs.map(func(x: MacroInOut) -> HenPropEditor.Prop: return HenPropEditor.Prop.new({
                name = 'name',
                type = HenPropEditor.Prop.Type.STRING,
                default_value = x.name,
                on_value_changed = x.on_change_name,
                on_item_delete = delete_flow.bind(x, HenSideBar.ParamType.OUTPUT),
                on_item_move = move_flow.bind(x, HenSideBar.ParamType.OUTPUT),
            })),
        }),
        HenPropEditor.Prop.new({
            name = 'Inputs',
            type = HenPropEditor.Prop.Type.ARRAY,
            on_item_create = create_param.bind(HenSideBar.ParamType.INPUT),
            prop_list = inputs_value.map(func(x: HenParamData) -> HenPropEditor.Prop: return HenPropEditor.Prop.new({
                name = 'name',
                type = HenPropEditor.Prop.Type.STRING,
                default_value = x.name,
                on_value_changed = x.on_change_name,
                on_item_delete = delete_param.bind(x, HenSideBar.ParamType.INPUT),
                on_item_move = move_param.bind(x, HenSideBar.ParamType.INPUT),
            })),
        }),
        HenPropEditor.Prop.new({
            name = 'Outputs',
            type = HenPropEditor.Prop.Type.ARRAY,
            on_item_create = create_param.bind(HenSideBar.ParamType.OUTPUT),
            prop_list = outputs_value.map(func(x: HenParamData) -> HenPropEditor.Prop: return HenPropEditor.Prop.new({
                name = 'name',
                type = HenPropEditor.Prop.Type.STRING,
                default_value = x.name,
                on_value_changed = x.on_change_name,
                on_item_delete = delete_param.bind(x, HenSideBar.ParamType.OUTPUT),
                on_item_move = move_param.bind(x, HenSideBar.ParamType.OUTPUT),
            })),
        }),
    ] as Array[HenPropEditor.Prop]

    
func get_save() -> Dictionary:
    return {
        id = id,
        name = name,
        inputs = inputs.map(func(x: MacroInOut) -> Dictionary: return x.get_save()),
        outputs = outputs.map(func(x: MacroInOut) -> Dictionary: return x.get_save()),
        inputs_value = inputs_value.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
        outputs_value = outputs_value.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
        virtual_cnode_list = virtual_cnode_list.map(func(x: HenVirtualCNode) -> Dictionary: return x.get_save()),
        local_vars = local_vars.map(func(x: HenVarData) -> Dictionary: return x.get_save()),
    }

func load_save(_data: Dictionary) -> void:
    name = _data.name
    id = _data.id

    HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

    for item_data: Dictionary in _data.inputs:
        var item: MacroInOut = MacroInOut.new()
        item.load_save(item_data)
        inputs.append(item)

    for item_data: Dictionary in _data.outputs:
        var item: MacroInOut = MacroInOut.new()
        item.load_save(item_data)
        outputs.append(item)
    
    for item_data: Dictionary in _data.local_vars:
        var item: HenVarData = HenVarData.new()
        item.local_ref = self
        item.load_save(item_data)
        local_vars.append(item)

    for item_data: Dictionary in _data.inputs_value:
        var item: HenParamData = HenParamData.new()
        item.load_save(item_data)
        inputs_value.append(item)

    for item_data: Dictionary in _data.outputs_value:
        var item: HenParamData = HenParamData.new()
        item.load_save(item_data)
        outputs_value.append(item)

    cnode_list_to_load = _data.virtual_cnode_list
