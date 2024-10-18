@tool
extends Line2D

# imports
const _Global = preload('res://addons/hengo/scripts/global.gd')

var start_pos: Vector2
var in_out

const SHORT_SIZE: int = 5
const SHORT_LENGTH: int = 3

const LONG_SIZE: int = 8
const LONG_LENGTH: int = 10

var SIZE: int = LONG_SIZE
const FORCE: Vector2 = Vector2(0, 10000)
var LENGTH: int = LONG_LENGTH

var point_list: Array[Point] = []
var stick_list: Array[Stick] = []

var hover_pos = null
var is_in_out: bool = true

class Point:
	var position: Vector2 = Vector2.ZERO
	var old_pos: Vector2
	var mass: float = 1.
	var pinned: bool = false
	var use_mouse: bool = false

	func _init(_mass: float, _pinned: bool = false, _mouse: bool = false) -> void:
		self.mass = _mass
		self.pinned = _pinned
		self.use_mouse = _mouse

	func update(dt: float, mouse_pos: Vector2):
		if self.use_mouse:
			self.position = mouse_pos
			return

		if self.pinned:
			return

		var vel = self.position - self.old_pos
		self.old_pos = self.position
		var acc = FORCE / self.mass
		self.position += vel + acc * (dt * dt)


class Stick:
	var p0: Point
	var p1: Point
	var length: int

	func _init(_p0, _p1, _length) -> void:
		self.p0 = _p0
		self.p1 = _p1
		self.length = _length
	
	func update() -> void:
		var d = p1.position - p0.position
		var dist = sqrt(d.x * d.x + d.y * d.y)
		var diff = length - dist
		var percent = (diff / dist) / 2

		var offset = d * percent

		if not p0.pinned:
			p0.position -= offset
		
		if not p1.pinned:
			p1.position += offset


func _ready() -> void:
	set_physics_process(false)

func start(_start: Vector2, _in_out = null) -> void:
	points = []
	start_pos = _start
	point_list = []
	stick_list = []
	in_out = _in_out

	# points
	for i in range(SIZE):
		var p: Point
		if i == 0:
			p = Point.new(1, true)
		elif i == SIZE - 1:
			p = Point.new(1, true, true)
		else:
			p = Point.new(1)

		p.position.x = start_pos.x + (12 * i)
		p.position.y = start_pos.y + (LENGTH * i)
		p.old_pos = p.position

		point_list.append(p)

	# sticks
	for i in range(SIZE - 1):
		var s = Stick.new(point_list[i], point_list[i + 1], LENGTH)
		stick_list.append(s)


	if _in_out:
		var first_color: Color = _in_out.get_type_color(_in_out.connection_type)
		gradient.colors[0] = first_color

	set_physics_process(true)
	visible = true

func end() -> void:
	points = []
	set_physics_process(false)
	visible = false


var factor: int = 1

func _physics_process(delta: float) -> void:
	# points
	for point in point_list:
		point.update(delta, get_local_mouse_position() if not hover_pos != null else hover_pos)
	
	# sticks
	for stick in stick_list:
		stick.update()

	points = PackedVector2Array(point_list.map(func(x): return x.position))
