@tool
class_name HenActionApproachValue extends HenScriptMacroBase


# moves a numeric Target toward To at Step per second, never overshooting. Target
# must be BOUND to a variable/property (it becomes the assignment lvalue).
# the body needs delta, so only update and physics are offered.


func get_id() -> StringName:
	return &'approach_value'


func get_description() -> String:
	return 'Moves a number toward a target value at a fixed speed, without overshooting.'


func get_display_name() -> String:
	return 'Approach'


func get_icon() -> String:
	return 'trending-up'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
				doc = 'The variable or property to move.',
			lvalue = true,
			default_value = null
		},
		{
			name = 'To',
			type = 'float',
			id = &'to',
				doc = 'The value to move toward.',
			default_value = 0.0
		},
		{
			name = 'Step',
			type = 'float',
			id = &'step',
				doc = 'How fast to move, in units per second.',
			default_value = 1.0
		}
	]


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Reached',
			id = &'reached',
			optional = true,
			doc = 'Where to go on the frame the number lands on the target value.'
		},
		{
			name = 'Going',
			id = &'going',
			optional = true,
			doc = 'Where to go while the number is still short of the target value.'
		}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# move_toward returns the target itself once the step covers what is left
func _body() -> String:
	if not any_flow_connected():
		return '{{target}} = move_toward({{target}}, {{to}}, {{step}} * delta)'

	return 'var to_{{VCNODE_ID}} = {{to}}\n' \
		+ '{{target}} = move_toward({{target}}, to_{{VCNODE_ID}}, {{step}} * delta)\n' \
		+ 'if {{target}} == to_{{VCNODE_ID}}:\n' \
		+ '\t{{reached}}\n' \
		+ 'else:\n' \
		+ '\t{{going}}'
