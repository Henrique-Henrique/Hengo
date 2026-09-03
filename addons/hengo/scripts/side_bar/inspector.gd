@tool
class_name HenInspector extends VBoxContainer

signal inline_changed

const PROP_CONTAINER: PackedScene = preload('res://addons/hengo/scenes/prop_container.tscn')
const TITLE_FONT: Font = preload('res://addons/hengo/assets/fonts/bold.ttf')
const DROPDOWN_HINT_TYPES: Array[String] = [
	'action',
	'all_godot_classes',
	'var_type',
	'hengo_states',
	'all_classes',
	'all_classes_self',
	'enum_list',
	'all_props',
	'signal',
	'callable',
	'key_code',
	'mouse_button',
	'state_event_list'
]
# a slot the action writes to and that is still unset
const WARNING_COLOR: Color = Color('#f0a24a')
# first row of the node menu: falls back to the plain text field
const TYPED_PATH_ENTRY: String = 'Type a path...'
# property name -> what the popup calls it, when capitalizing the field is not
# enough to tell it apart from the value params next to it
const PROP_LABELS: Dictionary = {
	flow_inputs = 'Entries',
	flow_outputs = 'Branches'
}
const PROPS: Dictionary = {
	TYPE_BOOL: preload('res://addons/hengo/scenes/props/boolean.tscn'),
	TYPE_INT: preload('res://addons/hengo/scenes/props/int.tscn'),
	TYPE_FLOAT: preload('res://addons/hengo/scenes/props/float.tscn'),
	TYPE_STRING: preload('res://addons/hengo/scenes/props/string.tscn'),
	TYPE_STRING_NAME: preload('res://addons/hengo/scenes/props/string.tscn'),
	TYPE_VECTOR2: preload('res://addons/hengo/scenes/props/vec2.tscn'),
	TYPE_VECTOR2I: preload('res://addons/hengo/scenes/props/vec2i.tscn'),
	TYPE_VECTOR3: preload('res://addons/hengo/scenes/props/vec3.tscn'),
	TYPE_VECTOR3I: preload('res://addons/hengo/scenes/props/vec3i.tscn'),
	TYPE_VECTOR4: preload('res://addons/hengo/scenes/props/vec4.tscn'),
	TYPE_COLOR: preload('res://addons/hengo/scenes/props/color.tscn'),
	TYPE_ARRAY: preload('res://addons/hengo/scenes/props/array.tscn')
}

var resource: Resource
var header_panel: PanelContainer
var header_margin: MarginContainer
var header_box: HBoxContainer
var title_label: Label
var actions_box: HBoxContainer
var body_scroll: ScrollContainer
var vbox: VBoxContainer
var inspector_title: String = ''
var inspector_actions: Array[Dictionary] = []
# a nested action runs at the loop's phase, so its phase selector is hidden
var hide_phase: bool = false
# running index across all rendered value slots (incl. nested word rows)
var _slot_idx: int = 0
var nested_producer: bool = false
# the single slot or branch this inspector was opened on, so a redraw comes back
# as the row it was showing instead of the whole action behind it
var _single_slot: Dictionary = {}
var _single_branch: Dictionary = {}
# an edit landed that nothing else announced, so the sidebar and the graph still
# show what the resource was called before it
var _dirty: bool = false
# (slot: Dictionary, chip: Control), set by the cascade
var on_action_chip: Callable = Callable()
var active_action_key: String = ''


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override('separation', 8)

	header_panel = PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_header_panel_style()
	add_child(header_panel)

	header_margin = MarginContainer.new()
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_margin.add_theme_constant_override('margin_top', 4)
	header_margin.add_theme_constant_override('margin_bottom', 4)
	header_margin.add_theme_constant_override('margin_left', 8)
	header_margin.add_theme_constant_override('margin_right', 8)
	header_panel.add_child(header_margin)

	header_box = HBoxContainer.new()
	header_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_box.add_theme_constant_override('separation', 10)
	header_margin.add_child(header_box)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_font_override('font', TITLE_FONT)
	ThemeUtils.apply_font_size(title_label, 18)
	title_label.add_theme_color_override('font_color', Color('#f3f4f6'))
	header_box.add_child(title_label)

	actions_box = HBoxContainer.new()
	actions_box.alignment = BoxContainer.ALIGNMENT_END
	actions_box.add_theme_constant_override('separation', 6)
	header_box.add_child(actions_box)

	body_scroll = ScrollContainer.new()
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(body_scroll)

	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(vbox)


