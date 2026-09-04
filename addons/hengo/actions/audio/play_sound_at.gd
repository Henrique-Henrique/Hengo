@tool
class_name HenActionPlaySoundAt extends HenScriptMacroBase


func get_id() -> StringName:
	return &'play_sound_at'


func get_description() -> String:
	return 'Plays a sound from a temporary player added to the scene, so it still plays when this node is destroyed. The player frees itself once the sound ends.'


func get_display_name() -> String:
	return 'Play Sound At'


func get_icon() -> String:
	return 'volume-2'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Sound',
			type = 'AudioStream',
			id = &'sound',
			doc = 'The sound file to play.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Position',
			type = 'Variant',
			id = &'position',
			doc = 'Where the sound comes from. Leave it empty to play at the spot of this node.',
			optional = true,
			default_value = null
		},
		{
			name = 'Volume',
			type = 'float',
			id = &'volume',
			doc = 'How loud the sound is in decibels, 0 for full and -80 for silence.',
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


# autoplay and not play(): the player only starts once it is inside the tree
func _body() -> String:
	var player_class: String = 'AudioStreamPlayer3D' if targets(&'Node3D') else 'AudioStreamPlayer2D'
	var code: String = 'var sound_{{VCNODE_ID}} := ' + player_class + '.new()\n' \
		+ 'sound_{{VCNODE_ID}}.stream = {{sound}}\n' \
		+ 'sound_{{VCNODE_ID}}.volume_db = {{volume}}\n'

	if is_bound(&'position') or value_of(&'position') != null:
		code += 'sound_{{VCNODE_ID}}.position = {{position}}\n'
	elif targets(&'Node2D') or targets(&'Node3D'):
		code += 'sound_{{VCNODE_ID}}.position = _ref.global_position\n'

	return code + 'sound_{{VCNODE_ID}}.autoplay = true\n' \
		+ 'sound_{{VCNODE_ID}}.finished.connect(sound_{{VCNODE_ID}}.queue_free)\n' \
		+ '_ref.get_tree().current_scene.add_child.call_deferred(sound_{{VCNODE_ID}})'
