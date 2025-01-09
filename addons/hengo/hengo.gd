@tool
class_name HenHengo extends EditorPlugin

const PLUGIN_NAME = 'Hengo'
const MENU_NATIVE_API_NAME = "Hengo Generate Native Api"

var main_scene
var gd_previewer: CodeEdit
var tabs_hide_helper
var tabs_container

# docks
#
var dock_container
# left docks
var dock_left_1
var dock_left_2
# right docks
var dock_right_1
var dock_right_2
# scene tabs
var scene_tabs
var docks_references: Array = []

# file system tree
var file_system_tree: Tree
var file_tree_signals: Array = []

var debug_plugin: EditorDebuggerPlugin

func _enter_tree():
	debug_plugin = load('res://addons/hengo/scripts/debug/debug_plugin.gd').new()
	add_debugger_plugin(debug_plugin)

	# getting native api like String, float... methods.
	var native_api_file: FileAccess = FileAccess.open(HenEnums.NATIVE_API_PATH, FileAccess.READ)

	if native_api_file:
		var api_json: Dictionary = JSON.parse_string(native_api_file.get_as_text())

		HenEnums.NATIVE_API_LIST = api_json.native_api
		HenEnums.CONST_API_LIST = api_json.const_api
		HenEnums.SINGLETON_API_LIST = api_json.singleton_api
		HenEnums.NATIVE_PROPS_LIST = api_json.native_props
		HenEnums.MATH_UTILITY_NAME_LIST = api_json.math_utility_names

		native_api_file.close()
	else:
		print('NATIVE LIST JSON -> ', FileAccess.get_open_error())

	# creating hengo folder
	if not DirAccess.dir_exists_absolute('res://hengo'):
		DirAccess.make_dir_absolute('res://hengo')

		get_editor_interface().get_resource_filesystem().scan()


	# ---------------------------------------------------------------------------- #

	# setting scene reference here to prevent crash on development when reload scripts on editor :)
	HenAssets.ConnectionLineScene = load('res://addons/hengo/scenes/connection_line.tscn')
	HenAssets.StateConnectionLineScene = load('res://addons/hengo/scenes/state_connection_line.tscn')
	HenAssets.FlowConnectionLineScene = load('res://addons/hengo/scenes/flow_connection_line.tscn')
	HenAssets.HengoRootScene = load('res://addons/hengo/scenes/hengo_root.tscn')
	HenAssets.CNodeInputScene = load('res://addons/hengo/scenes/cnode_input.tscn')
	HenAssets.CNodeOutputScene = load('res://addons/hengo/scenes/cnode_output.tscn')
	HenAssets.CNodeScene = load('res://addons/hengo/scenes/cnode.tscn')
	HenAssets.CNodeFlowScene = load('res://addons/hengo/scenes/cnode_flow.tscn')
	HenAssets.CNodeIfFlowScene = load('res://addons/hengo/scenes/cnode_if_flow.tscn')
	HenAssets.EventScene = load('res://addons/hengo/scenes/event.tscn')
	HenAssets.EventStructScene = load('res://addons/hengo/scenes/event_structure.tscn')
	HenAssets.SideBarSectionItemScene = load('res://addons/hengo/scenes/side_bar_section_item.tscn')
	HenAssets.PropContainerScene = load('res://addons/hengo/scenes/prop_container.tscn')
	HenAssets.CNodeInputLabel = load('res://addons/hengo/scenes/cnode_input_label.tscn')
	HenAssets.CNodeCenterImage = load('res://addons/hengo/scenes/cnode_center_image.tscn')

	HenGlobal.editor_interface = get_editor_interface()
	print('setted')

	main_scene = HenAssets.HengoRootScene.instantiate()

	HenGlobal.GENERAL_POPUP = main_scene.get_node('%GeneralPopUp')

	EditorInterface.get_editor_main_screen().add_child(main_scene)
	_make_visible(false)

	var root = get_node('/root')

	# setting tabs references
	dock_container = root.find_child('DockHSplitLeftL', true, false)
	dock_left_1 = dock_container.find_child('DockVSplitLeftL', true, false)
	dock_left_2 = dock_container.find_child('DockVSplitLeftR', true, false)
	dock_right_1 = dock_container.find_child('DockVSplitRightL', true, false)
	dock_right_2 = dock_container.find_child('DockVSplitRightR', true, false)
	scene_tabs = get_editor_interface().get_editor_main_screen().get_node('../..').get_child(0)
	
	add_tool_menu_item(MENU_NATIVE_API_NAME, _generate_native_api)

	main_screen_changed.connect(_on_change_main_screen)
	set_docks()

	add_autoload_singleton('HengoDebugger', 'res://addons/hengo/scripts/debug/hengo_debugger.gd')
	HenGlobal.HENGO_EDITOR_PLUGIN = self

	# adding gdscript editor
	gd_previewer = (load('res://addons/hengo/scenes/gd_editor.tscn') as PackedScene).instantiate()
	gd_previewer.code_completion_enabled = false
	gd_previewer.editable = false

	var highlighter: CodeHighlighter = gd_previewer.syntax_highlighter
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

	add_control_to_bottom_panel(gd_previewer, 'Hengo Code')
	HenGlobal.GD_PREVIEWER = gd_previewer

