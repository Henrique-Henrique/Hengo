@tool
class_name HenActionVisuals extends RefCounted

# the look of an action, shared by whatever draws one: the state card, the edge
# pills and the action search

const ICON_DIR: String = 'res://addons/hengo/assets/new_icons/'
const FALLBACK_ICON: String = 'square-function'
const FALLBACK_COLOR: String = '#7c93ff'

const TITLE_SIZE: int = 18
const TITLE_COLOR: Color = Color('#dde4ed')

# colors the phase section header; the row accent is the action's category
const PHASE_COLORS: Dictionary = {
	enter = '#63d98a',
	update = '#7c93ff',
	physics = '#f2b134',
	exit = '#e08b7f'
}

const PHASE_ICONS: Dictionary = {
	enter = 'arrow-right-to-line',
	update = 'refresh-cw',
	exit = 'arrow-left-from-line'
}

# where a value comes from drives its color, so the line stays scannable
const KINDS: Dictionary = {
	literal = '#dbe3ef',
	variable = '#7cc0ff',
	property = '#6fd3a0',
	native = '#ffd166',
	node = '#9bb1c9',
	expression = '#c08cff',
	action = '#ff9e64',
	branch = '#8f86ff'
}

const NAME_COLOR: Color = Color('#6e7889')
const SLOT_LABEL_COLOR: Color = Color('#6e7889')
const LABEL_SIZE: int = 14
const VALUE_SIZE: int = 17

const CAPSULE_BASE_BG: Color = Color('#151a22')
const CAPSULE_TINT: float = 0.2
const CAPSULE_DEPTH_DARKEN: float = 0.14
const CAPSULE_TITLE_SIZE: int = 16

# debug: same green and window the cnode border uses
const RUN_COLOR: Color = Color('#63ff92')


# icon name from assets/new_icons, falling back when the macro declares none
static func icon_texture(icon_name: String) -> Texture2D:
	var path: String = ICON_DIR + (icon_name if not icon_name.is_empty() else FALLBACK_ICON) + '.svg'

	return load(path) if ResourceLoader.exists(path) else load(ICON_DIR + FALLBACK_ICON + '.svg')


static func accent_of(_macro: HenSaveMacro) -> Color:
	if _macro and not _macro.color.is_empty():
		return Color(_macro.color)

	return Color(FALLBACK_COLOR)


static func phase_color(_phase: StringName) -> Color:
	return Color(str(PHASE_COLORS.get(str(_phase), FALLBACK_COLOR)))


static func kind_color(_kind: String) -> Color:
	return Color(str(KINDS.get(_kind, KINDS.literal)))
