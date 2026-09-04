class_name HengoState

var _ref
var _transitions: Dictionary
var _d_counter: float
var _can_reenter: bool = false

var _script_id: String = ''

static var INVALID_PLACEHOLDER: Variant


func _init(_p, _trans: Dictionary = {}) -> void:
	_ref = _p
	_transitions = _trans
	_d_counter = 0.
	_script_id = HengoDebugger.resolve_script_id(_p)


func make_transition(_name: String) -> void:
	if _transitions.has(_name):
		_ref._STATE_CONTROLLER.change_state(_transitions.get(_name))


var sub_states: Dictionary = {}
var current_sub_state: HengoState
# state that holds this one as a sub-state, null for a top level state. weak on
# purpose: the parent already holds the child in sub_states, and HengoState is
# RefCounted, so a strong link both ways would never be freed
var _parent_ref: WeakRef
# key this state was registered under, needed to name it when handing control back
var _sub_name: String = ''
# where change_sub_state came from, so a sub-state can hand control back
var previous_sub_state_name: String = ''


func add_sub_state(_name: String, _state: HengoState, _reenter: bool = false) -> void:
	sub_states[_name] = _state
	_state._parent_ref = weakref(self)
	_state._sub_name = _name
	_state._can_reenter = _reenter


# returns to whoever was running before this state took over. a sub-state hands
# control back to its sibling, a top level state to the previous top level one
func go_back() -> void:
	var parent: HengoState = _parent_ref.get_ref() if _parent_ref else null

	if parent:
		if not parent.previous_sub_state_name.is_empty():
			parent.change_sub_state(parent.previous_sub_state_name)
		return

	if _ref:
		_ref._STATE_CONTROLLER.go_back()


func change_sub_state(_name: String, ..._args) -> void:
	if not sub_states.has(_name):
		return

	# a state only runs again from the outside when it opts in
	if current_sub_state and sub_states.get(_name) == current_sub_state and not current_sub_state._can_reenter:
		return

	if current_sub_state:
		previous_sub_state_name = current_sub_state._sub_name
		current_sub_state.exit()

	var state: HengoState = sub_states[_name]
	current_sub_state = state

	# the substate is now the deepest active state; let the controller re-emit it
	if _ref:
		var ctrl = _ref.get('_STATE_CONTROLLER')
		if ctrl:
			ctrl._last_debug_name = _name

	if OS.is_debug_build() and EngineDebugger.is_active():
		if _ref and _ref.get_instance_id() == HengoDebugger.state_targets.get(_script_id, -1):
			EngineDebugger.send_message('hengo:state', [_name, _script_id])

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
