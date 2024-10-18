@tool
extends PanelContainer

# imports
const _State = preload('res://addons/hengo/scripts/state.gd')

var state: _State

# private
#
func _ready() -> void:
	get_node('%Add').pressed.connect(_on_add)
	get_node('%StateName').connect('value_changed', _name_change)


func _on_add() -> void:
	var _name: String = 'Transition ' + str(get_node('%TransitionContainer').get_child_count())
	var names = get_node('%TransitionContainer').get_children().map(func(x): return x.get_prop_name())
	
	if names.has(_name):
		_name = 'Transition ' + str(Time.get_ticks_msec())

	_add_transition(_name)


func _add_transition(_name: String = '', _ref = null) -> void:
	var transition = load('res://addons/hengo/scenes/state_transition_prop.tscn').instantiate()
	transition.set_prop_name(_name)

	if _ref == null:
		# TODO generate unique name when created
		var state_transition = state.add_transition(_name)
		transition.state_transition_ref = state_transition
	else:
		transition.state_transition_ref = _ref

	get_node('%TransitionContainer').add_child(transition)


func _name_change(_name: String) -> void:
	state.set_state_name(_name)


# public
#
func start_prop(_state: _State) -> void:
	state = _state

	get_node('%StateName').text = state.get_state_name()

	var transition_container = get_node('%TransitionContainer')
	# cleaning other
	for prop in transition_container.get_children():
		prop.queue_free()
	
	for transition in state.get_node('%TransitionContainer').get_children():
		_add_transition(transition.get_transition_name(), transition)