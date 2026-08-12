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

	return pool


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


# the outputs of this action the input can actually take: with more than one the
# picker has to ask which, or a Vector2 XY always feeds X
static func outputs_for(_macro: HenSaveMacro, _type: String) -> Array:
	var instance: HenScriptMacroBase = HenGeneratorAction._load_instance(_macro)
	var out: Array = []

	if not instance:
		return out

	for output: Dictionary in instance.get_outputs():
		if type_accepts(_type, str(output.get('type', 'Variant'))):
			out.append({
				id = str(output.get('id', '')),
				name = str(output.get('name', output.get('id', ''))),
				type = str(output.get('type', 'Variant'))
			})

	return out


static func _is_producer(_macro: HenSaveMacro, _type: String) -> bool:
	var instance: HenScriptMacroBase = HenGeneratorAction._load_instance(_macro)

	if not instance or not HenGeneratorAction.is_inlinable(instance):
		return false

	return not outputs_for(_macro, _type).is_empty()


static func type_accepts(_input_type: String, _output_type: String) -> bool:
	return _input_type.is_empty() or _input_type == 'Variant' or _output_type == 'Variant' \
		or HenUtils.is_type_relation_valid(StringName(_input_type), StringName(_output_type))
