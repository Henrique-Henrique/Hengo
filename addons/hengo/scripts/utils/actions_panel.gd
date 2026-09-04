@tool
class_name HenActionsPanel extends RefCounted


# list with the action pulled out and reinserted at index inside the target phase
static func reorder(_actions: Array, _action: HenSaveAction, _phase: StringName, _index: int) -> Array:
	var rest: Array = _actions.duplicate()
	rest.erase(_action)

	var groups: Dictionary = group_by_phase(rest)
	var bucket: Array = groups.get(str(_phase), [])

	bucket.insert(clampi(_index, 0, bucket.size()), _action)
	groups[str(_phase)] = bucket

	return flatten_phases(groups)


# counted without the dragged action, -1 when the target left the list
static func drop_index(_actions: Array, _target: HenSaveAction, _dragged: HenSaveAction, _before: bool) -> int:
	var bucket: Array = []

	for action: HenSaveAction in _actions:
		if str(action.phase) == str(_target.phase) and action != _dragged:
			bucket.append(action)

	var index: int = bucket.find(_target)

	return -1 if index < 0 else (index if _before else index + 1)


# phase key -> actions, preserving the list order inside each phase
static func group_by_phase(_actions: Array) -> Dictionary:
	var groups: Dictionary = {}

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		groups[str(phase)] = []

	for action: HenSaveAction in _actions:
		var key: String = str(action.phase)

		if not groups.has(key):
			groups[key] = []

		(groups[key] as Array).append(action)

	return groups


# flat list in run order; an unknown phase keeps its actions at the end
static func flatten_phases(_groups: Dictionary) -> Array:
	var out: Array = []

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		out.append_array(_groups.get(str(phase), []))

	for key: Variant in _groups:
		if not HenSaveAction.PHASE_ORDER.has(StringName(str(key))):
			out.append_array(_groups[key])

	return out


# the action being dragged, or null when the payload is something else
static func dragged_action(_data: Variant) -> HenSaveAction:
	if not _data is Dictionary or str((_data as Dictionary).get('type', '')) != 'hengo_action':
		return null

	return (_data as Dictionary).get('action') as HenSaveAction


# a phase is only a valid target when the macro has a body for it. a place a macro
# leaves for its uses is judged by the phase it runs at
static func can_use_phase(_action: HenSaveAction, _phase: StringName, _save_data: HenSaveData = null, _state: HenSaveState = null) -> bool:
	var macro: HenSaveMacro = find_macro(_action.macro_id)

	if not macro:
		return str(_action.phase) == str(_phase)

	var phase: StringName = _phase

	if not HenSaveAction.PHASE_ORDER.has(phase) and _save_data and _state and _state.is_macro_use():
		phase = HenGeneratorAction.hook_phase(_save_data, _state, phase)

	return HenSaveAction.supported_phases(macro).has(phase)


# macro id -> macro, plus the pool sizes it was built from
static var _macro_index: Dictionary = {}
static var _macro_index_sizes: Vector2i = Vector2i(-1, -1)


# the pools are rewritten wholesale on load, and an index keyed by id would keep
# serving the macros they held before
static func invalidate_macro_index() -> void:
	_macro_index.clear()
	_macro_index_sizes = Vector2i(-1, -1)


# a pool swapped for another of the same size keeps the size check quiet, and the
# index would go on serving macros that belong to the pool that is gone
static func _is_stale(_global: HenGlobal) -> bool:
	for pool: Array in [_global.action_macros, _global.script_macros]:
		if not pool.is_empty() and _macro_index.get((pool[0] as HenSaveMacro).id) != pool[0]:
			return true

	return false


# every action row resolves its macro, several times over, so this cannot scan
# the branch an older save's body_actions belong to, empty when the macro never
# had one. read from the macro script, so the mapping lives with the action
static func body_branch_of(_macro_id: StringName) -> StringName:
	var macro: HenSaveMacro = find_macro(_macro_id)

	if not macro or not macro.is_script_macro or not FileAccess.file_exists(macro.script_path):
		return &''

	var script: GDScript = ResourceLoader.load(macro.script_path, '', ResourceLoader.CACHE_MODE_REUSE) as GDScript

	if not script:
		return &''

	var instance: HenScriptMacroBase = script.new() as HenScriptMacroBase

	return instance.get_body_branch() if instance else &''


