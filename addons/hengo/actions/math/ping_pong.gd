@tool
class_name HenActionPingPong extends HenScriptMacroBase


# writes Value folded to bounce between 0 and Length into Store: it rises to
# Length then falls back, over and over. feed it time for a back-and-forth.


func get_id() -> StringName:
	return &'ping_pong'


func get_description() -> String:
	return 'Makes a number climb up to Length and then walk back down to 0, over and over. Feeding it the elapsed time with Length = 1 gives a value that goes 0 to 1 and back, the way a platform slides side to side.'


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
			doc = 'A number that keeps growing, usually the elapsed time.',
			default_value = 0.0
		},
		{
			name = 'Length',
			type = 'float',
			id = &'length',
			doc = 'How high it climbs before turning back down.',
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
	return '{{out:result}}'
