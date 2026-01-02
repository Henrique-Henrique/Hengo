extends Resource
class_name HengoStateController

var parent: Node
var connections: Dictionary = {}
var signal_params: Dictionary = {}

var states: Dictionary = {}
var current_state: HengoState

func set_states(_states: Dictionary) -> void:
	states = _states

func change_state(_state: String, ..._args) -> void:
	if not states.has(_state):
		print('State not found: ', _state)
		return
		
	print('S -> ', _state)
	
	if current_state:
		current_state.exit()
		
	var state: HengoState = states[_state]
	current_state = state

	if state.has_method(&'enter'):
		state.callv(&'enter', _args)


func static_process(_delta: float) -> void:
	if current_state:
		current_state.update(_delta)


func static_physics_process(_delta: float) -> void:
	if current_state:
		current_state.physics(_delta)
