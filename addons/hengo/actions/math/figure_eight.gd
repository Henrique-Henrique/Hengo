@tool
class_name HenActionFigureEight extends HenScriptMacroBase


func get_id() -> StringName:
	return &'figure_eight'


func get_description() -> String:
	return 'Gives two numbers that together trace a sideways figure eight, Side swinging once across while Rise swings twice. With Speed = 2 the eight is drawn twice a second, and adding both to a position makes a firefly loop or an idle character sway. Oscillate rides the game clock, so changing its Frequency jumps the value, while this one keeps its own count and can speed up without a jump.'


func get_display_name() -> String:
	return 'Figure Eight'


func get_icon() -> String:
	return 'spline'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How many full eights are drawn each second.',
			default_value = 1.0
		},
		{
			name = 'Reach',
			type = 'float',
			id = &'reach',
			doc = 'How far the eight reaches sideways, with Rise reaching half of that. A Spring To value here makes the motion grow and shrink smoothly instead of switching on and off.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Side', type = 'float', id = &'side', doc = 'Where to store the side to side offset, which swings once per eight.'},
		{name = 'Rise', type = 'float', id = &'rise', doc = 'Where to store the up and down offset, which swings twice per eight and is what bends the path into an eight.'}
	]


func get_output_side() -> String:
	return 'sin(eight_phase_{{VCNODE_ID}} * TAU) * {{reach}}'


func get_output_rise() -> String:
	return 'sin(eight_phase_{{VCNODE_ID}} * TAU * 2.0) * {{reach}} * 0.5'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


# a reset here would zero the count, which is the jump this action exists to avoid
func get_script_base() -> String:
	return 'var eight_phase_{{VCNODE_ID}}: float = 0.0'


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'eight_phase_{{VCNODE_ID}} = fmod(eight_phase_{{VCNODE_ID}} + {{speed}} * delta, 1.0)\n' \
		+ '{{out:side}}\n' \
		+ '{{out:rise}}'
