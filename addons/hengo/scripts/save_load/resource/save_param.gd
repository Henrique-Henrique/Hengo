@tool
class_name HenSaveParam extends HenSaveResType

@export_custom(PROPERTY_HINT_NONE, 'all_godot_classes')
var type: StringName = &'Variant':
	set(v):
		type = v
		default_value = null
		notify_property_list_changed()

var default_value: Variant = null
# optional: this input's effective type follows another input's bound source
@export var type_from: StringName = &''
# optional: fixed set of code fragments this input can hold, shown as a dropdown
@export var options: Array[String] = []
# optional: what each option is called on screen, when the value emitted is not
# what should be read (an id the user never typed)
@export var option_labels: Array[String] = []
# the value is emitted verbatim instead of being quoted as a literal
@export var raw: bool = false
# the input is an assignment target: it must be bound, and only to something
# assignable — a variable or a property, never a call
@export var lvalue: bool = false
# the input is written to, but leaving it unbound is fine: the macro only emits
# the assignment when it is set
@export var optional: bool = false
# the input is read, but a literal makes no sense for it (a node reference), so
# it must be bound; any source works, including a node path
@export var bind_only: bool = false
# optional one-line explanation of this field, shown in the hover documentation
@export var doc: String = ''
# optional named source of suggestions, listed when the slot opens instead of at
# load time, so it follows what the project holds right now
@export var picker: StringName = &''


func _init() -> void:
	id = StringName(str((Engine.get_singleton(&'Global') as HenGlobal).get_new_node_counter()))
	name = get_new_name()
	type = &'Variant'


static func create(data: Dictionary = {}) -> HenSaveParam:
	var p: HenSaveParam = HenSaveParam.new()
	if data:
		if data.has('name'): p.name = data.name
		if data.has('type'): p.type = data.type
		if data.has('id'): p.id = str(data.id)
		if data.has('type_from'): p.type_from = StringName(str(data.type_from))
		if data.has('raw'): p.raw = bool(data.raw)
		if data.has('lvalue'): p.lvalue = bool(data.lvalue)
		if data.has('bind_only'): p.bind_only = bool(data.bind_only)
		if data.has('optional'): p.optional = bool(data.optional)
		if data.has('options'):
			for option: Variant in data.options:
				p.options.append(str(option))
		if data.has('option_labels'):
			for label: Variant in data.option_labels:
				p.option_labels.append(str(label))
		if data.has('doc'): p.doc = str(data.doc)
		if data.has('picker'): p.picker = StringName(str(data.picker))
		if data.has('default_value'): p.default_value = data.default_value
	return p


func get_data() -> Dictionary:
	return {
		name = name,
		type = type,
		id = id,
		type_from = type_from,
		options = options,
		option_labels = option_labels,
		raw = raw,
		lvalue = lvalue,
		bind_only = bind_only,
		optional = optional,
		doc = doc,
		picker = picker,
		default_value = default_value
	}


func _validate_property(_property: Dictionary) -> void:
	super (_property)
	if _property.name in [&'type_from', &'options', &'option_labels', &'raw', &'lvalue', &'bind_only', &'optional', &'doc', &'picker']:
		_property.usage = PROPERTY_USAGE_STORAGE


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var variant_type_int: int = HenUtils.get_variant_type_from_string(type)

	if variant_type_int != TYPE_NIL or type == &'Variant':
		list.append({
			name = 'default_value',
			type = variant_type_int if variant_type_int != TYPE_NIL else TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		})

	return list


func get_new_name() -> String:
	return 'param_' + str(id)
# what an option is called on screen; the value itself when it has no label
func option_label(_value: Variant) -> String:
	var index: int = options.find(str(_value))

	return option_labels[index] if index >= 0 and index < option_labels.size() else str(_value)