# initializes the inspector within the custom popup system
static func edit_resource(_res: Resource, _title: String = '', _actions: Array[Dictionary] = [], _popup_opts: Dictionary = {}, _hide_phase: bool = false, _flat: bool = false) -> void:
	var global: HenGlobal = Engine.get_singleton('Global')
	var scene: PackedScene = load('res://addons/hengo/scenes/custom_inspector.tscn')
	var inspector: HenInspector = scene.instantiate()

	var popup: HenPopupContainer = (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(inspector, _popup_opts)
	inspector.hide_phase = _hide_phase

	if _flat:
		inspector.make_flat()

	inspector.edit(_res, _title, _actions)

	global.CURRENT_INSPECTOR = inspector
	inspector.grab_focus()
	inspector.announce_on_close(popup)


# one input of an action, with the same row the full inspector renders for it:
# the typed editor plus the bind, expression and producer buttons, and nothing else
static func edit_slot(_action: HenSaveAction, _slot: Dictionary, _title: String, _popup_opts: Dictionary = {}) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var inspector: HenInspector = (load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()

	var popup: HenPopupContainer = (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(inspector, _popup_opts)

	inspector.make_flat()
	inspector.edit_one_slot(_action, _slot, _title)

	global.CURRENT_INSPECTOR = inspector
	inspector.grab_focus()
	inspector.announce_on_close(popup)

	# after the row's own grab_focus, and deferred past the popup's deferred move:
	# the chip is a value being edited, so the caret belongs in the editor
	inspector.focus_editor.call_deferred()


# one branch of an action, with the same row the full inspector renders for it:
# the state picker, the label and the instance binding, and nothing else
static func edit_branch(_action: HenSaveAction, _key: String, _title: String, _popup_opts: Dictionary = {}) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var inspector: HenInspector = (load('res://addons/hengo/scenes/custom_inspector.tscn') as PackedScene).instantiate()

	var popup: HenPopupContainer = (Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(inspector, _popup_opts)

	inspector.make_flat()
	inspector.edit_one_branch(_action, _key, _title)

	global.CURRENT_INSPECTOR = inspector
	inspector.grab_focus()
	inspector.announce_on_close(popup)


# the sidebar rows and the state graph read a resource by its name, so renaming one
# leaves both showing the old name until something says so. announcing per keystroke
# would rebuild the whole sidebar while the name is still being typed
func announce_on_close(_popup: HenPopupContainer) -> void:
	if not is_instance_valid(_popup):
		return

	_popup.closed.connect(announce_changes, CONNECT_ONE_SHOT)


# an edit nothing else announced: the sidebar and the graph still show what the
# resource was before it
func mark_dirty() -> void:
	_dirty = true


func announce_changes() -> void:
	if not _dirty:
		return

	_dirty = false
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func edit_one_branch(_action: HenSaveAction, _key: String, _title: String) -> void:
	resource = _action
	inspector_title = _title
	inspector_actions = []
	_single_slot = {}
	_single_branch = {key = _key, title = _title}

	_update_header()
	_update_props()


func edit_one_slot(_action: HenSaveAction, _slot: Dictionary, _title: String) -> void:
	resource = _action
	inspector_title = _title
	inspector_actions = []

	# a value a macro use hands its definition has no action holding it
	if _action:
		_migrate_name_bindings(_action)

	var slot: Dictionary = _slot.duplicate()

	slot.macro_params = _get_macro_params(_action.macro_id) if _action else {}
	slot.indent = 0

	_single_branch = {}
	_single_slot = slot

	_update_header()
	_update_props()


func edit(_res: Resource, _title: String = '', _actions: Array[Dictionary] = []) -> void:
	resource = _res
	inspector_title = _title
	inspector_actions = _actions
	_single_slot = {}
	_single_branch = {}

	_update_header()
	_update_props()

	if not _res.property_list_changed.is_connected(_update_props): _res.property_list_changed.connect(_update_props)


# the inner scroll has no minimum of its own and would collapse the body
func make_flat() -> void:
	if not is_instance_valid(body_scroll):
		return

	body_scroll.remove_child(vbox)
	remove_child(body_scroll)
	body_scroll.queue_free()
	body_scroll = null

	add_child(vbox)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _update_header() -> void:
	var text: String = inspector_title.strip_edges()
	if text.is_empty():
		text = _get_default_title()
	title_label.text = text

	for child in actions_box.get_children():
		child.queue_free()

	for action in inspector_actions:
		var bt: Button = _create_action_button(action)
		if bt:
			actions_box.add_child(bt)


func _update_props() -> void:
	for child in vbox.get_children():
		child.queue_free()

	# a value a macro use hands its definition has no action behind the row
	if not _single_slot.is_empty():
		_slot_idx = 0
		_create_value_slot(_single_slot)
		return

	if not resource:
		return

	if not _single_branch.is_empty():
		_create_branch_row(resource as HenSaveAction, str(_single_branch.key), str(_single_branch.title))
		return

	# actions render as a value-only param list (schema is owned by the macro)
	if resource is HenSaveAction:
		_render_action_params()
		return

	# a use of a macro is values and ways out, never the state fields
	if resource is HenSaveState and (resource as HenSaveState).is_macro_use():
		_render_macro_use(resource as HenSaveState)
		return

	var prop_index: int = 0
	for prop in resource.get_property_list():
		if _is_tool_button_property(prop):
			_create_tool_button(prop, prop_index)
			prop_index += 1
			continue

		if prop.type == TYPE_ARRAY or prop.usage & PROPERTY_USAGE_EDITOR:
			_create_prop_editor(prop, prop_index)
			prop_index += 1


static func prop_label(_name: String) -> String:
	return str(PROP_LABELS.get(_name, _name.capitalize()))


func _create_prop_editor(prop: Dictionary, prop_index: int) -> void:
	var prop_scene: PackedScene = get_prop_scene(resource, prop)
	if not prop_scene:
		return

	if prop_index > 0:
		var separator := HSeparator.new()
		vbox.add_child(separator)

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = prop_label(prop.name)
	ThemeUtils.apply_font_size(label, 14)

	vbox.add_theme_constant_override('separation', 10)

	var editor: Control = _instantiate_editor(prop_scene, prop)
	if not editor:
		return

	configure_editor(editor, resource, prop)

	container.add_child(editor)

	var panel: PanelContainer = PanelContainer.new()

	if prop_index % 2 != 0:
		panel.self_modulate = Color(1, 1, 1, 0.05)
	else:
		panel.self_modulate = Color(1, 1, 1, 0)

	panel.add_child(container)
	vbox.add_child(panel)


# a use hands the macro its values and says where each way out leads
func _render_macro_use(use: HenSaveState) -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var macro: HenSaveStateMacro = use.get_macro(save_data)

	_slot_idx = 0

	_create_name_editor()

	if not macro:
		var missing := Label.new()
		missing.text = 'The macro this state runs is gone.'
		missing.add_theme_color_override('font_color', HenActionVisuals.ERROR_COLOR)
		vbox.add_child(missing)
		return

	use.sync_macro_inputs(save_data)

	for param: HenSaveParam in use.macro_inputs:
		_create_value_slot({
			param = param,
			bind_store = use.macro_bindings,
			bind_key = str(param.id),
			macro_params = {},
			indent = 0
		})

	for flow: HenSaveFlowParam in macro.flow_outputs:
		_create_macro_exit_row(use, flow)


func _create_name_editor() -> void:
	for prop: Dictionary in resource.get_property_list():
		if prop.name == &'name':
			_create_prop_editor(prop, 0)
			return


func _create_macro_exit_row(use: HenSaveState, flow: HenSaveFlowParam) -> void:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var target_id: String = str((use.flow_targets.get(str(flow.id), {}) as Dictionary).get('state_id', ''))
	var target: HenSaveState = HenGeneratorAction.find_state(save_data, StringName(target_id))

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')

	label.text = flow.name + '  (branch)'
	ThemeUtils.apply_font_size(label, 14)

	var target_bt := Button.new()

	target_bt.text = ('-> ' + target.name) if target else 'Nowhere'
	target_bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	target_bt.pressed.connect(_open_macro_exit_picker.bind(use, str(flow.id), target_bt))

	container.add_child(target_bt)

	var panel := PanelContainer.new()

	panel.add_child(container)
	vbox.add_child(panel)


func _open_macro_exit_picker(use: HenSaveState, exit_id: String, anchor: Control) -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(220, 280)
	})

	menu.mount(_build_use_target_options(use), _on_macro_exit_selected.bind(use, exit_id), 'item_type')


# the states a use can hand control to: the ones of the scope holding it
func _build_use_target_options(use: HenSaveState) -> Array:
	var save_data: HenSaveData = (Engine.get_singleton(&'Global') as HenGlobal).SAVE_DATA
	var options: Array = [ {name = 'Nowhere', kind = 'none'} ]

	for state: HenSaveState in save_data.states:
		options.append({name = state.name, kind = 'state', state_id = state.id})

	for holder: HenSaveState in HenGeneratorAction.ancestor_chain(save_data, use):
		if holder == use:
			continue

		for sub: HenSaveState in holder.get_sub_states(save_data):
			if sub == use:
				continue

			options.append({name = holder.name + ' / ' + sub.name, kind = 'state', state_id = sub.id})

	return options


func _on_macro_exit_selected(item: Dictionary, use: HenSaveState, exit_id: String) -> void:
	if str(item.get('kind', '')) == 'none':
		use.flow_targets.erase(exit_id)
	else:
		use.flow_targets[exit_id] = {state_id = item.state_id, label = ''}

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


# value-only editor for each of an action's inputs (reuses the prop widgets)
func _render_action_params() -> void:
	var action: HenSaveAction = resource as HenSaveAction
	var macro_params: Dictionary = _get_macro_params(action.macro_id)
	_slot_idx = 0

	_migrate_name_bindings(action)

	# a nested action runs at its loop's phase, so it has no phase of its own
	if not hide_phase and not nested_producer:
		_create_phase_selector(action)
	if not nested_producer:
		_create_branch_selector(action)

	var macro: HenSaveMacro = _find_macro(action.macro_id)
	var outputs: Array[HenSaveParam] = macro.outputs if macro else [] as Array[HenSaveParam]

	HenSaveAction.sync_action_inputs(action, macro)

	if action.inputs.is_empty() and outputs.is_empty():
		var label := Label.new()
		label.text = 'This action has no parameters.'
		label.add_theme_color_override('font_color', Color(1, 1, 1, 0.5))
		vbox.add_child(label)
		return

	for param: HenSaveParam in action.inputs:
		# a top-level slot: bindings on the action, expressions allowed
		_create_value_slot({
			param = param,
			action = action,
			bind_store = action.input_bindings,
			bind_key = str(param.id),
			expr_store = action.input_expressions,
			expr_key = str(param.id),
			action_store = action.input_actions,
			action_key = str(param.id),
			macro_params = macro_params,
			indent = 0
		})



# upgrades bindings saved by name to the id form, so opening an action once makes
# its variables rename-proof. props keep their bare name
static func _migrate_name_bindings(action: HenSaveAction) -> void:
	# the owner and not the active script: this rewrites the bindings, so resolving a
	# name against another script would store the id of its same-named variable
	var save_data: HenSaveData = HenActionsPanel.owner_of(action)

	if not save_data:
		return

	_migrate_bind_store(save_data, action.input_bindings)

	for expr: HenSaveActionExpression in action.input_expressions.values():
		_migrate_bind_store(save_data, expr.word_bindings)

	for branch: Variant in action.branches.values():
		var bind: String = str((branch as Dictionary).get('instance_bind', ''))
		var variable: HenSaveVar = HenUtils.get_bind_var(save_data, bind)

		if variable and not bind.begins_with(HenUtils.BIND_VAR_PREFIX):
			(branch as Dictionary).instance_bind = HenUtils.bind_code_for_var(variable)


static func _migrate_bind_store(save_data: HenSaveData, store: Dictionary) -> void:
	for key: Variant in store.keys():
		var bind: String = str(store[key])

		if bind.begins_with(HenUtils.BIND_VAR_PREFIX):
			continue

		var variable: HenSaveVar = HenUtils.get_bind_var(save_data, bind)

		if variable:
			store[key] = HenUtils.bind_code_for_var(variable)


# renders one value slot: literal | bound (chip) | expression (button + word slots).
# reused for top-level params AND for an expression's word props (expr_store null).
func _create_value_slot(slot: Dictionary) -> void:
	var param: HenSaveParam = slot.param
	var bind_store: Dictionary = slot.bind_store
	var bind_key: String = slot.bind_key
	var expr_store: Variant = slot.get('expr_store')
	var expr_key: String = slot.get('expr_key', '')
	var indent: int = slot.get('indent', 0)

	var has_expr: bool = expr_store != null and (expr_store as Dictionary).has(expr_key)
	var bind_code: String = bind_store.get(bind_key, '')
	var action_store: Variant = slot.get('action_store')
	var action_key: String = slot.get('action_key', '')
	var has_action: bool = action_store != null and (action_store as Dictionary).has(action_key)
	var idx: int = _slot_idx
	_slot_idx += 1

	# a fixed option set replaces the whole value-source machinery with a picker
	var options: Array[String] = _slot_options(slot, param)
	# a required slot only accepts a binding, never a literal or expression
	var is_lvalue: bool = _slot_requires_bind(slot, param)

	if idx > 0:
		vbox.add_child(HSeparator.new())

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = param.name
	ThemeUtils.apply_font_size(label, 14)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override('separation', 4)

	# value display: option picker | expression button | bound chip | literal editor
	if not options.is_empty():
		var option_bt := Button.new()
		option_bt.text = param.option_label(param.default_value) if param.default_value != null else param.option_label(options[0])
		option_bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		option_bt.pressed.connect(_open_option_picker.bind(param, options, option_bt))
		row.add_child(option_bt)
	elif has_action:
		var action_chip := Button.new()
		action_chip.icon = load('res://addons/hengo/assets/new_icons/square-function.svg')
		action_chip.text = HenActionsPanel.inline_label((action_store as Dictionary)[action_key])
		action_chip.clip_text = true
		action_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		action_chip.pressed.connect(_on_action_chip_pressed.bind(slot, action_chip))

		if not active_action_key.is_empty() and action_key == active_action_key:
			action_chip.add_theme_color_override('font_color', Color('#ff9e64'))
			action_chip.add_theme_color_override('icon_normal_color', Color('#ff9e64'))

		row.add_child(action_chip)
	elif has_expr:
		var expr: HenSaveActionExpression = (expr_store as Dictionary)[expr_key]
		var exp_bt: HenExpressionBt = load('res://addons/hengo/scenes/utils/expression_bt.tscn').instantiate()
		exp_bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(exp_bt)
		exp_bt.set_default(expr.code if not expr.code.is_empty() else 'Expression')
		exp_bt.on_expression_save.connect(_on_expression_saved.bind(expr))
	elif not bind_code.is_empty():
		# bound: a clickable chip shows the source; click re-opens the picker (has None to unbind)
		var chip := Button.new()
		chip.text = '= ' + HenUtils.get_bind_label(HenActionsPanel.owner_of(slot.get('action') as HenSaveAction), bind_code)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.pressed.connect(_open_bind_picker.bind(slot, chip))
		row.add_child(chip)
	elif is_lvalue:
		# an unbound target has nowhere to write, and a literal there is never read:
		# ask for the variable instead of showing a dead editor
		var optional: bool = _slot_is_optional(slot, param)
		var pick_bt := Button.new()
		pick_bt.text = 'Choose a variable... (optional)' if optional else 'Choose a variable...'
		pick_bt.tooltip_text = 'Leave it empty to skip this value' if optional else 'This action writes here, so it needs a variable or property'
		pick_bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pick_bt.pressed.connect(_open_bind_picker.bind(slot, pick_bt))

		# only a slot that actually blocks the action gets the alert treatment
		if not optional:
			pick_bt.icon = load('res://addons/hengo/assets/new_icons/triangle.svg')
			pick_bt.add_theme_color_override('font_color', WARNING_COLOR)
			pick_bt.add_theme_color_override('icon_normal_color', WARNING_COLOR)

		row.add_child(pick_bt)
	else:
		# effective type may follow another input's binding (type_from)
		var dv_prop: Dictionary = _get_default_value_prop(_effective_slot_type(slot, param))
		var prop_scene: PackedScene = get_prop_scene(param, dv_prop)

		if prop_scene:
			# seed fallback: null (pre value-editing) shows the macro default
			var mp: HenSaveParam = (slot.get('macro_params', {}) as Dictionary).get(bind_key)
			if param.default_value == null and mp and mp.default_value != null:
				param.default_value = mp.default_value

			# coerce a literal left over from a looser type (e.g. "45" typed as Variant -> 45.0)
			if param.default_value is String and dv_prop.type != TYPE_STRING:
				param.default_value = normalize_value(param, 'default_value', param.default_value, dv_prop.type)

			var editor: Control = _instantiate_editor(prop_scene, dv_prop)
			if editor:
				# seed first, connect after — the seed's spurious value_changed is discarded
				configure_editor(editor, param, dv_prop, 0, '', false)
				if editor.has_signal('value_changed'):
					editor.value_changed.connect(func(new_val: Variant) -> void:
						_on_action_param_changed(param, dv_prop.type, new_val)
					)
				editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(editor)

	# value-source buttons: bind | new variable | expression (top level only)
	if not options.is_empty():
		container.add_child(row)
		_mount_slot(container, idx, indent)
		return

	var picker: StringName = _slot_picker(slot, param)

	if HenSlotPickers.has(picker):
		var suggest_bt := Button.new()
		suggest_bt.icon = load('res://addons/hengo/assets/new_icons/list.svg')
		suggest_bt.tooltip_text = 'Pick one the project already has'
		suggest_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		suggest_bt.pressed.connect(_open_suggestion_picker.bind(param, picker, suggest_bt))
		row.add_child(suggest_bt)

	var bind_bt := Button.new()
	bind_bt.icon = load('res://addons/hengo/assets/new_icons/circle-dot.svg')
	bind_bt.tooltip_text = 'Bind to a variable or property'
	bind_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bind_bt.pressed.connect(_open_bind_picker.bind(slot, bind_bt))
	row.add_child(bind_bt)

	var newvar_bt := Button.new()
	newvar_bt.icon = load('res://addons/hengo/assets/new_icons/circle-plus.svg')
	newvar_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# an output already has a name and a type, so its variable is created in one
	# click; a plain input opens the prompt to name it
	if slot.get('quick_var', false):
		newvar_bt.tooltip_text = 'Create a variable named after this output'
		newvar_bt.pressed.connect(_quick_new_var.bind(slot))
	else:
		newvar_bt.tooltip_text = 'Create and bind a new variable'
		newvar_bt.pressed.connect(_prompt_new_var.bind(slot))
	row.add_child(newvar_bt)

	# an assignment target only accepts a binding, so no expression toggle there
	if expr_store != null and not is_lvalue:
		# toggle: expression <-> regular input
		var expr_bt := Button.new()
		expr_bt.icon = load('res://addons/hengo/assets/new_icons/calculator.svg')
		expr_bt.toggle_mode = true
		expr_bt.button_pressed = has_expr
		expr_bt.tooltip_text = 'Back to a regular input' if has_expr else 'Use an expression'
		expr_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		expr_bt.pressed.connect(_on_expression_pressed.bind(slot))
		row.add_child(expr_bt)

	if action_store != null and not is_lvalue:
		var action_bt := Button.new()
		action_bt.icon = load('res://addons/hengo/assets/new_icons/square-function.svg')
		action_bt.toggle_mode = true
		action_bt.button_pressed = has_action
		action_bt.tooltip_text = 'Back to a regular input' if has_action else 'Use an action as the value'
		action_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		action_bt.pressed.connect(_on_action_toggle.bind(slot))
		row.add_child(action_bt)

	container.add_child(row)
	_mount_slot(container, idx, indent)

	# expression word props render as nested slots right below the button
	if has_expr:
		var expr: HenSaveActionExpression = (expr_store as Dictionary)[expr_key]
		for word: HenSaveParam in expr.words:
			_create_value_slot({
				param = word,
				bind_store = expr.word_bindings,
				bind_key = word.name,
				expr_store = null,
				expr_key = '',
				macro_defaults = {},
				indent = indent + 1
			})


# wraps a built slot row in its striped panel and adds it to the list
# a chip opens this row to edit a value, so the caret starts in the editor and
# typing works without aiming at the field first
func focus_editor() -> void:
	var editor: Control = _first_editor(vbox)

	if not is_instance_valid(editor):
		return

	editor.grab_focus()

	if editor is LineEdit:
		(editor as LineEdit).select_all()

	if not editor.gui_input.is_connected(_on_editor_input):
		editor.gui_input.connect(_on_editor_input)


func _on_editor_input(_event: InputEvent) -> void:
	if not is_dismiss_key(_event):
		return

	get_viewport().set_input_as_handled()
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


# the caret is placed in the editor, so the keyboard has to be able to leave it.
# both keys just dismiss, because the editors write on every keystroke and there
# is nothing left to commit by the time either is pressed
static func is_dismiss_key(_event: InputEvent) -> bool:
	var key := _event as InputEventKey

	return key != null and key.pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]


# the row nests the editor inside a panel and a container, and a Vector2 nests one
# field per component: the first that takes the keyboard is the one to type into
func _first_editor(_node: Node) -> Control:
	for child: Node in _node.get_children():
		if child is LineEdit or child is SpinBox:
			return child as Control

		var deeper: Control = _first_editor(child)

		if deeper:
			return deeper

	return null


func _mount_slot(container: Control, idx: int, indent: int) -> void:
	var panel := PanelContainer.new()
	panel.self_modulate = Color(1, 1, 1, 0.05) if idx % 2 != 0 else Color(1, 1, 1, 0)

	if indent > 0:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override('margin_left', int(14 * indent))
		margin.add_child(container)
		panel.add_child(margin)
	else:
		panel.add_child(container)

	vbox.add_child(panel)


# fixed option set of a slot, read from the macro definition (the action's clone
# is the fallback for params saved before the macro declared them)
func _slot_options(slot: Dictionary, param: HenSaveParam) -> Array[String]:
	var macro_param: HenSaveParam = _macro_param(slot)

	if macro_param and not macro_param.options.is_empty():
		return macro_param.options

	return param.options


# the slot is the left side of an assignment: only a variable or a property fits
func _slot_is_lvalue(slot: Dictionary, param: HenSaveParam) -> bool:
	var macro_param: HenSaveParam = _macro_param(slot)

	return macro_param.lvalue if macro_param else param.lvalue


# the slot is written to, but leaving it empty is a valid choice
func _slot_is_optional(slot: Dictionary, param: HenSaveParam) -> bool:
	var macro_param: HenSaveParam = _macro_param(slot)

	return macro_param.optional if macro_param else param.optional


# the slot needs a source, whether it is written to or just read from
func _slot_requires_bind(slot: Dictionary, param: HenSaveParam) -> bool:
	var macro_param: HenSaveParam = _macro_param(slot)
	var target: HenSaveParam = macro_param if macro_param else param

	return target.lvalue or target.bind_only


func _macro_param(slot: Dictionary) -> HenSaveParam:
	return (slot.get('macro_params', {}) as Dictionary).get(slot.get('bind_key', '')) as HenSaveParam


# named source of suggestions of a slot, declared by the macro
func _slot_picker(slot: Dictionary, param: HenSaveParam) -> StringName:
	var macro_param: HenSaveParam = _macro_param(slot)

	if macro_param and not macro_param.picker.is_empty():
		return macro_param.picker

	return param.picker


# the entries are read here, not at load, so they follow the project as it is now
func _open_suggestion_picker(param: HenSaveParam, picker: StringName, anchor: Button) -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()
	var list: Array = []

	for entry: String in HenSlotPickers.entries(picker):
		list.append({name = entry})

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(240, 260)
	})

	menu.mount(list, func(item: Dictionary) -> void:
		param.default_value = str(item.name)
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	, 'item_type')


