@tool
class_name HenActionFlash extends HenScriptMacroBase


# briefly tints a bound node toward Color and back, the hit feedback a character
# gets when damaged. runs once, so best on enter.


func get_id() -> StringName:
	return &'flash'


func get_description() -> String:
	return 'Briefly tints a node toward a color and back, the flash a character shows when it takes damage. Runs once when the state starts.'


func get_display_name() -> String:
	return 'Flash'


func get_icon() -> String:
	return 'sparkles'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Node',
			id = &'target',
			doc = 'The node to flash.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Color',
			type = 'Color',
			id = &'color',
			doc = 'The color to flash toward.',
			default_value = Color(1, 0, 0, 1)
		},
		{
			name = 'Duration',
			type = 'float',
			id = &'duration',
			doc = 'How long the whole flash takes, in seconds.',
			default_value = 0.2
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


# capture the current tint so the flash returns to it, not to plain white
func _body() -> String:
	return 'var orig_{{VCNODE_ID}} = {{target}}.modulate\n' \
		+ 'var flash_{{VCNODE_ID}} = _ref.create_tween()\n' \
		+ 'flash_{{VCNODE_ID}}.tween_property({{target}}, "modulate", {{color}}, {{duration}} * 0.5)\n' \
		+ 'flash_{{VCNODE_ID}}.tween_property({{target}}, "modulate", orig_{{VCNODE_ID}}, {{duration}} * 0.5)'
