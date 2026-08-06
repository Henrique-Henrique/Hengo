@tool
class_name HenActionLine extends RefCounted

const VALUE_SCENE: PackedScene = preload('res://addons/hengo/scenes/action_value.tscn')
const CAPSULE_SCENE: PackedScene = preload('res://addons/hengo/scenes/action_capsule.tscn')
const LABEL_COLOR: Color = Color('#6e7889')


# one chip per part, in reading order; a part fed by another action becomes a
# nested capsule. every text-editable chip lands in sink, which is the tab order
static func fill(_flow: Container, _parts: Array, _depth: int, _sink: Array, _on_chip: Callable) -> void:
	for part: Dictionary in _parts:
		var capsule: Dictionary = part.get('capsule', {})

		if capsule.is_empty():
			var chip: HenActionValue = VALUE_SCENE.instantiate()
			_flow.add_child(chip)
			chip.setup(part)

			if _on_chip.is_valid():
				chip.pressed.connect(_on_chip)

			if chip.is_editable():
				_sink.append(chip)

			continue

		var label: String = str(part.get('label', ''))

		if not label.is_empty():
			_flow.add_child(slot_label(label))

		var nested: HenActionCapsule = CAPSULE_SCENE.instantiate()
		_flow.add_child(nested)
		nested.setup(capsule, _depth + 1, _sink, _on_chip)


static func slot_label(_text: String) -> Label:
	var label := Label.new()
	label.text = _text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeUtils.apply_font_size(label, HenActionValue.LABEL_SIZE)
	label.add_theme_color_override('font_color', LABEL_COLOR)

	return label
