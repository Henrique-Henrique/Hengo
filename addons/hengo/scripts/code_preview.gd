@tool
class_name HenCodePreview extends CodeEdit

@onready var code_preview: CodeEdit = %CodePreview

const final_text: String = '\n\n\n\n\n\n\n\n\n'

var text_cache: String = ''
var id_list: Array[int] = []
var reg: RegEx

func _ready() -> void:
    reg = RegEx.new()
    reg.compile('#ID:[0-9]*')


func set_code(_code: String) -> void:
    var new_id_list: Array = get_tree().get_nodes_in_group(HenEnums.CNODE_SELECTED_GROUP).map(func(x): return x.virtual_ref.id)

    if id_list == new_id_list:
        return
    
    text_cache = _code
    code_preview.text = reg.sub(_code, '', true) + final_text


func show_vc_line_reference() -> void:
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
                    code_preview.set_line_background_color(idx, Color(Color('#63c1ff'), 0.1))
                    last_line = idx

            idx += 1
    
    code_preview.set_caret_line(last_line + 3)
    

func clear_code() -> void:
    text_cache = ''
    code_preview.text = ''
    id_list.clear()