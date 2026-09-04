@tool
class_name HenActionOverlappingBodies extends HenScriptMacroBase


func get_id() -> StringName:
	return &'overlapping_bodies'


func get_description() -> String:
	return 'Stores the bodies that are inside an Area2D or an Area3D right now, such as the 3 enemies standing in a damage zone. It reads the list the area already keeps, while Get Bodies In Radius asks the physics world again.'


func get_display_name() -> String:
	return 'Get Overlapping Bodies'


func get_icon() -> String:
	return 'group'


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Area',
			type = 'Node',
			id = &'area',
			doc = 'The Area2D or Area3D to read, such as a hitbox or a pickup radius.',
			bind_only = true,
			default_value = null
		}
	]


func get_outputs() -> Array[Dictionary]:
	return [
		{name = 'Result', type = 'Array', id = &'result', doc = 'Where to store the bodies that touch the area right now.'}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'bodies_{{VCNODE_ID}}'

	return '{{area}}.get_overlapping_bodies()'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Enter', id = &'enter'},
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_outputs() -> Array[Dictionary]:
	return [
		{
			name = 'Found',
			id = &'found',
			optional = true,
			doc = 'Where to go when at least one body is inside the area.'
		},
		{
			name = 'None',
			id = &'none',
			optional = true,
			doc = 'Where to go when no body is inside the area, which is when an empty list is stored.'
		}
	]


func get_flow_enter() -> String:
	return _body()


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	if not any_flow_connected():
		return '{{out:result}}'

	return 'var bodies_{{VCNODE_ID}} = {{area}}.get_overlapping_bodies()\n' \
		+ '{{out:result}}\n' \
		+ 'if not bodies_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{found}}\n' \
		+ 'else:\n' \
		+ '\t{{none}}'
