@tool
class_name HenActionEmitParticles extends HenScriptMacroBase


func get_id() -> StringName:
	return &'emit_particles'


func get_description() -> String:
	return 'Restarts a particle node and turns its emission on, the burst a hit or an explosion shows. It works with the 2D and the 3D particle nodes.'


func get_display_name() -> String:
	return 'Emit Particles'


func get_icon() -> String:
	return 'sparkles'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Particles',
			type = 'Node',
			id = &'particles',
			doc = 'The particles node to fire. Leave it empty to fire this node.',
			bind_only = true,
			optional = true,
			default_value = null
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


func _body() -> String:
	return '{{particles}}.restart()\n{{particles}}.emitting = true'
