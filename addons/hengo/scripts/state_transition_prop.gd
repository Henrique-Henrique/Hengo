@tool
class_name HenStateTransitionProp extends HBoxContainer

var flow_connection_data: HenVirtualCNode.FlowConnectionData
var virtual_state: HenVirtualCNode

func _ready() -> void:
	get_node('String').value_changed.connect(_on_change_name)


func _on_change_name(_name: String) -> void:
	flow_connection_data.name = _name
	virtual_state.update()

func change_name(_name: String) -> void:
	get_node('String').text = _name