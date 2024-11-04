@tool
extends Control

# imports
const _Cam = preload('res://addons/hengo/scripts/cam.gd')
const _Router = preload('res://addons/hengo/scripts/router.gd')
const _Global = preload('res://addons/hengo/scripts/global.gd')
const _CNode = preload('res://addons/hengo/scripts/cnode.gd')
const _State = preload('res://addons/hengo/scripts/state.gd')
const _Enums = preload('res://addons/hengo/references/enums.gd')

var target_zoom: float = .8
var state_ui: Panel
var cnode_ui: Panel
var state_cam: _Cam
var cnode_cam: _Cam

var state_stat_label: Label
var cnode_stat_label: Label

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false

# private
#
func _ready() -> void:
	if _Global.editor_interface.get_edited_scene_root() == self:
		set_process(false)
		return

	set_process(true)
	# initializing
	_Router.current_route = {}
	_Router.route_reference = {}
	_Router.line_route_reference = {}
	_Router.comment_reference = {}
	_Global.history = UndoRedo.new()
	_Enums.DROPDOWN_STATES = []

	# defining types
	var object_list = ClassDB.get_inheriters_from_class('Object')
	object_list.sort()
	_Enums.OBJECT_TYPES = object_list
	_Enums.DROPDOWN_OBJECT_TYPES = Array(_Enums.OBJECT_TYPES).map(
		func(x: String) -> Dictionary:
			return {
				name = x
			}
	)

	var all_classes = ClassDB.get_class_list()
	all_classes.sort()

	all_classes = _Enums.VARIANT_TYPES + all_classes
	_Enums.ALL_CLASSES = all_classes.duplicate()
	_Enums.DROPDOWN_ALL_CLASSES = Array(_Enums.ALL_CLASSES).map(
		func(x: String) -> Dictionary:
			return {
				name = x
			}
	)

	# Global.CAM = cam
	state_ui = get_node('%StateUI') as Panel
	cnode_ui = get_node('%CNodeUI') as Panel
	state_cam = state_ui.get_node('Cam')
	cnode_cam = cnode_ui.get_node('Cam')

	cnode_ui.mouse_entered.connect(func(): _Global.mouse_on_cnode_ui = true)
	cnode_ui.mouse_exited.connect(func(): _Global.mouse_on_cnode_ui = false)
	state_ui.gui_input.connect(_on_state_gui_input)
	cnode_ui.gui_input.connect(_on_cnode_gui_input)

	# setting globals
	_Global.CAM = state_cam
	_Global.STATE_CAM = state_cam
	_Global.CNODE_CAM = cnode_cam
	_Global.SIDE_BAR = get_node('%SideBar')
	_Global.DROP_PROP_MENU = get_node('%DropPropMenu')
	_Global.CNODE_CONTAINER = get_node('%CnodeContainer')
	_Global.COMMENT_CONTAINER = get_node('%CommentContainer')
	_Global.STATE_CONTAINER = get_node('%StateContainer')
	_Global.DROPDOWN_MENU = get_node('%DropDownMenu')
	_Global.POPUP_CONTAINER = get_node('%PopupContainer')
	_Global.LOCAL_VAR_SECTION = _Global.SIDE_BAR.get_node('%LocalVar')
	_Global.SIGNAL_SECTION = _Global.SIDE_BAR.get_node('%StateSignal')
	_Global.CODE_TOOLTIP = get_node('%CodeToolTip')
	_Global.ERROR_BT = get_node('%ErrorBt')
	_Global.CONNECTION_GUIDE = cnode_ui.get_node('%ConnectionGuide')
	_Global.STATE_CONNECTION_GUIDE = cnode_ui.get_node('%StateConnectionGuide')
	_Global.GENERAL_CONTAINER = state_cam.get_node('%GeneralContainer')


	# config code preview
	var editor: TextEdit = _Global.CODE_TOOLTIP.get_child(0)
	var highlighter: CodeHighlighter = editor.syntax_highlighter

	highlighter.clear_color_regions()
	highlighter.add_color_region('\"', '\"', Color('#9ece6a'))
	highlighter.add_color_region('#', '', Color('#565f89'), true)

	for kw in [
		"and", "as", "assert", "break", "class", "class_name", "continue", "extends",
		"elif", "else", "enum", "export", "for", "func", "if", "in", "is", "match",
		"not", "onready", "or", "pass", "return", "setget", "signal", "static", "tool",
		"var", "while", "yield"
	]:
		highlighter.add_keyword_color(kw, Color('#bb9af7'))

	state_stat_label = get_node('%StateStatLabel')
	cnode_stat_label = get_node('%CNodeStatLabel')


func _on_state_gui_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			match _event.button_index:
				MOUSE_BUTTON_LEFT:
					for state in get_tree().get_nodes_in_group(_Enums.STATE_SELECTED_GROUP):
						state.unselect()

					cnode_selecting_rect = true
					start_select_pos = get_global_mouse_position()
		else:
			match _event.button_index:
				MOUSE_BUTTON_LEFT:
					if can_select:
						_select_state()

					cnode_selecting_rect = false
					start_select_pos = Vector2.ZERO
					_Global.STATE_CAM.get_node('SelectionRect').visible = false