func _open_option_picker(param: HenSaveParam, options: Array[String], anchor: Button) -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()
	var list: Array = []

	for option: String in options:
		list.append({name = param.option_label(option), value = option})

	# show first (enters the tree → _ready resolves the refs), then mount
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(180, 220)
	})

	menu.mount(list, func(item: Dictionary) -> void:
		param.default_value = str(item.get('value', item.name))
		anchor.text = str(item.name)
	, 'item_type')


# opens the value-source picker for a slot (None / variables / props / New Variable [/ Expression])
func _open_bind_picker(slot: Dictionary, anchor: Control) -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	# show first (enters the tree → _ready resolves %SearchBar/%List and wires the
	# click once), then mount — mounting before tree leaves select_callable unset
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(220, 280)
	})

	menu.mount(_build_bind_options(slot), _on_bind_selected.bind(slot), 'item_type')


# type-filtered list of Hengo variables + owner-class properties (+ Expression at top level)
func _build_bind_options(slot: Dictionary) -> Array:
	var param: HenSaveParam = slot.param
	var ptype: String = _effective_slot_type(slot, param)
	# the picker writes what it offers, so it has to offer the owner's variables
	var save_data: HenSaveData = HenActionsPanel.owner_of(slot.get('action') as HenSaveAction)
	var options: Array = [ {name = 'None (literal)', kind = 'none'} ]
	# a write target must stay assignable: every call-shaped source is left out,
	# `randf() = 5` would not compile
	var assignable_only: bool = _slot_is_lvalue(slot, param)

	# engine-provided values (mouse position and friends) sit on top, they are the
	# ones nobody wants to model as a variable
	for source: Dictionary in (HenUtils.NATIVE_SOURCES if not assignable_only else []):
		var needs: String = str(source.needs_class)

		if not needs.is_empty() and not ClassDB.is_parent_class(save_data.identity.type, needs):
			continue

		if not (ptype == 'Variant' or HenUtils.is_type_relation_valid(ptype, StringName(str(source.type)))):
			continue

		# a source that takes an argument asks for it before binding
		if source.has('key'):
			options.append({name = str(source.name) + '...', kind = 'native_arg', source_key = str(source.key)})
		else:
			options.append({name = str(source.name), kind = 'bind', code = str(source.code)})

	# inside a function or a macro its own inputs come first: they are what the
	# definition was handed to work with
	for scope_input: HenSaveParam in _scope_inputs(save_data, slot.get('action') as HenSaveAction):
		if ptype == 'Variant' or HenUtils.is_type_relation_valid(ptype, scope_input.type):
			options.append({name = scope_input.name, kind = 'bind', code = HenUtils.bind_code_for_arg(scope_input)})

	for v: HenSaveVar in save_data.variables:
		if HenUtils.is_type_relation_valid(ptype, v.type):
			options.append({name = v.name, kind = 'bind', code = HenUtils.bind_code_for_var(v)})

	for prop: Dictionary in ClassDB.class_get_property_list(save_data.identity.type):
		if not (int(prop.usage) & PROPERTY_USAGE_EDITOR):
			continue
		var prop_type: StringName = type_string(prop.type)
		if (ptype == 'Variant' and prop.type != TYPE_NIL) or HenUtils.is_type_relation_valid(ptype, prop_type):
			options.append({name = prop.name, kind = 'bind', code = prop.name})

	return options


