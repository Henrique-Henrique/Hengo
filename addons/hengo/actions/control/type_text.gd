@tool
class_name HenActionTypeText extends HenActionTweenBase


func get_id() -> StringName:
	return &'type_text'


func get_description() -> String:
	return 'Reveals the text of a label one character at a time, the typewriter effect used in dialogue. Runs once when the state starts. Wire Finished and the flow moves on by itself when it ends, with no timer of your own.'


func get_display_name() -> String:
	return 'Type Text'


func get_icon() -> String:
	return 'text-cursor'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Label',
			type = 'Node',
			id = &'label',
			doc = 'The Label or RichTextLabel that shows the text.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'Text',
			type = 'String',
			id = &'text',
			doc = 'The full text to reveal.',
			default_value = 'Hello'
		},
		{
			name = 'Speed',
			type = 'float',
			id = &'speed',
			doc = 'How many characters appear per second.',
			default_value = 30.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'}
	]


func get_flow_enter() -> String:
	return _body()


func _body() -> String:
	return 'var text_{{VCNODE_ID}}: String = str({{text}})\n' \
		+ '{{label}}.text = text_{{VCNODE_ID}}\n' \
		+ '{{label}}.visible_ratio = 0.0\n' \
		+ start_tween('tween_property({{label}}, "visible_ratio", 1.0, text_{{VCNODE_ID}}.length() / maxf({{speed}}, 0.001))')
