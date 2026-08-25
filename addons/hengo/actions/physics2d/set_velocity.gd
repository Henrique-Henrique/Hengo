@tool
class_name HenActionSetVelocity extends HenScriptMacroBase


# writes the body velocity in pixels per second. it only moves the body once
# Move And Slide runs.


func get_id() -> StringName:
	return &'set_velocity'


func get_description() -> String:
	return 'Sets the body velocity directly, in pixels per second. It only moves the body once Move And Slide runs.'


func get_display_name() -> String:
	return 'Set Velocity'


func get_icon() -> String:
	return 'gauge'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to change. Leave it empty to change this node.'),
		{
			name = 'Velocity',
			type = 'Vector2',
			id = &'velocity',
				doc = 'The velocity to apply, in pixels per second.',
			default_value = Vector2.ZERO
		}
	]


func get_default_phase() -> StringName:
	return &'physics'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{ref}}.velocity = {{velocity}}'
