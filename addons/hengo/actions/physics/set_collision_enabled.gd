@tool
class_name HenActionSetCollisionEnabled extends HenScriptMacroBase


func get_id() -> StringName:
	return &'set_collision_enabled'


func get_description() -> String:
	return 'Turns a collision shape on or off, so a body can stop colliding without leaving the scene. Good for a hitbox that only counts during an attack.'


func get_display_name() -> String:
	return 'Set Collision Enabled'


func get_icon() -> String:
	return 'shield'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Shape',
			type = 'Node',
			id = &'shape',
			doc = 'The collision shape to turn on or off. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Enabled',
			type = 'bool',
			id = &'enabled',
			doc = 'True to make the shape collide again, false to switch it off.',
			default_value = true
		}
	]


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


# set_deferred because a shape cannot be switched while the physics server is flushing
func _body() -> String:
	return '{{shape}}.set_deferred("disabled", not {{enabled}})'
