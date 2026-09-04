@tool
class_name HenActionSetTooltip extends HenScriptMacroBase


# sets the hover tooltip of a bound Control node. Target is bound by variable or
# node path; the assignment is duck-typed.


func get_id() -> StringName:
	return &'set_tooltip'


func get_description() -> String:
	return 'Sets the tooltip a Control node shows when the mouse rests on it.'


func get_display_name() -> String:
	return 'Set Tooltip'


func get_icon() -> String:
	return 'message-square'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Target',
			type = 'Control',
			id = &'target',
			doc = 'The node to give the tooltip to. Leave it empty to change this node.',
			bind_only = true,
			optional = true,
			default_value = null
		},
		{
			name = 'Text',
			type = 'String',
			id = &'text',
			doc = 'The tooltip text to show on hover.',
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
	return '{{target}}.tooltip_text = {{text}}'
