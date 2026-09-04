@tool
class_name HenStateOps extends RefCounted

# moving a state between machines: the sidebar and the flow viewer both drive it,
# so the menu entry, the guards and the mutation live here instead of in the ui


const MOVE_ICON: String = 'res://addons/hengo/assets/new_icons/move.svg'
const MACRO_ICON: String = 'res://addons/hengo/assets/new_icons/box.svg'
const MENU_SIZE: Vector2 = Vector2(200, 230)


# the header entry the state inspector shows beside delete
static func move_action(_state: HenSaveState) -> Dictionary:
	return {
		name = 'Move to',
		tooltip = 'Move this state into another state',
		callable = open_move_menu.bind(_state),
		icon = MOVE_ICON
	}


# the header entry that drops a macro inside this state
static func use_macro_action(_state: HenSaveState) -> Dictionary:
	return {
		name = 'Use macro',
		tooltip = 'Run a macro inside this state',
		callable = open_macro_menu.bind(_state),
		icon = MACRO_ICON
	}


static func open_macro_menu(_state: HenSaveState) -> void:
	var save_data: HenSaveData = owner_of(_state)

	if not save_data:
		return

	if save_data.macros.is_empty():
		_notify('There is no macro to use yet.', HenToast.MessageType.INFO)
		return

	var options: Array = []

	for macro: HenSaveStateMacro in save_data.macros:
		options.append({name = macro.name, kind = 'macro', macro_id = macro.id})

	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = _mouse_position(),
		min_size = MENU_SIZE
	})

	menu.mount(options, _on_macro_picked.bind(save_data, _state), 'item_type')


static func _on_macro_picked(_item: Dictionary, _save_data: HenSaveData, _state: HenSaveState) -> void:
	var macro: HenSaveStateMacro = _save_data.find_macro(StringName(str(_item.get('macro_id', ''))))

	if not macro:
		return

	request_add_macro_use.bind(_save_data, _state, macro).call_deferred()


# a use is a sub-state of the host that runs the machine of the definition
static func request_add_macro_use(_save_data: HenSaveData, _parent: HenSaveState, _macro: HenSaveStateMacro) -> HenSaveState:
	if not _save_data or not _parent or not _macro:
		return null

	var use: HenSaveState = HenSaveState.create_macro_use(_macro, _save_data)

	_record(_save_data, 'Use ' + _macro.name, func() -> bool:
		if not _save_data.sub_states.has(_parent.id):
			_save_data.sub_states[_parent.id] = []

		var list: Array = _save_data.sub_states[_parent.id]

		if not list.has(use):
			list.append(use)

		if list.size() == 1:
			use.start = true

		return true
	)

	return use


# where one way out of a macro leads, asked per use: the states of the scope that
# holds it, never the ones inside the macro
static func open_way_out_menu(_use: HenSaveState, _exit_id: String) -> void:
	var save_data: HenSaveData = owner_of(_use)

	if not save_data:
		return

	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = _mouse_position(),
		min_size = MENU_SIZE
	})

	menu.mount(way_out_options(save_data, _use), _on_way_out_picked.bind(save_data, _use, _exit_id), 'item_type')


static func way_out_options(_save_data: HenSaveData, _use: HenSaveState) -> Array:
	var options: Array = [ {name = 'Nowhere', kind = 'none'} ]

	for state: HenSaveState in _save_data.states:
		options.append({name = state.name, kind = 'state', state_id = state.id})

	for holder: HenSaveState in HenGeneratorAction.ancestor_chain(_save_data, _use):
		if holder == _use:
			continue

		for sub: HenSaveState in holder.get_sub_states(_save_data):
			if sub == _use:
				continue

			options.append({name = holder.name + ' / ' + sub.name, kind = 'state', state_id = sub.id})

	return options