static func find_macro(_macro_id: StringName) -> HenSaveMacro:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global:
		return null

	if HenFunctionMacro.is_function_macro(_macro_id):
		return HenFunctionMacro.macro_for(global.SAVE_DATA, _macro_id)

	if HenMacroHookMacro.is_hook_macro(_macro_id):
		return HenMacroHookMacro.macro_for(global.SAVE_DATA, _macro_id)

	var sizes: Vector2i = Vector2i(global.action_macros.size(), global.script_macros.size())

	if sizes != _macro_index_sizes or _is_stale(global):
		_macro_index.clear()

		for pool: Array in [global.action_macros, global.script_macros]:
			for macro: HenSaveMacro in pool:
				if not _macro_index.has(macro.id):
					_macro_index[macro.id] = macro

		_macro_index_sizes = sizes

	return _macro_index.get(_macro_id)


# resolves the macro pool's current name so renamed macros reach already-saved actions
static func display_name(_action: HenSaveAction) -> String:
	if not _action.label.strip_edges().is_empty():
		return _action.label

	var macro: HenSaveMacro = find_macro(_action.macro_id)
	return macro.name if macro else _action.name


# one {kind, label, value} per input; kind picks the chip color, and the label is
# dropped on single-input actions (the value alone already reads). a part also
# carries `slot` (what the value editor writes to), `options` and, when another
# action feeds it, the recursive `capsule`
# _owner is the save data the action belongs to: with several scripts open, the
# active one is not always it, and a binding only resolves against its own
static func value_parts(_action: HenSaveAction, _owner: HenSaveData = null) -> Array[Dictionary]:
	var macro: HenSaveMacro = find_macro(_action.macro_id)
	var show_names: bool = _action.inputs.size() > 1
	var params: Dictionary = macro_params(macro)
	var parts: Array[Dictionary] = []

	for param: HenSaveParam in _action.inputs:
		var key: String = str(param.id)
		var part: Dictionary = _slot_part(_action, key, _seeded_value(macro, key, param.default_value), _is_raw(macro, key, param), _owner)

		# a slot that needs a source is unusable until bound, so say it out loud
		var declared: HenSaveParam = _macro_param(macro, key, param)
		var needs_bind: bool = declared.lvalue or declared.bind_only

		if part.kind == &'literal' and needs_bind:
			if HenUtils.is_node_ref_slot(declared.type, declared.bind_only, declared.optional):
				part.value = 'Self'
			else:
				part.value = '(none)' if declared.optional else 'not set'

		part.label = param.name if show_names else ''
		part.options = declared.options if not declared.options.is_empty() else param.options
		part.option_labels = declared.option_labels if not declared.option_labels.is_empty() else param.option_labels

		# an option whose value is an id nobody typed reads as the name it was given
		if part.kind == &'literal' and not part.option_labels.is_empty():
			part.value = declared.option_label(param.default_value)
		part.picker = declared.picker if not declared.picker.is_empty() else param.picker
		part.slot = input_slot(_action, param, declared, params)
		part.editor = editor_kind(part, needs_bind)

		parts.append(part)

	parts.append_array(branch_parts(_action, macro, _owner))

	return parts


# what the value editor of an input slot writes to, in the shape the inspector
# builds for the same input
static func input_slot(_action: HenSaveAction, _param: HenSaveParam, _declared: HenSaveParam, _params: Dictionary) -> Dictionary:
	var key: String = str(_param.id)

	return {
		action = _action,
		param = _param,
		type = slot_type(_action, _declared, _param),
		bind_store = _action.input_bindings,
		bind_key = key,
		expr_store = _action.input_expressions,
		expr_key = key,
		action_store = _action.input_actions,
		action_key = key,
		macro_params = _params
	}


