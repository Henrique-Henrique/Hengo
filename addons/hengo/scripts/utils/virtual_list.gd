@tool
class_name HenVirtualList extends Control

@export var item_scene: PackedScene
@export var default_item_height: int = 70

@export var scroll_container: ScrollContainer
@export var content: Control

const Y_PADDING = 20

var _full_data: Array[Dictionary] = []
var _item_nodes: Array[Control] = []
var _layout_cache: Array[Dictionary] = []
var _is_updating: bool = false
var _pending_update: bool = false
var _heights_calculated: Dictionary = {}


func _ready() -> void:
	var v_scroll_bar = scroll_container.get_v_scroll_bar()
	if v_scroll_bar:
		v_scroll_bar.value_changed.connect(_on_scroll_changed)
	scroll_container.resized.connect(_on_scroll_changed)


func _on_scroll_changed(_value: float = 0.0) -> void:
	# prevent race conditions by marking pending update
	if _is_updating:
		_pending_update = true
		return
	_update_visible_items()


func set_data(data: Array[Dictionary]) -> void:
	_full_data = data
	_heights_calculated.clear()
	_build_layout_cache()
	
	var total_height: float = 0.0
	if not _layout_cache.is_empty():
		var last_item_cache = _layout_cache[-1]
		total_height = last_item_cache.y_pos + last_item_cache.height
		
	content.custom_minimum_size.y = total_height
	
	for item in _item_nodes:
		item.queue_free()
	_item_nodes.clear()
	
	# wait one frame to ensure cleanup before rendering
	await get_tree().process_frame
	_update_visible_items()


func _build_layout_cache() -> void:
	_layout_cache.clear()
	var current_y: float = 0.0
	for i in range(_full_data.size()):
		var item_data = _full_data[i]
		var item_height: float = item_data.get('custom_height', default_item_height)
		
		_layout_cache.append({
			height = item_height,
			y_pos = current_y
		})
		current_y += item_height


func _find_first_visible_item_index(scroll_y: float) -> int:
	# binary search for better performance
	var left = 0
	var right = _layout_cache.size() - 1
	
	while left <= right:
		var mid = (left + right) / 2
		var item_cache = _layout_cache[mid]
		
		if item_cache.y_pos + item_cache.height <= scroll_y:
			left = mid + 1
		else:
			right = mid - 1
	
	return max(0, left - 1)


func _update_item_height(index: int, new_height: float) -> void:
	if index >= _layout_cache.size():
		return
	
	var old_height = _layout_cache[index].height
	var height_diff = new_height - old_height
	
	if abs(height_diff) < 0.01:
		return
	
	_layout_cache[index].height = new_height
	_heights_calculated[index] = true
	
	# update positions of all subsequent items
	for i in range(index + 1, _layout_cache.size()):
		_layout_cache[i].y_pos += height_diff
	
	if not _layout_cache.is_empty():
		var last_item_cache = _layout_cache[-1]
		content.custom_minimum_size.y = last_item_cache.y_pos + last_item_cache.height


func _update_visible_items() -> void:
	if _full_data.is_empty() or _is_updating:
		return
	
	_is_updating = true
	_pending_update = false
	
	var scroll_y: float = scroll_container.scroll_vertical
	var viewport_height: float = scroll_container.size.y
	
	# add buffer to prevent visual pop-in
	var buffer: float = default_item_height * 2.0
	var render_start = max(0, scroll_y - buffer)
	var render_end = scroll_y + viewport_height + buffer

	var first_idx: int = _find_first_visible_item_index(render_start)
	
	var visible_items: Array[Dictionary] = []
	
	for i in range(first_idx, _full_data.size()):
		var cache_info = _layout_cache[i]
		
		if cache_info.y_pos > render_end:
			break
		
		visible_items.append({
			"data_idx": i,
			"cache": cache_info
		})
	
	while _item_nodes.size() < visible_items.size():
		var new_item: Control = item_scene.instantiate()
		content.add_child(new_item)
		_item_nodes.append(new_item)
	
	for i in range(visible_items.size()):
		var item_info = visible_items[i]
		var data_idx = item_info.data_idx
		var cache_info = item_info.cache
		var item_node = _item_nodes[i]
		
		item_node.position.y = cache_info.y_pos
		item_node.size.x = content.size.x
		item_node.size.y = cache_info.height
		item_node.visible = true
		
		# only calculate height once per item to avoid flickering
		if not _heights_calculated.has(data_idx):
			if item_node.has_method("set_item_data"):
				item_node.set_item_data(_full_data[data_idx])
				
				await get_tree().process_frame
				
				if item_node and is_instance_valid(item_node):
					var actual_height = item_node.size.y + Y_PADDING
					if actual_height > 0 and abs(actual_height - cache_info.height) > 0.01:
						_update_item_height(data_idx, actual_height)
						item_node.position.y = _layout_cache[data_idx].y_pos
						item_node.size.y = actual_height
		else:
			if item_node.has_method("set_item_data"):
				item_node.set_item_data(_full_data[data_idx])
	
	for i in range(visible_items.size(), _item_nodes.size()):
		_item_nodes[i].visible = false
	
	_is_updating = false
	
	# handle any scroll that happened during update
	if _pending_update:
		call_deferred("_update_visible_items")