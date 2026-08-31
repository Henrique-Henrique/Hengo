@tool
class_name HenStateGraphSource
extends RefCounted

# the state machine as a plain dictionary, derived from the save data. both the
# state viewer and the flow view parse the same shape, so a transition drawn in
# one is the same transition in the other

const TRANSITION_ICON: String = 'arrow-right-to-line'


# wraps every script as a labeled compound machine under a single root
static func collection_dict(_open_scripts: Array) -> Dictionary:
	var root: Dictionary = {id = 'collection', states = {}}

	for save_data: HenSaveData in _open_scripts:
		if not save_data:
			continue

		var script: Dictionary = script_dict(save_data)

		if (script.get('states', {}) as Dictionary).is_empty():
			continue

		root.states[save_data.identity.name] = script

	return root


# the machine the open scope draws: the states of the script, or the single body
# of the definition being edited
static func scope_dict(_save_data: HenSaveData, _scope: HenSaveResType) -> Dictionary:
	if _scope is HenSaveFunc:
		return function_dict(_save_data, _scope as HenSaveFunc)

	if _scope is HenSaveStateMacro:
		return macro_dict(_save_data, _scope as HenSaveStateMacro)

	return script_dict(_save_data)


# the machine a macro holds, drawn the way the script's own is
static func macro_dict(_save_data: HenSaveData, _macro: HenSaveStateMacro) -> Dictionary:
	var root: Dictionary = {
		id = _macro.name,
		states = {},
		script_type = String(_save_data.identity.type) if _save_data.identity else ''
	}

	var states: Array = _macro.get_states(_save_data)

	if states.is_empty():
		return root

	root.initial = states[0].name

	for state: HenSaveState in states:
		if state.start:
			root.initial = state.name

		root.states[state.name] = state_dict(state, _save_data)

	return root


# a function body draws as one frame: it has no machine of its own
static func function_dict(_save_data: HenSaveData, _func: HenSaveFunc) -> Dictionary:
	var scope: HenSaveState = _func.scope_state()

	return {
		id = _func.name,
		states = {_func.name: {
			state_id = String(scope.id),
			script_id = String(_save_data.identity.id) if _save_data.identity else ''
		}},
		initial = _func.name,
		script_type = String(_save_data.identity.type) if _save_data.identity else ''
	}


static func script_dict(_save_data: HenSaveData) -> Dictionary:
	var root: Dictionary = {
		id = _save_data.identity.name if _save_data.identity else 'root',
		states = {},
		script_type = String(_save_data.identity.type) if _save_data.identity else ''
	}

	var roots: Array = []

	if _save_data.states:
		for state: HenSaveState in _save_data.states:
			if not state.is_sub_state:
				roots.append(state)

	if roots.is_empty():
		return root

	root.initial = roots[0].name

	for state: HenSaveState in roots:
		if state.start:
			root.initial = state.name

		root.states[state.name] = state_dict(state, _save_data)

	return root


static func state_dict(_state: HenSaveState, _save_data: HenSaveData) -> Dictionary:
	# ids keep highlight and selection independent of state names
	var out: Dictionary = {
		state_id = String(_state.id),
		script_id = String(_save_data.identity.id) if _save_data.identity else ''
	}

	if not _state.description.is_empty():
		out.description = _state.description

	# a use of a macro draws as a closed box: what it runs is edited in the macro
	if _state.is_macro_use():
		return out

	_add_sub_states(_state, _save_data, out)

	var on_dict: Dictionary = {}
	var on_meta: Dictionary = {}

	add_branch_edges(_state, _save_data, on_dict, on_meta)

	if not on_dict.is_empty():
		out.on = on_dict
		out.on_meta = on_meta

	return out


static func _add_sub_states(_state: HenSaveState, _save_data: HenSaveData, _out: Dictionary) -> void:
	var subs: Array = _state.get_sub_states(_save_data)

	if subs.is_empty():
		return

	var valid: Array = []

	for sub: HenSaveState in subs:
		if sub and is_instance_valid(sub):
			valid.append(sub)

	if valid.is_empty():
		return

	_out.states = {}
	_out.initial = valid[0].name

	for sub: HenSaveState in valid:
		if sub.start:
			_out.initial = sub.name

		_out.states[sub.name] = state_dict(sub, _save_data)


# branching actions transition too, so their targets draw as edges. the branch
# label is what names the arrow; unnamed falls back to go_to_<target>
static func add_branch_edges(_state: HenSaveState, _save_data: HenSaveData, _on: Dictionary, _meta: Dictionary) -> void:
	for action: HenSaveAction in _save_data.get_state_actions(_state.id):
		var macro: HenSaveMacro = HenActionsPanel.find_macro(action.macro_id)

		for key: Variant in action.branches.keys():
			var branch: Variant = action.branches[key]

			if not branch is Dictionary:
				continue

			var target: HenSaveState = HenGeneratorAction.branch_target(_save_data, action, str(key))

			if not target:
				continue

			var path: String = target.name
			var script_id: StringName = HenGeneratorAction.branch_script_id(_save_data, action, str(key))

			if not script_id.is_empty():
				var owner: String = script_name_for_id(script_id)

				if owner.is_empty():
					continue

				path = owner + '.' + target.name

			var label: String = str((branch as Dictionary).get('label', ''))
			var event: String = label if not label.is_empty() else 'go_to_' + target.name

			_on[event] = path
			_meta[event] = branch_meta(macro, script_id, label.is_empty())


# a branch reads as cross-script first, then conditional when the macro forks. the
# icon stays the macro's own so the action type is still recognizable on the line
static func branch_meta(_macro: HenSaveMacro, _script_id: StringName, _auto_label: bool) -> Dictionary:
	var kind: StringName = &'transition'

	if not _script_id.is_empty():
		kind = &'cross_script'
	elif _macro and _macro.flow_outputs.size() > 1:
		kind = &'condition'

	return {
		kind = kind,
		icon = _macro.icon if _macro and not _macro.icon.is_empty() else TRANSITION_ICON,
		color = _macro.color if _macro else '',
		auto_label = _auto_label
	}


# resolves a script's display name (the key used in the collection dict) from its id
static func script_name_for_id(_save_data_id: StringName) -> String:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global:
		return ''

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and str(save_data.identity.id) == str(_save_data_id):
			return save_data.identity.name

	return ''


static func find_state_by_id(_id: Variant, _save_data: HenSaveData) -> HenSaveState:
	var target: String = str(_id)

	for state: HenSaveState in _save_data.states:
		if str(state.id) == target:
			return state

	for parent_id: StringName in _save_data.sub_states:
		for state: HenSaveState in _save_data.sub_states[parent_id]:
			if str(state.id) == target:
				return state

	return null
