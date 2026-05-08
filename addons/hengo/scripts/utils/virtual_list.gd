@tool
class_name HenVirtualList extends Control

@export var item_scene: PackedScene
@export var scroll_container: ScrollContainer
@export var content: Control

const Y_PADDING: float = 20.0
const HEIGHT_EPSILON: float = 0.5
const WIDTH_EPSILON: float = 1.0

var default_item_height: float = 50.0

var _full_data: Array = []
var _item_pool: Array[Control] = []
var _active_items: Dictionary = {}
var _layout: Array[Dictionary] = []
var _measured: Dictionary = {}
var _last_width: float = -1.0
var _update_scheduled: bool = false
var _measure_scheduled: bool = false


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	default_item_height = HenUtils.get_scaled_size(50)

	var v_scroll: VScrollBar = scroll_container.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value_changed.connect(_on_scroll_or_resize)
	scroll_container.resized.connect(_on_scroll_or_resize)


func _on_scroll_or_resize(_value: float = 0.0) -> void:
	_request_update()


func set_data(data: Array) -> void:
	_full_data = data
	_measured.clear()

	# release every active item back to the pool
	for n: Control in _active_items.values():
		if is_instance_valid(n):
			n.visible = false
			_item_pool.append(n)
	_active_items.clear()

	_build_layout()
	_update_content_size()

	scroll_container.scroll_vertical = 0
	_request_update()


func update(force_recalc: bool = false) -> void:
	if force_recalc:
		_measured.clear()
		_last_width = -1.0
		_build_layout()
		_update_content_size()
	_request_update()


func _request_update() -> void:
	if _update_scheduled or not is_inside_tree():
		return
	_update_scheduled = true
	_do_update.call_deferred()


func _request_measure() -> void:
	if _measure_scheduled or not is_inside_tree():
		return
	_measure_scheduled = true
	_measure_pass.call_deferred()


func _build_layout() -> void:
	_layout.clear()
	var y: float = 0.0
	for i: int in range(_full_data.size()):
		var item_value: Variant = _full_data[i]
		var h: float = default_item_height
		if _measured.has(i):
			h = _measured[i]
		elif item_value is Dictionary and (item_value as Dictionary).has('custom_height'):
			h = (item_value as Dictionary).custom_height
		_layout.append({height = h, y_pos = y})
		y += h


func _update_content_size() -> void:
	if _layout.is_empty():
		content.custom_minimum_size.y = 0
		return
	var last: Dictionary = _layout[-1]
	content.custom_minimum_size.y = last.y_pos + last.height


func _get_content_width() -> float:
	var w: float = scroll_container.size.x
	var v: VScrollBar = scroll_container.get_v_scroll_bar()
	if v and v.visible:
		w -= v.size.x
	return max(0.0, w)


func _find_first_visible(scroll_y: float) -> int:
	var lo: int = 0
	var hi: int = _layout.size() - 1
	while lo <= hi:
		var mid: int = (lo + hi) / 2
		var info: Dictionary = _layout[mid]
		if info.y_pos + info.height <= scroll_y:
			lo = mid + 1
		else:
			hi = mid - 1
	return max(0, lo - 1)


func _do_update() -> void:
	_update_scheduled = false

	if not is_inside_tree():
		return

	var width: float = _get_content_width()
	if abs(width - _last_width) > WIDTH_EPSILON:
		# only invalidate if we already had measured heights, since width affects wrapping
		if _last_width >= 0.0 and not _measured.is_empty():
			_measured.clear()
			_build_layout()
			_update_content_size()
		_last_width = width

	if _full_data.is_empty():
		for n: Control in _active_items.values():
			if is_instance_valid(n):
				n.visible = false
				_item_pool.append(n)
		_active_items.clear()
		return

	var scroll_y: float = scroll_container.scroll_vertical
	var view_h: float = scroll_container.size.y
	var buffer: float = max(view_h * 0.5, default_item_height * 2.0)
	var top: float = max(0.0, scroll_y - buffer)
	var bottom: float = scroll_y + view_h + buffer

	var first_idx: int = _find_first_visible(top)
	var visible_set: Dictionary = {}
	for i: int in range(first_idx, _full_data.size()):
		if _layout[i].y_pos > bottom:
			break
		visible_set[i] = true

	for idx: int in _active_items.keys():
		if not visible_set.has(idx):
			var released: Control = _active_items[idx]
			if is_instance_valid(released):
				released.visible = false
				_item_pool.append(released)
			_active_items.erase(idx)

	var any_unmeasured: bool = false
	for idx: int in visible_set.keys():
		var bind_data: bool = not _active_items.has(idx)
		var n: Control
		if bind_data:
			n = _acquire_item()
			_active_items[idx] = n
		else:
			n = _active_items[idx]

		n.visible = true
		_place_item(n, idx, width)

		if bind_data and n.has_method('set_item_data'):
			n.set_item_data(_full_data[idx])

		if not _measured.has(idx):
			any_unmeasured = true

	if any_unmeasured:
		_request_measure()


func _acquire_item() -> Control:
	while not _item_pool.is_empty():
		var pooled: Control = _item_pool.pop_back()
		if is_instance_valid(pooled):
			return pooled
	var new_item: Control = item_scene.instantiate()
	new_item.set_anchors_preset(Control.PRESET_TOP_LEFT)
	content.add_child(new_item)
	return new_item


func _place_item(n: Control, idx: int, width: float) -> void:
	var info: Dictionary = _layout[idx]
	n.position = Vector2(0, info.y_pos)
	n.custom_minimum_size.x = width
	n.size.x = width
	if _measured.has(idx):
		n.size.y = info.height


func _measure_pass() -> void:
	_measure_scheduled = false

	if not is_inside_tree() or _full_data.is_empty():
		return

	var width: float = _get_content_width()
	var changed: bool = false

	for idx: int in _active_items.keys():
		var n: Control = _active_items[idx]
		if not is_instance_valid(n) or not n.visible:
			continue
		var min_h: float = n.get_combined_minimum_size().y
		if min_h <= 0.0:
			continue
		var real_h: float = min_h + Y_PADDING
		var current: float = _measured.get(idx, -1.0)
		if abs(current - real_h) > HEIGHT_EPSILON:
			_measured[idx] = real_h
			changed = true

	if not changed:
		return

	_build_layout()
	_update_content_size()
	for idx: int in _active_items.keys():
		var n: Control = _active_items[idx]
		if is_instance_valid(n):
			_place_item(n, idx, width)
	_request_update()
