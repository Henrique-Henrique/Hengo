@tool
class_name HenStateViewerGraphTypes
extends RefCounted

class DirectedGraphNode:
	var id: String
	var data: Dictionary
	var children: Array[DirectedGraphNode] = []
	var ports: Array = []
	var edges: Array[DirectedGraphEdge] = []
	var parent: DirectedGraphNode = null
	var level: int = 0
	var layout: Dictionary = {
		x = 0.0,
		y = 0.0,
		width = 0.0,
		height = 0.0
	}


	# initializes node data and links parents
	func _init(config: Dictionary) -> void:
		id = config.id
		data = config.state_node

		for child in config.children:
			children.append(child)
			child.parent = self
			child.level = level + 1


	# recursively calculates absolute position accumulating parent offsets
	func get_absolute() -> Vector2:
		if parent == null:
			return Vector2(layout.x, layout.y)

		var parent_pos: Vector2 = parent.get_absolute()
		return Vector2(layout.x + parent_pos.x, layout.y + parent_pos.y)


class DirectedGraphEdge:
	var id: String
	var source: DirectedGraphNode
	var target: DirectedGraphNode
	var transition: Dictionary
	var label: Dictionary = {
		text = '',
		x = 0.0,
		y = 0.0
	}
	var sections: Array = []


	# initializes edge between source and target
	func _init(config: Dictionary) -> void:
		id = config.id
		source = config.source
		target = config.target
		transition = config.transition
		label.text = config.label_text
