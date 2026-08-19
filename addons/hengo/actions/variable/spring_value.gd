@tool
class_name HenActionSpringValue extends HenScriptMacroBase


# eases Target toward To like a spring, overshooting and settling instead of
# gliding. Stiffness pulls harder, Damping bleeds the bounce. good for a punchy
# scale or a springy ui number. it keeps a velocity per action, so the value
# needs delta and runs in update or physics only.


func get_id() -> StringName:
	return &'spring_value'


func get_description() -> String:
	return 'Eases a number toward a target like a spring, so it overshoots and settles instead of gliding in. Stiffness pulls harder and Damping bleeds off the bounce. It settles without landing exactly, so use Is Near to tell that it arrived.'


func get_display_name() -> String:
	return 'Spring To'


func get_icon() -> String:
	return 'spline'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Variant',
			id = &'target',
			doc = 'The number the spring moves and stores back into.',
			lvalue = true,
			default_value = null
		},
		{
			name = 'To',
			type = 'Variant',
			id = &'to',
			doc = 'The value the spring settles at.',
			type_from = &'target',
			default_value = 0.0
		},
		{
			name = 'Stiffness',
			type = 'float',
			id = &'stiffness',
			doc = 'How hard the spring pulls toward To.',
			default_value = 150.0
		},
		{
			name = 'Damping',
			type = 'float',
			id = &'damping',
			doc = 'How fast the bounce dies down.',
			default_value = 10.0
		}
	]


# one velocity per action, kept across frames; zeroed when the state is entered
func get_script_base() -> String:
	return 'var spring_vel_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'spring_vel_{{VCNODE_ID}} = 0.0'


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
	return 'spring_vel_{{VCNODE_ID}} += ({{to}} - {{target}}) * {{stiffness}} * delta\n' \
		+ 'spring_vel_{{VCNODE_ID}} *= clampf(1.0 - {{damping}} * delta, 0.0, 1.0)\n' \
		+ '{{target}} += spring_vel_{{VCNODE_ID}} * delta'
