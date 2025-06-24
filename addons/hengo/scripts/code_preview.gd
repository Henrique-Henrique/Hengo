@tool
class_name HenCodePreview extends VBoxContainer

@onready var code_preview: CodeEdit = %CodePreview

var text_cache: String = ''
var id_list: Array[int] = []
var can_show_preview: bool = false
var reg: RegEx

func _ready() -> void:
    reg = RegEx.new()
    reg.compile('#ID:[0-9]*')
    (%PreviewCheck as CheckButton).toggled.connect(_preview_check)
    code_preview.visible = false


func _preview_check(_toggle: bool) -> void:
    (%CodePreview as CodeEdit).visible = _toggle
    can_show_preview = _toggle


func set_code(_code: String) -> void:
    var new_id_list: Array = get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP).map(func(x): return x.virtual_ref.id)

    if not can_show_preview or id_list == new_id_list:
        return
    
    text_cache = _code
    code_preview.text = reg.sub(_code, '', true)
    # code_preview.text = text_cache


func show_vc_line_reference() -> void:
    if not can_show_preview:
        return
    
    var idx: int = 0
    var last_line: int = 0
    var new_id_list: Array = get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP).map(func(x): return x.virtual_ref.id)

    if id_list != new_id_list:
        id_list.clear()

        for id: int in new_id_list:
            id_list.append(id)

        for line: String in text_cache.split('\n'):
            for id in id_list:
                if line.contains('#ID:%d' % id):
                    code_preview.set_line_background_color(idx, Color(Color('#a1fff6'), 0.05))
                    last_line = idx

            idx += 1
    
    code_preview.set_caret_line(last_line)
    

func clear() -> void:
    text_cache = ''
    code_preview.text = ''