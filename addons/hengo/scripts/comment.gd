@tool
extends VBoxContainer


# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

var check_pin: CheckButton
var title_panel: PanelContainer
var top_right: TextureRect
var bottom_left: TextureRect
var top_left: TextureRect
var bottom_right: TextureRect
var title: LineEdit

var route_ref: Dictionary

var is_scaling: bool = false
var is_moving: bool = false
var is_pinned: bool = true
var PADDING: Vector2 = Vector2(40, 40)

var cnode_inside: Array = []

enum Types {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}


func _ready() -> void:
	title_panel = get_node('%TitlePanel')

	top_left = get_node('%TopLeft')
	top_right = get_node('%TopRight')
	bottom_left = get_node('%BottomLeft')
	bottom_right = get_node('%BottomRight')

	title_panel.gui_input.connect(_on_title_gui)

	title = get_node('%Title')
	title.text_submitted.connect(_on_submit)

	top_left.gui_input.connect(_on_gui.bind(Types.TOP_LEFT))
	bottom_right.gui_input.connect(_on_gui.bind(Types.BOTTOM_RIGHT))
	top_right.gui_input.connect(_on_gui.bind(Types.TOP_RIGHT))
	bottom_left.gui_input.connect(_on_gui.bind(Types.BOTTOM_LEFT))

	check_pin = get_node('%CheckButton')
	check_pin.pressed.connect(_on_pin)

	get_node('%ColorButton').color_changed.connect(_on_color)
	get_node('%Icon').set('texture_normal', random_icon())


	# it's just for animation
	top_left.mouse_entered.connect(_handle_hover.bind(top_left))
	bottom_right.mouse_entered.connect(_handle_hover.bind(bottom_right))
	top_right.mouse_entered.connect(_handle_hover.bind(top_right))
	bottom_left.mouse_entered.connect(_handle_hover.bind(bottom_left))

	top_left.mouse_exited.connect(_handle_exit.bind(top_left))
	bottom_right.mouse_exited.connect(_handle_exit.bind(bottom_right))
	top_right.mouse_exited.connect(_handle_exit.bind(top_right))
	bottom_left.mouse_exited.connect(_handle_exit.bind(bottom_left))


func _handle_hover(_anchor) -> void:
	get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).tween_property(_anchor, 'modulate', Color('#ffffff60'), 1.)


func _handle_exit(_anchor) -> void:
	# _anchor.modulate = Color.TRANSPARENT
	get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).tween_property(_anchor, 'modulate', Color('#ffffff20'), 1.)


func random_icon() -> Texture2D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var arr: Array = [load('res://addons/hengo/assets/icons/comment.svg'), load('res://addons/hengo/assets/icons/comment2.svg'), load('res://addons/hengo/assets/icons/comment3.svg')]

	return arr[rng.randi_range(0, arr.size() - 1)]


func get_comment() -> String:
	return title.text


func set_comment(_text: String) -> void:
	title.text = _text


func _on_pin() -> void:
	is_pinned = check_pin.button_pressed

	if is_pinned:
		pin_to_cnodes()
	else:
		cnode_inside = []
	

func pin_to_cnodes() -> void:
		var min_vec: Vector2 = Vector2.INF
		var max_vec: Vector2 = -Vector2.INF

		# defyning cnode area
		for cnode in _Global.CNODE_CONTAINER.get_children():
			if get_rect().has_point(cnode.position):
				min_vec = min_vec.min(cnode.position)
				max_vec = max_vec.max(cnode.position + cnode.size)
			
				cnode_inside.append(cnode)
	
		if min_vec >= Vector2.INF or max_vec <= -Vector2.INF:
			return

		var target_position = min_vec
		var target_size = (max_vec - min_vec)

		target_position.x -= PADDING.x
		target_position.y -= title.size.y + PADDING.y

		target_size.x += PADDING.x * 2
		target_size.y += (PADDING.y + title.size.y) + PADDING.y

		var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_parallel()
		
		tween.tween_property(self, 'position', target_position, .1)
		tween.tween_property(self, 'size', target_size, .1)


func _on_color(_color: Color) -> void:
	var style: StyleBoxFlat = title_panel.get('theme_override_styles/panel')
	
	style.set('bg_color', _color)
	style.set('border_color', _color.lightened(.1))

	_color.a = .4
	get_node('%Background').get('theme_override_styles/panel').set('bg_color', _color)


func get_color() -> Color:
	return title_panel.get('theme_override_styles/panel').get('bg_color')


func _on_submit(_new_text: String) -> void:
	title.editable = false
	title.selecting_enabled = false
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_title_gui(_event: InputEvent) -> void:
	if _event is InputEventMouseButton:
		if _event.double_click:
			title.editable = true
			title.selecting_enabled = true
			title.mouse_filter = Control.MOUSE_FILTER_STOP
			title.select_all()
			title.grab_focus()
		elif _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				is_moving = true
		else:
			is_moving = false
	elif _event is InputEventMouseMotion:
		if is_moving:
			position += _event.relative

			for cnode in cnode_inside:
				cnode.move(cnode.position + _event.relative)


func _on_gui(_event: InputEvent, _type: Types) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed:
			if _event.button_index == MOUSE_BUTTON_LEFT:
				is_scaling = true

				cnode_inside = []
		else:
			is_scaling = false

			if not is_pinned:
				return

			pin_to_cnodes()

	elif _event is InputEventMouseMotion:
		if is_scaling:
			match _type:
				Types.TOP_LEFT:
					size -= _event.relative
					position += _event.relative
				Types.TOP_RIGHT:
					size -= Vector2(-_event.relative.x, _event.relative.y)
					position.y += _event.relative.y
				Types.BOTTOM_RIGHT:
					size += _event.relative
				Types.BOTTOM_LEFT:
					size += Vector2(-_event.relative.x, _event.relative.y)
					position.x += _event.relative.x