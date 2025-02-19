@tool
class_name HenAssets extends Resource

static var ConnectionLineScene: PackedScene
static var StateConnectionLineScene: PackedScene
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


static func get_icon_texture(_type: StringName) -> ImageTexture:
    if cache_icon_images.has(_type):
        return cache_icon_images[_type]

    var path: String = 'res://addons/hengo/assets/.editor_icons/' + _type + '.svg'

    if not FileAccess.file_exists(path):
        path = 'res://addons/hengo/assets/icons/circle.svg'

    var icon: Image = Image.load_from_file(path)
    var image: ImageTexture = ImageTexture.create_from_image(icon)
    cache_icon_images[_type] = image

    return image