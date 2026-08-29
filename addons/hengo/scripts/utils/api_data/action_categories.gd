class_name HenActionCategories extends RefCounted

# an action's category is the folder it lives in under actions/ (or macros/).
# this table gives each folder its label, icon and color; the color tints the
# action row, so actions of the same kind read as a group

const DEFAULT: Dictionary = {
	name = 'General',
	icon = 'square-function',
	color = '#7c93ff',
	order = 999
}

const CATEGORIES: Dictionary = {
	flow = {name = 'Flow', icon = 'git-branch', color = '#f97316', order = 0},
	event = {name = 'Event', icon = 'radio-tower', color = '#84cc16', order = 10},
	variable = {name = 'Variable', icon = 'variable', color = '#1dd1a1', order = 20},
	math = {name = 'Math', icon = 'sigma', color = '#8b5cf6', order = 30},
	convert = {name = 'Convert', icon = 'arrow-right-left', color = '#d946ef', order = 35},
	logic = {name = 'Logic', icon = 'git-compare', color = '#ef4444', order = 40},
	vector = {name = 'Vector', icon = 'move-3d', color = '#a855f7', order = 50},
	string = {name = 'String', icon = 'type', color = '#eab308', order = 60},
	array = {name = 'Array', icon = 'list-ordered', color = '#f59e0b', order = 70},
	dictionary = {name = 'Dictionary', icon = 'braces', color = '#14b8a6', order = 75},
	node2d = {name = 'Node 2D', icon = 'move', color = '#0abde3', order = 80},
	node3d = {name = 'Node 3D', icon = 'axis-3d', color = '#06b6d4', order = 90},
	camera = {name = 'Camera', icon = 'video', color = '#0ea5e9', order = 95},
	physics2d = {name = 'Physics 2D', icon = 'shapes', color = '#22d3ee', order = 100},
	physics3d = {name = 'Physics 3D', icon = 'box', color = '#2dd4bf', order = 105},
	physics = {name = 'Physics', icon = 'atom', color = '#2bb5c4', order = 106},
	navigation = {name = 'Navigation', icon = 'route', color = '#4ade80', order = 107},
	input = {name = 'Input', icon = 'gamepad-2', color = '#38bdf8', order = 110},
	audio = {name = 'Audio', icon = 'volume-2', color = '#ec4899', order = 120},
	animation = {name = 'Animation', icon = 'film', color = '#f472b6', order = 130},
	tween = {name = 'Tween', icon = 'sparkles', color = '#fb7185', order = 135},
	render = {name = 'Render', icon = 'palette', color = '#f368e0', order = 140},
	control = {name = 'Control', icon = 'sliders-horizontal', color = '#60a5fa', order = 145},
	tilemap = {name = 'Tile Map', icon = 'grid-3x3', color = '#7c9a6b', order = 148},
	scene = {name = 'Scene', icon = 'layers', color = '#64748b', order = 150},
	save = {name = 'Save', icon = 'save', color = '#a3a3a3', order = 155},
	time = {name = 'Time', icon = 'timer', color = '#94a3b8', order = 160},
	debug = {name = 'Debug', icon = 'terminal', color = '#10b981', order = 170}
}


# an unknown folder falls back to a neutral entry using the folder name as label
static func get_data(_folder: String) -> Dictionary:
	if CATEGORIES.has(_folder):
		return CATEGORIES[_folder]

	if _folder.is_empty():
		return DEFAULT

	var data: Dictionary = DEFAULT.duplicate()
	data.name = _folder.capitalize()
	return data


# folders present in _folders, sorted by the table order then alphabetically
static func sorted(_folders: Array) -> Array:
	var list: Array = _folders.duplicate()

	list.sort_custom(func(a: String, b: String) -> bool:
		var order_a: int = int(get_data(a).order)
		var order_b: int = int(get_data(b).order)

		if order_a != order_b:
			return order_a < order_b

		return a < b
	)

	return list
