@tool
class_name HenSaveData extends Resource

@export var counter: int
@export var identity: HenSaveDataIdentity
@export var variables: Array[HenSaveVar]
@export var states: Array[HenSaveState]
@export var sub_states: Dictionary
# linear action lists keyed by state id (str(state.id) -> Array[HenSaveAction])
@export var state_actions: Dictionary

var _node_cache: Dictionary = {}


func add_dep(_id: StringName) -> void:
	if not _id:
		return

	if identity.id == _id:
		return

	if not identity.deps.has(_id):
		identity.deps.append(_id)


func add_detailed_dep(_id: StringName, _dep_info: Dictionary) -> void:
	if not _id:
		return

	if identity.id == _id:
		return

	if not identity.detailed_deps.has(_id):
		identity.detailed_deps[_id] = []

	for dep: Dictionary in identity.detailed_deps[_id]:
		if dep.type == _dep_info.type and dep.id == _dep_info.id:
			return

	(identity.detailed_deps[_id] as Array).append(_dep_info)


func add_var(_save: bool = true) -> HenSaveVar:
	var v: HenSaveVar = HenSaveVar.create()

	if not v:
		return null

	if _save:
		if not HenUtils.save_side_bar_item(v, identity.id, HenSideBar.SideBarItem.VARIABLES):
			return null

	variables.append(v)
	return v


# a free variable name based on _base, appending 2, 3, ... when taken. compared on
# the emitted identifier (snake_case), since that is what would collide in codegen
func unique_var_name(_base: String) -> String:
	var taken: Dictionary = {}

	for v: HenSaveVar in variables:
		taken[v.name.to_snake_case()] = true

	if not taken.has(_base.to_snake_case()):
		return _base

	var i: int = 2
	while taken.has((_base + str(i)).to_snake_case()):
		i += 1

	return _base + str(i)


func add_state(_save: bool = true) -> HenSaveState:
	var s: HenSaveState = HenSaveState.create()

	if not s:
		return null
	
	if _save:
		if not HenUtils.save_side_bar_item(s, identity.id, HenSideBar.SideBarItem.STATES):
			return
	
	states.append(s)

	# the flag is set after the append, because its setter sweeps the siblings by
	# looking for the list holding this state and would find none before it
	if states.size() == 1:
		s.start = true

	return s










func add_state_action(_state_id: StringName, _action: HenSaveAction) -> void:
	if not state_actions.has(_state_id):
		state_actions[_state_id] = []

	(state_actions[_state_id] as Array).append(_action)


func get_state_actions(_state_id: StringName) -> Array:
	if not state_actions.has(_state_id):
		return []

	return state_actions[_state_id]


func remove_state_action(_state_id: StringName, _action: HenSaveAction) -> void:
	if not state_actions.has(_state_id):
		return

	(state_actions[_state_id] as Array).erase(_action)

	if (state_actions[_state_id] as Array).is_empty():
		state_actions.erase(_state_id)


# an action can sit at the top of the list, inside a loop body or bound to an
# input of another action, and only the first one has an entry in state_actions
func remove_action_anywhere(_state_id: StringName, _action: HenSaveAction) -> bool:
	if not state_actions.has(_state_id) or not _action:
		return false

	var list: Array = state_actions[_state_id]

	if not _remove_action_from(list, _action):
		return false

	if list.is_empty():
		state_actions.erase(_state_id)

	return true


func _remove_action_from(_list: Array, _target: HenSaveAction) -> bool:
	for i: int in range(_list.size()):
		if _list[i] == _target:
			_list.remove_at(i)
			return true

		if _remove_action_inside(_list[i], _target):
			return true

	return false


func _remove_action_inside(_action: HenSaveAction, _target: HenSaveAction) -> bool:
	for key: Variant in _action.input_actions.keys():
		var nested: HenSaveAction = (_action.input_actions[key] as Dictionary).get('action')

		if nested == _target:
			_action.input_actions.erase(key)
			return true

		if nested and _remove_action_inside(nested, _target):
			return true

	return _remove_action_from(_action.body_actions, _target)


# inserts at a flat index; a negative or out of range index appends
func insert_state_action(_state_id: StringName, _action: HenSaveAction, _index: int) -> void:
	if not state_actions.has(_state_id):
		state_actions[_state_id] = []

	var list: Array = state_actions[_state_id]

	if _index < 0 or _index > list.size():
		list.append(_action)
	else:
		list.insert(_index, _action)


# replaces the whole list, keeping the empty-means-absent invariant
func set_state_actions(_state_id: StringName, _actions: Array) -> void:
	if _actions.is_empty():
		state_actions.erase(_state_id)
		return

	state_actions[_state_id] = _actions.duplicate()