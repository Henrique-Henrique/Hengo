@tool
class_name HenStateTransition extends HBoxContainer

@export var root: HenState

var line: HenStateConnectionLine

# deleted
var state_ref_deleted: HenState
var transition_ref: HenVirtualState.TransitionData

# private
#
func _ready() -> void:
	var bt: PanelContainer = get_node('TransitionButton') as PanelContainer
	bt.gui_input.connect(_on_input)
	item_rect_changed.connect(_on_rect_change)


func _on_rect_change() -> void:
	if line:
		await get_tree().process_frame

		line.update_line()


func _on_input(_event: InputEvent):
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				HenGlobal.can_make_state_connection = true
				HenGlobal.current_state_transition = self
				HenGlobal.STATE_CONNECTION_GUIDE.is_in_out = true
				HenGlobal.STATE_CONNECTION_GUIDE.start(HenGlobal.CAM.get_relative_vec2(global_position))
		else:
			if HenGlobal.can_make_state_connection and HenGlobal.state_connection_to_date.is_empty():
				pass
				# if line:
				# 	HenGlobal.history.create_action('Remove State Connection')
				# 	HenGlobal.history.add_do_method(line.remove_from_scene)
				# 	HenGlobal.history.add_undo_reference(line)
				# 	HenGlobal.history.add_undo_method(line.add_to_scene)
				# 	HenGlobal.history.commit_action()
			elif HenGlobal.can_make_state_connection and not HenGlobal.state_connection_to_date.is_empty():
				create_virtual_connection(HenGlobal.state_connection_to_date)
			
				# var _line: HenStateConnectionLine = create_connection_line(HenGlobal.state_connection_to_date)

				# HenGlobal.history.create_action('Add State Connection')
				# HenGlobal.history.add_do_method(_line.add_to_scene)
				# HenGlobal.history.add_do_reference(_line)
				# HenGlobal.history.add_undo_method(_line.remove_from_scene)
				# HenGlobal.history.commit_action()

			HenGlobal.connection_to_data = {}
			HenGlobal.can_make_state_connection = false
			HenGlobal.STATE_CONNECTION_GUIDE.end()
			HenGlobal.current_state_transition = null
			hover(false)

# public
#
func add_to_scene() -> void:
	if line:
		line.add_to_scene(false)
	
	state_ref_deleted.get_node('%TransitionContainer').add_child(self)

func remove_from_scene() -> void:
	if line:
		line.remove_from_scene(false)
	
	state_ref_deleted = get_parent().owner
	get_parent().remove_child(self)
	state_ref_deleted.size = Vector2.ZERO

func hover(_hover: bool) -> void:
	get_node('%Panel').visible = _hover


func set_transition_name(_name: String) -> void:
	get_node('%Name').text = _name


func get_transition_name() -> String:
	return get_node('%Name').text


func create_virtual_connection(_config: Dictionary) -> HenStateConnectionLine:
	if transition_ref and transition_ref.to:
		transition_ref.to.from_transitions.clear()

	var _line: HenStateConnectionLine = HenPool.get_state_line_from_pool()

	# set virtual transition connection
	transition_ref.from = root.virtual_ref
	transition_ref.to = (_config.state_from as HenState).virtual_ref
	(_config.state_from as HenState).virtual_ref.from_transitions.append(transition_ref)

	_line.from_transition = self
	_line.to_state = _config.state_from
	
	_line.update_line()

	transition_ref.line_ref = _line
	line = _line

	# signal to update connection line
	if not root.is_connected('on_move', _line.update_line):
		root.connect('on_move', _line.update_line)
	
	if not _config.state_from.is_connected('on_move', line.update_line):
		_config.state_from.connect('on_move', line.update_line)

	return _line


func create_connection_line(_config: Dictionary) -> HenStateConnectionLine:
	var _line: HenStateConnectionLine = HenAssets.StateConnectionLineScene.instantiate()

	_line.from_transition = self
	_line.to_state = _config.state_from

	# signal to update connection line
	root.connect('on_move', _line.update_line)
	_config.state_from.connect('on_move', _line.update_line)

	return _line


func add_connection(_config: Dictionary) -> HenStateConnectionLine:
	var _line: HenStateConnectionLine = create_connection_line(_config)

	_line.add_to_scene()

	return _line
