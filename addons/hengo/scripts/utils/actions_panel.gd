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


# a phase is only a valid target when the macro has a body for it
static func can_use_phase(_action: HenSaveAction, _phase: StringName) -> bool:
	var macro: HenSaveMacro = find_macro(_action.macro_id)

	if not macro:
		return str(_action.phase) == str(_phase)

	return HenSaveAction.supported_phases(macro).has(_phase)


# macro id -> macro, plus the pool sizes it was built from
static var _macro_index: Dictionary = {}
static var _macro_index_sizes: Vector2i = Vector2i(-1, -1)


# the pools are rewritten wholesale on load, and an index keyed by id would keep
# serving the macros they held before
static func invalidate_macro_index() -> void:
	_macro_index.clear()
	_macro_index_sizes = Vector2i(-1, -1)


# every action row resolves its macro, several times over, so this cannot scan
static func find_macro(_macro_id: StringName) -> HenSaveMacro:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global:
		return null

	var sizes: Vector2i = Vector2i(global.action_macros.size(), global.script_macros.size())

	if sizes != _macro_index_sizes:
		_macro_index.clear()

		for pool: Array in [global.action_macros, global.script_macros]:
			for macro: HenSaveMacro in pool:
				if not _macro_index.has(macro.id):
					_macro_index[macro.id] = macro

		_macro_index_sizes = sizes

	return _macro_index.get(_macro_id)


# resolves the macro pool's current name so renamed macros reach already-saved actions
static func display_name(_action: HenSaveAction) -> String:
	var macro: HenSaveMacro = find_macro(_action.macro_id)
	return macro.name if macro else _action.name


# one {kind, label, value} per input; kind picks the chip color, and the label is
# dropped on single-input actions (the value alone already reads). a part also
# carries `slot` (what the value editor writes to), `options`, `editable` and,
# when another action feeds it, the recursive `capsule`
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
			part.value = '(none)' if declared.optional else 'not set'

		part.label = param.name if show_names else ''
		part.options = declared.options if not declared.options.is_empty() else param.options
		part.slot = input_slot(_action, param, declared, params)
		part.editable = part.kind == &'literal' and not needs_bind and (part.options as Array).is_empty() and is_text_type(str(part.slot.type))

		parts.append(part)

	parts.append_array(output_parts(_action, macro, _owner))
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


# a type that reads and round-trips as a single line of text; anything composite
# keeps its dedicated inspector editor
static func is_text_type(_type: String) -> bool:
	return HenUtils.get_variant_type_from_string(_type) in [TYPE_NIL, TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT]


# text typed in a value chip, converted to the slot type. an untyped slot stays a
# string, which is what the inspector's editor does for Variant
static func parse_literal(_text: String, _type: String) -> Variant:
	match HenUtils.get_variant_type_from_string(_type):
		TYPE_STRING_NAME:
			return StringName(_text)
		TYPE_INT:
			return int(_text)
		TYPE_FLOAT:
			return float(_text)

	return _text


# what a chip shows once it is being typed into: the stored text without the
# quotes format_value adds
static func edit_text(_value: Variant) -> String:
	return '' if _value == null else str(_value)


# the literal a chip edits, seeded from the macro default the same way the
# inspector seeds it before showing an editor
static func literal_value(_slot: Dictionary) -> Variant:
	var param: HenSaveParam = _slot.get('param')

	if not param:
		return null

	if param.default_value == null:
		var declared: HenSaveParam = (_slot.get('macro_params', {}) as Dictionary).get(str(_slot.get('bind_key', '')))

		if declared and declared.default_value != null:
			param.default_value = declared.default_value

	return param.default_value


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


# where each stored output lands, so a producer's reason to exist reads on the
# row; an unbound output is left out
static func output_parts(_action: HenSaveAction, _macro: HenSaveMacro, _owner: HenSaveData = null) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []

	if not _macro or _macro.outputs.is_empty():
		return parts

	var show_names: bool = _macro.outputs.size() > 1

	for output: HenSaveParam in _macro.outputs:
		var bind: String = str(_action.output_bindings.get(str(output.id), ''))

		if bind.is_empty():
			continue

		parts.append({
			kind = _bind_kind(bind, _owner),
			label = output.name if show_names else '',
			value = '-> ' + _bind_label(bind, _owner),
			slot = {action = _action}
		})

	return parts


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
	for state_id: Variant in _save_data.state_actions:
		for action: HenSaveAction in _save_data.state_actions[state_id]:
			if _contains_action(action, _target):
				return true

	return false


# an action may be nested in a loop body or feeding an input, so the search walks both
static func _contains_action(_root: HenSaveAction, _target: HenSaveAction) -> bool:
	if _root == _target:
		return true

	for child: HenSaveAction in _root.body_actions:
		if _contains_action(child, _target):
			return true

	for key: Variant in _root.input_actions:
		var child: HenSaveAction = inline_child(_root.input_actions[key])

		if child and _contains_action(child, _target):
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
		return str(snappedf(_value as float, 0.001))

	return str(_value)


# pre-binding actions stored null, so the macro default is what the inspector shows
static func _seeded_value(_macro: HenSaveMacro, _key: String, _value: Variant) -> Variant:
	if _value != null or not _macro:
		return _value

	for input: HenSaveParam in _macro.inputs:
		if str(input.id) == _key:
			return input.default_value

	return null
