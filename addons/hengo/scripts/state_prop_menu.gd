@tool
class_name HenStatePropMenu extends PanelContainer

const TRANSITION_PROP = preload('res://addons/hengo/scenes/state_transition_prop.tscn')

var virtual_state: HenVirtualCNode
@onready var transition_container = get_node('%TransitionContainer')

func _ready() -> void:
	get_node('%StateName').value_changed.connect(_on_change_name)
	get_node('%Add').pressed.connect(_on_add)

	get_node('%StateName').text = virtual_state.name

	for connetion: HenVirtualCNode.FlowConnectionData in virtual_state.flow_connections:
		transition_container.add_child(_add_transition(connetion.name, connetion, virtual_state))


func _on_change_name(_name: String) -> void:
	virtual_state.name = _name
	virtual_state.update()


func _on_add() -> void:
	var flow_size: int = virtual_state.flow_connections.size()

	if flow_size >= 5: # TODO flow limit, make dynamic
		return

	var flow_name: String = 'Flow ' + str(flow_size)
	var flow_connetion_data: HenVirtualCNode.FlowConnectionData = HenVirtualCNode.FlowConnectionData.new(flow_name)

	transition_container.add_child(_add_transition(flow_name, flow_connetion_data, virtual_state))
	virtual_state.flow_connections.append(flow_connetion_data)
	virtual_state.update()


func _add_transition(_name: String, _ref: HenVirtualCNode.FlowConnectionData, _virtual_state: HenVirtualCNode) -> HenStateTransitionProp:
	var transition: HenStateTransitionProp = TRANSITION_PROP.instantiate()
	transition.virtual_state = _virtual_state
	transition.flow_connection_data = _ref
	transition.change_name(_name)
	return transition
