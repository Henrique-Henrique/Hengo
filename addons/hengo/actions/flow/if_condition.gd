@tool
class_name HenActionIf extends HenScriptMacroBase


# branches to a state or sub-state based on a boolean. it has no body — each flow
# output is a branch whose transition target is set per action in the inspector.


func get_id() -> StringName:
	return &'if_condition'


func get_description() -> String:
	return 'Branches to one of two targets based on a condition. Each branch transitions to a state or sub-state set per action.'


func get_display_name() -> String:
	return 'If'


func get_icon() -> String:
	return 'git-branch'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Condition',
			type = 'bool',
			id = &'condition',
			doc = 'The test that decides which branch runs.',
			default_value = true
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'},
		{name = 'Exit', id = &'exit'}
	]


# each flow output is a branch; the action binds it to a state or sub-state
func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the condition is true.'},
		{name = 'False', id = &'false', doc = 'Where to go when it is false.'}
	]


func get_flow_enter() -> String:
	return _branch_body()


func get_flow_update() -> String:
	return _branch_body()


func get_flow_physics() -> String:
	return _branch_body()


func get_flow_exit() -> String:
	return _branch_body()


# an unset branch resolves to `pass`, so the block always compiles
func _branch_body() -> String:
	return 'if {{condition}}:\n\t{{true}}\nelse:\n\t{{false}}'
