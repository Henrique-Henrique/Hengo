class_name HengoStateController

var parent
var connections: Dictionary = {}
var signal_params: Dictionary = {}

var states: Dictionary = {}
var current_state: HengoState


func _init(_ref) -> void:
	parent = _ref


func set_states(_states: Dictionary) -> void:
	states = _states


func change_state(_state: String, ..._args) -> void:
	if not states.has(_state):
		print('State not found: ', _state)
		return
		
	if current_state:
		current_state.exit()
		
	var state: HengoState = states[_state]
	current_state = state

	if OS.is_debug_build() and EngineDebugger.is_active():
		if parent and parent.get_instance_id() == HengoDebugger.target_instance_id:
			EngineDebugger.send_message('hengo:state', [_state])

	if state.has_method(&'enter'):
		state.callv(&'enter', _args)


func static_process(_delta: float) -> void:
	if current_state:
		current_state.update(_delta)


func static_physics_process(_delta: float) -> void:
	if current_state:
		current_state.physics(_delta)
