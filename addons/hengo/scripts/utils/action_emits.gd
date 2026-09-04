@tool
class_name HenActionEmits

# what code an action emits, read through the same priming codegen uses so the
# answer can never drift from what is actually generated

const TARGET_STATE_ID: StringName = &'preview_target'
# tokens a body may hold that name no input, output or branch
const SPECIAL_TOKENS: Array[String] = ['VCNODE_ID', 'loop_body']


# one entry per target class, collapsed to a single entry with an empty
# target_class when the classes all emit the same thing
static func of(_macro: HenSaveMacro) -> Array:
	var variants: Array = []
	var shapes: Dictionary = {}

	for target: StringName in target_classes(_macro):
		var data: Dictionary = _variant(_macro, target)

		shapes[JSON.stringify(data)] = true
		data['target_class'] = str(target)
		variants.append(data)

	if variants.is_empty():
		return []

	if shapes.size() == 1:
		variants[0]['target_class'] = ''
		return [variants[0]]

	return variants


# the class the bodies dispatch on comes from the script identity, so a macro that
# serves everything is only ever primed as Node
static func target_classes(_macro: HenSaveMacro) -> Array:
	if _macro.target_classes.is_empty():
		return [&'Node']

	var out: Array = []

	for target: StringName in _macro.target_classes:
		out.append(target)

	return out


static func _variant(_macro: HenSaveMacro, _target: StringName) -> Dictionary:
	var shape: Dictionary = _shape(_macro, _target, {})
	var option_shapes: Array = _option_shapes(_macro, _target, shape)

	if option_shapes.is_empty():
		return shape

	shape['option_shapes'] = option_shapes

	return shape


# everything a macro emits under one set of literals: the picker values are part
# of the context the bodies read, so a choice can change any of it
static func _shape(_macro: HenSaveMacro, _target: StringName, _values: Dictionary) -> Dictionary:
	var code: Dictionary = {}

	for phase: StringName in HenSaveAction.supported_phases(_macro):
		var primed: HenScriptMacroBase = instance_of(_macro, _target, phase, _values)

		if not primed:
			continue

		var body: String = HenGeneratorAction._get_phase_body(primed, phase)

		if not body.is_empty():
			code[str(phase)] = body

	var default: HenScriptMacroBase = instance_of(_macro, _target, HenSaveAction.default_phase(_macro), _values)

	if not default:
		return {code = code, outputs = {}, declares = {}}

	var outputs: Dictionary = {}

	for output: Dictionary in default.get_outputs():
		outputs[str(output.get('id', ''))] = HenGeneratorAction._output_rhs(default, str(output.get('id', '')))

	return {code = code, outputs = outputs, declares = _declares(default)}


# one axis at a time, holding the other pickers at their default: the question is
# whether a field changes the code, not what every combination of them emits
static func _option_shapes(_macro: HenSaveMacro, _target: StringName, _default: Dictionary) -> Array:
	var shapes: Array = []
	var base: String = JSON.stringify(_default)

	for param: HenSaveParam in _macro.inputs:
		if param.options.is_empty():
			continue

		var groups: Dictionary = {}

		for option: String in param.options:
			var shape: Dictionary = _normalize(
				_shape(_macro, _target, {str(param.id): option}), option, '{{' + str(param.id) + '}}'
			)
			var key: String = JSON.stringify(shape)

			if key == base:
				continue

			if not groups.has(key):
				shape['input'] = str(param.id)
				shape['values'] = []
				groups[key] = shape

			# bracket access on purpose: `values` is also a Dictionary method
			(groups[key]['values'] as Array).append(option)

		for key: String in groups:
			shapes.append(groups[key])

	return shapes


# a picked value is pasted into the code, so two choices differing only by that
# literal are one shape and not two
static func _normalize(_shape: Dictionary, _value: String, _token: String) -> Dictionary:
	if not _value.is_valid_identifier():
		return _shape

	var regex: RegEx = RegEx.create_from_string('\\b' + _value + '\\b')
	var out: Dictionary = {}

	for key: String in _shape:
		out[key] = _replaced(_shape[key], regex, _token)

	return out


static func _replaced(_value: Variant, _regex: RegEx, _token: String) -> Variant:
	if _value is String:
		return _regex.sub(_value as String, _token, true)

	if not _value is Dictionary:
		return _value

	var out: Dictionary = {}

	for key: String in (_value as Dictionary):
		out[key] = _replaced((_value as Dictionary)[key], _regex, _token)

	return out


# only what the macro actually contributes: an empty key would read as a feature
# the action has and does nothing with
static func _declares(_instance: HenScriptMacroBase) -> Dictionary:
	var out: Dictionary = {}
	var base: String = _instance.get_script_base()
	var scope: String = _instance.get_script_scope()

	if not base.is_empty():
		out['state_vars'] = base

	if not scope.is_empty():
		out['script_vars'] = scope

	for hook: String in ['reset', 'teardown']:
		var method: String = 'get_flow_' + hook

		if _instance.has_method(method) and not str(_instance.call(method)).is_empty():
			out[hook] = str(_instance.call(method))

	var overrides: Dictionary = {}

	for override: Dictionary in _instance.get_function_overrides():
		overrides[str(override.get('name', ''))] = _override_body(override)

	if not overrides.is_empty():
		out['overrides'] = overrides

	return out


