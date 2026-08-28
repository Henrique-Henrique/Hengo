@tool
class_name HenActionChance extends HenScriptMacroBase


# rolls the dice and takes one of the two branches. Chance is a percentage:
# 50 means it goes True half of the time, 100 always.


func get_id() -> StringName:
	return &'chance'


func get_description() -> String:
	return 'Answers a random roll against the chance given, so Chance = 25 comes up true about one time in four. It can branch on the answer or hand it to a field that takes a yes or no.'


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


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Yes', type = 'bool', id = &'result', doc = 'Where to store whether the roll came up inside the chance.'}
	]


func get_output_result() -> String:
	return 'randf() * 100.0 < {{chance}}'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{name = 'True', id = &'true', optional = true, doc = 'Where to go when the roll succeeds.'},
		{name = 'False', id = &'false', optional = true, doc = 'Where to go when it fails.'}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


# with no branch wired it is only the answer, which is what lets it be read
# from inside another action's field
func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return '{{out:result}}\n' \
		+ 'if randf() * 100.0 < {{chance}}:\n' \
		+ '\t{{true}}\n' \
		+ 'else:\n' \
		+ '\t{{false}}'
