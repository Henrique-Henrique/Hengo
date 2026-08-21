@tool
@abstract
class_name HenScriptMacroBase

# base class of the script this macro is being generated into, set before the
# body getters are called so a macro can emit different code per node type
var target_class: StringName = &''
# input id -> literal value of the action being generated, set alongside
# target_class. only literals: a bound slot has no value here
var input_values: Dictionary = {}
# input id -> true when that slot is bound to a variable, property or node path
var bound_inputs: Dictionary = {}
# flow output id -> true when that branch has somewhere to go. only meaningful for
# a branch declared optional: the others are required before the action is emitted
var connected_flows: Dictionary = {}


# literal an input holds on the action being generated
func value_of(_id: StringName, _fallback: Variant = null) -> Variant:
	var value: Variant = input_values.get(str(_id))

	return value if value != null else _fallback


func is_bound(_id: StringName) -> bool:
	return bool(bound_inputs.get(str(_id), false))


# an optional branch nobody wired should not cost an `if` at runtime, so the body
# can drop it and emit the plain statement instead
func is_flow_connected(_id: StringName) -> bool:
	return bool(connected_flows.get(str(_id), false))


func any_flow_connected() -> bool:
	return not connected_flows.is_empty()


# native classes this macro supports; a script whose base inherits from any of
# them can use it. empty means every class
func get_target_classes() -> Array[StringName]:
	return []


# true when target_class inherits from _class, for dispatching inside the bodies
func targets(_class: StringName) -> bool:
	return ClassDB.is_parent_class(target_class, _class) if ClassDB.class_exists(target_class) else false


# returns an array of dictionary with { name: string, type: string, id: stringname }
# optional keys: default_value, type_from (follow another input's bound type),
# raw (emit the value verbatim), options (fixed set shown as a picker — pair it
# with raw and make default_value the first option, or the ui and the emitted code
# disagree), lvalue (assignment target: must be bound to a variable or a property,
# never to a call), bind_only (read, but a literal makes no sense for it — any
# bound source works, node paths included). an unmet requirement skips the action
func get_inputs() -> Array[Dictionary]:
	return []


# returns an array of dictionary with { name: string, type: string, id: stringname }
# for each output define a func get_output_<id>() -> String returning its rhs.
# as an action, place {{out:<id>}} on its own line in the flow body where the
# assignment goes: it becomes `<store> = <rhs>` when the user binds the output to a
# variable, and the line vanishes when nobody stores it. the rhs may hold
# {{input}} and {{VCNODE_ID}} placeholders
func get_outputs() -> Array[Dictionary]:
	return []


# returns an array of dictionary with { name: string, id: stringname }
func get_flow_inputs() -> Array[Dictionary]:
	return []


# returns an array of dictionary with { name: string, id: stringname }
func get_flow_outputs() -> Array[Dictionary]:
	return []


# optional self-check run after the context is primed: returning a reason skips
# the action with a loud marker instead of emitting code that silently does nothing
func get_validation_error() -> String:
	return ''


# optional lifecycle phase a new action lands on (enter/update/physics/exit).
# empty picks the first phase the flow inputs declare a body for
func get_default_phase() -> StringName:
	return &''


# returns an array of Dictionary with { name: String, params: Array[{name: String, type: String}], body: Variant }
# body can be a String template or a Callable that returns a String template
# string templates support {{VCNODE_ID}} and any input/flow output ids as {{placeholder}}.
# as an action the body lands at script scope, where {{input}} is NOT substituted:
# read the value with value_of() and paste it into the string instead
func get_function_overrides() -> Array[Dictionary]:
	return []


# returns an optional string of gdscript code injected as class-level variables
# use {{VCNODE_ID}} to make variable names unique per instance.
# as an action it lands inside the state class, so the value survives frames.
# pair it with an optional get_flow_reset() -> String, whose body runs at the top
# of the state's enter() whatever phase the action is on
func get_script_base() -> String:
	return ''


# returns optional gdscript declarations injected at SCRIPT scope, next to the
# variables. as an action, use it when a virtual override from
# get_function_overrides() has to read them — _input runs on the node, not on the
# state class, which reaches these through `_ref.`
func get_script_scope() -> String:
	return ''


# optional human-readable name shown in the ui
# empty falls back to the file name, capitalized (my_action.gd -> "My Action")
func get_display_name() -> String:
	return ''


# optional one-line documentation shown as a tooltip on hover in the ui
func get_description() -> String:
	return ''


# true when the action owns a nested list of actions run per iteration (a loop).
# the flow body must hold {{loop_body}} where the nested actions go
func get_has_body() -> bool:
	return false


# true when the action only makes sense inside a loop body (break, continue).
# emitting it at the top level is refused with a loud marker
func get_needs_loop() -> bool:
	return false


# optional icon name from assets/new_icons (without the .svg), e.g. 'git-branch'
func get_icon() -> String:
	return ''


# optional category color as a hex string, e.g. '#f97316'. it tints the row
# background, so actions of the same kind read as a group
func get_color() -> String:
	return ''


# returns the id of the macro
# must be unique so hengo doesn't lose the macro when reloading the project
@abstract func get_id() -> StringName