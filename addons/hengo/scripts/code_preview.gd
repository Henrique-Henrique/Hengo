@tool
class_name HenCodePreview extends PanelContainer

@onready var code_preview: CodeEdit = %CodePreview

var text_cache: String = ''
var reg: RegEx

func _ready() -> void:
    reg = RegEx.new()
    reg.compile('#ID:[0-9]*')


func set_code(_code: String) -> void:
    text_cache = _code
    code_preview.text = reg.sub(_code, '', true)


func show_vc_line_reference(_id: int) -> void:
    var idx: int = 0

    for line: String in text_cache.split('\n'):
        code_preview.set_line_background_color(idx, Color.TRANSPARENT)

        if line.contains('#ID:%d' % _id):
            code_preview.set_line_background_color(idx, Color(1, 0.5, 0.5, 0.5))

        idx += 1
    

func clear() -> void:
    text_cache = ''
    code_preview.text = ''