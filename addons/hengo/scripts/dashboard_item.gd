@tool
class_name HenDashboardItem extends PanelContainer


var item_name: String = ''
var script_path: String = ''

func _ready() -> void:
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

	gui_input.connect(_on_gui)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed and _event.button_index == MOUSE_BUTTON_LEFT:
			_open_script()
		

func _open_script() -> void:
	HenLoader.load(script_path)
	HenGlobal.DASHBOARD.hide_dashboard()
	print('aqq -> ', HenGlobal.DASHBOARD.visible)


func _on_hover() -> void:
	(get_theme_stylebox('panel') as StyleBoxFlat).bg_color = Color('#00000058')


func _on_exit() -> void:
	(get_theme_stylebox('panel') as StyleBoxFlat).bg_color = Color.TRANSPARENT


func set_item_data(_config: Dictionary) -> void:
	%Name.text = _config.name.capitalize()
	%Type.text = _config.type if not _config.type.is_empty() else 'New'

	%ImgText.text = %Name.text.substr(0, 2)
	item_name = %Name.text
	script_path = _config.path