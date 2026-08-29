@tool
class_name HenActionStopParticles extends HenScriptMacroBase


func get_id() -> StringName:
	return &'stop_particles'


func get_description() -> String:
	return 'Turns the emission of a particle node off, the counterpart of Emit Particles. It is what shuts down a continuous emitter such as fire, smoke or a thruster.'


func get_display_name() -> String:
	return 'Stop Particles'


func get_icon() -> String:
	return 'square'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Particles',
			type = 'Node',
			id = &'particles',
			doc = 'The particles node to turn off. Leave it empty to turn off this node.',
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
	return '{{particles}}.emitting = false'
