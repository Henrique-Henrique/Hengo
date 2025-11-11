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

	var router: HenRouter = Engine.get_singleton(&'Router')
	var enums: HenEnums = Engine.get_singleton(&'Enums')

	# initializing
	router.current_route = null
	router.comment_reference = {}
	# HenGlobal.history = UndoRedo.new()
	enums.DROPDOWN_STATES = []
	(Engine.get_singleton(&'Global') as HenGlobal).SELECTED_VIRTUAL_CNODE.clear()

	# defining types
	var object_list = ClassDB.get_inheriters_from_class('Object')
	object_list.sort()
	enums.OBJECT_TYPES = object_list
	enums.DROPDOWN_OBJECT_TYPES = Array(enums.OBJECT_TYPES).map(
		func(x: String) -> Dictionary:
			return {
				name = x
			}
	)

	var all_classes = ClassDB.get_class_list()
	all_classes.sort()

	all_classes = HenEnums.VARIANT_TYPES + all_classes
	enums.ALL_CLASSES = all_classes.duplicate()
	enums.DROPDOWN_ALL_CLASSES = Array(enums.ALL_CLASSES).map(
		func(x: String) -> Dictionary:
			return {
				name = x
			}
	)

	# show msg
	(get_node('%ScriptMsgContainer') as PanelContainer).visible = true


func _select_cnode() -> void:
	var selection_rect: ReferenceRect = (Engine.get_singleton(&'Global') as HenGlobal).CAM.get_node('SelectionRect')
	var router: HenRouter = Engine.get_singleton(&'Router')

	for v_cnode: HenVirtualCNode in router.get_current_route_v_cnodes():
		if v_cnode.cnode_instance:
			if selection_rect.get_global_rect().has_point(v_cnode.cnode_instance.global_position):
				v_cnode.select()
			else:
				v_cnode.unselect()


func _input(event: InputEvent) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global.HENGO_ROOT and not global.HENGO_ROOT.visible:
		return
	
	if event is InputEventKey:
		if event.pressed:
			if event.shift_pressed and event.keycode == KEY_F:
				var all_nodes = global.SELECTED_VIRTUAL_CNODE
				global.history.create_action('Delete Node')

				for v_cnode: HenVirtualCNode in all_nodes:
					if not v_cnode.cnode_instance:
						continue

					var v_cnode_return: HenVCNodeReturn = v_cnode.get_history_obj()

					global.history.add_do_method(v_cnode_return.remove)
					global.history.add_undo_reference(v_cnode_return)
					global.history.add_undo_method(v_cnode_return.add)

				global.history.commit_action()
				
			elif event.keycode == KEY_F8:
				(Engine.get_singleton(&'Router') as HenRouter).change_route(global.BASE_ROUTE)
			elif event.keycode == KEY_F10:
				for line: HenConnectionLine in global.connection_line_pool:
					if line.visible:
						line.visible = true
			elif event.keycode == KEY_F9:
				var old: HenVirtualCNode
				var router: HenRouter = Engine.get_singleton(&'Router')
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
						route = router.current_route,
						position = Vector2(0, 500 * i + 1)
					})

			if event.ctrl_pressed:
				if event.keycode == KEY_Z:
					get_tree().root.set_input_as_handled()
					global.history.undo()
				elif event.keycode == KEY_Y:
					global.history.redo()
				elif event.keycode == KEY_C:
					global.history.clear_history()
				elif event.keycode == KEY_SPACE:
					global.HENGO_EDITOR_PLUGIN.bottom_panel_visibility(toggle_bottom_panel)
					toggle_bottom_panel = not toggle_bottom_panel
				elif event.keycode == KEY_P:
					var script_data_cache: HenScriptDataCache = Engine.get_singleton(&'ScriptDataCache')
					script_data_cache.clear()
					print('Script data cache cleared')
				elif event.keycode == KEY_F:
					get_tree().root.set_input_as_handled()
					HenFormatter.format_current_route()
					print('FORMATTED')
