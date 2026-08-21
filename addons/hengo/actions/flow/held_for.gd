@tool
class_name HenActionHeldFor extends HenScriptMacroBase


func get_id() -> StringName:
	return &'held_for'


func get_description() -> String:
	return 'Takes the Held branch once the condition has stayed true for the whole time asked, such as holding a button to charge a shot. Any frame the condition fails puts the count back to zero.'


func get_display_name() -> String:
	return 'Held For'


func get_icon() -> String:
	return 'timer-reset'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test that has to stay true, such as a Check action placed right here.',
			default_value = true
		},
		{
			name = 'Seconds',
			type = 'float',
			id = &'seconds',
			doc = 'How long the condition has to hold without breaking, in seconds.',
			default_value = 1.0
		}
	]


# one counter per action, so two charges in the same state never share it
func get_script_base() -> String:
	return 'var held_{{VCNODE_ID}}: float = 0.0'


func get_flow_reset() -> String:
	return 'held_{{VCNODE_ID}} = 0.0'


func get_default_phase() -> StringName:
	return &'update'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'Held', id = &'held', doc = 'Where to go once the condition has held long enough. It keeps firing while the condition stays true.'},
		{name = 'Waiting', id = &'waiting', doc = 'Where to go while the time is not complete.'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if {{condition}}:\n' \
		+ '\theld_{{VCNODE_ID}} += delta\n' \
		+ 'else:\n' \
		+ '\theld_{{VCNODE_ID}} = 0.0\n' \
		+ 'if held_{{VCNODE_ID}} > 0.0 and held_{{VCNODE_ID}} >= {{seconds}}:\n' \
		+ '\t{{held}}\n' \
		+ 'else:\n' \
		+ '\t{{waiting}}'
