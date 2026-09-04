@tool
class_name HenActionValueEditors
extends RefCounted

# which editor a chip handles on the card itself. only a bool does: a checkbox
# behind a popup is one click too many. every other type opens the slot row of the
# inspector, which has the typed editor and the bind, expression and producer
# buttons side by side, so one click reaches every source the slot can take

const BOOL: StringName = &'bool'


static func kind_for(_type: String) -> StringName:
	if HenUtils.get_variant_type_from_string(_type) == TYPE_BOOL:
		return BOOL

	return &''
