@tool
class_name HenSaveVar extends HenSaveResType

@export_custom(PROPERTY_HINT_NONE, 'var_type') var type: StringName:
	set(v):
		type = v
		default_value = null
		notify_property_list_changed()
@export var is_export: bool
# hengo script this variable holds an instance of; empty = plain godot type.
# `type` still carries that script's base class, so codegen and props are unaffected
@export var script_id: StringName

var default_value: Variant = null

static func create() -> HenSaveVar:
	var v: HenSaveVar = HenSaveVar.new()
	return v


func _init() -> void:
	id = (Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()
	name = get_new_name()
	type = &'Variant'


func get_new_name() -> String:
	return 'variable_' + str(id)


func get_data() -> Dictionary:
	return {
		name = name,
		type = type,
		id = id,
		export = is_export,
		default_value = default_value
	}


# the script binding rides on the type dropdown, never as its own field
func _validate_property(_property: Dictionary) -> void:
	super (_property)

	if _property.name == &'script_id':
		_property.usage = PROPERTY_USAGE_STORAGE


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var variant_type_int: int = HenUtils.get_variant_type_from_string(type)
	
	if variant_type_int != TYPE_NIL:
		list.append({
			name = 'default_value',
			type = variant_type_int,
			usage = PROPERTY_USAGE_DEFAULT
		})
	
	return list


func _get_resource_info() -> Dictionary:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	
	if not map_dep:
		return {name = name, type = &'Variant'}
	
	for project_ast: HenMapDependencies.ProjectAST in map_dep.ast_list.values():
		for var_res: HenSaveVar in project_ast.variables:
			if var_res.id == id:
				if project_ast.identity:
					return {name = project_ast.identity.name, type = project_ast.identity.type}
				break
	
	return {name = name, type = &'Variant'}