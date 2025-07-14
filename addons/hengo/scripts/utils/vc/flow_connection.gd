@tool
class_name HenVCFlowConnection extends Object

var name: String: set = _on_change_name
var id: int = -1
var ref: Object

signal update_changes
signal data_changed
signal moved
signal deleted

func _on_change_name(_name: String) -> void:
    name = _name
    data_changed.emit('value', _name)
    data_changed.emit('code_value', _name)

func _init(_data: Dictionary = {}) -> void:
    name = _data.name if _data.has('name') else ''
    id = _data.id if _data.has('id') else HenGlobal.get_new_node_counter()

    if _data.has('ref'): set_ref(_data.ref)

func set_ref(_ref) -> void:
    ref = _ref
    # when param is moved
    if ref.has_signal('moved'):
        ref.moved.connect(_on_move)

    if ref.has_signal('deleted'):
        ref.deleted.connect(_on_delete)
    
    if _ref.has_signal('data_changed'):
        _ref.data_changed.connect(on_data_changed)


func _on_move(_pos: int) -> void:
    moved.emit(self is HenVCFromFlowConnectionData, _pos, self)

func _on_delete() -> void:
    deleted.emit(self is HenVCFlowConnectionData, self)

func on_data_changed(_name: String, _value) -> void:
    set(_name, _value)
    update_changes.emit()