# the inputs of the definition the step belongs to, empty for a step of a state
func _scope_inputs(_save_data: HenSaveData, _action: HenSaveAction) -> Array[HenSaveParam]:
	var scope: HenSaveResType = _definition_of(_save_data, _action)

	if scope is HenSaveFunc:
		return (scope as HenSaveFunc).inputs

	if scope is HenSaveStateMacro:
		return (scope as HenSaveStateMacro).inputs

	return []


# the definition holding a step; the open scope answers for the paths that have no
# action at hand yet
func _definition_of(_save_data: HenSaveData, _action: HenSaveAction) -> HenSaveResType:
	if not _action:
		return HenRoute.current_scope(_save_data)

	var scope_id: StringName = HenActionsPanel.state_id_of(_save_data, _action)

	return HenRoute.definition_of(_save_data, scope_id) if not scope_id.is_empty() else HenRoute.current_scope(_save_data)


func _on_bind_selected(item: Dictionary, slot: Dictionary) -> void:
	var bind_store: Dictionary = slot.bind_store
	var bind_key: String = slot.bind_key
	var expr_store: Variant = slot.get('expr_store')
	var expr_key: String = slot.get('expr_key', '')

	match str(item.get('kind', '')):
		'none':
			bind_store.erase(bind_key)
			if expr_store != null:
				(expr_store as Dictionary).erase(expr_key)
			_erase_action(slot)
			_update_props()
		'bind':
			bind_store[bind_key] = item.code
			if expr_store != null:
				(expr_store as Dictionary).erase(expr_key)
			_erase_action(slot)
			_update_props()
		'native_arg':
			_prompt_source_arg(slot, str(item.source_key))


# a slot holds one source at a time
func _erase_action(slot: Dictionary) -> void:
	var action_store: Variant = slot.get('action_store')
	var key: String = slot.get('action_key', '')

	if action_store != null and (action_store as Dictionary).has(key):
		(action_store as Dictionary).erase(key)
		inline_changed.emit()


# switches the slot to expression mode (keeps an existing expression)
func _on_expression_pressed(slot: Dictionary) -> void:
	var expr_store: Variant = slot.get('expr_store')
	if expr_store == null:
		return

	var store: Dictionary = expr_store as Dictionary
	var expr_key: String = slot.get('expr_key', '')

	if store.has(expr_key):
		# toggle off: back to a regular (literal) input, dropping the expression
		store.erase(expr_key)
	else:
		store[expr_key] = HenSaveActionExpression.new()
		(slot.bind_store as Dictionary).erase(slot.bind_key)
		_erase_action(slot)

	_update_props()


func _on_action_chip_pressed(slot: Dictionary, chip: Control) -> void:
	if on_action_chip.is_valid():
		on_action_chip.call(slot, chip)
	else:
		HenActionCascade.open(self, slot, chip)


