@tool
class_name HenActionPingPong extends HenScriptMacroBase


# writes Value folded to bounce between 0 and Length into Store: it rises to
# Length then falls back, over and over. feed it time for a back-and-forth.


func get_id() -> StringName:
	return &'ping_pong'


func get_description() -> String:
	return 'Folds a value so it bounces between 0 and a length, rising then falling over and over. Feed it time to drive a back-and-forth motion.'


func get_display_name() -> String:
	return 'Ping Pong'


func get_icon() -> String:
	return 'arrow-left-right'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Value',
			type = 'float',
			id = &'value',
			doc = 'The number to fold, often accumulated time.',
			default_value = 0.0
		},
		{
			name = 'Length',
			type = 'float',
			id = &'length',
			doc = 'The value it bounces up to before falling back.',
			default_value = 1.0
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'float', id = &'result', doc = 'The bounced value, between 0 and Length.'}
	]


func get_output_result() -> String:
	return 'pingpong({{value}}, {{length}})'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Exit', id = &'exit'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_exit() -> String:
	return _body()


func _body() -> String:
	return '{{out:result}}'
