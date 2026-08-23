@tool
class_name HenHengoRoot extends Control

var target_zoom: float = .8

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false

# sidebar collapse
var _sidebar_collapsed: bool = false

# script-tabs panel collapse
var _script_tabs_collapsed: bool = false

const SCRIPT_TABS_COLLAPSED_WIDTH: int = 44
const SCRIPT_TABS_EXPANDED_WIDTH: int = 220

# re-scales chrome fonts live when the font_scale setting changes; theme
# default_font_size covers inherited text, the walk covers explicit overrides,
# and the refresh signals rebuild code-built lists so icon sizes follow too
func reapply_font_scale() -> void:
	var ui_base: Control = get_node_or_null('%UIBase')
	if not ui_base or not ui_base.theme:
		return

	ui_base.theme.default_font_size = ThemeUtils.fs(ThemeUtils.BASE_DEFAULT_FONT_SIZE)
	# forces every child to re-resolve theme items even if the auto-notify misses
	ui_base.propagate_notification(NOTIFICATION_THEME_CHANGED)
	ThemeUtils.apply_font_scale(ui_base)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.request_list_update.emit()
		signal_bus.request_structural_update.emit()


# updates ui parts that depend on whether a script is currently loaded
func refresh_script_state() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var has_script: bool = global != null and global.SAVE_DATA != null

	var tabs: TabContainer = get_node_or_null('%SidebarTabContainer')
	if tabs:
		tabs.set_tab_disabled(1, not has_script)
		tabs.set_tab_disabled(2, not has_script)
		if not has_script and tabs.current_tab != 0:
			tabs.current_tab = 0

	var props_icon: Button = get_node_or_null('%PropsIconBt')
	if props_icon:
		props_icon.disabled = not has_script

	var cl_label: Button = get_node_or_null('%ClassName')
	if cl_label and not has_script:
		cl_label.text = 'No script loaded'
		cl_label.icon = null
		cl_label.disabled = true
		var sb: StyleBoxFlat = cl_label.get_theme_stylebox('normal')
		if sb:
			sb.bg_color = Color(1, 1, 1, 0.04)
	elif cl_label:
		cl_label.disabled = false

	var script_icon: TextureRect = get_node_or_null('%ScriptIcon')
	if script_icon:
		if has_script:
			var type: String = global.SAVE_DATA.identity.type
			script_icon.texture = HenUtils.get_icon_texture(type)
			script_icon.modulate = HenUtils.get_type_parent_color(type, 1., Color.WHITE).lightened(.3)
			script_icon.visible = true
		else:
			script_icon.visible = false

	# flow focus follows the active script during a debug session
	if global and global.HENGO_DEBUGGER_PLUGIN and global.SAVE_DATA:
		global.HENGO_DEBUGGER_PLUGIN.on_active_script_changed(String(global.SAVE_DATA.identity.id))


func show_shortcuts() -> void:
	var panel: HenShortcutsPanel = (load('res://addons/hengo/scenes/shortcuts_panel.tscn') as PackedScene).instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(panel, {
		layout = HenGeneralPopup.Layout.COMPACT,
		min_size = Vector2(660, 620)
	})


# the flow is the only graph view now, so there is nothing left to switch between
func _setup_flow_view() -> void:
	var flow: HenFlowViewer = get_node_or_null('%FlowViewer')
	var refresh_bt: Button = get_node_or_null('%RefreshGraphBt')

	if not flow or not refresh_bt:
		return

	refresh_bt.pressed.connect(flow.rebuild)
	refresh_bt.visible = flow.is_visible_in_tree()

	var shortcuts_bt: Button = get_node_or_null('%ShortcutsBt')

	if shortcuts_bt:
		shortcuts_bt.pressed.connect(show_shortcuts)

	var wrap_bt: Button = get_node_or_null('%FlowWrapBt')

	if wrap_bt:
		wrap_bt.button_pressed = not HenFlowFormatter.wrap_enabled()
		_sync_wrap_button(wrap_bt)
		wrap_bt.toggled.connect(func(_pressed: bool) -> void:
			(Engine.get_singleton(&'Global') as HenGlobal).SETTINGS.flow_wrap = not _pressed
			_sync_wrap_button(wrap_bt)
			flow.rebuild()
		)

	flow.visibility_changed.connect(func():
		refresh_bt.visible = flow.is_visible_in_tree()

		if wrap_bt:
			wrap_bt.visible = flow.is_visible_in_tree()
	)


# pressed is the straight layout, so the icon shows the shape the click turns on
func _sync_wrap_button(_bt: Button) -> void:
	var straight: bool = _bt.button_pressed

	_bt.icon = load(
		'res://addons/hengo/assets/new_icons/unfold-vertical.svg' if straight
		else 'res://addons/hengo/assets/new_icons/columns-3.svg'
	)
	_bt.tooltip_text = 'Straight run, one column' if straight else 'Compact run, wrapped into columns'


