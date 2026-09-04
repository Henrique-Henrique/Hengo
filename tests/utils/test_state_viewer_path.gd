@tool
class_name TestHenStateViewerPath extends GdUnitTestSuite


const CHAMFER: float = HenStateViewerEdgesOverlay.EDGE_CHAMFER

# the corridor route, the longest shape the layout engine still emits itself
const SECTION: Dictionary = {
	start_point = Vector2(600, 1400),
	bend_points = [
		Vector2(600, 1424), Vector2(1300, 1424), Vector2(1300, 100),
		Vector2(3100, 100), Vector2(3100, 900), Vector2(2800, 900)
	],
	end_point = Vector2(2800, 940)
}


func _sharp() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([SECTION.start_point])

	for bend: Vector2 in SECTION.bend_points:
		pts.append(bend)

	pts.append(SECTION.end_point)

	return pts


func _drawn() -> PackedVector2Array:
	return HenFlowWires.chamfer(_sharp(), CHAMFER)


func _max_deviation(_reference: PackedVector2Array, _candidate: PackedVector2Array) -> float:
	var worst: float = 0.0

	for p: Vector2 in _reference:
		var best: float = INF

		for i: int in range(_candidate.size() - 1):
			best = minf(best, _dist_to_segment(p, _candidate[i], _candidate[i + 1]))

		worst = maxf(worst, best)

	return worst


func _dist_to_segment(_p: Vector2, _a: Vector2, _b: Vector2) -> float:
	var l2: float = _a.distance_squared_to(_b)

	if l2 == 0.0:
		return _p.distance_to(_a)

	var t: float = clampf((_p - _a).dot(_b - _a) / l2, 0.0, 1.0)

	return _p.distance_to(_a + t * (_b - _a))


# the chamfer only cuts inside a corner, so the drawn route never leaves the lane
# the router proved clear by more than the cut itself
func test_the_chamfer_stays_within_its_own_radius() -> void:
	assert_float(_max_deviation(_drawn(), _sharp())).is_less_equal(CHAMFER)


# a corner is cut by at most the radius, so the sharp route it stands for is never
# further than that from what gets drawn
func test_the_drawn_route_hugs_the_sharp_one() -> void:
	assert_float(_max_deviation(_sharp(), _drawn())).is_less_equal(CHAMFER)


# hover reads the drawn polyline itself now, which only works while it stays small
func test_the_drawn_route_stays_a_handful_of_points() -> void:
	assert_int(_drawn().size()).is_equal(_sharp().size() * 2 - 2)


func test_a_straight_route_is_left_alone() -> void:
	var straight: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 400)])

	assert_array(HenFlowWires.chamfer(straight, CHAMFER)).is_equal(straight)
