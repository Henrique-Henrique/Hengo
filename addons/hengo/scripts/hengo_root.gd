@tool
class_name HenHengoRoot extends Control

var target_zoom: float = .8

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false

func _ready() -> void:
	if HenUtils.disable_scene(self):
		return

	set_process(true)

	var router: HenRouter = Engine.get_singleton(&'Router')
	var enums: HenEnums = Engine.get_singleton(&'Enums')

	var margin: int = HenUtils.get_scaled_size(8)
	var action_bar_margin: MarginContainer = get_node('%ActionBarMargin')
	var side_bar_margin: MarginContainer = get_node('%SideBarMargin')

	action_bar_margin.add_theme_constant_override('margin_left', margin)
	action_bar_margin.add_theme_constant_override('margin_right', margin)
	action_bar_margin.add_theme_constant_override('margin_top', margin)
	action_bar_margin.add_theme_constant_override('margin_bottom', margin)

	side_bar_margin.add_theme_constant_override('margin_left', margin)
	side_bar_margin.add_theme_constant_override('margin_right', margin)
	side_bar_margin.add_theme_constant_override('margin_top', margin)
	side_bar_margin.add_theme_constant_override('margin_bottom', margin)

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
	(get_node('%CloseBt') as Button).pressed.connect(_on_close)
	(get_node('%OpenDashboard') as Button).pressed.connect(_on_open_dashboard)
	(get_node('%TerminalBt') as Button).pressed.connect(_on_open_terminal)


func _on_open_terminal() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.GENERAL_POPUP.show_content(HenTerminal.new())


func _on_open_dashboard() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.DASHBOARD.show_dashboard()


func _on_close() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.HENGO_EDITOR_PLUGIN.hide_plugin()


func _input(event: InputEvent) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if not global.HENGO_ROOT:
		return

	if not global.HENGO_ROOT.visible:
		if event is InputEventKey:
			var e: InputEventKey = event
			if e.pressed and e.shift_pressed:
				if e.keycode == KEY_SPACE:
					get_tree().root.set_input_as_handled()
					global.HENGO_EDITOR_PLUGIN.show_plugin()
		return
	
	if event is InputEventKey:
		var e: InputEventKey = event

		if e.pressed:
			if e.shift_pressed:
				if e.keycode == KEY_F:
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
				elif e.keycode == KEY_SPACE:
					get_tree().root.set_input_as_handled()
					global.HENGO_EDITOR_PLUGIN.hide_plugin()
				elif e.keycode == KEY_E:
					global.DASHBOARD.toggle_dashboard()
				elif e.keycode == KEY_H:
					var code_generation: HenCodeGeneration = Engine.get_singleton('CodeGeneration')
					print(
						code_generation.get_code(global.SAVE_DATA)
					)
				
			elif e.keycode == KEY_F8:
				(Engine.get_singleton(&'Router') as HenRouter).change_route(global.SAVE_DATA.base_route)
			elif e.keycode == KEY_F10:
				for line: HenConnectionLine in global.connection_line_pool:
					if line.visible:
						line.visible = true
			if e.ctrl_pressed:
				if e.keycode == KEY_Z:
					get_tree().root.set_input_as_handled()

					if global.CURRENT_INSPECTOR:
						global.CURRENT_INSPECTOR.undo_redo(true)
					else:
						global.history.undo()
				elif e.keycode == KEY_Y:
					get_tree().root.set_input_as_handled()

					if global.CURRENT_INSPECTOR:
						global.CURRENT_INSPECTOR.undo_redo(false)
					else:
						global.history.redo()
				elif e.keycode == KEY_C:
					global.history.clear_history()
				elif e.keycode == KEY_F:
					get_tree().root.set_input_as_handled()
					HenFormatter.format_current_route()
					print('FORMATTED')
