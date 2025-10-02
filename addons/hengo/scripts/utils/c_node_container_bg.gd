@tool
extends Control

# selection rect
var cnode_selecting_rect: bool = false
var start_select_pos: Vector2 = Vector2.ZERO
var can_select: bool = false
var toggle_bottom_panel: bool = true

func _ready() -> void:
	gui_input.connect(_on_gui)

	print(22)


func _on_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion and can_select:
		_select_cnode()
	
	if _event is InputEventMouseButton:
		if _event.pressed:
			HenVCActionButtons.get_singleton().hide_action()

			match _event.button_index:
				MOUSE_BUTTON_RIGHT:
					if not (HenGlobal.HENGO_ROOT.get_node('%ScriptMsgContainer') as PanelContainer).visible:
						var method_list = load('res://addons/hengo/scenes/utils/method_picker.tscn').instantiate()
						method_list.start(HenGlobal.script_config.type, get_global_mouse_position())
						HenGlobal.GENERAL_POPUP.get_parent().show_content(method_list, 'Pick a Method', get_global_mouse_position())
				MOUSE_BUTTON_LEFT:
					for cnode: HenVirtualCNode in HenGlobal.SELECTED_VIRTUAL_CNODE:
						cnode.unselect()
					
					HenGlobal.CODE_PREVIEWER.clear_code()
					
					get_viewport().gui_release_focus()

					cnode_selecting_rect = true
					start_select_pos = get_global_mouse_position()
					HenGlobal.ACTION_BAR.filesystem_dock(true)
		else:
			match _event.button_index:
				MOUSE_BUTTON_LEFT:
					if can_select:
						_select_cnode()
						can_select = false

					cnode_selecting_rect = false
					start_select_pos = Vector2.ZERO
					HenGlobal.CAM.get_node('SelectionRect').visible = false


func _select_cnode() -> void:
	var selection_rect: ReferenceRect = HenGlobal.CAM.get_node('SelectionRect')

	for v_cnode: HenVirtualCNode in HenRouter.get_current_route_v_cnodes():
		if v_cnode.cnode_instance:
			if selection_rect.get_global_rect().has_point(v_cnode.cnode_instance.global_position):
				v_cnode.select()
			else:
				v_cnode.unselect()


func _process(_delta: float) -> void:
	# cnode_stat_label.text = str('pos => ', HenGlobal.CAM.position as Vector2i) + str(' zoom => ', snapped(HenGlobal.CAM.transform.x.x, 0.01))
	if cnode_selecting_rect and HenGlobal.CAM:
		if get_global_mouse_position().distance_to(start_select_pos) > 50:
			var selection_rect: ReferenceRect = HenGlobal.CAM.get_node('SelectionRect')
			
			selection_rect.size = abs(HenGlobal.CAM.get_relative_vec2(get_global_mouse_position()) - HenGlobal.CAM.get_relative_vec2(start_select_pos))
			selection_rect.position = HenGlobal.CAM.get_relative_vec2(start_select_pos)

			if get_global_mouse_position().x - start_select_pos.x < 0:
				selection_rect.position.x -= selection_rect.size.x
			
			if get_global_mouse_position().y - start_select_pos.y < 0:
				selection_rect.position.y -= selection_rect.size.y

			selection_rect.border_width = 2 / HenGlobal.CAM.transform.x.x
			selection_rect.visible = true

			can_select = true
		else:
			can_select = false
			HenGlobal.CAM.get_node('SelectionRect').visible = false