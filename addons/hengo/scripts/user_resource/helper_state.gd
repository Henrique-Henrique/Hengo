extends RefCounted
class_name HengoState

var _ref
var _transitions: Dictionary
var _d_counter: float

static var INVALID_PLACEHOLDER: Variant


func _init(_p, _trans: Dictionary = {}) -> void:
	_ref = _p
	_transitions = _trans
	_d_counter = 0.


func make_transition(_name: String) -> void:
	if _transitions.has(_name):
		_ref._STATE_CONTROLLER.change_state(_transitions.get(_name))


var sub_states: Dictionary = {}
var current_sub_state: HengoState


func add_sub_state(_name: String, _state: HengoState) -> void:
	sub_states[_name] = _state


func change_sub_state(_name: String, ..._args) -> void:
	if not sub_states.has(_name):
		return
		
	if current_sub_state:
		current_sub_state.exit()
		
	var state: HengoState = sub_states[_name]
	current_sub_state = state

	if OS.is_debug_build() and EngineDebugger.is_active():
		EngineDebugger.send_message('hengo:state', [_name])

	if state.has_method(&'enter'):
		state.callv(&'enter', _args)


func exit() -> void:
	if current_sub_state:
		current_sub_state.exit()
		current_sub_state = null


func update(_delta: float) -> void:
	if current_sub_state:
		current_sub_state.update(_delta)


func physics(_delta: float) -> void:
	if current_sub_state:
		current_sub_state.physics(_delta)
