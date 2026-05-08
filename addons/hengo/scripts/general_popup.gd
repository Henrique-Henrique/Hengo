@tool
class_name HenGeneralPopup extends Node

const POPUP_CONTAINER_SCENE: PackedScene = preload('res://addons/hengo/scenes/utils/popup_container.tscn')

enum Layout {
	CENTER,
	COMPACT,
	ANCHORED
}

signal closed

var _ui_base: Control
var _popups: Array[HenPopupContainer] = []


func _ready() -> void:
	if _ui_base:
		return

	var global: HenGlobal = Engine.get_singleton(&'Global')
	if global and global.HENGO_ROOT:
		_ui_base = global.HENGO_ROOT.get_node_or_null('%UIBase')


func setup(ui_base: Control) -> void:
	_ui_base = ui_base


# opts (all optional):
#   layout: Layout (default CENTER)
#   anchor_to: Control (required for ANCHORED)
#   side: int SIDE_LEFT/RIGHT/TOP/BOTTOM (default SIDE_RIGHT for ANCHORED)
#   fill_axis: bool (ANCHORED only — fills the axis perpendicular to side using anchor_to's size)
#   offset: Vector2 (default ZERO)
#   pos: Vector2 (overrides anchored placement)
#   min_size: Vector2 (default ZERO)
#   lod: float (default 1.0 for CENTER/COMPACT, 0.0 for ANCHORED)
#   blur: bool (default false — soft blur backdrop, overrides lod styling)
func show_content(content: Control, opts: Dictionary = {}) -> HenPopupContainer:
	if not _ui_base:
		push_error('GeneralPopup singleton is not initialized. Call setup(ui_base) first.')
		return null

	var popup: HenPopupContainer = POPUP_CONTAINER_SCENE.instantiate()
	_ui_base.add_child(popup)
	_popups.append(popup)

	popup.closed.connect(func():
		_on_popup_closed(popup)
	, CONNECT_ONE_SHOT)

	popup.show_content(content, opts)
	return popup


func hide_popup() -> void:
	if _popups.is_empty():
		return

	var popup: HenPopupContainer = _popups[-1]
	if is_instance_valid(popup):
		popup.hide_popup()
	else:
		_popups.pop_back()


func hide_all() -> void:
	while not _popups.is_empty():
		var popup: HenPopupContainer = _popups[-1]
		if is_instance_valid(popup):
			popup.hide_popup()
		else:
			_popups.pop_back()


func _on_popup_closed(popup: HenPopupContainer) -> void:
	var idx: int = _popups.find(popup)
	if idx >= 0:
		_popups.remove_at(idx)

	if is_instance_valid(popup):
		popup.queue_free()

	closed.emit()

	# keep canvas scroll disabled while any popup remains
	if not _popups.is_empty():
		(Engine.get_singleton(&'Global') as HenGlobal).CAM.can_scroll = false
