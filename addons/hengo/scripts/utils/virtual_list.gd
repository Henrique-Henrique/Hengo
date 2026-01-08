@tool
class_name HenVirtualList extends Control

@export var item_scene: PackedScene

@export var scroll_container: ScrollContainer
@export var content: Control

const Y_PADDING = 20
var default_item_height: float = 50.0

var _full_data: Array = []
var _item_nodes: Array[Control] = []
var _layout_cache: Array[Dictionary] = []
var _is_updating: bool = false
var _pending_update: bool = false
var _heights_calculated: Dictionary = {}
var _last_width: float = 0.0


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	
	default_item_height = HenUtils.get_scaled_size(50)

	var v_scroll_bar: VScrollBar = scroll_container.get_v_scroll_bar()
	if v_scroll_bar:
		v_scroll_bar.value_changed.connect(_on_scroll_changed)
	scroll_container.resized.connect(_on_scroll_changed)


# prevent race conditions by marking pending update
func _on_scroll_changed(_value: float = 0.0) -> void:
	if _is_updating:
		_pending_update = true
		return
	
	_update_visible_items()


func update(force_recalc: bool = false) -> void:
	if force_recalc:
		_heights_calculated.clear()
		_last_width = 0.0
		# rebuild cache to ensure fresh positions
		_build_layout_cache()
	
	_on_scroll_changed()


func set_data(data: Array) -> void:
	_full_data = data
	_heights_calculated.clear()
	_build_layout_cache()
	
	modulate.a = 0.0
	
	var total_height: float = 0.0
	if not _layout_cache.is_empty():
		var last_item_cache: Dictionary = _layout_cache[-1]
		total_height = last_item_cache.y_pos + last_item_cache.height
		
	content.custom_minimum_size.y = total_height
	
	for item in _item_nodes:
		item.queue_free()
	_item_nodes.clear()
	
	# wait one frame to ensure cleanup before rendering
	await get_tree().process_frame
	_update_visible_items()


# build cache for fast scroll access
func _build_layout_cache() -> void:
	_layout_cache.clear()
	var current_y: float = 0.0
	for i in range(_full_data.size()):
		var item_data: Dictionary = _full_data[i]
		var item_height: float = item_data.get('custom_height', default_item_height)
		
		_layout_cache.append({
			height = item_height,
			y_pos = current_y
		})
		current_y += item_height


# binary search for better performance
func _find_first_visible_item_index(scroll_y: float) -> int:
	var left: int = 0
	var right: int = _layout_cache.size() - 1
	
	while left <= right:
		var mid: int = (left + right) / 2
		var item_cache: Dictionary = _layout_cache[mid]
		
		if item_cache.y_pos + item_cache.height <= scroll_y:
			left = mid + 1
		else:
			right = mid - 1
	
	return max(0, left - 1)


func _update_item_height(index: int, new_height: float) -> void:
	if index >= _layout_cache.size():
		return
	
	var old_height: float = _layout_cache[index].height
	var height_diff: float = new_height - old_height
	
	if abs(height_diff) < 0.01:
		return
	
	_layout_cache[index].height = new_height
	_heights_calculated[index] = true
	
	# update positions of all subsequent items
	for i in range(index + 1, _layout_cache.size()):
		_layout_cache[i].y_pos += height_diff
	
	if not _layout_cache.is_empty():
		var last_item_cache: Dictionary = _layout_cache[-1]
		content.custom_minimum_size.y = last_item_cache.y_pos + last_item_cache.height


func _update_visible_items() -> void:
	if _full_data.is_empty() or _is_updating:
		return
	
	_is_updating = true
	_pending_update = false
	
	var scroll_y: float = scroll_container.scroll_vertical
	var viewport_height: float = scroll_container.size.y
	
	# calculate available width minus scrollbar
	var available_width: float = scroll_container.size.x
	var v_scroll: VScrollBar = scroll_container.get_v_scroll_bar()
	if v_scroll and v_scroll.visible:
		available_width -= v_scroll.size.x
	
	# detect significant width change (resize)
	if abs(available_width - _last_width) > 0.1:
		_last_width = available_width
		_heights_calculated.clear()
		_build_layout_cache()
		modulate.a = 0.0
	
	# buffer logic
	var buffer: float = default_item_height * 2.0
	var render_start: float = max(0, scroll_y - buffer)
	var render_end: float = scroll_y + viewport_height + buffer

	var first_idx: int = _find_first_visible_item_index(render_start)
	var visible_items: Array[Dictionary] = []
	
	for i in range(first_idx, _full_data.size()):
		var cache_info: Dictionary = _layout_cache[i]
		if cache_info.y_pos > render_end:
			break
		visible_items.append({'data_idx': i, 'cache': cache_info})
	
	# pool management
	while _item_nodes.size() < visible_items.size():
		var new_item: Control = item_scene.instantiate()
		new_item.set_anchors_preset(Control.PRESET_TOP_LEFT)
		
		content.add_child(new_item)
		_item_nodes.append(new_item)
	
	for i in range(visible_items.size(), _item_nodes.size()):
		_item_nodes[i].visible = false
	
	var needs_recalculation: bool = false
	
	for i in range(visible_items.size()):
		var item_node: Control = _item_nodes[i]
		var cache_info: Dictionary = visible_items[i].cache
		var data_idx: int = visible_items[i].data_idx
		
		item_node.visible = true
		item_node.position.y = cache_info.y_pos
		item_node.custom_minimum_size.y = 0
		item_node.size.y = 0
		item_node.custom_minimum_size.x = available_width
		item_node.size.x = available_width
		
		if item_node.has_method('set_item_data'):
			item_node.set_item_data(_full_data[data_idx])
		
		if not _heights_calculated.has(data_idx):
			needs_recalculation = true
		else:
			item_node.size.y = cache_info.height

	if needs_recalculation:
		var max_retries: int = 5
		
		for attempt in range(max_retries):
			await RenderingServer.frame_pre_draw
			
			if _item_nodes.is_empty() or _pending_update:
				_is_updating = false
				if _pending_update:
					call_deferred('_update_visible_items')
				return

			var correction_offset: float = 0.0
			var all_calculated: bool = true
			
			for i in range(visible_items.size()):
				var item_node: Control = _item_nodes[i]
				var data_idx: int = visible_items[i].data_idx
				
				if correction_offset > 0.0:
					item_node.position.y += correction_offset

				var real_height: float = item_node.get_combined_minimum_size().y + Y_PADDING
				var cached_height: float = _layout_cache[data_idx].height
				
				if abs(real_height - cached_height) > 0.1:
					_update_item_height(data_idx, real_height)
					item_node.size.y = real_height
					correction_offset += (real_height - cached_height)
				elif not _heights_calculated.has(data_idx):
					if attempt == max_retries - 1:
						_heights_calculated[data_idx] = true
					else:
						all_calculated = false
			
			if all_calculated:
				break
	
	# only fade in if we are not pending another immediate update
	if modulate.a < 1.0 and not _pending_update:
		var tween: Tween = create_tween()
		tween.tween_property(self, 'modulate:a', 1.0, 0.25)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)

	_is_updating = false
	if _pending_update:
		call_deferred('_update_visible_items')