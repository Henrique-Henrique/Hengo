@tool
class_name HenActionWatchValue extends HenScriptMacroBase


func get_id() -> StringName:
	return &'watch_value'


func get_description() -> String:
	return 'Shows a value in the corner of the screen and rewrites it every frame, so a number that keeps changing can be read while the game runs. With Label = speed, one line reading speed: 412.5 stays in place instead of flooding the Output panel the way Print Value does.'


func get_display_name() -> String:
	return 'Watch Value'


func get_icon() -> String:
	return 'monitor-dot'


func get_default_phase() -> StringName:
	return &'update'


func get_inputs() -> Array[Dictionary]:
	return [
		{
			name = 'Label',
			type = 'String',
			id = &'label',
			doc = 'The name shown before the value, and also the name of the line, so two Watch Value actions with the same label overwrite each other while different labels stack.',
			default_value = 'value'
		},
		{
			name = 'Value',
			type = 'Variant',
			id = &'value',
			doc = 'The value to show, such as a variable or a node property.',
			default_value = 0
		}
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
	return 'var watch_{{VCNODE_ID}} = _ref.get_tree().root.get_node_or_null(\'HengoWatch\')\n' \
		+ 'if watch_{{VCNODE_ID}} == null:\n' \
		+ '\twatch_{{VCNODE_ID}} = CanvasLayer.new()\n' \
		+ '\twatch_{{VCNODE_ID}}.name = \'HengoWatch\'\n' \
		+ '\tvar box_{{VCNODE_ID}} = VBoxContainer.new()\n' \
		+ '\tbox_{{VCNODE_ID}}.name = \'Lines\'\n' \
		+ '\tbox_{{VCNODE_ID}}.position = Vector2(16, 16)\n' \
		+ '\twatch_{{VCNODE_ID}}.add_child(box_{{VCNODE_ID}})\n' \
		+ '\t_ref.get_tree().root.add_child(watch_{{VCNODE_ID}})\n' \
		+ 'var lines_{{VCNODE_ID}} = watch_{{VCNODE_ID}}.get_node(\'Lines\')\n' \
		+ 'var line_{{VCNODE_ID}} = lines_{{VCNODE_ID}}.get_node_or_null({{label}})\n' \
		+ 'if line_{{VCNODE_ID}} == null:\n' \
		+ '\tline_{{VCNODE_ID}} = Label.new()\n' \
		+ '\tline_{{VCNODE_ID}}.name = {{label}}\n' \
		+ '\tlines_{{VCNODE_ID}}.add_child(line_{{VCNODE_ID}})\n' \
		+ 'line_{{VCNODE_ID}}.text = str({{label}}) + \': \' + str({{value}})'
