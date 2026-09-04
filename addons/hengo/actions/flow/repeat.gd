@tool
class_name HenActionRepeat extends HenScriptMacroBase


# runs its nested actions Times in a row, all in the same frame. bind Index to a
# variable to know which pass it is (0 to Times minus one).


func get_id() -> StringName:
	return &'repeat'


func get_description() -> String:
	return 'Runs the actions inside it a fixed number of times, all in the same frame. With Times = 10, ten bullets go out on the same frame and Index counts from 0 to 9. A timer nested inside it ticks once per pass, so ten passes in one frame move it ten steps.'


func get_display_name() -> String:
	return 'Repeat'


func get_icon() -> String:
	return 'repeat-2'


func get_has_body() -> bool:
	return true


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Times',
			type = 'int',
			id = &'times',
			doc = 'How many times to run the nested actions.',
			default_value = 3
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Index', type = 'int', id = &'index', branch = &'body', doc = 'The current pass number, starting at 0.'}
	]


func get_output_index() -> String:
	return '__i_{{VCNODE_ID}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'for __i_{{VCNODE_ID}} in {{times}}:\n\t{{out:index}}\n\t{{loop_body}}'
