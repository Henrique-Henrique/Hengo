@tool
class_name HenActionOverlappingAreas extends HenScriptMacroBase


func get_id() -> StringName:
	return &'overlapping_areas'


func get_description() -> String:
	return 'Stores the other areas that overlap an Area2D or an Area3D right now, such as the 2 hurtboxes a sword swing is touching. It reads the list the area already keeps, while Get Bodies In Radius asks the physics world again.'


func get_display_name() -> String:
	return 'Get Overlapping Areas'


func get_icon() -> String:
	return 'blend'


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
		{name = 'Result', type = 'Array', id = &'result', doc = 'Where to store the areas that overlap the area right now.'}
	]


func get_output_result() -> String:
	if any_flow_connected():
		return 'areas_{{VCNODE_ID}}'

	return '{{area}}.get_overlapping_areas()'


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
			doc = 'Where to go when at least one other area overlaps this one.'
		},
		{
			name = 'None',
			id = &'none',
			optional = true,
			doc = 'Where to go when no other area overlaps this one, which is when an empty list is stored.'
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

	return 'var areas_{{VCNODE_ID}} = {{area}}.get_overlapping_areas()\n' \
		+ '{{out:result}}\n' \
		+ 'if not areas_{{VCNODE_ID}}.is_empty():\n' \
		+ '\t{{found}}\n' \
		+ 'else:\n' \
		+ '\t{{none}}'
