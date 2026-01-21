@tool
class_name HenSettings extends Resource

const DEVELOPMENT_MODE_PATH = 'hengo/settings/development_mode'
const AUTO_LAYOUT_PATH = 'hengo/settings/auto_layout'
const AUTO_MOVE_PATH = 'hengo/settings/auto_move'
const AUTO_ZOOM_PATH = 'hengo/settings/auto_zoom'
const AUTO_MOVE_ON_ADD_PATH = 'hengo/settings/auto_move_on_add'
const AUTO_MOVE_ON_REMOVE_PATH = 'hengo/settings/auto_move_on_remove'
const AUTO_MOVE_ON_CONNECTION_PATH = 'hengo/settings/auto_move_on_connection'
const AUTO_ZOOM_LEVEL_PATH = 'hengo/settings/auto_zoom_level_v2'


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

@export var auto_move_on_add: bool:
	set(value):
		_set_value(AUTO_MOVE_ON_ADD_PATH, value)
	get:
		return _get_value(AUTO_MOVE_ON_ADD_PATH, true)

@export var auto_move_on_remove: bool:
	set(value):
		_set_value(AUTO_MOVE_ON_REMOVE_PATH, value)
	get:
		return _get_value(AUTO_MOVE_ON_REMOVE_PATH, true)

@export var auto_move_on_connection: bool:
	set(value):
		_set_value(AUTO_MOVE_ON_CONNECTION_PATH, value)
	get:
		return _get_value(AUTO_MOVE_ON_CONNECTION_PATH, true)

@export_range(HenCam.MIN_ZOOM, 2, 0.1) var auto_zoom_level: float:
	set(value):
		_set_value(AUTO_ZOOM_LEVEL_PATH, value)
	get:
		return _get_value(AUTO_ZOOM_LEVEL_PATH, 1.7)


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
		&'auto_zoom',
		&'auto_move_on_add',
		&'auto_move_on_remove',
		&'auto_move_on_connection',
		&'auto_zoom_level'
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
		&'auto_move_on_add':
			return true
		&'auto_move_on_remove':
			return true
		&'auto_move_on_connection':
			return true
		&'auto_zoom_level':
			return 1.7
	return null


func _validate_property(_property: Dictionary) -> void:
	if _property.name in [&'resource_local_to_scene', &'resource_path', &'resource_name']:
		_property.usage = PROPERTY_USAGE_NONE