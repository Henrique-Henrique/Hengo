@tool
class_name HenActionApproachValue extends HenScriptMacroBase


# moves a numeric Target toward To at Step per second, never overshooting. Target
# must be BOUND to a variable/property (it becomes the assignment lvalue).
# the body needs delta, so only update and physics are offered.


func get_id() -> StringName:
	return &'approach_value'


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
			lvalue = true,
			default_value = null
		},
		{
			name = 'To',
			type = 'float',
			id = &'to',
			default_value = 0.0
		},
		{
			name = 'Step',
			type = 'float',
			id = &'step',
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


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{target}} = move_toward({{target}}, {{to}}, {{step}} * delta)'