# the body may be a callable that builds the string, which is what a macro reaches
# for when the override depends on its own context
static func _override_body(_override: Dictionary) -> String:
	var body: Variant = _override.get('body', '')

	if body is Callable:
		var built: Variant = (body as Callable).call()

		return str(built) if built is String else ''

	return str(body)


static func instance_of(_macro: HenSaveMacro, _target: StringName, _phase: StringName, _values: Dictionary = {}) -> HenScriptMacroBase:
	var primed: HenScriptMacroBase = HenGeneratorAction._load_instance(_macro)

	if not primed:
		return null

	HenGeneratorAction._prime_instance(_context(_target), primed, _synthetic_action(_macro, _phase, _values), _phase, 0)

	return primed


static func _context(_target: StringName) -> HenSaveData:
	var save_data: HenSaveData = HenSaveData.new()
	var state: HenSaveState = HenSaveState.new()

	save_data.identity = HenSaveDataIdentity.create(&'preview', _target, 'preview')
	state.id = TARGET_STATE_ID
	state.name = 'Somewhere'
	save_data.states.append(state)

	return save_data


# every branch points somewhere: an action that drops its `if` when nobody wired a
# branch would report a body it only emits in that one case
static func _synthetic_action(_macro: HenSaveMacro, _phase: StringName, _values: Dictionary = {}) -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.create(_macro)

	action.phase = _phase

	for param: HenSaveParam in action.inputs:
		if _values.has(str(param.id)):
			param.default_value = _values[str(param.id)]

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		action.branches[str(flow.id)] = {state_id = TARGET_STATE_ID}

	return action


# the json entry this action takes in tools/hengo_cli.gd, filled with the declared
# defaults, so the shape is copied instead of guessed
static func usage(_macro: HenSaveMacro) -> Dictionary:
	var entry: Dictionary = {id = str(_macro.id), phase = str(HenSaveAction.default_phase(_macro))}
	var inputs: Dictionary = {}

	for param: HenSaveParam in _macro.inputs:
		inputs[str(param.id)] = _slot_hint(param)

	if not inputs.is_empty():
		entry['inputs'] = inputs

	if not _macro.flow_outputs.is_empty():
		var branches: Dictionary = {}

		for flow: HenSaveFlowParam in _macro.flow_outputs:
			branches[str(flow.id)] = 'SomeState'

		entry['branches'] = branches

	return entry


static func _slot_hint(_param: HenSaveParam) -> Variant:
	if _param.bind_only:
		return {bind = '<variable>'}

	if _param.default_value != null:
		return _as_json(_param.default_value)

	return '<' + str(_param.type) + '>'


# the cli reads a color or a vector as a plain array, so stringifying the godot
# value straight would hand back something it cannot parse
static func _as_json(_value: Variant) -> Variant:
	match typeof(_value):
		TYPE_COLOR:
			var color: Color = _value

			return [color.r, color.g, color.b, color.a]
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [_value.x, _value.y]
		TYPE_VECTOR3, TYPE_VECTOR3I:
			return [_value.x, _value.y, _value.z]

	return _value


# every {{token}} a body holds, so a name that matches no slot can be caught
static func tokens_of(_macro: HenSaveMacro) -> Array:
	var found: Dictionary = {}

	for variant: Dictionary in of(_macro):
		for shape: Dictionary in [variant] + (variant.get('option_shapes', []) as Array):
			for source: Variant in _sources_of(shape):
				for token: String in _tokens_in(str(source)):
					found[token] = true

	return found.keys()


static func _sources_of(_shape: Dictionary) -> Array:
	var sources: Array = (_shape.code as Dictionary).values()

	for value: Variant in (_shape.declares as Dictionary).values():
		if value is Dictionary:
			sources.append_array((value as Dictionary).values())
		else:
			sources.append(value)

	return sources.filter(func(source: Variant) -> bool: return source is String)


static func _tokens_in(_body: String) -> Array:
	var out: Array = []
	var from: int = _body.find('{{')

	while from >= 0:
		var close: int = _body.find('}}', from)

		if close < 0:
			break

		out.append(_body.substr(from + 2, close - from - 2))
		from = _body.find('{{', close)

	return out


# the slot names a body may legally reference
static func known_tokens(_macro: HenSaveMacro) -> Array:
	var out: Array = []

	out.append_array(SPECIAL_TOKENS)

	for param: HenSaveParam in _macro.inputs:
		out.append(str(param.id))

	for param: HenSaveParam in _macro.outputs:
		out.append('out:' + str(param.id))

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		out.append(str(flow.id))

	return out


# --- human readable ---------------------------------------------------------


