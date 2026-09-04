@tool
class_name HenActionSetBusVolume extends HenScriptMacroBase


# sets the volume of an audio bus by name (Master, Music, SFX...). -80 dB is
# silence and 0 dB is full. it affects every sound routed through that bus.


func get_id() -> StringName:
	return &'set_bus_volume'


func get_description() -> String:
	return 'Sets the volume of an audio bus by name, such as Master or Music. -80 is silence and 0 is full. It affects every sound routed through that bus.'


func get_display_name() -> String:
	return 'Set Bus Volume'


func get_icon() -> String:
	return 'sliders-horizontal'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Bus',
			type = 'String',
			id = &'bus',
			picker = 'audio_bus',
			doc = 'The name of the audio bus to change.',
			default_value = 'Master'
		},
		{
			name = 'Volume',
			type = 'float',
			id = &'volume',
			doc = 'The new volume in decibels, -80 for silence and 0 for full.',
			default_value = 0.0
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
	return 'AudioServer.set_bus_volume_db(AudioServer.get_bus_index({{bus}}), {{volume}})'
