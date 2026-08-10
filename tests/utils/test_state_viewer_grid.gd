@tool
class_name TestHenStateViewerGrid extends GdUnitTestSuite

# the label solver reads overlap through this grid instead of scanning every rect,
# so it has to answer exactly what the linear scan answered


const CELL: float = HenStateViewerEdgesOverlay.RectGrid.CELL


func _rects() -> Array[Rect2]:
	var out: Array[Rect2] = []

	# deliberately spans cell borders, which is where a bucket grid goes wrong
	for i: int in 40:
		out.append(Rect2(
			Vector2(float(i) * 73.0 - 400.0, float(i * i % 37) * 61.0 - 300.0),
			Vector2(40.0 + float(i % 5) * 120.0, 30.0 + float(i % 3) * 90.0)
		))

	return out


func _brute_overlap(_rect: Rect2, _all: Array[Rect2]) -> float:
	var total: float = 0.0

	for other: Rect2 in _all:
		var clip: Rect2 = _rect.intersection(other)
		total += clip.size.x * clip.size.y

	return total


func _grid_of(_all: Array[Rect2]) -> HenStateViewerEdgesOverlay.RectGrid:
	var grid: HenStateViewerEdgesOverlay.RectGrid = HenStateViewerEdgesOverlay.RectGrid.new()

	for rect: Rect2 in _all:
		grid.add(rect)

	return grid


func test_overlap_area_matches_the_linear_scan() -> void:
	var all: Array[Rect2] = _rects()
	var grid: HenStateViewerEdgesOverlay.RectGrid = _grid_of(all)

	for i: int in 60:
		var probe: Rect2 = Rect2(
			Vector2(float(i) * 47.0 - 350.0, float(i * 7 % 29) * 83.0 - 250.0),
			Vector2(90.0, 26.0)
		)

		assert_float(grid.overlap_area(probe)) \
			.override_failure_message('probe %d em %s' % [i, probe]) \
			.is_equal_approx(_brute_overlap(probe, all), 0.01)


func test_intersecting_matches_the_linear_scan() -> void:
	var all: Array[Rect2] = _rects()
	var grid: HenStateViewerEdgesOverlay.RectGrid = _grid_of(all)

	for i: int in 40:
		var probe: Rect2 = Rect2(
			Vector2(float(i) * 91.0 - 300.0, float(i * 3 % 23) * 77.0 - 200.0),
			Vector2(150.0, 60.0)
		)

		var expected: int = 0

		for other: Rect2 in all:
			if probe.intersects(other):
				expected += 1

		assert_int(grid.intersecting(probe).size()) \
			.override_failure_message('probe %d em %s' % [i, probe]) \
			.is_equal(expected)


# a rect wider than a cell lands in several buckets and must still count once
func test_a_rect_spanning_cells_is_counted_once() -> void:
	var wide: Rect2 = Rect2(Vector2.ZERO, Vector2(CELL * 4.0, CELL * 2.0))
	var grid: HenStateViewerEdgesOverlay.RectGrid = _grid_of([wide] as Array[Rect2])
	var probe: Rect2 = Rect2(Vector2(CELL, CELL * 0.5), Vector2(CELL * 2.0, CELL))

	assert_float(grid.overlap_area(probe)).is_equal_approx(CELL * 2.0 * CELL, 0.01)
	assert_int(grid.intersecting(probe).size()).is_equal(1)
