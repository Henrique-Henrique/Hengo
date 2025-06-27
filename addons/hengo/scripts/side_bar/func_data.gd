class_name HenFuncData extends RefCounted

signal name_changed
signal in_out_added(_is_input: bool, _data: Dictionary)
signal deleted(_deleted: bool)

var id: int = HenGlobal.get_new_node_counter()
var name: String = 'func ' + str(Time.get_ticks_usec()): set = on_change_name
var inputs: Array
var outputs: Array
var route: Dictionary
var virtual_cnode_list: Array
var input_ref: HenVirtualCNode
var output_ref: HenVirtualCNode
var local_vars: Array
var cnode_list_to_load: Array

func _init(_load_vc: bool = true) -> void:
    route = {
        name = name,
        type = HenRouter.ROUTE_TYPE.FUNC,
        id = HenUtilsName.get_unique_name(),
        ref = self
    }

    HenRouter.line_route_reference[route.id] = []
    HenRouter.comment_reference[route.id] = []

    if _load_vc:
        HenVirtualCNode.instantiate_virtual_cnode({
            name = 'input',
            sub_type = HenVirtualCNode.SubType.FUNC_INPUT,
            outputs = outputs.map(func(x: HenParamData) -> Dictionary: return x.get_data()),
            route = route,
            position = Vector2.ZERO,
            ref = self,
            can_delete = false
        })

        HenVirtualCNode.instantiate_virtual_cnode({
            name = 'output',
            sub_type = HenVirtualCNode.SubType.FUNC_OUTPUT,
            route = route,
            inputs = inputs.map(func(x: HenParamData) -> Dictionary: return x.get_data()),
            position = Vector2(400, 0),
            ref = self,
            can_delete = false
        })

func on_change_name(_name: String) -> void:
    name = _name
    name_changed.emit(_name)

func create_param(_type: HenSideBar.ParamType) -> void:
    var in_out: HenParamData = HenParamData.new()

    match _type:
        HenSideBar.ParamType.INPUT:
            inputs.append(in_out)
            in_out_added.emit(true, in_out.get_data())
        HenSideBar.ParamType.OUTPUT:
            outputs.append(in_out)
            in_out_added.emit(false, in_out.get_data())
    

func move_param(_ref: HenParamData, _type: HenSideBar.ParamType) -> void:
    match _type:
        HenSideBar.ParamType.INPUT:
            _ref.moved.emit(true, inputs.find(_ref))
        HenSideBar.ParamType.OUTPUT:
            _ref.moved.emit(false, outputs.find(_ref))


func delete_param(_ref: HenParamData, _type: HenSideBar.ParamType) -> void:
    _ref.deleted.emit(_type == HenSideBar.ParamType.INPUT)


func get_cnode_data() -> Dictionary:
    return {
            name = name,
            fantasy_name = 'Func -> ' + name,
            sub_type = HenVirtualCNode.SubType.USER_FUNC,
            inputs = inputs.map(func(x: HenParamData) -> Dictionary: return x.get_data()),
            outputs = outputs.map(func(x: HenParamData) -> Dictionary: return x.get_data()),
            route = HenRouter.current_route,
            ref = self
    }

func get_save() -> Dictionary:
    return {
        id = id,
        name = name,
        inputs = inputs.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
        outputs = outputs.map(func(x: HenParamData) -> Dictionary: return x.get_save()),
        virtual_cnode_list = virtual_cnode_list.map(func(x: HenVirtualCNode) -> Dictionary: return x.get_save()),
        local_vars = local_vars.map(func(x: HenVarData) -> Dictionary: return x.get_save()),
    }

func load_save(_data: Dictionary) -> void:
    name = _data.name
    id = _data.id

    HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

    for item_data: Dictionary in _data.inputs:
        var item: HenParamData = HenParamData.new()
        item.load_save(item_data)
        inputs.append(item)

    for item_data: Dictionary in _data.outputs:
        var item: HenParamData = HenParamData.new()
        item.load_save(item_data)
        outputs.append(item)
    
    for item_data: Dictionary in _data.local_vars:
        var item: HenVarData = HenVarData.new()
        item.local_ref = self
        item.load_save(item_data)
        local_vars.append(item)

    cnode_list_to_load = _data.virtual_cnode_list


func delete() -> void:
    var item_cache: HenSideBar.DeleteItemCache = HenSideBar.DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.func_list)

    HenGlobal.history.create_action('Delete Function')
    HenGlobal.history.add_do_method(item_cache.remove)
    HenGlobal.history.add_undo_reference(item_cache)
    HenGlobal.history.add_undo_method(item_cache.add)
    HenGlobal.history.commit_action()

    HenGlobal.GENERAL_POPUP.get_parent().hide_popup()


func get_inspector_array_list() -> Array:
    return [
        HenInspector.InspectorItem.new({
            type = &'@controls',
            ref = self
        }),
        HenInspector.InspectorItem.new({
            name = 'name',
            type = &'String',
            value = name,
            ref = self
        }),
        HenInspector.InspectorItem.new({
            name = 'inputs',
            type = &'Array',
            value = inputs,
            max_size = 5,
            item_creation_callback = create_param.bind(HenSideBar.ParamType.INPUT),
            item_move_callback = move_param.bind(HenSideBar.ParamType.INPUT),
            item_delete_callback = delete_param.bind(HenSideBar.ParamType.INPUT),
            field = {name = '', type = '@Param'}
        }),
        HenInspector.InspectorItem.new({
            name = 'outputs',
            type = &'Array',
            value = outputs,
            max_size = 5,
            item_creation_callback = create_param.bind(HenSideBar.ParamType.OUTPUT),
            item_move_callback = move_param.bind(HenSideBar.ParamType.OUTPUT),
            item_delete_callback = delete_param.bind(HenSideBar.ParamType.OUTPUT),
            field = {name = '', type = '@Param'}
        })
    ]
