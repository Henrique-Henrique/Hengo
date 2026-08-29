@tool
class_name HenActionRandomSeed extends HenScriptMacroBase


func get_id() -> StringName:
	return &'random_seed'


func get_description() -> String:
	return 'Fixes the starting point of every random action that runs after it, so the same seed always gives the same rolls. With Seed = 12345 a roguelike lays out the exact same run every time, which is what a shareable run code or a daily challenge is built on.'


func get_display_name() -> String:
	return 'Set Random Seed'


func get_icon() -> String:
	return 'dice-6'


func get_default_phase() -> StringName:
	return &'enter'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Seed',
			type = 'int',
			id = &'seed',
			doc = 'The number that decides which sequence of random values comes out.',
			default_value = 0
		}
	]


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
	return 'seed({{seed}})'
