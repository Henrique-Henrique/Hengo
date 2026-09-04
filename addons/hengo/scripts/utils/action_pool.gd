@tool
class_name HenActionPool
extends RefCounted

# the action macros a picker may offer, in one place: the search panel and the
# code search both ask here, so a filter fixed on one side is fixed on both

static var _producer_cache: Dictionary = {}


static func all() -> Array[HenSaveMacro]:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global:
		return []

	var script_class: StringName = _script_class()
	var pool: Array[HenSaveMacro] = []

	for macro: HenSaveMacro in global.action_macros + global.script_macros:
		if macro.serves_class(script_class):
			pool.append(macro)

	pool.append_array(function_macros(global.SAVE_DATA))

	return pool


# the functions of the script, offered like any other action. inside the body of
# one, the finish that ends it takes its place: a function is not a step of itself
static func function_macros(_save_data: HenSaveData) -> Array[HenSaveMacro]:
	var out: Array[HenSaveMacro] = []

	if not _save_data:
		return out

	var open_scope: HenSaveResType = HenRoute.current_scope(_save_data)

	for func_res: HenSaveFunc in _save_data.functions:
		out.append(HenFunctionMacro.macro_of(func_res, func_res == open_scope))

	# inside a macro, the places it leaves for its uses are steps of its own
	if open_scope is HenSaveStateMacro:
		for flow: HenSaveFlowParam in (open_scope as HenSaveStateMacro).flow_inputs:
			out.append(HenMacroHookMacro.macro_of(open_scope as HenSaveStateMacro, flow))

	return out


# actions with a body for this phase: offering one that has none would let the
# picker relocate the step to another chain behind the user's back
static func for_phase(_phase: StringName) -> Array[HenSaveMacro]:
	if _phase.is_empty():
		return all()

	var out: Array[HenSaveMacro] = []

	for macro: HenSaveMacro in all():
		if HenSaveAction.supported_phases(macro).has(_phase):
			out.append(macro)

	return out


# actions that can feed an input of this type: a pure producer whose output the
# type rules accept. an empty type means no filter at all
static func producers_for(_type: String) -> Array[HenSaveMacro]:
	var pool: Array[HenSaveMacro] = all()

	if _type.is_empty():
		return pool

	# the pool depends on what the script extends, so the key carries it: switching
	# scripts with a type-only key would serve the previous one's list
	var key: String = str(_script_class()) + '|' + _type

	if _producer_cache.has(key):
		return _producer_cache[key]

	var producers: Array[HenSaveMacro] = []

	for macro: HenSaveMacro in pool:
		if _is_producer(macro, _type):
			producers.append(macro)

	_producer_cache[key] = producers

	return producers


# the pool is rebuilt when a script opens or a macro is edited, and a stale cache
# would keep offering an action that no longer serves this class
static func invalidate() -> void:
	_producer_cache.clear()


static func _script_class() -> StringName:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	if not global or not global.SAVE_DATA or not global.SAVE_DATA.identity:
		return &''

	return global.SAVE_DATA.identity.type


# loading the script behind each of 350 actions costs 1.5s the first time
static func outputs_for(_macro: HenSaveMacro, _type: String) -> Array:
	var out: Array = []

	for output: HenSaveParam in _macro.outputs:
		if type_accepts(_type, str(output.type)):
			out.append({
				id = str(output.id),
				name = output.name,
				type = str(output.type)
			})

	return out


static func _is_producer(_macro: HenSaveMacro, _type: String) -> bool:
	if outputs_for(_macro, _type).is_empty():
		return false

	return _is_inlinable(_macro)


# a function or a hook is built in memory, so asking its instance costs nothing
static func _is_inlinable(_macro: HenSaveMacro) -> bool:
	if _macro.is_script_macro:
		return _macro.is_inlinable

	var instance: HenScriptMacroBase = HenGeneratorAction._load_instance(_macro)

	return instance != null and HenGeneratorAction.is_inlinable(instance)


static func type_accepts(_input_type: String, _output_type: String) -> bool:
	return _input_type.is_empty() or _input_type == 'Variant' or _output_type == 'Variant' \
		or HenUtils.is_type_relation_valid(StringName(_input_type), StringName(_output_type))
