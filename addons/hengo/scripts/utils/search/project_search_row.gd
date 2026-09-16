@tool
class_name HenProjectSearchRow extends PanelContainer

const SELECTED_BG: Color = Color(1, 1, 1, 0.06)
const IDLE_BG: Color = Color(1, 1, 1, 0)
const TITLE_COLOR: Color = Color('#e6ebf2')
const MUTED_COLOR: Color = Color('#7d8796')
const DISABLED_ALPHA: float = 0.5

@onready var _icon_box: PanelContainer = %IconBox
@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _context: Label = %Context
@onready var _detail: Label = %Detail
@onready var _phase_chip: PanelContainer = %PhaseChip
@onready var _phase: Label = %Phase
@onready var _kind: Label = %Kind

var index: int = -1
var _view: WeakRef
var _style: StyleBoxFlat = StyleBoxFlat.new()
var _icon_style: StyleBoxFlat = StyleBoxFlat.new()
var _phase_style: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return

	_style.bg_color = IDLE_BG
	_style.set_corner_radius_all(8)
	add_theme_stylebox_override('panel', _style)

	_icon_style.set_corner_radius_all(6)
	_icon_box.add_theme_stylebox_override('panel', _icon_style)

	_phase_style.set_corner_radius_all(4)
	_phase_style.content_margin_left = 6
	_phase_style.content_margin_right = 6
	_phase_style.content_margin_top = 1
	_phase_style.content_margin_bottom = 1
	_phase_chip.add_theme_stylebox_override('panel', _phase_style)

	ThemeUtils.apply_font_size(_title, 14)
	ThemeUtils.apply_font_size(_context, 11)
	ThemeUtils.apply_font_size(_detail, 11)
	ThemeUtils.apply_font_size(_phase, 10)
	ThemeUtils.apply_font_size(_kind, 10)

	_title.add_theme_color_override('font_color', TITLE_COLOR)
	_context.add_theme_color_override('font_color', MUTED_COLOR)
	_detail.add_theme_color_override('font_color', MUTED_COLOR)

	gui_input.connect(_on_gui_input)


func set_item_data(_data: Dictionary) -> void:
	var record: Dictionary = _data.record
	var kind: String = str(record.kind)
	var kind_color: Color = Color(str(HenSearchIndex.KIND_COLORS.get(kind, '#9fb2c7')))
	var accent: Color = Color(str(record.color)) if not str(record.color).is_empty() else kind_color

	index = _data.index
	_view = weakref(_data.view)

	_title.text = str(record.title)
	_context.text = str(record.context)
	_context.visible = not _context.text.is_empty()
	_detail.text = str(record.detail)
	_detail.visible = not _detail.text.is_empty()

	var phase: StringName = StringName(str(record.phase))
	var phase_color: Color = HenActionVisuals.phase_color(phase)

	_phase_chip.visible = not phase.is_empty()
	_phase.text = HenActionVisuals.phase_label(phase)
	_phase.add_theme_color_override('font_color', phase_color)
	_phase_style.bg_color = Color(phase_color, 0.12)

	if not str(record.class_icon).is_empty():
		_icon.texture = HenUtils.get_icon_texture(StringName(str(record.class_icon)))
		accent = HenUtils.get_type_parent_color(str(record.class_icon), 1., Color.WHITE).lightened(.3)
	else:
		_icon.texture = HenActionVisuals.icon_texture(str(record.icon))

	_icon.modulate = accent
	_icon_style.bg_color = Color(accent, 0.14)

	_kind.text = str(HenSearchIndex.KIND_LABELS.get(kind, kind)).to_upper()
	_kind.add_theme_color_override('font_color', Color(kind_color, 0.8))

	modulate.a = DISABLED_ALPHA if record.get('disabled', false) else 1.0

	var view: HenProjectSearch = _view.get_ref() as HenProjectSearch

	set_selected(view != null and view.selected_index == index)


func set_selected(_selected: bool) -> void:
	_style.bg_color = SELECTED_BG if _selected else IDLE_BG


# motion and not mouse_entered, which also fires when the arrows scroll the list under a still cursor
func _on_gui_input(_event: InputEvent) -> void:
	var view: HenProjectSearch = _view.get_ref() as HenProjectSearch if _view else null

	if not view:
		return

	if _event is InputEventMouseMotion:
		view.hover_index(index)
	elif _event is InputEventMouseButton and (_event as InputEventMouseButton).pressed \
			and (_event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		view.pick_index(index)
