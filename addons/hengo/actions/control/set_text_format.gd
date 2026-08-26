@tool
class_name HenActionSetTextFormat extends HenScriptMacroBase


# writes Template onto a Control, with {0}..{3} replaced by the value slots. it
# is the HUD label case ('HP: {0} / {1}') without hand-writing str() and +.


func get_id() -> StringName:
	return &'set_text_format'


func get_description() -> String:
	return 'Sets a Control text from a template, replacing {0}, {1} and so on with the value slots. This is the HUD label without joining strings by hand.'


func get_display_name() -> String:
	return 'Fill Text'


func get_icon() -> String:
	return 'type'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Control',
			id = &'target',
			doc = 'The node to write text to, such as a Label or Button. Leave it empty to write to this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Template',
			type = 'String',
			id = &'template',
			doc = 'The text, with {0}, {1}, {2}, {3} where the value slots go.',
			default_value = '{0}'
		},
		{
			name = 'Value 1',
			type = 'Variant',
			id = &'v0',
			doc = 'Fills {0} in the template.',
			default_value = ''
		},
		{
			name = 'Value 2',
			type = 'Variant',
			id = &'v1',
			doc = 'Fills {1} in the template.',
			default_value = ''
		},
		{
			name = 'Value 3',
			type = 'Variant',
			id = &'v2',
			doc = 'Fills {2} in the template.',
			default_value = ''
		},
		{
			name = 'Value 4',
			type = 'Variant',
			id = &'v3',
			doc = 'Fills {3} in the template.',
			default_value = ''
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
	return '{{target}}.text = ({{template}}).format([{{v0}}, {{v1}}, {{v2}}, {{v3}}])'