# input id -> the macro's own param, which carries the flags an action clone may
# predate (options, lvalue, type_from)
static func macro_params(_macro: HenSaveMacro) -> Dictionary:
	var params: Dictionary = {}

	if not _macro:
		return params

	for param: HenSaveParam in _macro.inputs:
		params[str(param.id)] = param

	return params


# declared type, unless type_from points at another input whose bound source
# dictates it (set_value's Value follows Target)
static func slot_type(_action: HenSaveAction, _declared: HenSaveParam, _param: HenSaveParam) -> String:
	var type_from: String = str(_declared.type_from)

	if type_from.is_empty():
		return str(_param.type)

	var bind: String = _action.input_bindings.get(type_from, '')

	if bind.is_empty():
		return str(_param.type)

	var resolved: String = HenUtils.get_bound_source_type(_save_data(), bind)

	return resolved if not resolved.is_empty() else str(_param.type)


# feeds an input with a new producer, dropping whatever fed it before: an input
# has one source, so the binding and the expression cannot survive it
static func set_producer(_slot: Dictionary, _macro: HenSaveMacro, _output: StringName = &'') -> HenSaveAction:
	var child: HenSaveAction = HenSaveAction.create(_macro)
	var output: StringName = _output

	if output.is_empty():
		output = _macro.outputs[0].id if not _macro.outputs.is_empty() else &''

	(_slot.action_store as Dictionary)[_slot.action_key] = {
		action = child,
		output = output
	}

	(_slot.bind_store as Dictionary).erase(_slot.bind_key)

	var expr_store: Variant = _slot.get('expr_store')

	if expr_store != null:
		(expr_store as Dictionary).erase(_slot.get('expr_key', ''))

	return child


# duplicate(true) keeps every id, and the action id is what the card index, the
# debug flash and the selection address a node by. the param ids are the macro's
# own names (target, value), so those stay: the bindings are keyed by them
static func duplicate_action(_action: HenSaveAction) -> HenSaveAction:
	var copy: HenSaveAction = _action.duplicate(true)

	_reid_action(copy)

	return copy


static func _reid_action(_action: HenSaveAction) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global:
		return

	_action.id = global.get_new_node_counter()

	for entry: Variant in _action.input_actions.values():
		var nested: HenSaveAction = (entry as Dictionary).get('action')

		if nested:
			_reid_action(nested)

	for list: Array in HenGeneratorAction.nested_lists(_action):
		for nested: HenSaveAction in list:
			_reid_action(nested)


static func editor_kind(_part: Dictionary, _needs_bind: bool) -> StringName:
	if _part.kind != &'literal' or _needs_bind or not (_part.options as Array).is_empty():
		return &''

	if not StringName(str(_part.get('picker', &''))).is_empty():
		return &''

	return HenActionValueEditors.kind_for(str((_part.slot as Dictionary).type))


# recursive {action, title, icon, color, parts} of the action feeding a slot, so
# a row can render it as a nested capsule instead of a flat label
static func capsule_data(_ref: Variant, _owner: HenSaveData = null) -> Dictionary:
	var child: HenSaveAction = inline_child(_ref)

	if not child:
		return {}

	var macro: HenSaveMacro = find_macro(child.macro_id)
	var parts: Array[Dictionary] = value_parts(child, _owner)

	# a producer runs at the phase of the action it feeds, so its own editor has
	# no phase to offer
	for part: Dictionary in parts:
		(part.slot as Dictionary).inline = true

	return {
		action = child,
		title = display_name(child),
		icon = macro.icon if macro else '',
		color = macro.color if macro else '',
		parts = parts
	}