func _on_action_toggle(slot: Dictionary) -> void:
	var action_store: Dictionary = slot.action_store
	var action_key: String = slot.action_key

	if action_store.has(action_key):
		_erase_action(slot)
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
		_update_props()
	else:
		_open_producer_palette(slot)


func _open_producer_palette(slot: Dictionary) -> void:
	var ptype: String = _effective_slot_type(slot, slot.param)
	var search: HenActionsSearch = load('res://addons/hengo/scenes/actions_search.tscn').instantiate()

	search.setup_producer_picker(ptype, _on_producer_picked.bind(slot))

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(search, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		anchor_to = (Engine.get_singleton(&'Global') as HenGlobal).SIDE_PANEL,
		side = SIDE_RIGHT,
		min_size = Vector2(320, 360)
	})


func _on_producer_picked(macro: HenSaveMacro, slot: Dictionary) -> void:
	HenActionsPanel.set_producer(slot, macro)

	inline_changed.emit()
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


# creates and binds a variable named after the output, no prompt
func _quick_new_var(slot: Dictionary) -> void:
	var param: HenSaveParam = slot.param
	_on_new_var_named(param.name.to_snake_case(), str(param.type), slot)


func _prompt_new_var(slot: Dictionary) -> void:
	var prompt: HenNamePrompt = load('res://addons/hengo/scenes/name_prompt.tscn').instantiate()

	# show first (enters the tree → _ready wires the refs), then setup
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(prompt, {
		layout = HenGeneralPopup.Layout.CENTER
	})

	var param: HenSaveParam = slot.param
	prompt.setup('New Variable', param.name.to_snake_case(), param.type, _on_new_var_named.bind(slot))


# asks for the argument of a source that takes one (a node path, an input action)
# and binds the slot to "<key>:<argument>"
func _prompt_source_arg(slot: Dictionary, source_key: String) -> void:
	var source: Dictionary = _native_source(source_key)

	if source.is_empty():
		return

	# the menu that picked this source hides the topmost popup right after this
	# callback, so opening now would close what just opened
	if StringName(str(source.get('arg_picker', &''))) == &'node_path':
		_open_node_path_menu.call_deferred(slot, source_key)
		return

	_open_source_arg_prompt.call_deferred(slot, source_key)


func _native_source(source_key: String) -> Dictionary:
	for entry: Dictionary in HenUtils.NATIVE_SOURCES:
		if str(entry.get('key', '')) == source_key:
			return entry

	return {}


# reopening an already bound slot starts from what is there
func _current_source_arg(slot: Dictionary, source_key: String) -> String:
	var current: String = str((slot.bind_store as Dictionary).get(slot.bind_key, ''))
	var prefix: String = source_key + ':'

	return current.substr(prefix.length()) if current.begins_with(prefix) else ''


func _open_source_arg_prompt(slot: Dictionary, source_key: String) -> void:
	var source: Dictionary = _native_source(source_key)

	if source.is_empty():
		return

	var prompt: HenNamePrompt = load('res://addons/hengo/scenes/name_prompt.tscn').instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(prompt, {
		layout = HenGeneralPopup.Layout.CENTER
	})

	prompt.setup(str(source.arg_prompt), _current_source_arg(slot, source_key), '', _on_source_arg_named.bind(slot, source_key), false)


# the nodes the scenes holding this script can reach, with the text field kept as
# the first row for a node that only exists at runtime
func _open_node_path_menu(slot: Dictionary, source_key: String) -> void:
	var save_data: HenSaveData = HenActionsPanel.owner_of(slot.get('action') as HenSaveAction)
	var entries: Array[Dictionary] = HenNodePaths.entries(save_data, StringName(_effective_slot_type(slot, slot.param)))

	if entries.is_empty():
		_open_source_arg_prompt(slot, source_key)
		return

	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()
	var list: Array = [{name = TYPED_PATH_ENTRY, path = ''}]

	for entry: Dictionary in entries:
		list.append({name = str(entry.label), path = str(entry.path)})

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.CENTER,
		min_size = Vector2(360, 320)
	})

	menu.mount(list, func(item: Dictionary) -> void:
		var path: String = str(item.get('path', ''))

		if path.is_empty():
			_open_source_arg_prompt.call_deferred(slot, source_key)
			return

		_on_source_arg_named(path, '', slot, source_key)
	, 'item_type')


func _on_source_arg_named(_arg: String, _type: String, slot: Dictionary, source_key: String) -> void:
	var arg: String = _arg.strip_edges()

	# an empty argument would emit ("") and still read as bound
	if arg.is_empty():
		return

	(slot.bind_store as Dictionary)[slot.bind_key] = source_key + ':' + arg

	var expr_store: Variant = slot.get('expr_store')
	if expr_store != null:
		(expr_store as Dictionary).erase(slot.get('expr_key', ''))

	_erase_action(slot)

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


func _on_new_var_named(_name: String, _type: String, slot: Dictionary) -> void:
	# the variable belongs to the script the action lives in, not to the active one
	var save_data: HenSaveData = HenActionsPanel.owner_of(slot.get('action') as HenSaveAction)

	if not save_data:
		return

	var v: HenSaveVar = save_data.add_var(false)
	if not v:
		return

	# a chosen name that clashes gets a 2/3/... suffix, so two Raycasts do not both
	# make a `collider` variable and break the parse
	if not _name.strip_edges().is_empty():
		v.name = save_data.unique_var_name(_name.strip_edges())
	v.type = _type if not _type.is_empty() else 'Variant'

	(slot.bind_store as Dictionary)[slot.bind_key] = HenUtils.bind_code_for_var(v)
	var expr_store: Variant = slot.get('expr_store')
	if expr_store != null:
		(expr_store as Dictionary).erase(slot.get('expr_key', ''))
	_erase_action(slot)
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


# stores the confirmed expression code and syncs its word props (add new, drop stale)
func _on_expression_saved(code: String, words: Array, expr: HenSaveActionExpression) -> void:
	expr.code = code

	var existing: Dictionary = {}
	for w: HenSaveParam in expr.words:
		existing[w.name] = w

	var new_set: Dictionary = {}
	var new_words: Array[HenSaveParam] = []
	for name: String in words:
		new_set[name] = true
		if existing.has(name):
			new_words.append(existing[name])
		else:
			new_words.append(HenSaveParam.create({name = name, type = 'Variant'}))

	# drop bindings of words no longer in the expression
	for name: String in existing:
		if not new_set.has(name):
			expr.word_bindings.erase(name)

	expr.words = new_words

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	_update_props()


# builds the default_value prop dict from the param type (mirrors save_param
# _get_property_list). built directly because get_property_list exposes TWO
# default_value entries — the Variant declaration (type NIL) and the typed one —
# and matching by name alone would grab the NIL one, yielding a null prop scene
func _get_default_value_prop(_type: String) -> Dictionary:
	var vtype: int = HenUtils.get_variant_type_from_string(_type)

	return {
		name = 'default_value',
		type = vtype if vtype != TYPE_NIL else TYPE_STRING,
		hint_string = ''
	}


# a slot's effective type: declared, unless type_from points at another input
# whose bound variable/property dictates it (e.g. set_value's Value follows Target)
func _effective_slot_type(slot: Dictionary, param: HenSaveParam) -> String:
	var mp: HenSaveParam = (slot.get('macro_params', {}) as Dictionary).get(slot.bind_key)
	var type_from: String = str(mp.type_from) if mp else str(param.type_from)

	if type_from.is_empty():
		return param.type

	var action: HenSaveAction = resource as HenSaveAction
	if not action:
		return param.type

	var bind: String = action.input_bindings.get(type_from, '')
	if bind.is_empty():
		return param.type

	var save_data: HenSaveData = HenActionsPanel.owner_of(action)
	var resolved: String = HenUtils.get_bound_source_type(save_data, bind)
	return resolved if not resolved.is_empty() else param.type


# lifecycle phase toggles; phases the macro has no body for are disabled
func _create_phase_selector(action: HenSaveAction) -> void:
	var macro: HenSaveMacro = _find_macro(action.macro_id)
	var supported: Array = HenSaveAction.supported_phases(macro) if macro else [&'update']

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = 'Phase'
	ThemeUtils.apply_font_size(label, 14)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override('separation', 4)

	for phase: StringName in HenSaveAction.PHASE_ORDER:
		var bt := Button.new()
		bt.text = HenActionVisuals.phase_label(phase)
		bt.toggle_mode = true
		bt.button_pressed = str(action.phase) == str(phase)
		bt.disabled = not supported.has(phase)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		bt.pressed.connect(_on_phase_selected.bind(phase))
		row.add_child(bt)

	container.add_child(row)

	var panel := PanelContainer.new()
	panel.add_child(container)
	vbox.add_child(panel)


