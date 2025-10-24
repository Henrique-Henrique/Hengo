@tool
class_name HenVirtualList extends Control

@export var item_scene: PackedScene
# default height if an item in data does not specify one
@export var default_item_height: int = 50

@export var scroll_container: ScrollContainer
@export var content: Control

var _full_data: Array[Dictionary] = []
var _item_nodes: Array[Control] = []
# cache to store each items height and position
# format height float y_pos float
var _layout_cache: Array[Dictionary] = []


func _ready() -> void:
    var v_scroll_bar = scroll_container.get_v_scroll_bar()
    if v_scroll_bar:
        v_scroll_bar.value_changed.connect(_update_visible_items)
    scroll_container.resized.connect(_update_visible_items)

# public function to populate the list with data
func set_data(data: Array[Dictionary]) -> void:
    _full_data = data
    _build_layout_cache() # new and crucial step
    
    # total height now comes from the cache
    var total_height: float = 0.0
    if not _layout_cache.is_empty():
        var last_item_cache = _layout_cache[-1]
        total_height = last_item_cache.y_pos + last_item_cache.height
        
    content.custom_minimum_size.y = total_height
    
    # clear old nodes
    for item in _item_nodes:
        item.queue_free()
    _item_nodes.clear()
    
    _update_visible_items()

# precalculates and stores the position and height of each item
func _build_layout_cache() -> void:
    _layout_cache.clear()
    var current_y: float = 0.0
    for item_data in _full_data:
        # this is where you determine the height
        # we are getting it from a custom_height field in the data
        var item_height: float = item_data.get("altura_customizada", default_item_height)
        
        _layout_cache.append({
            "height": item_height,
            "y_pos": current_y
        })
        current_y += item_height

# finds the index of the item that should be at a given y position
# note for very large lists a binary search here would be more performant
func _find_first_visible_item_index(scroll_y: float) -> int:
    for i in range(_layout_cache.size()):
        var item_cache = _layout_cache[i]
        # if the end of this item is after the start of the screen it is a candidate
        if (item_cache.y_pos + item_cache.height) > scroll_y:
            return i
    return 0 # fallback

func _update_visible_items(_value: float = 0.0) -> void:
    if _full_data.is_empty():
        return

    var scroll_y: float = scroll_container.scroll_vertical
    var viewport_height: float = scroll_container.get_viewport_rect().size.y

    # finds the start index using our cache search function
    var first_idx: int = _find_first_visible_item_index(scroll_y)
    
    var current_item_idx_in_pool = 0
    
    # iterate from the first visible item until the screen is filled
    for i in range(first_idx, _full_data.size()):
        var data_idx = i
        var cache_info = _layout_cache[data_idx]
        
        # if the item started below the end of the screen we can stop
        if cache_info.y_pos > scroll_y + viewport_height:
            break

        # ensures we have enough nodes in the pool
        if current_item_idx_in_pool >= _item_nodes.size():
            var new_item: Control = item_scene.instantiate()
            _item_nodes.append(new_item)
            content.add_child(new_item)
        
        var item_node = _item_nodes[current_item_idx_in_pool]
        item_node.visible = true
        
        # update the content
        if item_node.has_method("set_item_data"):
            item_node.set_item_data(_full_data[data_idx])
        
        # position and resize using the cache
        item_node.position.y = cache_info.y_pos
        item_node.size.x = content.size.x
        item_node.size.y = cache_info.height
        
        current_item_idx_in_pool += 1

    # hide remaining nodes in the pool that were not used
    for i in range(current_item_idx_in_pool, _item_nodes.size()):
        _item_nodes[i].visible = false