@tool
class_name HenErrorListPopup extends VBoxContainer

var errors: Array = []

func _ready() -> void:
	var label: Label = Label.new()
	label.text = 'Error List'
	label.add_theme_font_size_override('font_size', 24)
	add_child(label)
	
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	add_child(scroll)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	if errors.is_empty():
		var no_error: Label = Label.new()
		no_error.text = 'No errors found.'
		vbox.add_child(no_error)
		return

	for error in errors:
		var item: HBoxContainer = HBoxContainer.new()
		vbox.add_child(item)
		
		var err_label: Label = Label.new()
		err_label.text = error.description
		err_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_child(err_label)
		
		var btn: Button = Button.new()
		btn.text = 'Go to'
		btn.pressed.connect(_on_go_to.bind(error))
		item.add_child(btn)

# navigates to the error location, switching projects if necessary
func _on_go_to(error: Dictionary) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	
	(Engine.get_singleton(&'GeneralPopup') as HenGeneralPopup).hide_popup()
	
	if error.has('script_id') and str(error.script_id) != str(global.SAVE_DATA.identity.id):
		HenSaver.save_new()
		
		if await (Engine.get_singleton(&'Loader') as HenLoader).load(error.script_id):
			await get_tree().process_frame

	if error.has('route_id'):
		var route_id = error.route_id
		var target_route: HenRouteData
		
		if global.SAVE_DATA.get_base_route().id == route_id:
			target_route = global.SAVE_DATA.get_base_route()
		else:
			for state in global.SAVE_DATA.states:
				if state.get_route(global.SAVE_DATA).id == route_id:
					target_route = state.get_route(global.SAVE_DATA)
					break
			if not target_route:
				for func_data in global.SAVE_DATA.functions:
					if func_data.get_route(global.SAVE_DATA).id == route_id:
						target_route = func_data.get_route(global.SAVE_DATA)
						break
			if not target_route:
				for macro in global.SAVE_DATA.macros:
					if macro.get_route(global.SAVE_DATA).id == route_id:
						target_route = macro.get_route(global.SAVE_DATA)
						break
			if not target_route:
				for sc in global.SAVE_DATA.signals_callback:
					if sc.get_route(global.SAVE_DATA).id == route_id:
						target_route = sc.get_route(global.SAVE_DATA)
						break
		
		if target_route:
			var router: HenRouter = Engine.get_singleton(&'Router')
			router.change_route(target_route)
			
			if error.has('id'):
				for vc: HenVirtualCNode in target_route.virtual_cnode_list:
					if vc.id == error.id:
						global.CAM.go_to_center(vc.position)
						vc.select()
						break
