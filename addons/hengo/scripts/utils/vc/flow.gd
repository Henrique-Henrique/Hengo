@tool
class_name HenVCFlow extends RefCounted

var name: String: set = _on_change_name
var id: int = -1
var ref: RefCounted
var owner: WeakRef

signal update_changes
signal data_changed
signal moved
signal deleted

func _on_change_name(_name: String) -> void:
	name = _name
	data_changed.emit('value', _name)
	data_changed.emit('code_value', _name)

func _init(_owner: HenVirtualCNode, _data: Dictionary = {}) -> void:
	owner = weakref(_owner)
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


func get_owner() -> HenVirtualCNode:
	if not owner:
		return null
	
	return owner.get_ref()


func _on_move(_pos: int) -> void:
	moved.emit(self, _pos, self)


func _on_delete(_is_input: bool) -> void:
	deleted.emit(_is_input, self)


func on_data_changed(_name: String, _value) -> void:
	set(_name, _value)
	update_changes.emit()


func create_virtual_connection(_config: Dictionary) -> HenVCFlowConnectionReturn:
	return get_owner().add_flow_connection(
		id,
		_config.to_id,
		_config.to_cnode
	)


func on_create_connection_request() -> void:
	var connection: HenVCFlowConnectionReturn = create_virtual_connection(HenGlobal.flow_connection_to_data)
					
	if connection:
		HenGlobal.history.create_action('Add Connection')
		HenGlobal.history.add_do_method(connection.add)
		HenGlobal.history.add_do_reference(connection)
		HenGlobal.history.add_undo_method(connection.remove)
		HenGlobal.history.commit_action()
	

func on_flow_input_hover(_id: int) -> void:
	HenGlobal.flow_connection_to_data = {
		to_cnode = get_owner(),
		to_id = _id
	}
