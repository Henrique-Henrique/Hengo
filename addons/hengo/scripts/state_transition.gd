@tool
extends HBoxContainer

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _StateConnectionLine = preload('res://addons/hengo/scripts/state_connection_line.gd')
const _Assets = preload('res://addons/hengo/scripts/assets.gd')

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
				_Global.can_make_state_connection = true
				_Global.current_state_transition = self
				_Global.STATE_CONNECTION_GUIDE.is_in_out = true
				_Global.STATE_CONNECTION_GUIDE.start(_Global.CAM.get_relative_vec2(global_position))
		else:
			if _Global.can_make_state_connection and _Global.state_connection_to_date.is_empty():
				_Global.history.create_action('Remove State Connection')
				_Global.history.add_do_method(line.remove_from_scene)
				_Global.history.add_undo_reference(line)
				_Global.history.add_undo_method(line.add_to_scene)
				_Global.history.commit_action()
			elif _Global.can_make_state_connection and not _Global.state_connection_to_date.is_empty():
				var line := create_connection_line(_Global.state_connection_to_date)

				_Global.history.create_action('Add State Connection')
				_Global.history.add_do_method(line.add_to_scene)
				_Global.history.add_do_reference(line)
				_Global.history.add_undo_method(line.remove_from_scene)
				_Global.history.commit_action()

			_Global.connection_to_data = {}
			_Global.can_make_state_connection = false
			_Global.STATE_CONNECTION_GUIDE.end()
			_Global.current_state_transition = null
			hover(false)

# public
#
func hover(_hover: bool) -> void:
	get_node('%Panel').visible = _hover


func set_transition_name(_name: String) -> void:
	get_node('%Name').text = _name


func get_transition_name() -> String:
	return get_node('%Name').text


func create_connection_line(_config: Dictionary) -> _StateConnectionLine:
	var line = _Assets.StateConnectionLineScene.instantiate()

	line.from_transition = self
	line.to_state = _config.state_from

	# signal to update connection line
	root.connect('on_move', line.update_line)
	_config.state_from.connect('on_move', line.update_line)

	return line

func add_connection(_config: Dictionary) -> _StateConnectionLine:
	var line := create_connection_line(_config)

	line.add_to_scene()

	return line