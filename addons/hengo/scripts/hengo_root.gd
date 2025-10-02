@tool
class_name HenHengoRoot extends Control

var target_zoom: float = .8

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false
var toggle_bottom_panel: bool = true


func _ready() -> void:
	if HenUtils.disable_scene(self):
		return

	set_process(true)

	# map dependencies
	HenThreadHelper.add_task(HenMapDependencies.start_map)

	# initializing
	HenRouter.current_route = null
	HenRouter.line_route_reference = {}
	HenRouter.comment_reference = {}
	# HenGlobal.history = UndoRedo.new()
	HenEnums.DROPDOWN_STATES = []
	HenGlobal.SELECTED_VIRTUAL_CNODE.clear()

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

	# show msg
	(get_node('%ScriptMsgContainer') as PanelContainer).visible = true


func _select_cnode() -> void:
	var selection_rect: ReferenceRect = HenGlobal.CAM.get_node('SelectionRect')

	for v_cnode: HenVirtualCNode in HenRouter.get_current_route_v_cnodes():
		if v_cnode.cnode_instance:
			if selection_rect.get_global_rect().has_point(v_cnode.cnode_instance.global_position):
				v_cnode.select()
			else:
				v_cnode.unselect()


func _process(_delta: float) -> void:
	# task id
	for id in HenThreadHelper.task_id_list:
		if WorkerThreadPool.is_task_completed(id):
			WorkerThreadPool.wait_for_task_completion(id)
			HenThreadHelper.task_id_list.erase(id)


func _input(event: InputEvent) -> void:
	if HenGlobal.HENGO_ROOT and not HenGlobal.HENGO_ROOT.visible:
		return
	
	if event is InputEventKey:
		if event.pressed:
			if event.shift_pressed and event.keycode == KEY_F:
				var all_nodes = HenGlobal.SELECTED_VIRTUAL_CNODE
				HenGlobal.history.create_action('Delete Node')

				for v_cnode: HenVirtualCNode in all_nodes:
					if not v_cnode.cnode_instance:
						continue

					var v_cnode_return: HenVCNodeReturn = v_cnode.get_history_obj()

					HenGlobal.history.add_do_method(v_cnode_return.remove)
					HenGlobal.history.add_undo_reference(v_cnode_return)
					HenGlobal.history.add_undo_method(v_cnode_return.add)

				HenGlobal.history.commit_action()
				
			elif event.keycode == KEY_F8:
				# just for test
				HenRouter.change_route(HenGlobal.BASE_ROUTE)
			elif event.keycode == KEY_F10:
				for line: HenConnectionLine in HenGlobal.connection_line_pool:
					if line.visible:
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
				elif event.keycode == KEY_SPACE:
					HenGlobal.HENGO_EDITOR_PLUGIN.bottom_panel_visibility(toggle_bottom_panel)
					toggle_bottom_panel = not toggle_bottom_panel
				elif event.keycode == KEY_P:
					HenScriptDataCache.clear()
					print('Script data cache cleared')
				elif event.keycode == KEY_F:
					get_tree().root.set_input_as_handled()
					HenFormatter.format_current_route()
					print('FORMATTED')
