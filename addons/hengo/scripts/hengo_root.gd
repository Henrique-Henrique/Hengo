@tool
class_name HenHengoRoot extends Control

var target_zoom: float = .8

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false

# sidebar collapse
var _sidebar_collapsed: bool = false

# canvas layout
var _canvas_split_mode: bool = false

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
	# HenGlobal.history = UndoRedo.new()
	enums.DROPDOWN_STATES = []
	(Engine.get_singleton(&'Global') as HenGlobal).SELECTED_VIRTUAL_CNODE.clear()

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
	(get_node('%Config') as Button).pressed.connect(_on_config_pressed)
	(get_node('%ActionsBt') as Button).pressed.connect(_on_actions_bt_pressed)
	(get_node('%CollapseToggleBt') as Button).pressed.connect(_on_collapse_sidebar)
	(get_node('%ToggleLayoutBt') as Button).pressed.connect(_on_toggle_canvas_layout)

	# Dashboard backdrop: show/hide with dashboard
	var backdrop: Button = get_node('%DashboardBackdrop')
	var dashboard_node = get_node('%DashBoard')
	backdrop.pressed.connect(func():
		var g: HenGlobal = Engine.get_singleton(&'Global')
		if g and g.DASHBOARD:
			g.DASHBOARD.hide_dashboard()
	)
	dashboard_node.visibility_changed.connect(func():
		backdrop.visible = dashboard_node.visible
	)

	# Sidebar icon strip buttons
	(get_node('%PropsIconBt') as Button).pressed.connect(func():
		if _sidebar_collapsed:
			_on_collapse_sidebar()
		(get_node('%SidebarTabContainer') as TabContainer).current_tab = 0
	)
	(get_node('%CodeIconBt') as Button).pressed.connect(func():
		if _sidebar_collapsed:
			_on_collapse_sidebar()
		(get_node('%SidebarTabContainer') as TabContainer).current_tab = 1
	)
	
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.add_virtual_cnode_to_route.connect(_on_graph_changed_no_args)
	signal_bus.remove_virtual_cnode_from_route.connect(_on_graph_changed_no_args)
	signal_bus.request_list_update.connect(_on_graph_changed)
	signal_bus.connection_added.connect(_on_graph_changed_no_args)
	signal_bus.connection_removed.connect(_on_graph_changed_no_args)
	signal_bus.flow_connection_added.connect(_on_graph_changed_no_args)
	signal_bus.flow_connection_removed.connect(_on_graph_changed_no_args)
	
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).closed.connect(schedule_check_errors)


func _on_graph_changed() -> void:
	schedule_check_errors()


func _on_graph_changed_no_args(_a = null, _b = null) -> void:
	schedule_check_errors()


var _time: float = 0.0
var _debounce_time: float = 0.0
var _dirty: bool = false
const DEBOUNCE_DELAY: float = 0.13


func _process(delta: float) -> void:
	_time += delta
	
	if _dirty:
		_debounce_time += delta
		if _debounce_time >= DEBOUNCE_DELAY:
			check_errors(false)
			HenFormatter.format_current_route()
			_dirty = false
			_time = 0.0

 
func schedule_check_errors() -> void:
	_dirty = true
	_debounce_time = 0.0


func _on_config_pressed() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	HenInspector.edit_resource(global.SETTINGS)


func _on_open_terminal() -> void:
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(HenTerminal.new())


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
					get_tree().root.set_input_as_handled()
					var toast: HenToast = Engine.get_singleton(&'ToastContainer')
					var count: int = HenClipboard.copy(global.SELECTED_VIRTUAL_CNODE)
					if count > 0:
						toast.notify.call_deferred('copied ' + str(count) + ' node(s)', HenToast.MessageType.SUCCESS)
					else:
						toast.notify.call_deferred('no nodes selected to copy', HenToast.MessageType.INFO)
				elif e.keycode == KEY_V:
					get_tree().root.set_input_as_handled()
					var toast: HenToast = Engine.get_singleton(&'ToastContainer')
					var mouse_pos: Vector2 = get_global_mouse_position()
					var cam: HenCam = global.CAM
					
					if cam:
						mouse_pos = cam.get_relative_vec2(mouse_pos)
						
					var count: int = HenClipboard.paste(mouse_pos)
					if count > 0:
						toast.notify.call_deferred('pasted ' + str(count) + ' node(s)', HenToast.MessageType.SUCCESS)
					else:
						toast.notify.call_deferred('nothing to paste', HenToast.MessageType.INFO)
				elif e.keycode == KEY_F:
					get_tree().root.set_input_as_handled()
					HenFormatter.format_current_route()
					print('FORMATTED')


