extends Resource
class_name HengoStateController

var parent: Node
var connections: Dictionary = {}
var signal_params: Dictionary = {}

var states: Dictionary = {}
var current_state

func set_states(_states: Dictionary) -> void:
	states = _states

func change_state(_state: String) -> void:
	print('S -> ', _state)
	
	var state = states[_state]
	current_state = state
	state.call('enter')

func static_process(_delta: float) -> void:
	if current_state:
		current_state.update(_delta)

func static_physics_process(_delta: float) -> void:
	if current_state:
		current_state.physics(_delta)