# one row per branch the macro declares: where it goes + how it reads in the state viewer
func _create_branch_selector(action: HenSaveAction) -> void:
	var macro: HenSaveMacro = _find_macro(action.macro_id)

	if not macro or macro.flow_outputs.is_empty():
		return

	for flow: HenSaveFlowParam in macro.flow_outputs:
		_create_branch_row(action, str(flow.id), flow.name)


func _create_branch_row(action: HenSaveAction, key: String, title: String) -> void:
	var branch: Dictionary = action.branches.get(key, {})
	var save_data: HenSaveData = HenActionsPanel.owner_of(action)
	var target: HenSaveState = HenGeneratorAction.branch_target(save_data, action, key)
	var script_id: StringName = HenGeneratorAction.branch_script_id(save_data, action, key)

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.text = title
	ThemeUtils.apply_font_size(label, 14)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override('separation', 4)

	var target_bt := Button.new()
	target_bt.text = ('-> ' + _branch_target_name(target, script_id)) if target else 'Nowhere'

	# a way out is only resolved where the macro is used, so the row names the exit
	if HenGeneratorAction.branch_is_macro_exit(action, key):
		target_bt.text = 'leaves through ' + _macro_exit_name(save_data, str(branch.get('exit_id', '')))

	target_bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	target_bt.pressed.connect(_open_branch_picker.bind(key, target_bt))
	row.add_child(target_bt)

	# the label is what the state viewer prints on the arrow
	var name_edit := LineEdit.new()
	name_edit.text = str(branch.get('label', ''))
	name_edit.placeholder_text = 'transition name'
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_submitted.connect(func(text: String) -> void: _on_branch_label_changed(key, text))
	name_edit.focus_exited.connect(func() -> void: _on_branch_label_changed(key, name_edit.text))
	row.add_child(name_edit)

	# the state a transition needs may not exist yet, and going to the sidebar for
	# it loses the row that asked
	var new_bt := Button.new()
	new_bt.icon = load('res://addons/hengo/assets/new_icons/circle-plus.svg')
	new_bt.tooltip_text = 'Create a state and transition to it'
	new_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	new_bt.pressed.connect(_open_branch_create_menu.bind(key, new_bt))
	row.add_child(new_bt)

	# a branch does not have to leave the state: it can run steps of its own and
	# carry on, which is what saves a state per one-off bit of behaviour
	var step_bt := Button.new()
	step_bt.icon = load('res://addons/hengo/assets/new_icons/list-plus.svg')
	step_bt.tooltip_text = 'Run an action on this branch, staying in this state'
	step_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	step_bt.pressed.connect(_add_branch_step.bind(key, step_bt))
	row.add_child(step_bt)

	container.add_child(row)

	# a target on another script needs the instance whose machine will be driven
	if not script_id.is_empty():
		container.add_child(_create_branch_instance_row(action, key, script_id))

	var panel := PanelContainer.new()
	panel.add_child(container)
	vbox.add_child(panel)


# second line of a cross-script branch: instance source + optional runtime check
func _create_branch_instance_row(action: HenSaveAction, key: String, script_id: StringName) -> HBoxContainer:
	var save_data: HenSaveData = HenActionsPanel.owner_of(action)
	var branch: Dictionary = action.branches.get(key, {})
	var bind: String = str(branch.get('instance_bind', ''))

	# the path key drives the mode even while empty, so the field survives an unset path
	var mode: String = 'bind' if not bind.is_empty() else ('path' if branch.has('instance_path') else '')

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override('separation', 4)

	var source_bt := Button.new()
	source_bt.tooltip_text = 'node instance of ' + _script_name_for_id(script_id) + ' this transition drives'
	source_bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	source_bt.pressed.connect(_open_branch_instance_picker.bind(key, script_id, source_bt))
	row.add_child(source_bt)

	match mode:
		'bind':
			source_bt.text = '= ' + HenUtils.get_bind_label(save_data, bind)
		'path':
			source_bt.text = 'Node path'

			var path_edit := LineEdit.new()
			path_edit.text = str(branch.get('instance_path', ''))
			path_edit.placeholder_text = '%Player'
			path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			path_edit.text_submitted.connect(func(text: String) -> void: _on_branch_path_changed(key, text))
			path_edit.focus_exited.connect(func() -> void: _on_branch_path_changed(key, path_edit.text))
			row.add_child(path_edit)
		_:
			source_bt.text = 'Instance?'

	var check := CheckBox.new()
	check.text = 'Validate'
	check.tooltip_text = 'skips the transition when the instance is freed or belongs to another script'
	check.button_pressed = HenGeneratorAction.branch_checks_instance(save_data, action, key)
	check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	check.toggled.connect(func(pressed: bool) -> void: _on_branch_check_toggled(key, pressed))
	row.add_child(check)

	return row


# a new target is either a state of the script or a sibling of the state this
# action runs in, which only exist as two choices while the owner is nested
# the same action search the chain uses, landing at the end of the branch list
func _add_branch_step(key: String, anchor: Control) -> void:
	var action: HenSaveAction = resource as HenSaveAction
	var save_data: HenSaveData = HenActionsPanel.owner_of(action)

	if not action or not save_data:
		return

	var state_id: StringName = HenActionsPanel.state_id_of(save_data, action)

	if state_id.is_empty():
		return

	var editor: HenStateViewerCardEditor = HenStateViewerCardEditor.new()

	editor.target(save_data, state_id)
	editor.open_add(action.phase, action, -1, anchor.get_global_rect(), null, StringName(key))


func _open_branch_create_menu(key: String, anchor: Control) -> void:
	var save_data: HenSaveData = HenActionsPanel.owner_of(resource as HenSaveAction)

	if not save_data:
		return

	var owner_state: HenSaveState = _owner_state(save_data)
	var parent: HenSaveState = HenStateOps.parent_of(save_data, owner_state) if owner_state else null

	if not parent:
		_create_branch_target(key, null)
		return

	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(240, 140)
	})

	menu.mount(
		[
			{name = 'New state', kind = 'root'},
			{name = 'New sub-state in ' + parent.name, kind = 'sibling'}
		],
		_on_branch_create_selected.bind(key, parent),
		'item_type'
	)


# the menu closes the popup it lives in, so the creation runs after that close
func _on_branch_create_selected(item: Dictionary, key: String, parent: HenSaveState) -> void:
	var target: HenSaveState = parent if str(item.get('kind', '')) == 'sibling' else null

	_create_branch_target.bind(key, target).call_deferred()


# creates the state, points the branch at it and opens it so it can be named
func _create_branch_target(key: String, parent: HenSaveState, save: bool = true) -> void:
	var save_data: HenSaveData = HenActionsPanel.owner_of(resource as HenSaveAction)

	if not save_data:
		return

	var state: HenSaveState = HenStateOps.request_add_state(save_data, parent, save)

	if not state:
		return

	_on_branch_selected({kind = 'state', state_id = state.id}, key)
	_open_state_inspector(state)


# the same popup the sidebar opens on a state row, stacked over this one
func _open_state_inspector(state: HenSaveState) -> void:
	var side_bar: HenSideBar = (Engine.get_singleton(&'Global') as HenGlobal).SIDE_BAR

	if not side_bar:
		return

	HenInspector.edit_resource(
		state,
		side_bar.get_inspect_title(state),
		side_bar.get_inspect_actions(state),
		side_bar.get_inspect_popup_opts()
	)


func _open_branch_picker(key: String, anchor: Control) -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	# show first, then mount — same ordering the bind picker needs
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(220, 280)
	})

	menu.mount(_build_branch_options(), _on_branch_selected.bind(key), 'item_type')


# sibling states, the sub-states of the state that owns this action, and the
# top-level states of every other script
func _build_branch_options() -> Array:
	# the states offered have to come from the script the action lives in
	var save_data: HenSaveData = HenActionsPanel.owner_of(resource as HenSaveAction)
	var options: Array = [ {name = 'Nowhere', kind = 'none'} ]
	# inside a macro the reachable states are its own, plus the ways out each use
	# of it wires to a state of the scope that holds it
	var definition: HenSaveResType = _definition_of(save_data, resource as HenSaveAction)
	var macro: HenSaveStateMacro = definition as HenSaveStateMacro
	# a function has no machine of its own to change, so the only thing it may
	# drive is another node's: offering a state of this script would only earn the
	# step a red card
	var in_function: bool = definition is HenSaveFunc

	for state: HenSaveState in ([] if in_function else (macro.get_states(save_data) if macro else save_data.states)):
		options.append({name = state.name, kind = 'state', state_id = state.id})

	var owner_state: HenSaveState = _owner_state(save_data)

	# every state on the running chain can have its sub-states switched: the owner's
	# own children, its siblings, and so on up to the top
	if owner_state and not in_function:
		for holder: HenSaveState in HenGeneratorAction.ancestor_chain(save_data, owner_state):
			for sub: HenSaveState in holder.get_sub_states(save_data):
				if sub == owner_state:
					continue

				options.append({name = holder.name + ' / ' + sub.name, kind = 'state', state_id = sub.id})

	if macro:
		for flow: HenSaveFlowParam in macro.flow_outputs:
			options.append({name = flow.name + '  (branch)', kind = 'macro_exit', exit_id = str(flow.id)})

		return options

	for script: Dictionary in _other_scripts(save_data):
		for state: HenSaveState in script.states:
			if state.is_sub_state:
				continue

			options.append({
				name = str(script.name) + ' / ' + state.name,
				kind = 'state',
				state_id = state.id,
				script_id = script.id
			})

	return options