func _generate_native_api() -> void:
	var file: FileAccess = FileAccess.open('res://extension_api.json', FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())

	var native_api: Dictionary = {}
	var const_api: Dictionary = {}
	var singleton_api: Array = []
	var singleton_names: Array = []
	var native_props: Dictionary = {}
	var math_utility_names: Array = []

	for dict: Dictionary in (data['utility_functions'] as Array):
		if dict.category == 'math':
			math_utility_names.append(dict.name)


	for dict: Dictionary in (data['builtin_classes'] as Array):
		if HenEnums.VARIANT_TYPES.has(dict.name):
			if dict.has('members'):
				native_props[dict.name] = dict.members

			if dict.has('methods'):
				var arr: Array = []
				
				for method: Dictionary in dict['methods']:
					# static
					if method.is_static:
						var dt: Dictionary = {
							name = '',
							sub_type = 'singleton',
						}

						if method.has('arguments'):
							dt.inputs = _parse_arguments(method)
						
						if method.has('return_type'):
							dt['outputs'] = [ {
								name = '',
								type = _parse_enum_return(method.return_type)
							}]

						singleton_api.append({
							name = dict.name + '.' + method.name,
							data = dt
						})
					else:
						var dt: Dictionary = {
							name = method.name,
							sub_type = 'func',
							inputs = [ {
								name = dict.name,
								type = dict.name,
								ref = true
							}]
						}
						
						if method.has('arguments'):
							dt.inputs += _parse_arguments(method)
						
						if method.has('return_type'):
							dt['outputs'] = [ {
								name = '',
								type = _parse_enum_return(method.return_type)
							}]

						arr.append({
							name = method.name,
							data = dt
						})


				if not arr.is_empty():
					native_api[dict.name] = arr

			if dict.has('constants'):
				var arr: Array = []

				for constant: Dictionary in dict['constants']:
					var dt: Dictionary = {
						name = constant.name,
						type = constant.type
					}

					arr.append(dt)
				
				const_api[dict.name] = _generate_consts(dict)


	# parsing singleton names
	for dict: Dictionary in (data['singletons'] as Array):
		singleton_names.append(dict.name)

	# parsing classes const, enums...
	for dict: Dictionary in (data['classes'] as Array):
		if dict.has('methods'):
			for method: Dictionary in dict['methods']:
				# static
				if method.is_static or singleton_names.has(dict.name):
					var dt: Dictionary = {
						name = dict.name + '.' + method.name,
						fantasy_name = dict.name + ' -> ' + method.name,
						sub_type = 'singleton',
					}

					if method.has('arguments'):
						dt.inputs = _parse_arguments(method)
					
					if method.has('return_value'):
						dt['outputs'] = [ {
							name = '',
							type = _parse_enum_return(method.return_value.type)
						}]

					# if dict.name.contains('is_action_pressed'):
					print({
						name = dict.name + ' -> ' + method.name,
						data = dt
					})

					singleton_api.append({
						name = dict.name + ' -> ' + method.name,
						data = dt
					})

		if dict.has('constants'):
			const_api[dict.name] = _generate_consts(dict)
		
		if dict.has('enums'):
			if const_api.has(dict.name):
				const_api[dict.name] += _generate_enums(dict)
			else:
				const_api[dict.name] = _generate_enums(dict)

	var file_json: FileAccess = FileAccess.open(HenEnums.NATIVE_API_PATH, FileAccess.WRITE)

	file_json.store_string(
		JSON.stringify({
			native_api = native_api,
			const_api = const_api,
			singleton_api = singleton_api,
			native_props = native_props,
			math_utility_names = math_utility_names
		})
	)

	file_json.close()

	print('HENGO NATIVE API GENERATED!!')

	# for d in native_api:
	# 	print(native_api[d])