# where each configured branch goes; unset branches are left out of the row
static func branch_parts(_action: HenSaveAction, _macro: HenSaveMacro, _owner: HenSaveData = null) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []

	if not _macro:
		return parts

	var save_data: HenSaveData = _save_data(_owner)

	if not save_data:
		return parts

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		var target: HenSaveState = HenGeneratorAction.branch_target(save_data, _action, str(flow.id))

		if target:
			var source: Dictionary = HenGeneratorAction.branch_instance_source(save_data, _action, str(flow.id))
			var source_name: String = _bind_label(str(source.value), _owner) if str(source.get('kind', '')) == 'bind' else str(source.get('value', ''))
			var suffix: String = (' @ ' + source_name) if not source.is_empty() else ''
			parts.append({
				kind = &'branch',
				label = flow.name,
				value = '-> ' + target.name + suffix,
				slot = {action = _action}
			})

	return parts


# flattened parts, used as the row tooltip when the chips clip
static func value_preview(_action: HenSaveAction, _owner: HenSaveData = null) -> String:
	var texts: PackedStringArray = []

	for part: Dictionary in value_parts(_action, _owner):
		var value: String = ('(' + str(part.value) + ')') if part.kind == &'expression' else str(part.value)
		texts.append((str(part.label) + ': ' + value) if not str(part.label).is_empty() else value)

	return ' · '.join(texts)


# same precedence codegen uses: inline action > expression > binding > literal
static func _slot_part(_action: HenSaveAction, _key: String, _value: Variant, _raw: bool = false, _owner: HenSaveData = null) -> Dictionary:
	if _action.input_actions.has(_key):
		return {
			kind = &'action',
			value = inline_label(_action.input_actions[_key], _owner),
			capsule = capsule_data(_action.input_actions[_key], _owner)
		}

	if _action.input_expressions.has(_key):
		return {kind = &'expression', value = (_action.input_expressions[_key] as HenSaveActionExpression).code}

	var bind: String = _action.input_bindings.get(_key, '')

	if not bind.is_empty():
		return {kind = _bind_kind(bind, _owner), value = _bind_label(bind, _owner)}

	# a raw input is emitted verbatim, so quoting it here would misread as a string
	if _raw:
		return {kind = &'literal', value = str(_value) if _value != null else '—'}

	# the card draws a swatch for it: nobody reads a colour as four numbers
	if _value is Color:
		return {kind = &'literal', value = format_value(_value), swatch = _value}

	return {kind = &'literal', value = format_value(_value)}


# e.g. Raycast 120.0, 'enemy|world', +2 actions
static func inline_label(_ref: Variant, _owner: HenSaveData = null) -> String:
	var child: HenSaveAction = inline_child(_ref)

	if not child:
		return '?'

	var macro: HenSaveMacro = find_macro(child.macro_id)
	var literals: PackedStringArray = []
	var nested: int = 0

	for param: HenSaveParam in child.inputs:
		var key: String = str(param.id)

		if child.input_actions.has(key):
			nested += 1
		else:
			var part: Dictionary = _slot_part(child, key, _seeded_value(macro, key, param.default_value), _is_raw(macro, key, param), _owner)
			literals.append(('(' + str(part.value) + ')') if part.kind == &'expression' else str(part.value))

	var summary: String = ', '.join(literals)

	if nested > 0:
		summary += (', ' if not summary.is_empty() else '') + '+%d action%s' % [nested, 's' if nested > 1 else '']

	return display_name(child) + (' ' + summary if not summary.is_empty() else '')


# tolerates the {action, output} dict and a bare action (older data)
static func inline_child(_ref: Variant) -> HenSaveAction:
	if _ref is HenSaveAction:
		return _ref as HenSaveAction

	if _ref is Dictionary:
		return (_ref as Dictionary).get('action') as HenSaveAction

	return null


static func _is_raw(_macro: HenSaveMacro, _key: String, _param: HenSaveParam) -> bool:
	return _macro_param(_macro, _key, _param).raw


# the flags live on the macro definition; an action saved before they existed
# falls back to its own clone
static func _macro_param(_macro: HenSaveMacro, _key: String, _param: HenSaveParam) -> HenSaveParam:
	if not _macro:
		return _param

	for p: HenSaveParam in _macro.inputs:
		if str(p.id) == _key:
			return p

	return _param