# every mapped script but this one, each with its states (in-memory copy when open)
func _other_scripts(save_data: HenSaveData) -> Array:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var scripts: Array = []

	if not map_dep:
		return scripts

	for script_id: StringName in map_dep.ast_list:
		var ast: HenMapDependencies.ProjectAST = map_dep.ast_list[script_id]

		if not ast.identity or (save_data.identity and ast.identity.id == save_data.identity.id):
			continue

		scripts.append({
			id = ast.identity.id,
			name = ast.identity.name,
			type = ast.identity.type,
			states = _script_states(ast)
		})

	return scripts


# states of a mapped script; a closed one has none in the ast, so read the folder
func _script_states(ast: HenMapDependencies.ProjectAST) -> Array:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and save_data.identity.id == ast.identity.id:
			return save_data.states

	if not ast.states.is_empty():
		return ast.states

	var path: String = str(HenUtils.get_side_bar_item_path(ast.identity.id, HenSideBar.SideBarItem.STATES))
	var states: Array = []

	if not DirAccess.dir_exists_absolute(path):
		return states

	for file: String in DirAccess.get_files_at(path):
		if not file.ends_with(HenEnums.SAVE_EXTENSION):
			continue

		var state: HenSaveState = load(path + file) as HenSaveState

		if state:
			states.append(state)

	return states


# what a way out of the open macro is called, by its id
func _macro_exit_name(save_data: HenSaveData, exit_id: String) -> String:
	var macro: HenSaveStateMacro = _definition_of(save_data, resource as HenSaveAction) as HenSaveStateMacro

	if macro:
		for flow: HenSaveFlowParam in macro.flow_outputs:
			if str(flow.id) == exit_id:
				return flow.name

	return exit_id


func _script_name_for_id(script_id: StringName) -> String:
	var map_dep: HenMapDependencies = Engine.get_singleton(&'MapDependencies')

	if map_dep and map_dep.ast_list.has(script_id):
		var ast: HenMapDependencies.ProjectAST = map_dep.ast_list[script_id]
		if ast.identity:
			return ast.identity.name

	return str(script_id)


# a cross-script target reads as <script> / <state> so both rows and menu match
func _branch_target_name(target: HenSaveState, script_id: StringName) -> String:
	if script_id.is_empty():
		return target.name

	return _script_name_for_id(script_id) + ' / ' + target.name


# the state whose route is open — the action being edited belongs to it
func _on_branch_selected(item: Dictionary, key: String) -> void:
	var action: HenSaveAction = resource as HenSaveAction

	if not action:
		return

	if str(item.get('kind', '')) == 'none':
		action.branches.erase(key)
	elif str(item.get('kind', '')) == 'macro_exit':
		# a way out is resolved by whoever uses the macro, so it names no state here
		action.branches[key] = {exit_id = str(item.exit_id), label = str((action.branches.get(key, {}) as Dictionary).get('label', ''))}
	else:
		var branch: Dictionary = action.branches.get(key, {})
		var script_id: StringName = StringName(str(item.get('script_id', '')))

		# the instance only belongs to a cross-script target; retargeting drops it
		if str(branch.get('script_id', '')) != str(script_id):
			branch.erase('instance_bind')
			branch.erase('instance_path')

		branch.state_id = item.state_id
		branch.script_id = script_id
		branch.label = str(branch.get('label', ''))
		action.branches[key] = branch

	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


# picks which node instance a cross-script branch transitions
func _open_branch_instance_picker(key: String, script_id: StringName, anchor: Control) -> void:
	var menu: HenDropDownMenu = load('res://addons/hengo/scenes/drop_down_menu.tscn').instantiate()

	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).show_content(menu, {
		layout = HenGeneralPopup.Layout.ANCHORED,
		pos = anchor.global_position,
		min_size = Vector2(220, 280)
	})

	menu.mount(_build_branch_instance_options(script_id), _on_branch_instance_selected.bind(key), 'item_type')


# variables and owner-class properties that can hold an instance of the target
# script, plus the node path source (no variable kept anywhere)
func _build_branch_instance_options(script_id: StringName) -> Array:
	var save_data: HenSaveData = HenActionsPanel.owner_of(resource as HenSaveAction)
	var target_type: StringName = &''

	for script: Dictionary in _other_scripts(save_data):
		if str(script.id) == str(script_id):
			target_type = script.type
			break

	var options: Array = [ {name = 'None', kind = 'none'}, {name = 'Node path...', kind = 'path'} ]

	for v: HenSaveVar in save_data.variables:
		# a variable typed by script is exact: it either is this script's or it is out
		if not v.script_id.is_empty():
			if str(v.script_id) == str(script_id):
				options.append({name = v.name, kind = 'bind', code = HenUtils.bind_code_for_var(v)})
			continue

		if target_type.is_empty() or HenUtils.can_hold_instance_of(v.type, target_type):
			options.append({name = v.name, kind = 'bind', code = HenUtils.bind_code_for_var(v)})

	for prop: Dictionary in ClassDB.class_get_property_list(save_data.identity.type):
		if not (int(prop.usage) & PROPERTY_USAGE_EDITOR):
			continue

		if not target_type.is_empty() and HenUtils.can_hold_instance_of(_prop_type(prop), target_type):
			options.append({name = prop.name, kind = 'bind', code = prop.name})

	return options


# an object property's real class lives in class_name; type_string would flatten it to Object
func _prop_type(prop: Dictionary) -> StringName:
	if int(prop.type) == TYPE_OBJECT and not str(prop.get('class_name', '')).is_empty():
		return StringName(str(prop['class_name']))

	return type_string(int(prop.type))


func _on_branch_instance_selected(item: Dictionary, key: String) -> void:
	var action: HenSaveAction = resource as HenSaveAction

	if not action or not action.branches.has(key):
		return

	var branch: Dictionary = action.branches[key]

	# one source at a time: picking either drops the other
	branch.erase('instance_bind')
	branch.erase('instance_path')

	match str(item.get('kind', '')):
		'bind':
			branch.instance_bind = str(item.code)
		'path':
			branch.instance_path = ''

	action.branches[key] = branch
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


func _on_branch_path_changed(key: String, text: String) -> void:
	var action: HenSaveAction = resource as HenSaveAction

	if not action or not action.branches.has(key):
		return

	var branch: Dictionary = action.branches[key]
	var path: String = text.strip_edges()

	if str(branch.get('instance_path', '')) == path:
		return

	branch.instance_path = path
	branch.erase('instance_bind')
	action.branches[key] = branch
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _on_branch_check_toggled(key: String, pressed: bool) -> void:
	var action: HenSaveAction = resource as HenSaveAction

	if not action or not action.branches.has(key):
		return

	var branch: Dictionary = action.branches[key]
	branch.check_instance = pressed
	action.branches[key] = branch
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _on_branch_label_changed(key: String, text: String) -> void:
	var action: HenSaveAction = resource as HenSaveAction

	if not action or not action.branches.has(key):
		return

	var branch: Dictionary = action.branches[key]

	if str(branch.get('label', '')) == text:
		return

	branch.label = text
	action.branches[key] = branch
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _on_phase_selected(phase: StringName) -> void:
	var action: HenSaveAction = resource as HenSaveAction
	if not action:
		return

	action.phase = phase
	# repaints the actions panel row marker and the state viewer
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
	_update_props()


func _find_macro(_macro_id: StringName) -> HenSaveMacro:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for m: HenSaveMacro in (global.action_macros + global.script_macros):
		if m.id == _macro_id:
			return m

	return null


# macro-defined param per input id, read from the pool (carries default_value + type_from)
func _get_macro_params(_macro_id: StringName) -> Dictionary:
	var params: Dictionary = {}
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for m: HenSaveMacro in (global.action_macros + global.script_macros):
		if m.id == _macro_id:
			for p: HenSaveParam in m.inputs:
				params[str(p.id)] = p
			break

	return params


