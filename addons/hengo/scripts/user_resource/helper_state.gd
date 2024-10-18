extends RefCounted
class_name HengoState

var _ref
var _transitions: Dictionary
var _d_counter: float

func _init(_p, _trans: Dictionary = {}) -> void:
	_ref = _p
	_transitions = _trans
	_d_counter = 0.

func make_transition(_name: String) -> void:
	if _transitions.has(_name):
		_ref._STATE_CONTROLLER.change_state(_transitions.get(_name))


func enter() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics(_delta: float) -> void:
	pass
