@tool
class_name HenFunctionMacro extends HenScriptMacroBase

# a function of the script dressed as an action, so the palette, the card, the
# wires and the codegen treat it like any other one. two macros come out of one
# definition: the call, offered anywhere, and the finish that ends it, offered
# only inside its own body

const ICON: String = 'square-function'
const RETURN_ICON: String = 'corner-down-left'
const COLOR: String = '#b05353'
const CALL_PREFIX: String = 'fn:'
const RETURN_PREFIX: String = 'fnr:'
const BRANCH_INPUT: StringName = &'branch'
# where a branching function parks an output, since the return carries the branch
const OUTPUT_VAR_PREFIX: String = '_fn_'

# definition instance -> the synthesized macro, whose param arrays are the
# definition's own. keyed by instance and not by id, since two scripts number
# their definitions from the same counter
static var _macro_cache: Dictionary = {}
# built once: a call fits every phase, and the four flows say so
static var _phase_flows: Array[HenSaveFlowParam] = []

var save_data: HenSaveData
var func_res: HenSaveFunc
# the finish of the function, instead of a call to it
var is_return: bool = false


static func of(_save_data: HenSaveData, _func: HenSaveFunc, _is_return: bool = false) -> HenFunctionMacro:
	var macro: HenFunctionMacro = HenFunctionMacro.new()

	macro.save_data = _save_data
	macro.func_res = _func
	macro.is_return = _is_return

	return macro


static func is_function_macro(_macro_id: StringName) -> bool:
	var text: String = str(_macro_id)

	return text.begins_with(CALL_PREFIX) or text.begins_with(RETURN_PREFIX)


static func is_return_macro(_macro_id: StringName) -> bool:
	return str(_macro_id).begins_with(RETURN_PREFIX)


static func function_id_of(_macro_id: StringName) -> StringName:
	var text: String = str(_macro_id)

	for prefix: String in [RETURN_PREFIX, CALL_PREFIX]:
		if text.begins_with(prefix):
			return StringName(text.substr(prefix.length()))

	return &''


static func call_id(_func: HenSaveFunc) -> StringName:
	return StringName(CALL_PREFIX + str(_func.id))


static func return_id(_func: HenSaveFunc) -> StringName:
	return StringName(RETURN_PREFIX + str(_func.id))


static func instance_for(_save_data: HenSaveData, _macro_id: StringName) -> HenFunctionMacro:
	var save_data: HenSaveData = _save_data if _save_data else _active_save_data()
	var func_res: HenSaveFunc = save_data.find_function(function_id_of(_macro_id)) if save_data else null

	return of(save_data, func_res, is_return_macro(_macro_id)) if func_res else null


static func macro_for(_save_data: HenSaveData, _macro_id: StringName) -> HenSaveMacro:
	var save_data: HenSaveData = _save_data if _save_data else _active_save_data()
	var func_res: HenSaveFunc = save_data.find_function(function_id_of(_macro_id)) if save_data else null

	return macro_of(func_res, is_return_macro(_macro_id)) if func_res else null


# the param arrays are shared with the definition on purpose: an input added there
# has to show up on every action of it without anyone rebuilding a pool
static func macro_of(_func: HenSaveFunc, _is_return: bool = false) -> HenSaveMacro:
	var id: StringName = return_id(_func) if _is_return else call_id(_func)
	var key: String = str(_func.get_instance_id()) + ('r' if _is_return else 'c')
	var cached: Dictionary = _macro_cache.get(key, {})
	var macro: HenSaveMacro = cached.get('macro') as HenSaveMacro if cached else null

	# a freed definition can leave its instance id to another one, so the reference
	# is what says the cached macro is still the right one
	if macro and (cached.ref as WeakRef).get_ref() != _func:
		macro = null

	# the finish materializes its slots, so it is rebuilt when the shape moves
	if macro and _is_return and str(cached.get('stamp', '')) != _shape_stamp(_func):
		macro = null

	if not macro:
		macro = HenSaveMacro.new()
		macro.id = id
		macro.function_id = _func.id
		macro.color = COLOR
		macro.category = 'functions'
		macro.flow_inputs = _phase_inputs()

		macro.icon = RETURN_ICON if _is_return else ICON

		if _is_return:
			macro.inputs = _return_inputs(_func)

		_macro_cache[key] = {macro = macro, ref = weakref(_func), stamp = _shape_stamp(_func)}

	# the arrays are read every time: adding an input through the inspector swaps
	# the array of the definition, and a macro holding the old one shows nothing
	if not _is_return:
		macro.inputs = _func.inputs
		macro.outputs = _func.outputs
		macro.flow_outputs = _func.flow_outputs

	macro.name = 'Finish' if _is_return else _func.name
	macro.description = ('Ends ' + _func.name + ' and hands back what it produced.') if _is_return else _func.description

	return macro


