@tool
class_name HenSettings extends Resource

const DEVELOPMENT_MODE_PATH = 'hengo/settings/development_mode'
const AUTO_LAYOUT_PATH = 'hengo/settings/auto_layout'
const AUTO_MOVE_PATH = 'hengo/settings/auto_move'
const AUTO_ZOOM_PATH = 'hengo/settings/auto_zoom'


@export var development_mode: bool:
	set(value):
		_set_value(DEVELOPMENT_MODE_PATH, value)
	get:
		return _get_value(DEVELOPMENT_MODE_PATH, false)

@export var auto_layout: bool:
	set(value):
		_set_value(AUTO_LAYOUT_PATH, value)
	get:
		return _get_value(AUTO_LAYOUT_PATH, true)

@export var auto_move: bool:
	set(value):
		_set_value(AUTO_MOVE_PATH, value)
	get:
		return _get_value(AUTO_MOVE_PATH, true)

@export var auto_zoom: bool:
	set(value):
		_set_value(AUTO_ZOOM_PATH, value)
	get:
		return _get_value(AUTO_ZOOM_PATH, true)


# sets a value in project settings and saves it
func _set_value(path: String, value: Variant) -> void:
	ProjectSettings.set_setting(path, value)
	ProjectSettings.save()
	emit_changed()


# gets a value from project settings or returns default if not present
func _get_value(path: String, default: Variant) -> Variant:
	if ProjectSettings.has_setting(path):
		return ProjectSettings.get_setting(path)
	return default


func _property_can_revert(property: StringName) -> bool:
	return property in [
		&'development_mode',
		&'auto_layout',
		&'auto_move',
		&'auto_zoom'
	]


func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'development_mode':
			return false
		&'auto_layout':
			return true
		&'auto_move':
			return true
		&'auto_zoom':
			return true
	return null


func _validate_property(_property: Dictionary) -> void:
	if _property.name in [&'resource_local_to_scene', &'resource_path', &'resource_name']:
		_property.usage = PROPERTY_USAGE_NONE