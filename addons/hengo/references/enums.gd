@tool
extends MainLoop

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