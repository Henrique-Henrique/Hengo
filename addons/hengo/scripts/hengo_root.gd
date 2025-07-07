@tool
class_name HenHengoRoot extends Control

var target_zoom: float = .8
var cnode_ui: Panel
var cnode_cam: HenCam

var cnode_stat_label: Label

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false

# private
#
func _ready() -> void:
	if EditorInterface.get_edited_scene_root() == self:
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		return

	set_process(true)

	# initializing
	HenRouter.current_route = {}
	HenRouter.line_route_reference = {}
	HenRouter.comment_reference = {}
	HenGlobal.history = UndoRedo.new()
	HenEnums.DROPDOWN_STATES = []

	# defining types
	var object_list = ClassDB.get_inheriters_from_class('Object')
	object_list.sort()
	HenEnums.OBJECT_TYPES = object_list
	HenEnums.DROPDOWN_OBJECT_TYPES = Array(HenEnums.OBJECT_TYPES).map(
		func(x: String) -> Dictionary:
			return {
				name = x
			}
	)

	var all_classes = ClassDB.get_class_list()
	all_classes.sort()

	all_classes = HenEnums.VARIANT_TYPES + all_classes
	HenEnums.ALL_CLASSES = all_classes.duplicate()
	HenEnums.DROPDOWN_ALL_CLASSES = Array(HenEnums.ALL_CLASSES).map(
		func(x: String) -> Dictionary:
			return {
				name = x
			}
	)

	# Global.CAM = cam
	cnode_ui = get_node('%CNodeUI') as Panel
	cnode_cam = cnode_ui.get_node('Cam')

	cnode_ui.mouse_entered.connect(func(): HenGlobal.mouse_on_cnode_ui = true)
	cnode_ui.mouse_exited.connect(func(): HenGlobal.mouse_on_cnode_ui = false)
	cnode_ui.gui_input.connect(_on_cnode_gui_input)

	# setting globals
	HenGlobal.CAM = cnode_cam
	HenGlobal.CNODE_CONTAINER = get_node('%CnodeContainer')
	HenGlobal.COMMENT_CONTAINER = get_node('%CommentContainer')
	HenGlobal.DROPDOWN_MENU = get_node('%DropDownMenu')
	HenGlobal.POPUP_CONTAINER = get_node('%PopupContainer')
	HenGlobal.DOCS_TOOLTIP = get_node('%DocsToolTip')
	HenGlobal.CONNECTION_GUIDE = cnode_ui.get_node('%ConnectionGuide')
	HenGlobal.HENGO_ROOT = self
	HenGlobal.TOOLTIP = get_node('%Tooltip')
	HenGlobal.CODE_PREVIEWER = get_node('%CodePreviewContainer')

	cnode_stat_label = get_node('%CNodeStatLabel')


