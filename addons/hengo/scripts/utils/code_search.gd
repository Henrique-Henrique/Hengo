@tool
class_name HenCodeSearch extends VBoxContainer

const CODE_SEARCH = preload('res://addons/hengo/scenes/code_search.tscn')
const CODE_SEARCH_ITEM = preload('res://addons/hengo/scenes/code_search_item.tscn')

@onready var search_input: LineEdit = %Search

@export var first_list_virtual_list_item: PackedScene

var current_tab: int = 0
var config: Dictionary
var start_pos: Vector2
var categories: Dictionary
var loading_label: Label

func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self ):
		return

	(get_node('%FirstList').get_node('%VirtualList') as HenVirtualList).item_scene = first_list_virtual_list_item

	clear_list()

	search_input.text_changed.connect(_search)

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	signal_bus.request_code_search_show_list.connect(_on_list_request)
	signal_bus.request_code_search_show_categories.connect(_show_custom_categories)
	signal_bus.request_code_search_select.connect(_on_select)

	# deferred because the popup places itself deferred too, and focus taken on the
	# frame the container jumps is dropped
	search_input.grab_focus.call_deferred()

	var thread_helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')
	thread_helper.add_task(_open_categories)


func _show_custom_categories(_list: Array) -> void:
	clear_list()
	set_data.call_deferred(0, _list)


func _search(_text: String) -> void:
	if is_action_mode():
		_search_actions(_text)
		return

	if _text.is_empty():
		return

	var api: HenApi = Engine.get_singleton(&'API')
	var io_type: StringName = config.get(&'io_type', &'')
	var type: StringName = config.get(&'type', &'')

	api.on_search_change(_text, io_type, type)


# --- actions ---

# adding a step filters by the phase it lands on; feeding an input filters by type
func _action_pool() -> Array[HenSaveMacro]:
	var phase: StringName = StringName(str(config.get(&'phase', '')))

	if not phase.is_empty():
		return HenActionPool.for_phase(phase)

	return HenActionPool.producers_for(str(config.get(&'type', '')))


func is_action_mode() -> bool:
	return (config.get(&'on_pick', Callable()) as Callable).is_valid()


# the type the picker is filtering by, empty when opened without a target input
func get_connection_type() -> StringName:
	return config.get(&'type', &'')


# 253 macros filtered in memory: the api search is threaded because the native
# class list is huge, and paying for a thread here would only add a frame
func _search_actions(_text: String) -> void:
	var query: String = _text.strip_edges().to_lower()

	if query.is_empty():
		_open_action_categories()
		return

	var leaves: Array = []

	for macro: HenSaveMacro in _action_pool():
		if HenSearch.score_only(query, macro.name.to_lower()) > 0:
			leaves.append(_action_leaf(macro))

	set_data.call_deferred(1, leaves)


func _open_action_categories() -> void:
	# once per popup: a macro edited meanwhile must not be served from the cache
	HenActionPool.invalidate()

	var groups: Dictionary = {}

	for macro: HenSaveMacro in _action_pool():
		var folder: String = macro.category if not macro.category.is_empty() else 'user'

		if not groups.has(folder):
			groups[folder] = []

		(groups[folder] as Array).append(_action_leaf(macro))

	var entries: Array = []

	for folder: String in HenActionCategories.sorted(groups.keys()):
		var data: Dictionary = HenActionCategories.get_data(folder)

		entries.append({
			name = str(data.name),
			icon = str(data.icon),
			color = Color(str(data.color)),
			method_list = groups[folder]
		})

	set_data.call_deferred(0, [{_class_name = 'Actions', categories = entries}])
	set_data.call_deferred(1, [])


# force_valid is what makes the row select instead of drilling in, and
# recursive_props is what opens the third column: an action with two usable
# outputs asks which one feeds the input instead of silently taking the first
func _action_leaf(_macro: HenSaveMacro) -> Dictionary:
	var outputs: Array = HenActionPool.outputs_for(_macro, str(config.get(&'type', '')))

	if outputs.size() > 1:
		var branches: Array = []

		for output: Dictionary in outputs:
			branches.append({
				name = str(output.name),
				_class_name = str(output.type),
				force_valid = true,
				action_macro = _macro,
				output_id = str(output.id)
			})

		return {
			name = _macro.name,
			_class_name = _macro.category,
			action_macro = _macro,
			recursive_props = branches
		}

	return {
		name = _macro.name,
		_class_name = _macro.category,
		force_valid = true,
		action_macro = _macro,
		output_id = str(outputs[0].id) if not outputs.is_empty() else ''
	}

func clear_list() -> void:
	pass


func _on_list_request(_list: Array, _list_id: int = 1) -> void:
	set_data.call_deferred(_list_id, _list)


func _open_categories() -> void:
	if is_action_mode():
		call_deferred(&'_open_action_categories')
		return

	var json: JSON = load('res://addons/hengo/resources/json/api_categories.json')
	categories = json.data
	call_deferred("update")


func set_data(_virtual_list_id: int, _api_list: Array) -> void:
	var virtual_list: HenVirtualList

	var first_list: ScrollContainer = get_node('%FirstList')
	var second_list: ScrollContainer = get_node('%SecondList')
	var third_list: ScrollContainer = get_node('%ThirdList')

	match _virtual_list_id:
		0:
			virtual_list = first_list.get_node('%VirtualList')
			first_list.visible = true
			second_list.visible = false
			third_list.visible = false
		1:
			virtual_list = second_list.get_node('%VirtualList')
			first_list.visible = true
			second_list.visible = not _api_list.is_empty()
			third_list.visible = false
		2:
			virtual_list = third_list.get_node('%VirtualList')
			first_list.visible = true
			second_list.visible = true
			third_list.visible = not _api_list.is_empty()

	if virtual_list: virtual_list.set_data(_api_list)

	match _virtual_list_id:
		1, 2:
			await get_tree().process_frame
			(first_list.get_node('%VirtualList') as HenVirtualList).update.call_deferred(true)
			(second_list.get_node('%VirtualList') as HenVirtualList).update.call_deferred(true)
			(third_list.get_node('%VirtualList') as HenVirtualList).update.call_deferred(true)


# actions are the only thing this picker offers now
func _on_select(_data: Dictionary) -> void:
	var macro: Variant = _data.get(&'action_macro')

	if not is_action_mode() or not macro is HenSaveMacro:
		return

	(config.on_pick as Callable).call(macro as HenSaveMacro, StringName(str(_data.get(&'output_id', ''))))
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()


static func load(_start_pos: Vector2, _config: Dictionary = {}) -> HenCodeSearch:
	var code_search: HenCodeSearch = CODE_SEARCH.instantiate()

	code_search.current_tab = 0
	code_search.start_pos = _start_pos
	code_search.config = _config

	(Engine.get_singleton(&'Global') as HenGlobal).CODE_SEARCH = code_search

	return code_search