# a finish takes one slot per output plus the way out it ends on. the output slots
# keep the ids of the outputs, so the body can name them
static func _return_inputs(_func: HenSaveFunc) -> Array[HenSaveParam]:
	var inputs: Array[HenSaveParam] = []

	for param: HenSaveParam in _func.outputs:
		var data: Dictionary = param.get_data()

		data.doc = 'Value this path produces.'
		inputs.append(HenSaveParam.create(data))

	if _func.flow_outputs.is_empty():
		return inputs

	var options: Array[String] = []
	var labels: Array[String] = []

	for flow: HenSaveFlowParam in _func.flow_outputs:
		options.append(str(flow.id))
		labels.append(flow.name)

	inputs.append(HenSaveParam.create({
		name = 'Result',
		type = &'String',
		id = BRANCH_INPUT,
		raw = true,
		options = options,
		option_labels = labels,
		default_value = options[0],
		doc = 'Which way out of the function this path takes.'
	}))

	return inputs


# what the finish slots are built from: the outputs and the ways out
static func _shape_stamp(_func: HenSaveFunc) -> String:
	var parts: PackedStringArray = []

	for param: HenSaveParam in _func.outputs:
		parts.append(str(param.id) + ':' + str(param.type))

	parts.append('|')

	for flow: HenSaveFlowParam in _func.flow_outputs:
		parts.append(str(flow.id) + ':' + flow.name)

	return ','.join(parts)


# the cached macros of a definition, dropped when it is deleted
static func forget(_func: HenSaveFunc) -> void:
	_macro_cache.erase(str(_func.get_instance_id()) + 'c')
	_macro_cache.erase(str(_func.get_instance_id()) + 'r')


static func _phase_inputs() -> Array[HenSaveFlowParam]:
	if _phase_flows.is_empty():
		for phase: StringName in HenSaveAction.PHASE_ORDER:
			_phase_flows.append(HenSaveFlowParam.create({name = HenActionVisuals.phase_label(phase), id = phase}))

	return _phase_flows


static func _active_save_data() -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	return global.SAVE_DATA if global else null


static func output_var(_func: HenSaveFunc, _output_id: String) -> String:
	return OUTPUT_VAR_PREFIX + str(_func.id) + '_' + _output_id


# a function with no way out and a single output is read as its return value; any
# other shape runs as a statement and parks what it produces
static func returns_value(_func: HenSaveFunc) -> bool:
	return _func.flow_outputs.is_empty() and _func.outputs.size() == 1


func get_id() -> StringName:
	return return_id(func_res) if is_return else call_id(func_res)


func get_display_name() -> String:
	return 'Finish' if is_return else func_res.name


func get_description() -> String:
	if is_return:
		return 'Ends ' + func_res.name + ' and hands back what it produced.'

	return func_res.description


func get_icon() -> String:
	return RETURN_ICON if is_return else ICON


func get_color() -> String:
	return COLOR


func get_needs_function() -> bool:
	return is_return


func get_inputs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var params: Array[HenSaveParam] = macro_of(func_res, true).inputs if is_return else func_res.inputs

	for param: HenSaveParam in params:
		out.append(param.get_data())

	return out


func get_outputs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	if is_return:
		return out

	for param: HenSaveParam in func_res.outputs:
		out.append(param.get_data())

	return out


func get_flow_inputs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for flow: HenSaveFlowParam in _phase_inputs():
		out.append(flow.get_data())

	return out


func get_flow_outputs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	if is_return:
		return out

	for flow: HenSaveFlowParam in func_res.flow_outputs:
		out.append(flow.get_data())

	return out


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func get_output_rhs(_id: String) -> String:
	if is_return or not _has_output(_id):
		return ''

	if returns_value(func_res):
		return call_code()

	return '_ref.' + output_var(func_res, _id)


func has_output_rhs(_id: String) -> bool:
	return not is_return and _has_output(_id)


func call_code() -> String:
	var args: PackedStringArray = []

	for param: HenSaveParam in func_res.inputs:
		args.append('{{' + str(param.id) + '}}')

	return '_ref.' + HenGeneratorFunction.method_name(save_data, func_res) + '(' + ', '.join(args) + ')'


func _has_output(_id: String) -> bool:
	for param: HenSaveParam in func_res.outputs:
		if str(param.id) == _id:
			return true

	return false


func _body() -> String:
	return _return_body() if is_return else _call_body()


# a function of a script runs a body of its own, so the call has to be emitted
# even with nobody storing the value: only a native producer is free to vanish
func get_unstored_body() -> String:
	return '' if is_return or not func_res.flow_outputs.is_empty() else call_code()


func _call_body() -> String:
	if returns_value(func_res):
		return '{{out:' + str(func_res.outputs[0].id) + '}}'

	if func_res.flow_outputs.is_empty():
		return call_code()

	var lines: PackedStringArray = ['match ' + call_code() + ':']

	for flow: HenSaveFlowParam in func_res.flow_outputs:
		lines.append("\t&'" + str(flow.id) + "':")
		lines.append('\t\t{{' + str(flow.id) + '}}')

	return '\n'.join(lines)


func _return_body() -> String:
	if returns_value(func_res):
		return 'return {{' + str(func_res.outputs[0].id) + '}}'

	var lines: PackedStringArray = []

	for param: HenSaveParam in func_res.outputs:
		lines.append('_ref.' + output_var(func_res, str(param.id)) + ' = {{' + str(param.id) + '}}')

	if func_res.flow_outputs.is_empty():
		lines.append('return')
	else:
		lines.append("return &'{{" + str(BRANCH_INPUT) + "}}'")

	return '\n'.join(lines)