# a bound slot is one of the script's variables, an engine-provided value or a
# native property
# the open script holding this action, which is not always the active one. a
# binding is stored by variable id and ids repeat across scripts, so reading one
# against the wrong save data silently shows another script's variable
static func owner_of(_action: HenSaveAction) -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global or not _action:
		return _save_data()

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and _holds_action(save_data, _action):
			return save_data

	return global.SAVE_DATA


static func _holds_action(_save_data: HenSaveData, _target: HenSaveAction) -> bool:
	return not state_id_of(_save_data, _target).is_empty()


# the state whose chain holds this action, however deep inside it the action sits
static func state_id_of(_save_data: HenSaveData, _target: HenSaveAction) -> StringName:
	if not _save_data or not _target:
		return &''

	for state_id: Variant in _save_data.state_actions:
		for action: HenSaveAction in _save_data.state_actions[state_id]:
			if contains_action(action, _target):
				return StringName(str(state_id))

	return &''


# an action may be nested in a loop body or feeding an input, so the search walks both
static func contains_action(_root: HenSaveAction, _target: HenSaveAction) -> bool:
	if _root == _target:
		return true

	for list: Array in HenGeneratorAction.nested_lists(_root):
		for child: HenSaveAction in list:
			if contains_action(child, _target):
				return true

	for key: Variant in _root.input_actions:
		var child: HenSaveAction = inline_child(_root.input_actions[key])

		if child and contains_action(child, _target):
			return true

	return false


static func _bind_kind(_bind: String, _owner: HenSaveData = null) -> StringName:
	var save_data: HenSaveData = _save_data(_owner)

	var bind: Dictionary = HenUtils.classify_bind_code(save_data, _bind)

	match str(bind.kind):
		'var':
			return &'variable'
		'native':
			# a source may ask for another chip: a node path reads as a node, not
			# as an engine value
			return StringName(str((bind.value as Dictionary).get('kind', 'native')))

	return &'property'


# bindings are stored by id, so the row shows the variable's current name
static func _bind_label(_bind: String, _owner: HenSaveData = null) -> String:
	return HenUtils.get_bind_label(_save_data(_owner), _bind)


static func _save_data(_owner: HenSaveData = null) -> HenSaveData:
	if _owner:
		return _owner

	var global: HenGlobal = Engine.get_singleton(&'Global')

	return global.SAVE_DATA if global else null


# literals read like code: strings quoted, an unset value shows as a dash
static func format_value(_value: Variant) -> String:
	if _value == null:
		return '—'

	if _value is String or _value is StringName:
		return "'" + str(_value) + "'"

	if _value is float:
		return _number(_value)

	if _value is Color:
		return '#' + (_value as Color).to_html(false)

	if _value is Vector2:
		return _number((_value as Vector2).x) + ', ' + _number((_value as Vector2).y)

	if _value is Vector3:
		var vec: Vector3 = _value
		return _number(vec.x) + ', ' + _number(vec.y) + ', ' + _number(vec.z)

	if _value is Vector2i:
		return str((_value as Vector2i).x) + ', ' + str((_value as Vector2i).y)

	if _value is Vector3i:
		var vec: Vector3i = _value
		return str(vec.x) + ', ' + str(vec.y) + ', ' + str(vec.z)

	return str(_value)


# a chip is a few characters wide, so a trailing .0 costs a third of the room it
# has and says nothing
static func _number(_value: float) -> String:
	var snapped: float = snappedf(_value, 0.001)

	if is_equal_approx(snapped, roundf(snapped)):
		return str(int(snapped))

	return str(snapped)


# pre-binding actions stored null, so the macro default is what the inspector shows
static func _seeded_value(_macro: HenSaveMacro, _key: String, _value: Variant) -> Variant:
	if _value != null or not _macro:
		return _value

	for input: HenSaveParam in _macro.inputs:
		if str(input.id) == _key:
			return input.default_value

	return null
