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
const MIN_ZOOM_PATH = 'hengo/settings/min_zoom'
const MAX_ZOOM_PATH = 'hengo/settings/max_zoom'
const ZOOM_INCREMENT_PATH = 'hengo/settings/zoom_increment'
const ZOOM_RATE_PATH = 'hengo/settings/zoom_rate'


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

@export_group('Move')

@export var auto_move: bool:
	set(value):
		_set_value(AUTO_MOVE_PATH, value)
	get:
		return _get_value(AUTO_MOVE_PATH, true)

@export var auto_move_on_add: bool:
	set(value):
		_set_value(AUTO_MOVE_ON_ADD_PATH, value)
	get:
		return _get_value(AUTO_MOVE_ON_ADD_PATH, true)

@export var auto_move_on_remove: bool:
	set(value):
		_set_value(AUTO_MOVE_ON_REMOVE_PATH, value)
	get:
		return _get_value(AUTO_MOVE_ON_REMOVE_PATH, false)

@export var auto_move_on_connection: bool:
	set(value):
		_set_value(AUTO_MOVE_ON_CONNECTION_PATH, value)
	get:
		return _get_value(AUTO_MOVE_ON_CONNECTION_PATH, true)

@export_group('Zoom')

@export var auto_zoom: bool:
	set(value):
		_set_value(AUTO_ZOOM_PATH, value)
	get:
		return _get_value(AUTO_ZOOM_PATH, true)

@export_range(1, 2, 0.1) var auto_zoom_level: float:
	set(value):
		_set_value(AUTO_ZOOM_LEVEL_PATH, value)
	get:
		return _get_value(AUTO_ZOOM_LEVEL_PATH, 1.7)

@export_range(0.1, 10, 0.1) var min_zoom: float:
	set(value):
		_set_value(MIN_ZOOM_PATH, value)
	get:
		return _get_value(MIN_ZOOM_PATH, 1.0)

@export_range(0.1, 10, 0.1) var max_zoom: float:
	set(value):
		_set_value(MAX_ZOOM_PATH, value)
	get:
		return _get_value(MAX_ZOOM_PATH, 2.0)

@export_range(0.01, 1.0, 0.01) var zoom_increment: float:
	set(value):
		_set_value(ZOOM_INCREMENT_PATH, value)
	get:
		return _get_value(ZOOM_INCREMENT_PATH, 0.15)

@export_range(1.0, 50.0, 1.0) var zoom_rate: float:
	set(value):
		_set_value(ZOOM_RATE_PATH, value)
	get:
		return _get_value(ZOOM_RATE_PATH, 12.0)


# sets project setting value
func _set_value(path: String, value: Variant) -> void:
	ProjectSettings.set_setting(path, value)
	ProjectSettings.save()
	emit_changed()
	
	var global: HenGlobal = Engine.get_singleton('Global')
	if global and global.get("CAM") and global.CAM.has_method("update_settings"):
		global.CAM.update_settings()


# gets project setting value
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
		&'auto_zoom_level',
		&'min_zoom',
		&'max_zoom',
		&'zoom_increment',
		&'zoom_rate'
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
			return false
		&'auto_move_on_connection':
			return true
		&'auto_zoom_level':
			return 1.7
		&'min_zoom':
			return 1.0
		&'max_zoom':
			return 2.0
		&'zoom_increment':
			return 0.15
		&'zoom_rate':
			return 12.0
	return null


func _validate_property(_property: Dictionary) -> void:
	if _property.name in [&'resource_local_to_scene', &'resource_path', &'resource_name']:
		_property.usage = PROPERTY_USAGE_NONE