func _on_reset_zoom() -> void:
	HenCam.reset_all_zoom(get_tree())


func _on_graph_changed() -> void:
	schedule_check_errors()


var _time: float = 0.0
var _debounce_time: float = 0.0
var _dirty: bool = false
const DEBOUNCE_DELAY: float = 0.13




# tints toolbar/sidebar buttons with semantic colors
func _apply_semantic_colors() -> void:
	var c: Dictionary = HenUtils.UI_COLORS

	HenUtils.tint_button(get_node('%Config') as Button, c.settings, false)
	HenUtils.tint_button(get_node('%CloseBt') as Button, c.destructive, false)
	HenUtils.tint_button(get_node('%RefreshGraphBt') as Button, c.state, false)
	HenUtils.tint_button(get_node('%FlowWrapBt') as Button, c.state, false)


func _on_config_pressed() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	HenInspector.edit_resource(global.SETTINGS)


func _on_open_terminal() -> void:
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(HenTerminal.new())


func _on_close() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	global.HENGO_EDITOR_PLUGIN.hide_plugin()


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

	var ok_color: Color = Color(0.13, 0.77, 0.37, 1)
	var fail_color: Color = Color(0.94, 0.27, 0.27, 1)

	var err_label: Label = get_node_or_null('%ErrorStatusLabel')
	var err_icon: TextureRect = get_node_or_null('%ErrorIcon')

	if all_errors.is_empty():
		if err_label:
			err_label.text = 'No errors'
			err_label.modulate = ok_color
		if err_icon:
			err_icon.texture = preload('res://addons/hengo/assets/new_icons/circle-check.svg')
			err_icon.modulate = ok_color
	else:
		if err_label:
			err_label.text = '{0} error(s)'.format([all_errors.size()])
			err_label.modulate = fail_color
		if err_icon:
			err_icon.texture = preload('res://addons/hengo/assets/new_icons/shield-alert.svg')
			err_icon.modulate = fail_color


func _show_error_popup(all_errors: Array) -> void:
	var error_popup = preload('res://addons/hengo/scenes/utils/error_list_popup.tscn').instantiate()
	error_popup.errors = all_errors
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(error_popup)


func _on_actions_bt_pressed() -> void:
	# force check and show
	check_errors(true)


var _saved_split_offset: int = 0


func _on_collapse_sidebar() -> void:
	_sidebar_collapsed = not _sidebar_collapsed
	_apply_sidebar_collapse()


func expand_sidebar() -> void:
	if not _sidebar_collapsed:
		return

	_sidebar_collapsed = false
	_apply_sidebar_collapse()


func _apply_sidebar_collapse() -> void:
	var tab_container: TabContainer = get_node_or_null('%SidebarTabContainer')
	var icon_strip: BoxContainer = get_node_or_null('%SidebarIconStrip')
	var sidebar_margin: MarginContainer = get_node_or_null('%SideBarMargin')
	var collapse_btn: Button = get_node_or_null('%CollapseToggleBt')
	var separator: HSeparator = get_node_or_null('%SidebarTabsSep')

	if not tab_container or not icon_strip or not sidebar_margin or not collapse_btn:
		return

	var header: BoxContainer = collapse_btn.get_parent() as BoxContainer
	# HSplitContainer keeps the split position cached in split_offset; we must
	# reset it on collapse so the sidebar actually shrinks to the new minimum
	var content_area: HSplitContainer = sidebar_margin.get_parent() as HSplitContainer

	tab_container.visible = not _sidebar_collapsed
	header.vertical = _sidebar_collapsed
	icon_strip.vertical = _sidebar_collapsed
	collapse_btn.tooltip_text = 'Expand sidebar' if _sidebar_collapsed else 'Collapse sidebar'
	header.move_child(collapse_btn, 0 if _sidebar_collapsed else header.get_child_count() - 1)

	if separator:
		separator.visible = not _sidebar_collapsed

	if _sidebar_collapsed:
		if content_area:
			_saved_split_offset = content_area.split_offset
		sidebar_margin.custom_minimum_size = Vector2(52, 0)
		if content_area:
			content_area.split_offset = 0
	else:
		sidebar_margin.custom_minimum_size = Vector2(280, 0)
		if content_area:
			content_area.split_offset = _saved_split_offset


func toggle_fullscreen() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if global and global.HENGO_EDITOR_PLUGIN:
		global.HENGO_EDITOR_PLUGIN.toggle_fullscreen()