static func _on_way_out_picked(_item: Dictionary, _save_data: HenSaveData, _use: HenSaveState, _exit_id: String) -> void:
	_record(_save_data, 'Wire way out', func() -> bool:
		if str(_item.get('kind', '')) == 'none':
			_use.flow_targets.erase(_exit_id)
		else:
			_use.flow_targets[_exit_id] = {state_id = _item.state_id, label = ''}

		return true
	)


static func open_move_menu(_state: HenSaveState) -> void:
	var save_data: HenSaveData = owner_of(_state)

	if not save_data:
		return

	var options: Array = move_options(save_data, _state)

	if options.is_empty():
		_notify('There is nowhere to move ' + _state.name + ' to.', HenToast.MessageType.INFO)
		return

	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	# show first (tree entry wires the refs), then mount. it opens under the cursor
	# that asked for it: the list is short and crossing the panel to reach it costs
	# more than the list itself
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = _mouse_position(),
		min_size = MENU_SIZE
	})

	menu.mount(options, _on_target_picked.bind(save_data, _state), 'item_type')


# the menu closes the popup that hosted it, so the move runs after that close
static func _on_target_picked(_item: Dictionary, _save_data: HenSaveData, _state: HenSaveState) -> void:
	var parent: HenSaveState = null

	if str(_item.get('kind', '')) == 'state':
		parent = find_state(_save_data, StringName(str(_item.state_id)))

		if not parent:
			return

	request_move.bind(_save_data, _state, parent).call_deferred()


