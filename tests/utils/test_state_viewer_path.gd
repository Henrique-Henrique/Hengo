@tool
class_name TestHenStateViewerPath extends GdUnitTestSuite


const CORNER_RADIUS: float = HenStateViewerEdgesOverlay.EDGE_CORNER_RADIUS

# the corridor route, the longest shape the router emits
const SECTION: Dictionary = {
	start_point = Vector2(600, 1400),
	bend_points = [
		Vector2(600, 1424), Vector2(1300, 1424), Vector2(1300, 100),
		Vector2(3100, 100), Vector2(3100, 900), Vector2(2800, 900)
	],
	end_point = Vector2(2800, 940)
}


func _baked(_interval: float) -> PackedVector2Array:
	var curve: Curve2D = HenStateViewerPathUtils.new().round_path(SECTION, CORNER_RADIUS)
	curve.bake_interval = _interval

	return curve.get_baked_points()


func _sharp() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([SECTION.start_point])

	for bend: Vector2 in SECTION.bend_points:
		pts.append(bend)

	pts.append(SECTION.end_point)

	return pts


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


# the overlay hit-tests the unrounded route, so it has to stay well inside the
# hover threshold of the curve it stands for
func test_sharp_route_stays_near_the_drawn_curve() -> void:
	assert_float(_max_deviation(_baked(0.5), _sharp())) \
		.is_less(HenStateViewerEdgesOverlay.HOVER_SCREEN_PX * 0.5)


func test_bake_interval_keeps_the_rounded_corners() -> void:
	assert_float(_max_deviation(_baked(0.5), _baked(HenStateViewerPathUtils.BAKE_INTERVAL))) \
		.is_less(1.0)


func test_bake_interval_cuts_the_point_count() -> void:
	assert_int(_baked(HenStateViewerPathUtils.BAKE_INTERVAL).size()) \
		.is_less(_baked(5.0).size() / 2)
