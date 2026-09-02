@tool
class_name HenSaveMacro extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_inputs: Array[HenSaveFlowParam]
@export var flow_outputs: Array[HenSaveFlowParam]
@export var script_path: String
@export var is_script_macro: bool = false
# set when this macro stands for a function of a script instead of a file on disk
@export var function_id: StringName
# presentation, mirroring the native_items vocabulary: icon name + category color
@export var icon: String
@export var color: String
# one-line documentation shown as a tooltip on hover
@export var description: String
# folder the definition lives in; empty means uncategorized
@export var category: String
# lifecycle phase a new action of this macro lands on; empty picks it from the
# declared flow inputs
@export var default_phase: StringName
# native classes this macro serves; empty means every class
@export var target_classes: Array[StringName]
# the action owns a nested action list run per iteration (a loop)
@export var has_body: bool
# the action is a pure value producer, so a slot may take it inline. read from
# the loader recipe: computing it needs the definition script in memory
@export var is_inlinable: bool


static func create() -> HenSaveMacro:
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	macro.name = macro.get_new_name()

	return macro


func serves_class(_class: StringName) -> bool:
	return takes_any_node() or HenUtils.class_serves(_class, target_classes)


# an action whose first input is a self-defaulting node slot reaches any node, so
# the class of the script stops deciding whether it is offered. leaving that slot
# empty on a script the action was not written for is what reports the missing
# reference
func takes_any_node() -> bool:
	if inputs.is_empty():
		return false

	var first: HenSaveParam = inputs[0]

	return HenUtils.is_node_ref_slot(first.type, first.bind_only, first.optional)


func get_new_name() -> String:
	return 'macro_' + str(id)

