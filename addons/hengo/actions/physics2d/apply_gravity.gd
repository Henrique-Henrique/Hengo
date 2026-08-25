@tool
class_name HenActionApplyGravity extends HenScriptMacroBase


# accumulates gravity into the body velocity. the body needs delta, so it runs on
# physics (the default) or update, never on enter/exit.


func get_id() -> StringName:
	return &'apply_gravity'


func get_description() -> String:
	return 'Pulls the body downward by adding gravity to its velocity every physics frame, so it falls faster the longer it drops.'


func get_display_name() -> String:
	return 'Apply Gravity'


func get_icon() -> String:
	return 'arrow-down-to-line'


func get_target_classes() -> Array[StringName]:
	return [&'CharacterBody2D']


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The body to pull down. Leave it empty to pull this node.'),
		{
			name = 'Gravity',
			type = 'float',
			id = &'gravity',
				doc = 'How strong the downward pull is, in pixels per second squared.',
			default_value = 980.0
		}
	]


func get_default_phase() -> StringName:
	return &'physics'


func get_flow_inputs() -> Array[Dictionary]:
	return [
		{name = 'Update', id = &'update'},
		{name = 'Physics', id = &'physics'}
	]


func get_flow_update() -> String:
	return _body()


func get_flow_physics() -> String:
	return _body()


func _body() -> String:
	return '{{ref}}.velocity.y += {{gravity}} * delta'