func _on_toggle_script_tabs() -> void:
	_script_tabs_collapsed = not _script_tabs_collapsed
	_apply_script_tabs_collapse()


func _apply_script_tabs_collapse() -> void:
	var panel: PanelContainer = get_node_or_null('%ScriptTabsPanel')
	var title: Label = get_node_or_null('%ScriptTabsTitle')
	var new_bt: Button = get_node_or_null('%NewScriptTabBt')
	var toggle_bt: Button = get_node_or_null('%ToggleScriptTabsBt')
	var tab_list: HenTabs = get_node_or_null('%ScriptTabList') as HenTabs

	if panel:
		panel.custom_minimum_size.x = SCRIPT_TABS_COLLAPSED_WIDTH if _script_tabs_collapsed else SCRIPT_TABS_EXPANDED_WIDTH
	if title:
		title.visible = not _script_tabs_collapsed
	if new_bt:
		new_bt.visible = not _script_tabs_collapsed
	if toggle_bt:
		toggle_bt.tooltip_text = 'Expand script tabs' if _script_tabs_collapsed else 'Collapse script tabs'
	if tab_list:
		tab_list.set_collapsed(_script_tabs_collapsed)


func _on_new_script_tab() -> void:
	var anchor: Button = get_node_or_null('%NewScriptTabBt')
	var c: HenCreateScript = (load('res://addons/hengo/scenes/utils/create_script.tscn') as PackedScene).instantiate()
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(c, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = anchor,
		side = SIDE_RIGHT,
		min_size = Vector2(360, 0)
	})

func _ready() -> void:
	if HenUtils.disable_scene(self):
		return

	set_process(true)

	var enums: HenEnums = Engine.get_singleton(&'Enums')

	var margin: int = 8
	var side_bar_margin: MarginContainer = get_node('%SideBarMargin')

	side_bar_margin.add_theme_constant_override('margin_left', margin)
	side_bar_margin.add_theme_constant_override('margin_right', margin)
	side_bar_margin.add_theme_constant_override('margin_top', margin)
	side_bar_margin.add_theme_constant_override('margin_bottom', margin)

	# initializing
	enums.DROPDOWN_STATES = []

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
	(get_node('%TerminalBt') as Button).pressed.connect(_on_open_terminal)
	(get_node('%Config') as Button).pressed.connect(_on_config_pressed)
	(get_node('%ActionsBt') as Button).pressed.connect(_on_actions_bt_pressed)
	(get_node('%CollapseToggleBt') as Button).pressed.connect(_on_collapse_sidebar)
	(get_node('%ResetZoomBt') as Button).pressed.connect(_on_reset_zoom)
	_setup_flow_view()

	var toggle_tabs_bt: Button = get_node_or_null('%ToggleScriptTabsBt')
	if toggle_tabs_bt:
		toggle_tabs_bt.pressed.connect(_on_toggle_script_tabs)
	var new_tab_bt: Button = get_node_or_null('%NewScriptTabBt')
	if new_tab_bt:
		new_tab_bt.pressed.connect(_on_new_script_tab)
	_apply_script_tabs_collapse()

	_apply_semantic_colors()

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_list_update.connect(_on_graph_changed)

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).closed.connect(schedule_check_errors)

	refresh_script_state()

func _process(delta: float) -> void:
	_time += delta

	if _dirty:
		_debounce_time += delta
		if _debounce_time >= DEBOUNCE_DELAY:
			check_errors(false)
			_dirty = false
			_time = 0.0


func schedule_check_errors() -> void:
	_dirty = true
	_debounce_time = 0.0

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
				if e.keycode == KEY_SPACE:
					get_tree().root.set_input_as_handled()
					global.HENGO_EDITOR_PLUGIN.hide_plugin()
				elif e.keycode == KEY_E:
					if _sidebar_collapsed:
						expand_sidebar()
						var tabs: TabContainer = get_node_or_null('%SidebarTabContainer')
						if tabs:
							tabs.current_tab = HenDashboard.TAB_INDEX
					else:
						global.DASHBOARD.toggle_dashboard()
				elif e.keycode == KEY_H:
					var code_generation: HenCodeGeneration = Engine.get_singleton('CodeGeneration')
					print(
						code_generation.get_code(global.SAVE_DATA)
					)
			if e.ctrl_pressed:
				# ctrl+z/ctrl+y are not handled here: as a bottom panel, _input grabs
				# them editor-wide and blocks godot's own undo. the flow view binds
				# them through HenShortcuts instead, above the unhandled layer
				if e.keycode == KEY_F:
					get_tree().root.set_input_as_handled()
					print('FORMATTED')

func _validate_script_errors(_save_data: HenSaveData) -> Array:
	var errors: Array = []

	return errors