@tool
class_name HenEnums extends MainLoop

const SCRIPT_REF_PATH: StringName = 'res://hengo/save/hengo_cross_references.json'


static func add_script_ref_cache(_script_id: int, _id: int) -> void:
    var script_id: StringName = str(_script_id)
    var id: StringName = str(_id)

    if HenGlobal.SCRIPT_REF_CACHE.has(script_id):
        if HenGlobal.SCRIPT_REF_CACHE.get(script_id).has(id):
            return

        HenGlobal.SCRIPT_REF_CACHE.get(script_id).append(id)
    else:
        HenGlobal.SCRIPT_REF_CACHE.set(script_id, [id])


static func get_script_cache_refs(_script_id: int) -> Array:
    if HenGlobal.SCRIPT_REF_CACHE.has(str(_script_id)):
        return HenGlobal.SCRIPT_REF_CACHE.get(str(_script_id))

    return []


const CNODE_SELECTED_GROUP: String = 'hen_cnode_selected'
const STATE_SELECTED_GROUP: String = 'hen_state_selected'
const NATIVE_API_PATH: String = 'res://addons/hengo/api/native_api.json'

enum PROP_TYPE {
    STRING,
    FUNCTION_INPUT,
    FUNCTION_OUTPUT,
    DROPDOWN,
    BOOL
}

const VARIANT_TYPES: PackedStringArray = [
    'int',
    'float',
    'bool',
    'String',
    'Vector2',
    'Vector3',
    'Array',
    'Dictionary',
    'Color',
    'Transform2D',
    'Transform3D',
    'NodePath',
    'Object',
    'PackedFloat32Array',
    'PackedInt32Array',
    'PackedVector2Array',
    'PackedVector3Array',
    'Callable',
    'Signal',
    'StringName',
    'PackedStringArray',
    'Basis',
    'Rect2',
    'Quaternion',
    'RID',
    'PackedByteArray',
    'PackedColorArray',
    'PackedFloat64Array',
    'PackedInt64Array',
    'PackedVector3Array',
    'Vector2i',
    'Vector3i',
    'Vector4',
    'Vector4i',
    'Rect2i',
    'Plane',
    'Projection',
    'AABB',
    'Variant',
]

const RULES_TO_CONNECT: Dictionary = {
    int = ['float'],
    float = ['int'],
    String = ['StringName'],
    StringName = ['String'],
    Vector2 = ['Vector2i'],
    Vector2i = ['Vector2'],
    Vector3 = ['Vector3i'],
    Vector3i = ['Vector3'],
    Vector4 = ['Vector4i'],
    Vector4i = ['Vector4'],
    Rect2 = ['Rect2i'],
    Rect2i = ['Rect2'],
    Array = ['PackedByteArray', 'PackedInt32Array', 'PackedInt64Array', 'PackedFloat32Array', 'PackedFloat64Array', 'PackedStringArray', 'PackedVector2Array', 'PackedVector3Array', 'PackedColorArray'],
    PackedFloat32Array = ['Array'],
    PackedInt32Array = ['Array'],
    PackedVector2Array = ['Array'],
    PackedVector3Array = ['Array'],
    PackedStringArray = ['Array'],
    PackedByteArray = ['Array'],
    PackedColorArray = ['Array'],
    PackedFloat64Array = ['Array'],
    PackedInt64Array = ['Array'],
}

var string: String = NodePath()

# dynamic native api
static var NATIVE_API_LIST: Dictionary = {}
static var CONST_API_LIST: Dictionary = {}
static var SINGLETON_API_LIST: Array = []
static var NATIVE_PROPS_LIST: Dictionary = {}
static var MATH_UTILITY_NAME_LIST: Array = []

# static
#
static var OBJECT_TYPES: PackedStringArray
static var ALL_CLASSES: PackedStringArray

# dropdown
static var DROPDOWN_ALL_CLASSES: Array
static var DROPDOWN_OBJECT_TYPES: Array
static var DROPDOWN_STATES: Array = []


const TOOLTIP_TEXT = {
    MOUSE_ICON = '[img]res://addons/hengo/assets/icons/mouse.svg[/img]',
    RIGHT_MOUSE_INSPECT = '[img]res://addons/hengo/assets/icons/mouse.svg[/img] [i]Right Click to Inspect[/i]',
    DOUBLE_CLICK = '[img]res://addons/hengo/assets/icons/mouse.svg[/img] [i]Double Click to Enter[/i]',
    CNODE_INVALID = "[color=#f55][b]Invalid CNode[/b][/color]\nThis node references a deleted or missing object\n[i]It will be ignored during code generation[/i]"
}

const START_MSG = "[center][font_size=24][b]Hengo Visual Script[/b][/font_size][font_size=16][color=#cccccc]Please open the script to begin editing.[/color][/font_size][font_size=13][i][color=#888888]Tip: You can open the script using the button at the top right to access the FileSystem,  or via \"Select Resource\" (Ctrl + P), or directly from Scene dock.[/color][/i][/font_size][/center]"


class ScriptDataFile:
    var name: String
    var path: StringName