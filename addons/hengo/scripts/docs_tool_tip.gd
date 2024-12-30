@tool
extends PanelContainer

const _Global = preload('res://addons/hengo/scripts/global.gd')

#TODO: need to test in other languages
const LIMITER_DSC = ['\n\nOnline Tutorials', '\n\nProperties', '\n\nTheme Properties', '\n\nConstructors', '\n\nMethods', '\n\nSignals', '\n\nOperators', '\n\nConstants']

var is_hovering: bool = false
var first_show: bool = true

@export var rich_text_label: RichTextLabel
@export var title_label: Label

func _ready() -> void:
	rich_text_label.mouse_entered.connect(_on_hover)
	rich_text_label.mouse_exited.connect(_on_exit)


func _on_hover() -> void:
	is_hovering = true
	_Global.CAM.can_scroll = false

func _on_exit() -> void:
	is_hovering = false
	hide_docs()
	_Global.CAM.can_scroll = true


func hide_docs() -> void:
	if visible and not is_hovering:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
		tween.tween_property(self, 'modulate', Color.TRANSPARENT, .3)
		tween.finished.connect(hide)


func set_custom_doc(_content: String, _title: String) -> void:
	visible = false
	first_show = false
	is_hovering = false
	title_label.text = _title
	rich_text_label.text = _content

	await RenderingServer.frame_post_draw
	rich_text_label.size = Vector2(rich_text_label.get_content_width(), rich_text_label.get_content_height())
	size = Vector2(500, rich_text_label.size.y + title_label.size.y + 20)


func start_docs(_class_name: StringName, _member: String = '') -> void:
	rich_text_label.fit_content = false
	visible = false
	first_show = true
	is_hovering = false

	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	script_editor.goto_help(_class_name)
	var doc_rich_text_label: RichTextLabel = script_editor.find_child(_class_name, true, false).get_child(0)

	# script editor file popup menu
	var popup: PopupMenu = script_editor.find_child('*PopupMenu*', true, false)
	var arr: Array = Array(doc_rich_text_label.get_parsed_text().split('\n\n\n')).map(func(x): return x.split('\n\n\t'))
	var result: String = ''

	var conn_list: Array = popup.get_signal_connection_list('id_pressed')
	# 11 = "Close Docs" on File PopupMenu
	# Close all docs to prevent flick editor ui
	conn_list[0].callable.call(11)

	if _member.is_empty():
		for txt in arr[0].slice(1):
			var has_limiter: bool = false
			for limiter in LIMITER_DSC:
				if txt.contains(limiter):
					result += '\n\n' + txt.split(limiter)[0]
					has_limiter = true
					break
			
			if has_limiter: break
				
			result += txt
	else:
		for txt in arr.slice(1):
			# get member dscription
			if txt[0].contains(_member):
				result = txt[1]
				break


	# await get_tree().process_frame
	EditorInterface.set_main_screen_editor(_Global.HENGO_EDITOR_PLUGIN.PLUGIN_NAME)

	rich_text_label.text = result
	title_label.text = _class_name + '.' + _member

	await RenderingServer.frame_post_draw

	var label_height := rich_text_label.get_content_height()

	if label_height > 200:
		rich_text_label.size = Vector2(500, 200)
	else:
		rich_text_label.size = Vector2(500, label_height)
	
	size = Vector2(500, rich_text_label.size.y + title_label.size.y + 20)

	rich_text_label.scroll_to_line(0)