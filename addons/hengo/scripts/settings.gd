@tool
class_name HenSettings extends Resource

const DEVELOPMENT_MODE_PATH = 'hengo/settings/development_mode'
const MIN_ZOOM_PATH = 'hengo/settings/min_zoom'
const MAX_ZOOM_PATH = 'hengo/settings/max_zoom'
const ZOOM_INCREMENT_PATH = 'hengo/settings/zoom_increment'
const ZOOM_RATE_PATH = 'hengo/settings/zoom_rate'
const DEBUG_COMPILATION_PATH = 'hengo/settings/debug_compilation'
const DOCK_LOCATION_PATH = 'hengo/settings/dock_location'
const FONT_SCALE_PATH = 'hengo/settings/font_scale'
const STATE_ROWS_ZOOM_PATH = 'hengo/settings/state_rows_zoom'
const STATE_LINES_ZOOM_PATH = 'hengo/settings/state_lines_zoom'
const FLOW_WRAP_PATH = 'hengo/settings/flow_wrap'

@export_tool_button('Compile current', 'Build') var compile_current: Callable = _on_compile_current_pressed


@export var debug_compilation: bool:
	set(value):
		_set_value(DEBUG_COMPILATION_PATH, value)
	get:
		return _get_value(DEBUG_COMPILATION_PATH, true)


@export var development_mode: bool:
	set(value):
		_set_value(DEVELOPMENT_MODE_PATH, value)
	get:
		return _get_value(DEVELOPMENT_MODE_PATH, false)

@export_group('Interface')

# multiplies chrome ui font sizes; tuned down for 1080p, applied on reload.
# canvas and states are excluded since they have their own zoom control
@export_range(0.5, 1.5, 0.05) var font_scale: float:
	set(value):
		_set_value(FONT_SCALE_PATH, value)
	get:
		return _get_value(FONT_SCALE_PATH, 0.85)

# off makes a run of actions drop straight down instead of being cut into columns
@export var flow_wrap: bool:
	set(value):
		_set_value(FLOW_WRAP_PATH, value)
	get:
		return _get_value(FLOW_WRAP_PATH, true)

@export_group('Panel')

# re-docks the plugin live: 0 bottom panel, 1 left dock, 2 right dock
@export_enum('Bottom', 'Left', 'Right') var dock_location: int:
	set(value):
		_set_value(DOCK_LOCATION_PATH, value)
		var global: HenGlobal = Engine.get_singleton('Global')
		if global and global.HENGO_EDITOR_PLUGIN:
			global.HENGO_EDITOR_PLUGIN.apply_dock_location(value)
	get:
		return _get_value(DOCK_LOCATION_PATH, 0)

@export_group('Zoom')

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

# below this a node drops its slots and shows only its badge and name
@export_range(0.05, 2.0, 0.05) var state_rows_zoom: float:
	set(value):
		_set_value(STATE_ROWS_ZOOM_PATH, value)
	get:
		return _get_value(STATE_ROWS_ZOOM_PATH, 0.25)

@export_range(0.05, 2.0, 0.05) var state_lines_zoom: float:
	set(value):
		_set_value(STATE_LINES_ZOOM_PATH, value)
	get:
		return _get_value(STATE_LINES_ZOOM_PATH, 0.15)

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
	if global and is_instance_valid(global.get('HENGO_ROOT')):
		HenCam.update_all_settings(global.HENGO_ROOT.get_tree())

	# re-scale the ui live so the factor takes effect without a plugin reload
	if path == FONT_SCALE_PATH and global and is_instance_valid(global.get('HENGO_ROOT')) and global.HENGO_ROOT.has_method('reapply_font_scale'):
		global.HENGO_ROOT.reapply_font_scale()


# gets project setting value
func _get_value(path: String, default: Variant) -> Variant:
	if ProjectSettings.has_setting(path):
		return ProjectSettings.get_setting(path)
	return default


func _property_can_revert(property: StringName) -> bool:
	return property in [
		&'development_mode',
		&'min_zoom',
		&'max_zoom',
		&'zoom_increment',
		&'zoom_rate',
		&'debug_compilation',
		&'dock_location',
		&'font_scale',
		&'state_rows_zoom',
		&'state_lines_zoom'
	]


func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'development_mode':
			return false
		&'min_zoom':
			return 1.0
		&'max_zoom':
			return 2.0
		&'zoom_increment':
			return 0.15
		&'zoom_rate':
			return 12.0
		&'debug_compilation':
			return true
		&'dock_location':
			return 0
		&'font_scale':
			return 0.85
		&'state_rows_zoom':
			return 0.25
		&'state_lines_zoom':
			return 0.15
	return null


func _validate_property(_property: Dictionary) -> void:
	if _property.name in [&'resource_local_to_scene', &'resource_path', &'resource_name']:
		_property.usage = PROPERTY_USAGE_NONE


# compiles the current save
func _on_compile_current_pressed() -> void:
	HenSaver.save()
