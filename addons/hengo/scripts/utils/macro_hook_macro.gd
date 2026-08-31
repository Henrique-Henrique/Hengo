@tool
class_name HenMacroHookMacro extends HenScriptMacroBase

# one action per named place a macro leaves for its uses: dropping it inside the
# macro says where those steps run, and each use fills the place with its own

const ICON: String = 'chevrons-right'
const COLOR: String = '#e08b7f'
const PREFIX: String = 'mh:'

# macro id + hook id -> the synthesized macro
static var _macro_cache: Dictionary = {}

var save_data: HenSaveData
var macro_res: HenSaveStateMacro
var hook: HenSaveFlowParam


static func is_hook_macro(_macro_id: StringName) -> bool:
	return str(_macro_id).begins_with(PREFIX)


static func hook_id(_macro: HenSaveStateMacro, _flow: HenSaveFlowParam) -> StringName:
	return StringName(PREFIX + str(_macro.id) + ':' + str(_flow.id))


# "mh:<macro id>:<hook id>" -> [macro id, hook id]
static func parts_of(_macro_id: StringName) -> PackedStringArray:
	return str(_macro_id).substr(PREFIX.length()).split(':')


static func instance_for(_save_data: HenSaveData, _macro_id: StringName) -> HenMacroHookMacro:
	var save_data: HenSaveData = _save_data if _save_data else _active_save_data()
	var parts: PackedStringArray = parts_of(_macro_id)

	if not save_data or parts.size() != 2:
		return null

	var macro_res: HenSaveStateMacro = save_data.find_macro(StringName(parts[0]))
	var flow: HenSaveFlowParam = macro_res.find_flow_input(StringName(parts[1])) if macro_res else null

	if not flow:
		return null

	var instance: HenMacroHookMacro = HenMacroHookMacro.new()

	instance.save_data = save_data
	instance.macro_res = macro_res
	instance.hook = flow

	return instance


static func macro_for(_save_data: HenSaveData, _macro_id: StringName) -> HenSaveMacro:
	var instance: HenMacroHookMacro = instance_for(_save_data, _macro_id)

	return macro_of(instance.macro_res, instance.hook) if instance else null


static func macro_of(_macro: HenSaveStateMacro, _flow: HenSaveFlowParam) -> HenSaveMacro:
	var id: StringName = hook_id(_macro, _flow)
	var cached: Variant = _macro_cache.get(str(id))
	var macro: HenSaveMacro = cached as HenSaveMacro if cached else null

	if not macro:
		macro = HenSaveMacro.new()
		macro.id = id
		macro.function_id = _macro.id
		macro.icon = ICON
		macro.color = COLOR
		macro.category = 'macros'
		macro.flow_inputs = _phase_inputs()

		_macro_cache[str(id)] = macro

	macro.name = 'Run ' + _flow.name
	macro.description = 'Runs whatever the use of ' + _macro.name + ' put on ' + _flow.name + '.'

	return macro


static func _phase_inputs() -> Array[HenSaveFlowParam]:
	return HenFunctionMacro._phase_inputs()


static func _active_save_data() -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null

	return global.SAVE_DATA if global else null


func get_id() -> StringName:
	return hook_id(macro_res, hook)


func get_display_name() -> String:
	return 'Run ' + hook.name


func get_description() -> String:
	return 'Runs whatever the use of ' + macro_res.name + ' put on ' + hook.name + '.'


func get_icon() -> String:
	return ICON


func get_color() -> String:
	return COLOR


func get_flow_inputs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for flow: HenSaveFlowParam in _phase_inputs():
		out.append(flow.get_data())

	return out


# the body is written by the emit path, which is the only place that knows which
# use of the macro is being generated
func get_flow_enter() -> String:
	return HOOK_TOKEN


func get_flow_update() -> String:
	return HOOK_TOKEN


func get_flow_physics() -> String:
	return HOOK_TOKEN


func get_flow_exit() -> String:
	return HOOK_TOKEN


const HOOK_TOKEN: String = '{{macro_hook}}'
