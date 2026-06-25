@tool
class_name HenLoadingOverlay extends ColorRect

const SHOW_THRESHOLD_S: float = 0.250
const SPIN_SPEED: float = 4.0

const _BLUR_LOD: float = 3.0
const _BLUR_TRANS: float = 0.5
const _BLUR_COLOR: Color = Color(0, 0, 0, 1)
const _FADE_DURATION: float = 0.35

@onready var _label: Label = %MessageLabel
@onready var _spinner: TextureRect = %SpinnerTex

var _active_sources: Dictionary = {}
var _pending_timer: SceneTreeTimer = null
var _hide_tween: Tween = null


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_setup_blur_shader()

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if signal_bus:
		signal_bus.scripts_generation_started.connect(_on_generation_started)
		signal_bus.scripts_generation_finished.connect(_on_generation_finished)


func _setup_blur_shader() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload('res://addons/hengo/assets/shaders/blur.gdshader')
	mat.set_shader_parameter('lod', _BLUR_LOD)
	mat.set_shader_parameter('color', _BLUR_COLOR)
	mat.set_shader_parameter('transparency', _BLUR_TRANS)
	material = mat
	color = Color.TRANSPARENT


func _on_generation_started() -> void:
	show_loading('Compiling...', &'generation')


func _on_generation_finished(_paths: PackedStringArray = PackedStringArray()) -> void:
	hide_loading(&'generation')


func _process(_delta: float) -> void:
	if _spinner:
		_spinner.rotation += _delta * SPIN_SPEED
		_spinner.pivot_offset = _spinner.size / 2.0


func show_loading(_text: String, _source_id: StringName, _immediate: bool = false) -> void:
	_active_sources[_source_id] = _text
	if _label:
		_label.text = _text

	if _hide_tween and _hide_tween.is_valid():
		_hide_tween.kill()
		_hide_tween = null

	if visible:
		_reset_shader_params()
		return

	if _immediate:
		_show_now()
		return

	if _pending_timer != null:
		return
	var tree: SceneTree = get_tree()
	if not tree:
		return
	_pending_timer = tree.create_timer(SHOW_THRESHOLD_S)
	_pending_timer.timeout.connect(_on_threshold_elapsed, CONNECT_ONE_SHOT)


func hide_loading(_source_id: StringName) -> void:
	_active_sources.erase(_source_id)
	if not _active_sources.is_empty():
		if _label:
			_label.text = _active_sources.values()[0]
		return

	_pending_timer = null
	if not visible:
		set_process(false)
		return

	var tree: SceneTree = get_tree()
	if not tree:
		visible = false
		set_process(false)
		return

	_hide_tween = tree.create_tween()
	_hide_tween.set_parallel(true)
	_hide_tween.tween_method(_set_lod, _get_lod(), 0.0, _FADE_DURATION)
	_hide_tween.tween_method(_set_trans, _get_trans(), 0.0, _FADE_DURATION)
	_hide_tween.chain().tween_callback(func():
		visible = false
		set_process(false)
		_hide_tween = null
	)


func _on_threshold_elapsed() -> void:
	_pending_timer = null
	if _active_sources.is_empty():
		return
	_show_now()


func _show_now() -> void:
	_reset_shader_params()
	visible = true
	set_process(true)


func _reset_shader_params() -> void:
	if material is ShaderMaterial:
		var m: ShaderMaterial = material as ShaderMaterial
		m.set_shader_parameter('lod', _BLUR_LOD)
		m.set_shader_parameter('transparency', _BLUR_TRANS)


func _set_lod(_v: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter('lod', _v)


func _set_trans(_v: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter('transparency', _v)


func _get_lod() -> float:
	if material is ShaderMaterial:
		return (material as ShaderMaterial).get_shader_parameter('lod')
	return _BLUR_LOD


func _get_trans() -> float:
	if material is ShaderMaterial:
		return (material as ShaderMaterial).get_shader_parameter('transparency')
	return _BLUR_TRANS
