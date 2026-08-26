@tool
class_name HenActionChance extends HenScriptMacroBase


# rolls the dice and takes one of the two branches. Chance is a percentage:
# 50 means it goes True half of the time, 100 always.


func get_id() -> StringName:
	return &'chance'


func get_description() -> String:
	return 'Randomly branches to True or False based on a percentage. A chance of 50 goes True about half the time.'


func get_display_name() -> String:
	return 'Chance'


func get_icon() -> String:
	return 'dice-5'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Chance %',
			type = 'float',
			id = &'chance',
			doc = 'Percent chance of taking the True branch, from 0 to 100.',
			default_value = 50.0
		}
	]


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', doc = 'Where to go when the roll succeeds.'},
		{name = 'False', id = &'false', doc = 'Where to go when it fails.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return 'if randf() * 100.0 < {{chance}}:\n\t{{true}}\nelse:\n\t{{false}}'
