@tool
class_name HenActionScreenWrap extends HenScriptMacroBase


# wraps the owner to the opposite edge when it leaves the view, the way asteroids
# reappear on the far side. assumes a fixed screen with no scrolling camera.


func get_id() -> StringName:
	return &'screen_wrap'


func get_description() -> String:
	return 'Sends the node to the opposite edge when it leaves the screen, the way an asteroid reappears on the far side. Assumes a fixed screen with no scrolling camera.'


func get_display_name() -> String:
	return 'Wrap Around Screen'


func get_icon() -> String:
	return 'refresh-cw'


func get_target_classes() -> Array[StringName]:
	return [&'Node2D']


func get_default_phase() -> StringName:
	return &'physics'


func get_inputs() -> Array[Dictionary]:
	return [
		node_ref_input('The node to wrap around the screen. Leave it empty to wrap this node.')
	]


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
	return 'var rect_{{VCNODE_ID}} = _ref.get_viewport_rect()\n' \
		+ 'var pos_{{VCNODE_ID}} = {{ref}}.global_position\n' \
		+ 'pos_{{VCNODE_ID}}.x = wrapf(pos_{{VCNODE_ID}}.x, rect_{{VCNODE_ID}}.position.x, rect_{{VCNODE_ID}}.end.x)\n' \
		+ 'pos_{{VCNODE_ID}}.y = wrapf(pos_{{VCNODE_ID}}.y, rect_{{VCNODE_ID}}.position.y, rect_{{VCNODE_ID}}.end.y)\n' \
		+ '{{ref}}.global_position = pos_{{VCNODE_ID}}'