static func text(_macro: HenSaveMacro) -> String:
	var lines: PackedStringArray = []

	lines.append('%s   "%s"   category: %s' % [str(_macro.id), _macro.name, _macro.category])

	if not _macro.description.is_empty():
		lines.append('  ' + _macro.description)

	lines.append('')
	lines.append('  phases: %s   default: %s' % [
		', '.join(HenSaveAction.supported_phases(_macro).map(func(p: StringName) -> String: return str(p))),
		str(HenSaveAction.default_phase(_macro))
	])
	lines.append('  serves: ' + ('any class' if _macro.target_classes.is_empty() else ', '.join(target_classes(_macro).map(func(c: StringName) -> String: return str(c)))))
	lines.append('  has body: %s   loop only: %s' % [_yes(_macro.has_body), _yes(_needs_loop(_macro))])

	_append_inputs(lines, _macro)
	_append_flow(lines, _macro)
	_append_emits(lines, _macro)

	lines.append('')
	lines.append('  json')

	for line: String in JSON.stringify(usage(_macro), '  ').split('\n'):
		lines.append('    ' + line)

	return '\n'.join(lines)


static func _append_inputs(_lines: PackedStringArray, _macro: HenSaveMacro) -> void:
	if _macro.inputs.is_empty():
		return

	_lines.append('')
	_lines.append('  inputs')

	for param: HenSaveParam in _macro.inputs:
		var flags: PackedStringArray = []

		if param.raw:
			flags.append('raw')

		if param.lvalue:
			flags.append('lvalue')

		if param.bind_only:
			flags.append('bind only')

		if param.optional:
			flags.append('optional')

		if not str(param.type_from).is_empty():
			flags.append('type from ' + str(param.type_from))

		_lines.append(('    %s %s %s' % [
			str(param.id).rpad(14),
			str(param.type).rpad(12),
			' '.join(flags)
		]).rstrip(' '))

		if param.default_value != null:
			_lines.append('      default: ' + JSON.stringify(_as_json(param.default_value)))

		if not param.options.is_empty():
			_lines.append('      options: ' + ', '.join(param.options))

		if not param.doc.is_empty():
			_lines.append('      ' + param.doc)


static func _append_flow(_lines: PackedStringArray, _macro: HenSaveMacro) -> void:
	if not _macro.outputs.is_empty():
		_lines.append('')
		_lines.append('  outputs')

		for param: HenSaveParam in _macro.outputs:
			_lines.append('    %s %s %s' % [str(param.id).rpad(14), str(param.type).rpad(12), param.doc])

	if _macro.flow_outputs.is_empty():
		return

	_lines.append('')
	_lines.append('  branches')

	for flow: HenSaveFlowParam in _macro.flow_outputs:
		_lines.append('    %s %s %s' % [
			str(flow.id).rpad(14),
			('optional' if flow.optional else 'required').rpad(12),
			flow.doc
		])


static func _append_emits(_lines: PackedStringArray, _macro: HenSaveMacro) -> void:
	for variant: Dictionary in of(_macro):
		var target: String = str(variant.target_class)

		_append_shape(_lines, variant, 'emits' + ('' if target.is_empty() else ' on ' + target))

		for shape: Dictionary in (variant.get('option_shapes', []) as Array):
			_append_shape(_lines, shape, 'emits with "%s" = %s' % [shape.input, ' or '.join(shape['values'])])


static func _append_shape(_lines: PackedStringArray, _shape: Dictionary, _title: String) -> void:
	_lines.append('')
	_lines.append('  ' + _title)

	for group: Dictionary in _group_phases(_shape.code):
		_lines.append('    ' + ', '.join(group.phases) + ':')

		for line: String in str(group.code).split('\n'):
			_lines.append('      ' + line)

	for key: String in (_shape.outputs as Dictionary):
		_lines.append('    output %s = %s' % [key, _shape.outputs[key]])

	for key: String in (_shape.declares as Dictionary):
		var value: Variant = _shape.declares[key]

		if not value is Dictionary:
			_lines.append('    %s: %s' % [key, str(value).replace('\n', ' / ')])
			continue

		for name: String in (value as Dictionary):
			_lines.append('    %s %s: %s' % [key.trim_suffix('s'), name, str(value[name]).replace('\n', ' / ')])


# phases whose body is identical read as one entry, which is the common case
static func _group_phases(_code: Dictionary) -> Array:
	var groups: Array = []

	for phase: String in _code:
		var body: String = str(_code[phase])
		var merged: bool = false

		for group: Dictionary in groups:
			if str(group.code) == body:
				(group.phases as Array).append(phase)
				merged = true
				break

		if not merged:
			groups.append({phases = [phase], code = body})

	return groups


static func _needs_loop(_macro: HenSaveMacro) -> bool:
	var primed: HenScriptMacroBase = HenGeneratorAction._load_instance(_macro)

	return primed.get_needs_loop() if primed else false


static func _yes(_value: bool) -> String:
	return 'yes' if _value else 'no'
