@tool
class_name HenVCInOutData extends Object

var id: int = HenGlobal.get_new_node_counter()
var name: String
var type: StringName: set = _on_change_type
var sub_type: StringName
var category: StringName
var is_ref: bool
var code_value: String
var value: Variant
var data: Variant
var is_prop: bool
var is_static: bool
var ref: Object
var ref_change_rule: RefChangeRule
var from_id: int = -1

signal update_changes
signal moved
signal deleted
signal type_changed

enum RefChangeRule {
    NONE = 0,
    TYPE_CHANGE = 1,
    VALUE_CODE_VALUE_CHANGE = 2,
    IS_PROP = 3
}

func _init(_data: Dictionary) -> void:
    name = _data.name
    type = _data.type

    if _data.has('from_id'): from_id = _data.from_id
    if _data.has('id'): id = _data.id
    if _data.has('sub_type'): sub_type = _data.sub_type
    if _data.has('category'): category = _data.category
    if _data.has('is_ref'): is_ref = _data.is_ref
    if _data.has('code_value'): code_value = _data.code_value
    if _data.has('value'): value = _data.value
    if _data.has('data'): data = _data.data
    if _data.has('is_prop'): is_prop = _data.is_prop
    if _data.has('is_static'): is_static = _data.is_static
    if _data.has('ref'): set_ref(_data.ref, _data.ref_change_rule if _data.has('ref_change_rule') else RefChangeRule.NONE)


func _on_change_type(_type: StringName) -> void:
    type_changed.emit(type, _type, self)
    type = _type


func set_ref(_ref, _ref_change_rule: RefChangeRule = RefChangeRule.NONE) -> void:
    ref = _ref
    ref_change_rule = _ref_change_rule

    # when param is moved
    if ref.has_signal('moved') and not ref.is_connected('moved', _on_move):
        ref.moved.connect(_on_move)

    if ref.has_signal('deleted') and not ref.is_connected('deleted', _on_delete):
        if not ref is HenVarData:
            ref.deleted.connect(_on_delete)

    if _ref.has_signal('data_changed') and not ref.is_connected('data_changed', on_data_changed):
        _ref.data_changed.connect(on_data_changed)
    
    update_changes.emit()

func _on_move(_is_input: bool, _pos: int) -> void:
    moved.emit(_is_input, _pos, self)

func _on_delete(_is_input: bool) -> void:
    deleted.emit(_is_input, self)

func remove_ref() -> void:
    if ref:
        for signal_connetion: Dictionary in ref.get_signal_connection_list('data_changed'):
            signal_connetion.signal.disconnect(signal_connetion.callable)
    
    ref_change_rule = RefChangeRule.NONE
    update_changes.emit()

func on_data_changed(_name: String, _value) -> void:
    if ref_change_rule != RefChangeRule.NONE:
        match ref_change_rule:
            RefChangeRule.TYPE_CHANGE:
                if _name != 'type':
                    return
            RefChangeRule.VALUE_CODE_VALUE_CHANGE:
                if not ['value', 'code_value'].has(_name):
                    return
            RefChangeRule.IS_PROP:
                if _name == 'type':
                    # if new type is diffent, reset input
                    if not HenUtils.is_type_relation_valid(_value, type):
                    # if _value != 'Variant' and type != 'Variant' and _value != type:
                        reset_input_value()
                        remove_ref()
                        return
                
                if not ['value', 'code_value'].has(_name):
                    return
    
    set(_name, _value)

    if sub_type != '@dropdown':
        match _name:
            'type':
                reset_input_value()

    update_changes.emit()


func get_save() -> Dictionary:
    var dt: Dictionary = {
        id = id,
        name = name,
        type = type
    }

    if from_id > -1: dt.from_id = from_id
    if sub_type: dt.sub_type = sub_type
    if category: dt.category = category
    if is_ref: dt.is_ref = is_ref
    if code_value: dt.code_value = code_value
    if value: dt.value = value
    if data: dt.data = data
    if is_prop: dt.is_prop = is_prop
    if is_static: dt.is_static = is_static
    if ref: dt.ref_id = ref.id
    if ref_change_rule != RefChangeRule.NONE: dt.ref_change_rule = int(ref_change_rule)

    return dt


func reset_input_value() -> void:
    category = &'default_value'
    is_prop = false

    if HenGlobal.script_config and HenGlobal.script_config.type == type:
        code_value = '_ref.'
        is_ref = true
        return
    
    match type:
        'String', 'NodePath', 'StringName':
            code_value = '""'
        'int':
            code_value = '0'
        'float':
            code_value = '0.'
        'Vector2':
            code_value = 'Vector2(0, 0)'
        'bool':
            code_value = 'false'
        'Variant':
            code_value = 'null'
        _:
            if HenEnums.VARIANT_TYPES.has(type):
                code_value = type + '()'
            elif ClassDB.can_instantiate(type):
                code_value = type + '.new()'

    match type:
        'String', 'NodePath', 'StringName':
            value = ''
        _:
            value = code_value
