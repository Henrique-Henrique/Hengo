@tool
class_name HenActionTypeText extends HenActionTweenBase


func get_id() -> StringName:
	return &'type_text'


func get_description() -> String:
	return 'Reveals the text of a label one character at a time, the typewriter effect used in dialogue. Wire Finished and the flow moves on by itself when it ends, with no timer of your own. On enter it plays once; on update or physics it starts again as soon as the last one ended, so it keeps repeating while the state runs. Leaving the state before it ends reveals the rest at once, the way skipping a line of dialogue does.'


func get_display_name() -> String:
	return 'Type Text'


func get_icon() -> String:
	return 'text-cursor'


func finishes_on_cancel() -> bool:
	return true


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Label',
			type = 'Control',
			id = &'label',
			doc = 'The Label or RichTextLabel that shows the text. Leave it empty to type into this node.',
			bind_only = true,
			optional = true,
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




func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return guard_per_frame(_body())


func get_flow_physics() -> String:
	return guard_per_frame(_body())


func _body() -> String:
	return 'var text_{{VCNODE_ID}}: String = str({{text}})\n' \
		+ '{{label}}.text = text_{{VCNODE_ID}}\n' \
		+ '{{label}}.visible_ratio = 0.0\n' \
		+ start_tween('tween_property({{label}}, "visible_ratio", 1.0, text_{{VCNODE_ID}}.length() / maxf({{speed}}, 0.001))')
