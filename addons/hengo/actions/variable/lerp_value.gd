@tool
class_name HenActionLerpValue extends HenScriptMacroBase


# eases Target toward To by Weight each call. Target must be BOUND to a
# variable/property (it becomes the assignment lvalue `_ref.<name>`).
# meant for the update phase, but the body has no delta so any phase compiles.


func get_id() -> StringName:
	return &'lerp_value'


func get_description() -> String:
	return 'Smoothly eases a variable or property toward a target value each frame. It keeps getting closer without ever landing exactly, so use Is Near to tell that it arrived.'


func get_display_name() -> String:
	return 'Lerp Toward'


func get_icon() -> String:
	return 'spline'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
				doc = 'The variable or property to ease.',
			lvalue = true,
			default_value = null
		},
		{
			name = 'To',
			type = 'Variant',
			id = &'to',
				doc = 'The value to ease toward.',
			# effective type follows whatever Target is bound to (var/prop)
			type_from = &'target',
			default_value = 0
		},
		{
			name = 'Weight',
			type = 'float',
			id = &'weight',
				doc = 'How much to move each call, from 0 to 1. Higher is faster.',
			default_value = 0.1
		}
	]


# lifecycle phases this action supports
func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return '{{target}} = lerp({{target}}, {{to}}, {{weight}})'


func get_flow_update() -> String:
	return '{{target}} = lerp({{target}}, {{to}}, {{weight}})'


func get_flow_physics() -> String:
	return '{{target}} = lerp({{target}}, {{to}}, {{weight}})'


func get_flow_exit() -> String:
	return '{{target}} = lerp({{target}}, {{to}}, {{weight}})'
