class_name HenGeneratorFunction extends RefCounted

# writes the methods the functions of a script stand for. a function is an action
# list like a state's, run from wherever it is called instead of from a lifecycle
# phase, so it emits at script scope and never changes state


# what a step of a function keeps between runs lives at script scope, so zeroing
# it and undoing it are methods the callers ask for
const HOOK_SUFFIX: Dictionary = {
	get_flow_reset = '_reset',
	get_flow_teardown = '_teardown'
}


static func hook_method(_save_data: HenSaveData, _func: HenSaveFunc, _method: StringName) -> String:
	return method_name(_save_data, _func) + str(HOOK_SUFFIX.get(str(_method), '_hook'))


# two names can land on the same method ("take damage" and "Take Damage"), and one
# would overwrite the other: the later one is numbered, by the order they are kept
static func method_name(_save_data: HenSaveData, _func: HenSaveFunc) -> String:
	var base: String = _func.method_name()

	if not _save_data:
		return base

	var taken: int = 0

	for other: HenSaveFunc in _save_data.functions:
		if other == _func:
			break

		if other.method_name() == base:
			taken += 1

	return base if taken == 0 else base + '_' + str(taken + 1)


# every function of the script as a method, plus the variables a branching one
# parks its outputs in
static func get_functions_code(_save_data: HenSaveData) -> String:
	if not _save_data or _save_data.functions.is_empty():
		return ''

	var blocks: PackedStringArray = []

	for func_res: HenSaveFunc in _save_data.functions:
		blocks.append(_method_code(_save_data, func_res))

		for method: StringName in [&'get_flow_reset', &'get_flow_teardown']:
			var hook: String = _hook_code(_save_data, func_res, method)

			if not hook.is_empty():
				blocks.append(hook)

	return '\n\n'.join(blocks) + '\n\n'


static func _hook_code(_save_data: HenSaveData, _func: HenSaveFunc, _method: StringName) -> String:
	var tokens: Array = HenGeneratorAction.get_scope_hook_tokens(_save_data, _func.scope_state(), _method)

	if tokens.is_empty():
		return ''

	var body: PackedStringArray = []

	for token: Variant in tokens:
		body.append('\t' + str(token))

	return 'func {name}() -> void:\n{body}'.format({
		name = hook_method(_save_data, _func, _method),
		body = '\n'.join(body)
	})


# the outputs of a function that reports a way out ride script variables, since
# the return itself carries which way it took
static func get_output_var_lines(_save_data: HenSaveData) -> Array:
	var lines: Array = []

	if not _save_data:
		return lines

	for func_res: HenSaveFunc in _save_data.functions:
		if HenFunctionMacro.returns_value(func_res):
			continue

		for param: HenSaveParam in func_res.outputs:
			lines.append('var ' + HenFunctionMacro.output_var(func_res, str(param.id)) + ': ' + _type_hint(param) + ' = ' + _default_code(_save_data, param))

	return lines


# class level declarations the actions of a function need. a function has no state
# class to hold them, so they land at script scope, one set per definition
static func get_base_lines(_save_data: HenSaveData) -> Array:
	var lines: Array = []

	if not _save_data:
		return lines

	for func_res: HenSaveFunc in _save_data.functions:
		lines.append_array(HenGeneratorAction.get_state_base_lines(_save_data, func_res.scope_state()))

	return lines


static func _method_code(_save_data: HenSaveData, _func: HenSaveFunc) -> String:
	var scope: HenSaveState = _func.scope_state()
	var tokens: Array = HenGeneratorAction.get_function_tokens(_save_data, scope)
	var body: PackedStringArray = []

	for token: Variant in tokens:
		body.append('\t' + str(token))

	# a function that reports a way out has to name one even when nothing ran
	if not HenFunctionMacro.returns_value(_func) and not _func.flow_outputs.is_empty():
		body.append("\treturn &''")

	if body.is_empty():
		body.append('\tpass')

	return 'func {name}({params}) -> {type}:\n{body}'.format({
		name = method_name(_save_data, _func),
		params = _params_code(_func),
		type = _return_type(_func),
		body = '\n'.join(body)
	})


static func _params_code(_func: HenSaveFunc) -> String:
	var params: PackedStringArray = []

	for param: HenSaveParam in _func.inputs:
		params.append(param.name.to_snake_case() + ': ' + _type_hint(param) + ' = ' + _param_default(param))

	return ', '.join(params)


# a branching function answers with the way out it took, a plain one with its only
# output, and one that produces nothing at all with nothing
static func _return_type(_func: HenSaveFunc) -> String:
	if not _func.flow_outputs.is_empty():
		return 'StringName'

	if HenFunctionMacro.returns_value(_func):
		return _type_hint(_func.outputs[0])

	return 'void'


static func _type_hint(_param: HenSaveParam) -> String:
	var type: String = str(_param.type)

	if type.is_empty() or type == 'Variant' or not (HenEnums.VARIANT_TYPES.has(type) or ClassDB.class_exists(type)):
		return 'Variant'

	return type


# a default keeps a call valid while the caller has nothing in the slot yet
static func _param_default(_param: HenSaveParam) -> String:
	if _param.default_value != null:
		return HenActionCode.get_default_value_code(null, str(_param.type), false, '', null, _param.default_value)

	return _default_code(null, _param)


static func _default_code(_save_data: HenSaveData, _param: HenSaveParam) -> String:
	var type: String = _type_hint(_param)

	if type == 'Variant' or ClassDB.class_exists(type):
		return 'null'

	return HenActionCode.get_default_value_code(_save_data, type, false)
