@tool
class_name HenActionValueEditors
extends RefCounted

# which editor a chip opens, by slot type. only the two that are worth handling on
# the card itself live here: everything else opens the slot row of the inspector,
# which already has a typed editor plus the bind and expression buttons

const TEXT: StringName = &'text'
const BOOL: StringName = &'bool'


static func kind_for(_type: String) -> StringName:
	# an unknown class name also lands on NIL, which is why Variant and a node
	# reference read the same here: what keeps a node out is its bind_only flag
	match HenUtils.get_variant_type_from_string(_type):
		TYPE_NIL, TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT:
			return TEXT
		TYPE_BOOL:
			return BOOL

	return &''
