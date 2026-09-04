@tool
class_name HenActionIsNear extends HenScriptMacroBase


func get_id() -> StringName:
	return &'is_near'


func get_description() -> String:
	return 'Checks whether two positions are close enough to count as the same spot. Use it to tell that something arrived, since a value that eases toward a target keeps getting closer without ever landing on it.'


func get_display_name() -> String:
	return 'Is Near'


func get_icon() -> String:
	return 'circle-dot'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'A',
			type = 'Variant',
			id = &'a',
			doc = 'The first position, such as where the node is right now.',
			default_value = null
		},
		{
			name = 'B',
			type = 'Variant',
			id = &'b',
			doc = 'The second position, such as where it is heading.',
			default_value = null
		},
		{
			name = 'Distance',
			type = 'float',
			id = &'distance',
			doc = 'How close the two have to be to count as arrived, in pixels or units.',
			default_value = 4.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', id = &'yes', doc = 'Where to go once the two are close enough.'},
		{name = 'No', id = &'no', doc = 'Where to go while they are still apart.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# hoisted into untyped locals on purpose: reading the slots inline lets the parser
# resolve a literal and refuse float(null) or a distance_to on a number
func _body() -> String:
	return 'var from_{{VCNODE_ID}} = {{a}}\n' \
		+ 'var to_{{VCNODE_ID}} = {{b}}\n' \
		+ 'var near_{{VCNODE_ID}}: bool = absf(float(from_{{VCNODE_ID}}) - float(to_{{VCNODE_ID}})) <= {{distance}} if typeof(from_{{VCNODE_ID}}) in [TYPE_INT, TYPE_FLOAT] else from_{{VCNODE_ID}}.distance_to(to_{{VCNODE_ID}}) <= {{distance}}\n' \
		+ 'if near_{{VCNODE_ID}}:\n' \
		+ '\t{{yes}}\n' \
		+ 'else:\n' \
		+ '\t{{no}}'
