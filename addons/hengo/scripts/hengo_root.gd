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
	if HenGlobal.editor_interface.get_edited_scene_root() == self:
		set_process(false)
		return

	set_process(true)
	# initializing
	HenRouter.current_route = {}
	HenRouter.route_reference = {}
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
	HenGlobal.DASHBOARD = get_node('%DashBoard')

	cnode_stat_label = get_node('%CNodeStatLabel')


func _on_cnode_gui_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			match _event.button_index:
				MOUSE_BUTTON_RIGHT:
					var method_list = load('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
					method_list.start(HenGlobal.script_config.type if HenGlobal.script_config.has('type') else 'all', get_global_mouse_position())
					HenGlobal.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
				MOUSE_BUTTON_LEFT:
					for cnode in get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP):
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
					HenGlobal.CAM.get_node('SelectionRect').visible = false


func _select_cnode() -> void:
	var selection_rect: ReferenceRect = HenGlobal.CAM.get_node('SelectionRect')

	for cnode: HenCnode in HenGlobal.CNODE_CONTAINER.get_children():
		if selection_rect.get_global_rect().has_point(cnode.global_position):
			cnode.select()


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
					if not cnode.virtual_ref or cnode.sub_type == HenCnode.SUB_TYPE.VIRTUAL:
						continue

					var v_cnode: HenVirtualCNode.VCNodeReturn = cnode.virtual_ref.get_history_obj()

					HenGlobal.history.add_do_method(v_cnode.remove)
					HenGlobal.history.add_undo_reference(v_cnode)
					HenGlobal.history.add_undo_method(v_cnode.add)

				HenGlobal.history.commit_action()
			elif event.keycode == KEY_F9:
				# This is for Debug / Development key helper
				var start: float = Time.get_ticks_usec()
				var virtual: HenCnode = HenGlobal.CNODE_CONTAINER.get_child(0)

				virtual.position = Vector2.ZERO

				HenFormatter.arr = []
				HenFormatter.start_position = virtual.position + virtual.size / 2
				HenFormatter.format(
					virtual.flow_to.cnode,
					virtual
				)
				HenFormatter.format_y()

				virtual.move(
					Vector2(
						virtual.flow_to.cnode.position.x - (
							virtual.size.x - virtual.flow_to.cnode.size.x
						) / 2,
						virtual.position.y
					)
				)

				HenFormatter.format_comments()

				var end: float = Time.get_ticks_usec()

				print('Formatted in: ', (end - start) / 1000., 'ms')
				
			elif event.keycode == KEY_F8:
				# just for test
				HenRouter.change_route(HenGlobal.BASE_ROUTE)
					

			if event.ctrl_pressed:
				if event.keycode == KEY_Z:
					get_tree().root.set_input_as_handled()
					HenGlobal.history.undo()
				elif event.keycode == KEY_Y:
					HenGlobal.history.redo()
				elif event.keycode == KEY_C:
					HenGlobal.history.clear_history()
