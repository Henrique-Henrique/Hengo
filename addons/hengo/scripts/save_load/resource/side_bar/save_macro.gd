@tool
class_name HenSaveMacro extends HenSaveResTypeWithRoute

@export var inputs: Array[HenSaveParam]
@export var outputs: Array[HenSaveParam]
@export var flow_inputs: Array[HenSaveFlowParam]
@export var flow_outputs: Array[HenSaveFlowParam]
@export var script_path: String
@export var is_script_macro: bool = false
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


# a macro is offered to a script when its base inherits from one of the targets
static func create() -> HenSaveMacro:
	var macro: HenSaveMacro = HenSaveMacro.new()

	macro.id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	macro.name = macro.get_new_name()

	return macro


func serves_class(_class: StringName) -> bool:
	if target_classes.is_empty() or not ClassDB.class_exists(_class):
		return true

	for target: StringName in target_classes:
		if ClassDB.class_exists(target) and ClassDB.is_parent_class(_class, target):
			return true

	return false


func get_new_name() -> String:
	return 'macro_' + str(id)

