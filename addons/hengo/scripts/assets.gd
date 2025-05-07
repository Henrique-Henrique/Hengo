@tool
class_name HenAssets extends Resource

static var ConnectionLineScene: PackedScene
static var FlowConnectionLineScene: PackedScene
static var HengoRootScene: PackedScene
static var CNodeInputScene: PackedScene
static var CNodeOutputScene: PackedScene
static var CNodeScene: PackedScene
static var CNodeFlowScene: PackedScene
static var CNodeIfFlowScene: PackedScene
static var EventScene: PackedScene
static var EventStructScene: PackedScene
static var PropContainerScene: PackedScene
static var CNodeInputLabel: PackedScene
static var CNodeCenterImage: PackedScene

static var cache_icon_images: Dictionary = {}

const NONE_ICON = preload('res://addons/hengo/assets/icons/menu/none.svg')

static func get_icon_texture(_type: StringName) -> Texture2D:
	if EditorInterface.get_editor_theme().has_icon(_type, &'EditorIcons'):
		return EditorInterface.get_editor_theme().get_icon(_type, &'EditorIcons')
	
	return NONE_ICON