# checks for errors in current script and dependents
func check_errors(_compile: bool = false) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var loader: HenLoader = Engine.get_singleton(&'Loader')
	var save_data: HenSaveData = global.SAVE_DATA
	
	if not save_data:
		return false
		
	var all_errors: Array = []
	
	all_errors.append_array(_validate_script_errors(save_data))
	
	var deps: Array[StringName] = map_deps.check_dependencies(save_data.identity.id)
	for dep_id in deps:
		var dep_save_data: HenSaveData = loader.load_res(dep_id)
		if dep_save_data:
			var dep_errors = _validate_script_errors(dep_save_data)
			for err in dep_errors:
				err['description'] = '[{0}] {1}'.format([dep_save_data.identity.name, err.description])
				err['script_id'] = dep_id
			all_errors.append_array(dep_errors)
	
	call_deferred('_update_ui_state', all_errors)
	
	if _compile and not all_errors.is_empty():
		call_deferred('_show_error_popup', all_errors)
		return false

	return true


func _update_ui_state(all_errors: Array) -> void:
	var actions_bt: Button = get_node_or_null('%ActionsBt')
	if not actions_bt: return

	if all_errors.is_empty():
		actions_bt.text = 'Actions'
		actions_bt.icon = preload('res://addons/hengo/assets/new_icons/circle-check.svg')
		actions_bt.modulate = Color.WHITE
	else:
		actions_bt.text = 'Actions ({0})'.format([all_errors.size()])
		actions_bt.icon = preload('res://addons/hengo/assets/new_icons/shield-alert.svg')
		actions_bt.modulate = Color('ef4444')

	var global: HenGlobal = Engine.get_singleton(&'Global')

	var name_label: Label = get_node_or_null('%ScriptNameLabel')
	if name_label:
		if global and global.SAVE_DATA:
			name_label.text = global.SAVE_DATA.identity.name
		else:
			name_label.text = 'No script loaded'

	var err_label: Label = get_node_or_null('%ErrorStatusLabel')
	if err_label:
		if all_errors.is_empty():
			err_label.text = 'No errors'
			err_label.modulate = Color.WHITE
		else:
			err_label.text = '{0} error(s)'.format([all_errors.size()])
			err_label.modulate = Color('ef4444')


func _show_error_popup(all_errors: Array) -> void:
	var error_popup = preload('res://addons/hengo/scenes/utils/error_list_popup.tscn').instantiate()
	error_popup.errors = all_errors
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(error_popup, 'Compilation Errors')


func _validate_script_errors(_save_data: HenSaveData) -> Array:
	var errors: Array = []
	
	var routes: Array = [_save_data.get_base_route()]
	for state in _save_data.states:
		routes.append(state.get_route(_save_data))
	for func_data in _save_data.functions:
		routes.append(func_data.get_route(_save_data))
	for macro in _save_data.macros:
		routes.append(macro.get_route(_save_data))
	for sc in _save_data.signals_callback:
		routes.append(sc.get_route(_save_data))
		
	for route in routes:
		if not route: continue
		for vc: HenVirtualCNode in route.virtual_cnode_list:
			var node_errors = vc.validate_errors(_save_data)
			for err in node_errors:
				err['route_id'] = route.id
			errors.append_array(node_errors)
			
	return errors


func _on_actions_bt_pressed() -> void:
	# force check and show
	check_errors(true)


func _on_collapse_sidebar() -> void:
	_sidebar_collapsed = not _sidebar_collapsed

	var tab_container: TabContainer = get_node_or_null('%SidebarTabContainer')
	var icon_strip: VBoxContainer = get_node_or_null('%SidebarIconStrip')
	var sidebar_margin: MarginContainer = get_node_or_null('%SideBarMargin')
	var collapse_btn: Button = get_node_or_null('%CollapseToggleBt')

	if not tab_container or not icon_strip or not sidebar_margin:
		return

	if _sidebar_collapsed:
		tab_container.visible = false
		icon_strip.visible = true
		sidebar_margin.custom_minimum_size = Vector2(44, 0)
		if collapse_btn:
			collapse_btn.tooltip_text = 'Expand sidebar'
	else:
		tab_container.visible = true
		icon_strip.visible = false
		sidebar_margin.custom_minimum_size = Vector2(0, 0)
		if collapse_btn:
			collapse_btn.tooltip_text = 'Collapse sidebar'


func _on_toggle_canvas_layout() -> void:
	_canvas_split_mode = not _canvas_split_mode

	var canvas_tabs: TabContainer = get_node_or_null('%CanvasTabs')
	var canvas_split: HSplitContainer = get_node_or_null('%CanvasSplit')
	var toggle_btn: Button = get_node_or_null('%ToggleLayoutBt')

	if not canvas_tabs or not canvas_split:
		return

	if _canvas_split_mode:
		var children := canvas_tabs.get_children().duplicate()
		for child in children:
			child.reparent(canvas_split, false)
			child.visible = true
		canvas_tabs.visible = false
		canvas_split.visible = true
		if toggle_btn:
			toggle_btn.text = 'Tabs'
	else:
		var children := canvas_split.get_children().duplicate()
		for child in children:
			child.reparent(canvas_tabs, false)
		canvas_split.visible = false
		canvas_tabs.visible = true
		if toggle_btn:
			toggle_btn.text = 'Split'