# every state this one can become a child of, plus the script root when it is
# already nested. a state cannot land inside itself or inside its own sub tree
static func move_options(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var current: HenSaveState = parent_of(_save_data, _state)
	var blocked: Array = [_state] + descendants(_save_data, _state)
	var options: Array = []

	if current:
		options.append({name = 'Script (top level)', kind = 'root'})

	for state: HenSaveState in all_states(_save_data):
		# a use runs the machine of its definition, so nothing else lands inside it
		if state == current or blocked.has(state) or state.is_macro_use():
			continue

		options.append({name = path_label(_save_data, state), kind = 'state', state_id = state.id})

	return options


static func request_move(_save_data: HenSaveData, _state: HenSaveState, _parent: HenSaveState, _save: bool = true) -> void:
	if not can_move(_save_data, _state, _parent):
		return

	_record(_save_data, 'Move ' + _state.name, func() -> bool:
		apply_move(_save_data, _state, _parent, _save)
		return true
	)


# every edit to the machine goes on the one stack ctrl+z drains
static func _record(_save_data: HenSaveData, _label: String, _mutation: Callable) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global and global.flow_history:
		global.flow_history.record_tree(_save_data, _label, _mutation)
	else:
		_mutation.call()

	notify_changed()


# the state is built once and reinserted on every redo: creating it inside the do
# would hand out a new id each time, and the branches pointing at the first one
# would go nowhere. a null parent makes it a state of the script
static func request_add_state(_save_data: HenSaveData, _parent: HenSaveState, _save: bool = true) -> HenSaveState:
	if not _save_data:
		return null

	var state: HenSaveState = HenSaveState.create(_parent != null)

	if not state:
		return null

	# undoing takes it out of every list; the entry's own snapshot is what holds it
	_record(_save_data, 'New ' + ('sub-state' if _parent else 'state'), func() -> bool:
		_do_add(_save_data, state, _parent, _save)
		return true
	)

	return state


static func _do_add(_save_data: HenSaveData, _state: HenSaveState, _parent: HenSaveState, _save: bool) -> void:
	var list: Array = _save_data.states

	if _parent:
		if not _save_data.sub_states.has(_parent.id):
			_save_data.sub_states[_parent.id] = []

		list = _save_data.sub_states[_parent.id]

	if not list.has(_state):
		list.append(_state)

	_state.is_sub_state = _parent != null

	# the flags are set after the append: the start setter sweeps the siblings by
	# looking for the list holding this state and would find none before it
	if list.size() == 1:
		_state.is_base = not _parent
		_state.start = true

	if _save:
		persist(_save_data, _state, _parent == null)


# same shape as request_add_state: the variable is built once so a redo cannot
# hand out a second id for the same binding
static func request_add_var(_save_data: HenSaveData, _save: bool = true) -> HenSaveVar:
	if not _save_data:
		return null

	var variable: HenSaveVar = HenSaveVar.create()

	if not variable:
		return null

	_record(_save_data, 'New variable', func() -> bool:
		if not _save_data.variables.has(variable):
			_save_data.variables.append(variable)

		if _save:
			HenUtils.save_side_bar_item(variable, _save_data.identity.id, HenSideBar.SideBarItem.VARIABLES)

		return true
	)

	return variable


# a function is created with one input-less shape and edited from the inspector,
# the way a variable is
static func request_add_function(_save_data: HenSaveData) -> HenSaveFunc:
	if not _save_data:
		return null

	var func_res: HenSaveFunc = HenSaveFunc.create(_save_data)

	_record(_save_data, 'New function', func() -> bool:
		if not _save_data.functions.has(func_res):
			_save_data.functions.append(func_res)

		return true
	)

	return func_res


# a macro is created with one state inside it, so entering it has somewhere to run
static func request_add_macro(_save_data: HenSaveData) -> HenSaveStateMacro:
	if not _save_data:
		return null

	var macro: HenSaveStateMacro = HenSaveStateMacro.create(_save_data)
	var first: HenSaveState = HenSaveState.create(true, _save_data)

	first.start = true

	_record(_save_data, 'New macro', func() -> bool:
		if not _save_data.macros.has(macro):
			_save_data.macros.append(macro)

		if not _save_data.sub_states.has(macro.id):
			_save_data.sub_states[macro.id] = []

		var states: Array = _save_data.sub_states[macro.id]

		if not states.has(first):
			states.append(first)

		return true
	)

	return macro


# the setter demotes the sibling that held the flag, so the undo goes through the
# same snapshot the move uses instead of writing the property back
static func request_set_start(_save_data: HenSaveData, _state: HenSaveState, _save: bool = true) -> void:
	if not _save_data or not _state or _state.start:
		return

	_record(_save_data, 'Start ' + _state.name, func() -> bool:
		_do_set_start(_save_data, _state, _save)
		return true
	)


static func _do_set_start(_save_data: HenSaveData, _state: HenSaveState, _save: bool) -> void:
	var demoted: HenSaveState = current_start(_save_data, _state)

	_state.start = true

	if _save:
		persist(_save_data, _state, not _state.is_sub_state)

		if demoted:
			persist(_save_data, demoted, not demoted.is_sub_state)


# the arrays are rebuilt from a snapshot instead of undone step by step: the
# `start` setter rewrites siblings on its own, so replaying the move backwards
# would not land on the same flags
static func tree_snapshot(_save_data: HenSaveData) -> Dictionary:
	var subs: Dictionary = {}
	var flags: Array = []

	for key: Variant in _save_data.sub_states:
		subs[key] = (_save_data.sub_states[key] as Array).duplicate()

	for state: HenSaveState in all_states(_save_data):
		flags.append({state = state, start = state.start, is_sub_state = state.is_sub_state})

	return {
		states = _save_data.states.duplicate(),
		sub_states = subs,
		flags = flags,
		variables = _save_data.variables.duplicate(),
		functions = _save_data.functions.duplicate(),
		macros = _save_data.macros.duplicate()
	}


# the lists and the flags of every state, put back as one: the `start` setter
# rewrites siblings on its own, so replaying an edit backwards would not land on
# the same flags. writes the state files too, or a restored state would be left
# with nothing on disk for save.res to point at
static func apply_tree(_save_data: HenSaveData, _snap: Dictionary, _save: bool = true) -> void:
	if _snap.has('variables'):
		_save_data.variables.assign(_snap.variables)

	if _snap.has('functions'):
		_save_data.functions.assign(_snap.functions)

	if _snap.has('macros'):
		_save_data.macros.assign(_snap.macros)

	_save_data.states.assign(_snap.states)
	_save_data.sub_states.clear()

	for key: Variant in _snap.sub_states:
		_save_data.sub_states[key] = (_snap.sub_states[key] as Array).duplicate()

	for entry: Dictionary in _snap.flags:
		(entry.state as HenSaveState).is_sub_state = entry.is_sub_state
		(entry.state as HenSaveState).start = false

	# second pass: setting one to true sweeps its siblings, which are already
	# cleared, so the recorded flags survive whatever order they come back in
	for entry: Dictionary in _snap.flags:
		if entry.start:
			(entry.state as HenSaveState).start = true

	if not _save:
		return

	for entry: Dictionary in _snap.flags:
		var state: HenSaveState = entry.state

		if _save_data.states.has(state) or _is_nested(_save_data, state):
			persist(_save_data, state, not state.is_sub_state)

	# a restored variable needs its file back too, or save.res points at the trash
	for variable: HenSaveVar in _save_data.variables:
		HenUtils.save_side_bar_item(variable, _save_data.identity.id, HenSideBar.SideBarItem.VARIABLES)


static func _is_nested(_save_data: HenSaveData, _state: HenSaveState) -> bool:
	for key: Variant in _save_data.sub_states:
		if (_save_data.sub_states[key] as Array).has(_state):
			return true

	return false


# what makes two tree snapshots different: the shape of the machine and the flags,
# never the object ids, which change with every duplicate
static func tree_digest(_snap: Dictionary) -> String:
	var parts: Array = []

	for state: HenSaveState in _snap.states:
		parts.append(['top', str(state.id)])

	for key: Variant in _snap.sub_states:
		for state: HenSaveState in _snap.sub_states[key]:
			parts.append(['sub', str(key), str(state.id)])

	for entry: Dictionary in _snap.flags:
		parts.append([str((entry.state as HenSaveState).id), entry.start, entry.is_sub_state])

	for variable: HenSaveVar in _snap.get('variables', []):
		parts.append(['var', str(variable.id)])

	for func_res: HenSaveFunc in _snap.get('functions', []):
		parts.append(['fn', str(func_res.id)])

	for macro: HenSaveStateMacro in _snap.get('macros', []):
		parts.append(['macro', str(macro.id)])

	return var_to_str(parts)


# a null parent means the script root; the toast is the only feedback the menu
# can give, since a rejected pick just closes
static func can_move(_save_data: HenSaveData, _state: HenSaveState, _parent: HenSaveState) -> bool:
	if not _save_data or not _state:
		return false

	if _parent == _state:
		return false

	var current: HenSaveState = parent_of(_save_data, _state)

	if current == _parent:
		return false

	if _parent and descendants(_save_data, _state).has(_parent):
		_notify('A state cannot be moved into one of its own sub-states.', HenToast.MessageType.ERROR)
		return false

	if _parent and _state.is_base:
		_notify('The base state cannot be moved into another state.', HenToast.MessageType.ERROR)
		return false

	# the script machine would be left with no state to start on
	if _parent and not current and _save_data.states.size() <= 1:
		_notify('The script needs at least one top level state.', HenToast.MessageType.ERROR)
		return false

	return true


# the flag order is forced: `start` resolves its siblings through the list that
# holds the state right now, so it is cleared before the move and set after it
static func apply_move(_save_data: HenSaveData, _state: HenSaveState, _parent: HenSaveState, _save: bool = true) -> void:
	var was_start: bool = _state.start
	var old_parent: HenSaveState = parent_of(_save_data, _state)
	var old_list: Array = _save_data.sub_states.get(old_parent.id, []) if old_parent else _save_data.states

	_state.start = false
	old_list.erase(_state)

	if old_parent and old_list.is_empty():
		_save_data.sub_states.erase(old_parent.id)

	var new_list: Array = _save_data.states

	if _parent:
		if not _save_data.sub_states.has(_parent.id):
			_save_data.sub_states[_parent.id] = []

		new_list = _save_data.sub_states[_parent.id]

	new_list.append(_state)
	_state.is_sub_state = _parent != null

	var promoted: HenSaveState = (old_list[0] as HenSaveState) if was_start and not old_list.is_empty() else null

	if promoted:
		promoted.start = true

	if new_list.size() == 1:
		_state.start = true

	if _save:
		persist(_save_data, _state, _parent == null)

		# the flag lives in the state file, so the machine left behind is written too
		if promoted:
			persist(_save_data, promoted, not promoted.is_sub_state)


# `is_sub_state` is read back from the state file by the pickers that scan a
# closed script, so a moved state has to be written again. a sub-state that never
# had a file of its own stays embedded in the save
static func persist(_save_data: HenSaveData, _state: HenSaveState, _to_root: bool) -> void:
	if not _save_data or not _save_data.identity:
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')

	# a suite builds scripts that own no folder, and the path index resolves them
	# into whatever collection is on disk: the write would land on real data
	if global and global.IS_HEADLESS:
		return

	if not _to_root and _state.resource_path.is_empty():
		return

	HenUtils.save_side_bar_item(_state, _save_data.identity.id, HenSideBar.SideBarItem.STATES)


static func notify_changed() -> void:
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')

	if signal_bus:
		signal_bus.request_structural_update.emit()

	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global and global.HENGO_ROOT:
		global.HENGO_ROOT.schedule_check_errors()


# --- tree helpers ---

# the machine this state belongs to: its own list, top level or nested
static func siblings_of(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var parent: HenSaveState = parent_of(_save_data, _state)

	return _save_data.sub_states.get(parent.id, []) if parent else _save_data.states


static func current_start(_save_data: HenSaveData, _state: HenSaveState) -> HenSaveState:
	for sibling: HenSaveState in siblings_of(_save_data, _state):
		if sibling != _state and sibling.start:
			return sibling

	return null


static func parent_of(_save_data: HenSaveData, _state: HenSaveState) -> HenSaveState:
	for parent_id: Variant in _save_data.sub_states:
		if (_save_data.sub_states[parent_id] as Array).has(_state):
			return find_state(_save_data, StringName(str(parent_id)))

	return null


static func descendants(_save_data: HenSaveData, _state: HenSaveState) -> Array:
	var out: Array = []

	# what a use runs belongs to the macro, and is reached through it
	if _state.is_macro_use():
		return out

	for sub: HenSaveState in _state.get_sub_states(_save_data):
		out.append(sub)
		out.append_array(descendants(_save_data, sub))

	return out


# top level first, each state followed by its own sub tree
static func all_states(_save_data: HenSaveData) -> Array:
	var out: Array = []

	for state: HenSaveState in _save_data.states:
		out.append(state)
		out.append_array(descendants(_save_data, state))

	return out


static func find_state(_save_data: HenSaveData, _id: StringName) -> HenSaveState:
	for state: HenSaveState in all_states(_save_data):
		if state.id == _id:
			return state

	return null


static func path_label(_save_data: HenSaveData, _state: HenSaveState) -> String:
	var names: PackedStringArray = []
	var walker: HenSaveState = _state

	while walker:
		names.insert(0, walker.name)
		walker = parent_of(_save_data, walker)

	return ' / '.join(names)


static func owner_of(_state: HenSaveState) -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global:
		return null

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and all_states(save_data).has(_state):
			return save_data

	return global.SAVE_DATA


# the popups position in the space the hengo panel lives in, the same one an
# anchored control reports
static func _mouse_position() -> Vector2:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global or not global.HENGO_ROOT:
		return Vector2.INF

	return global.HENGO_ROOT.get_global_mouse_position()


static func _notify(_message: String, _type: int) -> void:
	var toast: HenToast = Engine.get_singleton(&'ToastContainer')

	# the container behind it is only wired once the panel is in the tree
	if toast and toast.is_inside_tree():
		toast.notify(_message, _type)