func _select_state() -> void:
	var selection_rect: ReferenceRect = _Global.STATE_CAM.get_node('SelectionRect')

	for cnode in _Global.STATE_CONTAINER.get_children():
		if selection_rect.get_global_rect().has_point(cnode.global_position):
			cnode.select()


func _on_cnode_gui_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			match _event.button_index:
				MOUSE_BUTTON_RIGHT:
					var method_list = load('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
					method_list.start(_Global.script_config.type if _Global.script_config.has('type') else 'all', get_global_mouse_position())
					_Global.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
				MOUSE_BUTTON_LEFT:
					for cnode in get_tree().get_nodes_in_group(_Enums.CNODE_SELECTED_GROUP):
						cnode.unselect()
					
					get_viewport().gui_release_focus()

					cnode_selecting_rect = true
					start_select_pos = get_global_mouse_position()
		else:
			match _event.button_index:
				MOUSE_BUTTON_LEFT:
					if can_select:
						_select_cnode()

					cnode_selecting_rect = false
					start_select_pos = Vector2.ZERO
					_Global.CNODE_CAM.get_node('SelectionRect').visible = false


func _select_cnode() -> void:
	var selection_rect: ReferenceRect = _Global.CNODE_CAM.get_node('SelectionRect')

	for cnode: _CNode in _Global.CNODE_CONTAINER.get_children():
		if selection_rect.get_global_rect().has_point(cnode.global_position):
			cnode.select()


func _process(_delta: float) -> void:
	if cnode_ui.get_global_rect().has_point(get_global_mouse_position()):
		_Global.CAM = cnode_cam
	elif state_ui.get_global_rect().has_point(get_global_mouse_position()):
		_Global.CAM = state_cam
	else:
		_Global.CAM = null

	state_stat_label.text = str('pos => ', _Global.STATE_CAM.position as Vector2i) + str(' zoom => ', snapped(_Global.STATE_CAM.transform.x.x, 0.01))
	cnode_stat_label.text = str('pos => ', _Global.CNODE_CAM.position as Vector2i) + str(' zoom => ', snapped(_Global.CNODE_CAM.transform.x.x, 0.01))

	if cnode_selecting_rect and _Global.CAM:
		if get_global_mouse_position().distance_to(start_select_pos) > 50:
			var selection_rect: ReferenceRect = _Global.CAM.get_node('SelectionRect')
			
			selection_rect.size = abs(_Global.CAM.get_relative_vec2(get_global_mouse_position()) - _Global.CAM.get_relative_vec2(start_select_pos))
			selection_rect.position = _Global.CAM.get_relative_vec2(start_select_pos)

			if get_global_mouse_position().x - start_select_pos.x < 0:
				selection_rect.position.x -= selection_rect.size.x
			
			if get_global_mouse_position().y - start_select_pos.y < 0:
				selection_rect.position.y -= selection_rect.size.y

			selection_rect.border_width = 2 / _Global.CAM.transform.x.x
			selection_rect.visible = true

			can_select = true
		else:
			can_select = false
			_Global.CAM.get_node('SelectionRect').visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.shift_pressed and event.keycode == KEY_S:
				var state_ref = _State.instantiate_state()

				_Global.history.create_action('Add State')
				_Global.history.add_do_method(state_ref.add_to_scene)
				_Global.history.add_do_reference(state_ref)
				_Global.history.add_undo_method(state_ref.remove_from_scene)
				_Global.history.commit_action()
			elif event.shift_pressed and event.keycode == KEY_C:
				# add comment
				var comment = load('res://addons/hengo/scenes/utils/comment.tscn').instantiate()
				comment.route_ref = _Router.current_route
				_Router.comment_reference[_Router.current_route.id].append(comment)
				_Global.COMMENT_CONTAINER.add_child(comment)
			elif event.shift_pressed and event.keycode == KEY_F:
				# delete cnode or state
				match _Global.CAM:
					_Global.CNODE_CAM:
						var all_nodes = get_tree().get_nodes_in_group(_Enums.CNODE_SELECTED_GROUP)
						_Global.history.create_action('Delete Node')

						for cnode: _CNode in all_nodes:
							if cnode.type == 'virtual':
								continue
							
							_Global.history.add_do_method(cnode.remove_from_scene)
							_Global.history.add_undo_reference(cnode)
							_Global.history.add_undo_method(cnode.add_to_scene)

						_Global.history.commit_action()
					_Global.STATE_CAM:
						var all_states = get_tree().get_nodes_in_group(_Enums.STATE_SELECTED_GROUP)
						var reset: bool = false
						_Global.history.create_action('Delete Node')

						for state: _State in all_states:
							if state == _Global.start_state:
								continue
							
							_Global.history.add_do_method(state.remove_from_scene)
							_Global.history.add_undo_reference(state)
							_Global.history.add_undo_method(state.add_to_scene)
							reset = true

						_Global.history.commit_action()

						if reset:
							_Router.change_route(_Global.start_state.route)
							_Global.start_state.select()

						print(all_states)
			elif event.keycode == KEY_F9:
				# This is for Debug / Development key helper
				
				
				print(_Global.COMMENT_CONTAINER.get_children())

			if event.ctrl_pressed:
				if event.keycode == KEY_Z:
					_Global.history.undo()
				elif event.keycode == KEY_Y:
					_Global.history.redo()
				elif event.keycode == KEY_C:
					_Global.history.clear_history()