func _parse_enum_return(_type: String) -> String:
	return _type.split('.')[-1] if _type.begins_with('enum::') else _type

func _parse_arguments(_dict: Dictionary) -> Array:
	var arr: Array = []

	for arg in _dict.arguments:
		var arg_dt: Dictionary = {
			name = arg.name
		}

		# parsing enums
		if arg.type.begins_with('enum::'):
			var enum_name: String = arg.type.split('.')[-1]

			arg_dt.type = enum_name
			arg_dt.sub_type = '@dropdown'
			arg_dt.category = 'enum_list'
			arg_dt.data = [_dict.name, enum_name]
		else:
			arg_dt.type = arg.type
		
		arr.append(arg_dt)

	return arr

func _generate_consts(_dict: Dictionary) -> Array:
	var arr: Array = []

	for constant: Dictionary in _dict['constants']:
		var dt: Dictionary = {
			name = constant.name,
			type = constant.type if constant.has('type') else 'Variant'
		}

		arr.append(dt)

	return arr

func _generate_enums(_dict: Dictionary) -> Array:
	var arr: Array = []

	for enum_value in _dict.enums:
		arr += enum_value.values.map(func(x: Dictionary) -> Dictionary: return {
			name = x.name,
			type = enum_value.name
		})
	
	return arr


func _get_window_layout(configuration: ConfigFile) -> void:
	if main_scene.visible:
		hide_docks()
	else:
		set_docks()

func _on_change_main_screen(_name: String) -> void:
	if _name == PLUGIN_NAME:
		hide_docks()
		change_colors()
	else:
		show_docks()

func _exit_tree():
	remove_debugger_plugin(debug_plugin)
	remove_tool_menu_item(MENU_NATIVE_API_NAME)
	remove_control_from_bottom_panel(gd_previewer)

	# reseting file system tree signals
	for signal_config: Dictionary in file_tree_signals:
		file_system_tree.connect('item_activated', signal_config.callable)

	if main_scene:
		main_scene.queue_free()
	
	remove_autoload_singleton('HengoDebugger')
	HenGlobal.HENGO_EDITOR_PLUGIN = null

func _make_visible(_visible: bool):
	if main_scene:
		if _visible: hide_docks()
		else: show_docks()

		main_scene.visible = _visible

func _get_plugin_name():
	return PLUGIN_NAME

func _has_main_screen() -> bool:
	return true

# public
#
func set_docks() -> void:
	docks_references = []

	# hiding left docks
	for dock in dock_left_1.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})

	for dock in dock_left_2.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})

	# hiding right docks
	for dock in dock_right_1.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})
	
	for dock in dock_right_2.get_children():
		docks_references.append({
			dock = dock,
			old_visibility = dock.visible
		})

func hide_docks() -> void:
	scene_tabs.visible = false

	# hiding all docks
	for obj in docks_references:
		obj.dock.visible = false

func show_docks() -> void:
	if scene_tabs:
		scene_tabs.visible = true

	# backuping docks visibility
	for obj in docks_references:
		obj.dock.visible = obj.old_visibility
	

func change_colors() -> void:
	# colors
	var base_color: Color = EditorInterface.get_editor_settings().get_setting('interface/theme/base_color')
	var color_factor: float = .4
	var cnode_style_box: StyleBoxFlat = load('res://addons/hengo/resources/style_box/cnode.tres')
	var event_style_box: StyleBoxFlat = load('res://addons/hengo/resources/style_box/event.tres')
	var route_ref: StyleBoxFlat = load('res://addons/hengo/resources/style_box/route_reference.tres')

	HenGlobal.HENGO_ROOT.get_node('%MenuBar').get_theme_stylebox('panel').bg_color = base_color
	cnode_style_box.bg_color = base_color.lightened(.015)
	HenGlobal.STATE_CAM.get_parent().get_theme_stylebox('panel').bg_color = base_color.darkened(color_factor)
	cnode_style_box.border_color = base_color.lightened(.2)
	event_style_box.bg_color = base_color.lightened(.05)
	event_style_box.border_color = base_color.lightened(.2)
	route_ref.bg_color = base_color.lightened(.1)