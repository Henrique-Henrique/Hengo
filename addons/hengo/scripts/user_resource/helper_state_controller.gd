class_name HengoStateController

var parent
var connections: Dictionary = {}
var signal_params: Dictionary = {}

var states: Dictionary = {}
var current_state: HengoState
# where change_state came from, so a state can hand control back. tracked apart
# from _last_debug_name, which change_sub_state also writes
var previous_state_name: String = ''
var _current_state_name: String = ''

var _script_id: String = ''
# deepest active state name (snake), kept so a freshly-set target can re-emit it
var _last_debug_name: String = ''


func _init(_ref) -> void:
	parent = _ref
	_script_id = HengoDebugger.resolve_script_id(_ref)


# re-sends the current state for this instance, so the viewer reflects it even
# when the target was chosen after the state was already entered
func debug_emit_current() -> void:
	if _last_debug_name.is_empty():
		return
	if not (OS.is_debug_build() and EngineDebugger.is_active()):
		return
	if parent and parent.get_instance_id() == HengoDebugger.state_targets.get(_script_id, -1):
		EngineDebugger.send_message('hengo:state', [_last_debug_name, _script_id])


func set_states(_states: Dictionary) -> void:
	states = _states


func set_reenterable(_names: Array) -> void:
	for state_name: String in _names:
		if states.has(state_name):
			(states[state_name] as HengoState)._can_reenter = true


func change_state(_state: String, ..._args) -> void:
	if not states.has(_state):
		print('State not found: ', _state)
		return

	# a state only runs again from the outside when it opts in
	if current_state and _current_state_name == _state and not current_state._can_reenter:
		return

	if current_state:
		previous_state_name = _current_state_name
		current_state.exit()

	var state: HengoState = states[_state]
	current_state = state
	_current_state_name = _state
	_last_debug_name = _state

	if OS.is_debug_build() and EngineDebugger.is_active():
		if parent and parent.get_instance_id() == HengoDebugger.state_targets.get(_script_id, -1):
			EngineDebugger.send_message('hengo:state', [_state, _script_id])

	if state.has_method(&'enter'):
		state.callv(&'enter', _args)


# returns to the state that was running before the current one
func go_back() -> void:
	if not previous_state_name.is_empty():
		change_state(previous_state_name)


func static_process(_delta: float) -> void:
	if current_state:
		current_state.update(_delta)


func static_physics_process(_delta: float) -> void:
	if current_state:
		current_state.physics(_delta)
