@tool
class_name HenSavePill extends PanelContainer

const SHOW_THRESHOLD_S: float = 0.300
const SPIN_SPEED: float = 4.0

@onready var _spinner: TextureRect = get_node('%SavePillSpinner')

var _pending_timer: SceneTreeTimer = null
var _save_in_flight: bool = false


func _ready() -> void:
	if HenUtils.disable_scene_with_owner(self):
		return
	visible = false
	set_process(false)
	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus')
	if not signal_bus:
		return
	signal_bus.scripts_generation_started.connect(_on_started)
	signal_bus.scripts_generation_finished.connect(_on_finished)


func _process(_delta: float) -> void:
	if _spinner:
		_spinner.rotation += _delta * SPIN_SPEED
		_spinner.pivot_offset = _spinner.size / 2.0


func _on_started() -> void:
	_save_in_flight = true
	if visible:
		return
	if _pending_timer != null:
		return
	var tree: SceneTree = get_tree()
	if not tree:
		return
	_pending_timer = tree.create_timer(SHOW_THRESHOLD_S)
	_pending_timer.timeout.connect(_show_now, CONNECT_ONE_SHOT)


func _show_now() -> void:
	_pending_timer = null
	if not _save_in_flight:
		return
	visible = true
	set_process(true)


func _on_finished(_paths: PackedStringArray = PackedStringArray()) -> void:
	_save_in_flight = false
	_pending_timer = null
	visible = false
	set_process(false)
