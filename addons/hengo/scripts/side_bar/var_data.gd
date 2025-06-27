class_name HenVarData extends RefCounted

var id: int = HenGlobal.get_new_node_counter()
var name: String = 'var ' + str(Time.get_ticks_usec()): set = on_change_name
var type: StringName = &'Variant': set = on_change_type
var local_ref: RefCounted
var export: bool = false

# used in inOut virtual cnode
signal data_changed(_property: String, _value)
signal deleted(_deleted: bool)

func on_change_type(_type: StringName) -> void:
    type = _type
    data_changed.emit('type', _type)

func on_change_name(_name: String) -> void:
    name = _name
    data_changed.emit('name', _name)

func get_save() -> Dictionary:
    return {
        id = id,
        name = name,
        type = type,
        export = export
    }

func load_save(_data: Dictionary) -> void:
    id = _data.id
    name = _data.name
    type = _data.type
    export = _data.export

    HenGlobal.SIDE_BAR_LIST_CACHE[id] = self

func delete() -> void:
    var item_cache: HenSideBar.DeleteItemCache = HenSideBar.DeleteItemCache.new(self, HenGlobal.SIDE_BAR_LIST.var_list if not local_ref else local_ref.get(&'local_vars'))

    HenGlobal.history.create_action('Delete Variable')
    HenGlobal.history.add_do_method(item_cache.remove)
    HenGlobal.history.add_undo_reference(item_cache)
    HenGlobal.history.add_undo_method(item_cache.add)
    HenGlobal.history.commit_action()

    HenGlobal.GENERAL_POPUP.get_parent().hide_popup()


func get_inspector_array_list(_is_local: bool = false) -> Array:
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
            name = 'type',
            type = &'@dropdown',
            value = type,
            category = 'all_classes',
            ref = self
        })
    ] + ([
        HenInspector.InspectorItem.new({
            name = 'export',
            type = &'bool',
            value = export ,
            ref = self
        }),
    ] if not _is_local else [])
