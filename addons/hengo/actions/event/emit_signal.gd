@tool
class_name HenActionEmitSignal extends HenScriptMacroBase


# fires one of this script own signals, reaching everything connected to it. the
# event folder only listens; this is the action that emits.


func get_id() -> StringName:
	return &'emit_signal'


func get_description() -> String:
	return 'Emits one of this script signals, reaching everything connected to it. The signal must be declared in this script first.'


func get_display_name() -> String:
	return 'Emit Signal'


func get_icon() -> String:
	return 'megaphone'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Signal',
			type = 'String',
			id = &'signal_name',
			doc = 'Name of the signal to emit, matching one declared in this script.',
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


# a blank name would emit emit_signal(""): compiles fine and never fires
func get_validation_error() -> String:
	return 'the signal name is empty' if str(value_of(&'signal_name', '')).strip_edges().is_empty() else ''


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


# hengo signals are generated without params, so no argument is passed
func _body() -> String:
	return '_ref.emit_signal({{signal_name}})'