func _on_cnode_gui_input(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion and can_select:
		_select_cnode()

	if _event is InputEventMouseButton:
		if _event.pressed:
			match _event.button_index:
				MOUSE_BUTTON_RIGHT:
					if not (HenGlobal.HENGO_ROOT.get_node('%ScriptMsgContainer') as PanelContainer).visible:
						var method_list = load('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
						method_list.start(HenGlobal.script_config.type, get_global_mouse_position())
						HenGlobal.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
				MOUSE_BUTTON_LEFT:
					for cnode in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
						cnode.unselect()
					
					HenGlobal.CODE_PREVIEWER.clear()
					
					get_viewport().gui_release_focus()

					cnode_selecting_rect = true
					start_select_pos = get_global_mouse_position()
					HenGlobal.ACTION_BAR.filesystem_dock(true)
		else:
			match _event.button_index:
				MOUSE_BUTTON_LEFT:
					if can_select:
						_select_cnode()
						can_select = false

					cnode_selecting_rect = false
					start_select_pos = Vector2.ZERO
					HenGlobal.CAM.get_node('SelectionRect').visible = false


func _select_cnode() -> void:
	var selection_rect: ReferenceRect = HenGlobal.CAM.get_node('SelectionRect')

	for v_cnode: HenVirtualCNode in HenRouter.get_current_route_v_cnodes():
		if v_cnode.cnode_ref:
			if selection_rect.get_global_rect().has_point(v_cnode.cnode_ref.global_position):
				v_cnode.cnode_ref.select()
			else:
				v_cnode.cnode_ref.unselect()


func _process(_delta: float) -> void:
	cnode_stat_label.text = str('pos => ', HenGlobal.CAM.position as Vector2i) + str(' zoom => ', snapped(HenGlobal.CAM.transform.x.x, 0.01))

	if cnode_selecting_rect and HenGlobal.CAM:
		if get_global_mouse_position().distance_to(start_select_pos) > 50:
			var selection_rect: ReferenceRect = HenGlobal.CAM.get_node('SelectionRect')
			
			selection_rect.size = abs(HenGlobal.CAM.get_relative_vec2(get_global_mouse_position()) - HenGlobal.CAM.get_relative_vec2(start_select_pos))
			selection_rect.position = HenGlobal.CAM.get_relative_vec2(start_select_pos)

			if get_global_mouse_position().x - start_select_pos.x < 0:
				selection_rect.position.x -= selection_rect.size.x
			
			if get_global_mouse_position().y - start_select_pos.y < 0:
				selection_rect.position.y -= selection_rect.size.y

			selection_rect.border_width = 2 / HenGlobal.CAM.transform.x.x
			selection_rect.visible = true

			can_select = true
		else:
			can_select = false
			HenGlobal.CAM.get_node('SelectionRect').visible = false


func _input(event: InputEvent) -> void:
	if not HenGlobal.HENGO_ROOT.visible:
		return
	
	if event is InputEventKey:
		if event.pressed:
			if event.shift_pressed and event.keycode == KEY_F:
				var all_nodes = get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP)
				HenGlobal.history.create_action('Delete Node')

				for cnode: HenCnode in all_nodes:
					var v_cnode: HenVCNodeReturn = cnode.virtual_ref.get_history_obj()

					HenGlobal.history.add_do_method(v_cnode.remove)
					HenGlobal.history.add_undo_reference(v_cnode)
					HenGlobal.history.add_undo_method(v_cnode.add)

				HenGlobal.history.commit_action()
				
			elif event.keycode == KEY_F8:
				# just for test
				HenRouter.change_route(HenGlobal.BASE_ROUTE)
			elif event.keycode == KEY_F10:
				for line: HenConnectionLine in HenGlobal.connection_line_pool:
					if line.visible:
						prints(line, line.visible, line.position, line.points.size())
						line.visible = true
			elif event.keycode == KEY_F9:
				var old: HenVirtualCNode
				for i in range(1000):
					var cnode2: HenVirtualCNode = HenVirtualCNode.instantiate_virtual_cnode_and_add({
						name = 'print',
						sub_type = HenVirtualCNode.SubType.VOID,
						category = 'native',
						inputs = [
							{
								name = 'content',
								type = 'String'
							}
						],
						route = HenRouter.current_route,
						position = Vector2(0, 500 * i + 1)
					})

			if event.ctrl_pressed:
				if event.keycode == KEY_Z:
					get_tree().root.set_input_as_handled()
					HenGlobal.history.undo()
				elif event.keycode == KEY_Y:
					HenGlobal.history.redo()
				elif event.keycode == KEY_C:
					HenGlobal.history.clear_history()


func get_script_list() -> void:
	var dir_files: PackedStringArray = DirAccess.get_files_at('res://hengo/save') if DirAccess.dir_exists_absolute('res://hengo/save') else PackedStringArray()

	for file_path: StringName in dir_files:
		var path: StringName = 'res://hengo/save/' + file_path
		var data: HenScriptData = ResourceLoader.load(path)
		
		var dict_data: Dictionary = {
			name = file_path.get_basename(),
			path = data.path,
			type = data.type,
			data_path = path,
			side_bar_list = data.side_bar_list
		}