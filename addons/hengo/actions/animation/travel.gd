@tool
class_name HenActionTravel extends HenScriptMacroBase


# tells a bound AnimationTree state machine to travel to a state, letting it walk
# the transitions in between instead of cutting straight there.


func get_id() -> StringName:
	return &'travel'


func get_description() -> String:
	return 'Tells an AnimationTree state machine to move to a state, walking the transitions in between. Bind Tree to the AnimationTree node.'


func get_display_name() -> String:
	return 'Animation Travel'


func get_icon() -> String:
	return 'workflow'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Tree',
			type = 'Node',
			id = &'tree',
			doc = 'The AnimationTree whose state machine travels.',
			bind_only = true,
			default_value = null
		},
		{
			name = 'State',
			type = 'StringName',
			id = &'state',
			doc = 'The state to travel to.',
			default_value = 'idle'
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
	return '({{tree}}.get(&"parameters/playback") as AnimationNodeStateMachinePlayback).travel({{state}})'
