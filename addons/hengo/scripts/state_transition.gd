@tool
class_name HenStateTransition extends HBoxContainer

@export var root: PanelContainer

var line

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
				HenGlobal.history.create_action('Remove State Connection')
				HenGlobal.history.add_do_method(line.remove_from_scene)
				HenGlobal.history.add_undo_reference(line)
				HenGlobal.history.add_undo_method(line.add_to_scene)
				HenGlobal.history.commit_action()
			elif HenGlobal.can_make_state_connection and not HenGlobal.state_connection_to_date.is_empty():
				var line := create_connection_line(HenGlobal.state_connection_to_date)

				HenGlobal.history.create_action('Add State Connection')
				HenGlobal.history.add_do_method(line.add_to_scene)
				HenGlobal.history.add_do_reference(line)
				HenGlobal.history.add_undo_method(line.remove_from_scene)
				HenGlobal.history.commit_action()

			HenGlobal.connection_to_data = {}
			HenGlobal.can_make_state_connection = false
			HenGlobal.STATE_CONNECTION_GUIDE.end()
			HenGlobal.current_state_transition = null
			hover(false)

# public
#
func hover(_hover: bool) -> void:
	get_node('%Panel').visible = _hover


func set_transition_name(_name: String) -> void:
	get_node('%Name').text = _name


func get_transition_name() -> String:
	return get_node('%Name').text


func create_connection_line(_config: Dictionary) -> HenStateConnectionLine:
	var line = HenAssets.StateConnectionLineScene.instantiate()

	line.from_transition = self
	line.to_state = _config.state_from

	# signal to update connection line
	root.connect('on_move', line.update_line)
	_config.state_from.connect('on_move', line.update_line)

	return line

func add_connection(_config: Dictionary) -> HenStateConnectionLine:
	var line := create_connection_line(_config)

	line.add_to_scene()

	return line