func _on_action_param_changed(param: HenSaveParam, type: int, new_val: Variant) -> void:
	param.default_value = normalize_value(param, 'default_value', new_val, type)


func _create_tool_button(prop: Dictionary, prop_index: int) -> void:
	if prop_index > 0:
		var separator := HSeparator.new()
		vbox.add_child(separator)

	var action_callable: Variant = resource.get(prop.name)
	var hint_data: Dictionary = _parse_tool_button_hint(prop)

	var bt := Button.new()
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bt.text = str(hint_data.get('text', prop.name.capitalize()))

	var icon_name: String = str(hint_data.get('icon', ''))
	if not icon_name.is_empty() and has_theme_icon(icon_name, &"EditorIcons"):
		bt.icon = get_theme_icon(icon_name, &"EditorIcons")

	if action_callable is Callable:
		var callable_value: Callable = action_callable as Callable
		bt.disabled = not callable_value.is_valid()
		if callable_value.is_valid():
			bt.pressed.connect(func():
				callable_value.call()
			)
	else:
		bt.disabled = true

	var container: VBoxContainer = PROP_CONTAINER.instantiate()
	var label: Label = container.get_node('Name')
	label.visible = false
	container.add_child(bt)

	var panel: PanelContainer = PanelContainer.new()
	if prop_index % 2 != 0:
		panel.self_modulate = Color(1, 1, 1, 0.05)
	else:
		panel.self_modulate = Color(1, 1, 1, 0)

	panel.add_child(container)
	vbox.add_child(panel)


func configure_editor(editor: Control, target_resource: Resource, prop: Dictionary, p_depth: int = 0, p_path: String = '', connect_change_signal: bool = true) -> void:
	var value: Variant = target_resource.get(prop.name)

	if editor is HenDropdown:
		var dropdown: HenDropdown = editor as HenDropdown
		if _is_dropdown_hint(prop.hint_string):
			dropdown.type = prop.hint_string
		elif target_resource is HenSaveParam and prop.name == 'type':
			dropdown.type = 'all_godot_classes'

		# a script-typed variable reads as the script, not as the class it extends
		if dropdown.type == 'var_type' and connect_change_signal:
			dropdown.on_set_res_data.connect(_on_var_type_selected)

			var script_var: HenSaveVar = target_resource as HenSaveVar
			if script_var and not script_var.script_id.is_empty():
				dropdown.set_default(_script_type_label(script_var))
				return

	if prop.type == TYPE_BOOL:
		editor.set_default(value)
	elif prop.type == TYPE_COLOR:
		editor.set_default(value)
	elif prop.type == TYPE_ARRAY:
		if editor.has_method('setup'):
			editor.call('setup', target_resource, prop.name, value, prop.hint_string, p_depth, p_path)
	else:
		if prop.type == TYPE_STRING and str(value) == '<null>':
			editor.set_default('')
		else:
			editor.set_default(str(value))

	if connect_change_signal and editor.has_signal('value_changed'):
		editor.value_changed.connect(func(new_val: Variant):
			_on_value_changed(prop.name, new_val, prop.type)
		)


# the type dropdown writes both fields at once: a plain class clears the binding
func _on_var_type_selected(item: Dictionary) -> void:
	var save_var: HenSaveVar = resource as HenSaveVar

	if not save_var:
		return

	save_var.type = StringName(str(item.get('type', 'Variant')))
	save_var.script_id = StringName(str(item.get('script_id', '')))

	_update_props()
	(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()


func _script_type_label(save_var: HenSaveVar) -> String:
	return _script_name_for_id(save_var.script_id) + ' (' + str(save_var.type) + ')'


func _on_value_changed(prop_name: String, new_val: Variant, type: int) -> void:
	var final_val: Variant = normalize_value(resource, prop_name, new_val, type)

	resource.set(prop_name, final_val)

	# the string editor emits on every keystroke, and a refresh rebuilds the whole
	# sidebar: the edit is announced once, when the popup that held it closes
	_dirty = true

	if prop_name == 'type' and (resource is HenSaveVar or resource is HenSaveParam):
		_update_props()
		(Engine.get_singleton(&'SignalBus') as HenSignalBus).request_structural_update.emit()
		_dirty = false


func get_prop_scene(target_resource: Resource, prop: Dictionary) -> PackedScene:
	var dropdown_prop = load('res://addons/hengo/scenes/props/dropdown.tscn')
	if (prop.type == TYPE_STRING or prop.type == TYPE_STRING_NAME) and _is_dropdown_hint(prop.hint_string):
		return dropdown_prop
	if target_resource is HenSaveParam and prop.name == 'type':
		return dropdown_prop
	return PROPS.get(prop.type)


func normalize_value(target_resource: Resource, prop_name: String, new_val: Variant, type: int) -> Variant:
	var final_val: Variant = new_val
	var current_value: Variant = target_resource.get(prop_name)

	if type == TYPE_INT and new_val is float:
		final_val = int(new_val)
	elif type == TYPE_INT and new_val is String:
		final_val = int(new_val)
	elif type == TYPE_FLOAT and new_val is String:
		final_val = float(new_val)
	elif type == TYPE_VECTOR2 and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR2I and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR3 and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR3I and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_VECTOR4 and new_val is String:
		final_val = str_to_var(new_val)
	elif type == TYPE_COLOR and new_val is String:
		final_val = str_to_var(new_val)
	elif current_value is StringName and new_val is String:
		final_val = StringName(new_val)

	return final_val


func _instantiate_editor(prop_scene: PackedScene, prop: Dictionary) -> Control:
	var editor: Control = prop_scene.instantiate()
	if editor:
		return editor

	var scene_path: String = prop_scene.resource_path if prop_scene else '<null>'
	push_error("Could not instantiate editor scene for prop '%s' (type: %s, hint: '%s') from '%s'." % [prop.name, str(prop.type), str(prop.hint_string), scene_path])
	return null


func _is_dropdown_hint(hint: String) -> bool:
	return DROPDOWN_HINT_TYPES.has(hint)


func _is_tool_button_property(prop: Dictionary) -> bool:
	return prop.type == TYPE_CALLABLE and int(prop.get('hint', PROPERTY_HINT_NONE)) == PROPERTY_HINT_TOOL_BUTTON and bool(prop.usage & PROPERTY_USAGE_EDITOR)


# parses tool button hint string
func _parse_tool_button_hint(prop: Dictionary) -> Dictionary:
	var default_text: String = str(prop.name).capitalize()
	var hint: String = str(prop.get('hint_string', ''))

	if hint.is_empty():
		return {
			text = default_text,
			icon = ''
		}

	var parts: PackedStringArray = hint.split(',', false, 1)
	var text: String = parts[0].strip_edges() if parts.size() > 0 else default_text
	var icon: String = parts[1].strip_edges() if parts.size() > 1 else ''

	if text.is_empty():
		text = default_text

	return {
		text = text,
		icon = icon
	}


func _get_default_title() -> String:
	if not resource:
		return 'Inspector'

	if resource.has_method('get'):
		var resource_name: Variant = resource.get('name')
		if resource_name is String and not (resource_name as String).is_empty():
			return str(resource_name)

	return resource.get_class()


func _create_action_button(action: Dictionary) -> Button:
	if not action is Dictionary:
		return null

	var action_callable: Callable = action.get('callable', Callable())
	if not action_callable.is_valid():
		return null

	var bt := Button.new()
	bt.text = str(action.get('name', 'Action'))
	bt.tooltip_text = str(action.get('tooltip', ''))

	var icon_value: Variant = action.get('icon', null)
	if icon_value is Texture2D:
		bt.icon = icon_value
	elif icon_value is String:
		var icon_res: Resource = load(icon_value)
		if icon_res is Texture2D:
			bt.icon = icon_res as Texture2D

	var color_value: Variant = action.get('color', null)
	if color_value is Color:
		_apply_button_color(bt, color_value as Color)

	bt.pressed.connect(func():
		var args: Variant = action.get('args', [])
		if args is Array and not (args as Array).is_empty():
			action_callable.callv(args)
		elif bool(action.get('pass_resource', false)):
			action_callable.call(resource)
		else:
			action_callable.call()
	)

	return bt


func _apply_button_color(bt: Button, color: Color) -> void:
	bt.self_modulate = color


func _apply_header_panel_style() -> void:
	header_panel.add_theme_stylebox_override('panel', StyleBoxEmpty.new())

# the state whose chain holds the action being edited
func _owner_state(save_data: HenSaveData) -> HenSaveState:
	return HenGeneratorAction.find_state(
		save_data,
		HenActionsPanel.state_id_of(save_data, resource as HenSaveAction)
	) if save_data else null
