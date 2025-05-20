@tool
class_name HenEnums extends MainLoop

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
    DOUBLE_CLICK = '[img]res://addons/hengo/assets/icons/mouse.svg[/img] [i]Double Click to Enter[/i]'
}


class ScriptDataFile:
    var name: String
    var path: StringName