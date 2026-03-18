@tool
class_name HenStateViewerPathUtils
extends RefCounted

# processes sharp path into a godot curve2d with rounded corners
func round_path(section: Dictionary, corner_radius: float = 6.0) -> Curve2D:
	var curve: Curve2D = Curve2D.new()
	var points: Array[Vector2] = []

	points.append(section.start_point)
	for bend in section.bend_points:
		points.append(bend)
	points.append(section.end_point)

	if points.size() < 3:
		for pt in points:
			curve.add_point(pt)
		return curve

	curve.add_point(points[0])

	# inserts midpoints to construct bezier curves smoothly
	for i in range(1, points.size() - 1):
		var p_prev: Vector2 = points[i - 1]
		var p_curr: Vector2 = points[i]
		var p_next: Vector2 = points[i + 1]

		var corner: Dictionary = _round_one_corner(p_prev, p_curr, p_next, corner_radius)
		curve.add_point(corner.p1)
		curve.add_point(corner.p2, corner.p - corner.p2, Vector2.ZERO)

	curve.add_point(points[points.size() - 1])
	return curve


# calculates bezier control points for a single corner
func _round_one_corner(p1: Vector2, corner: Vector2, p2: Vector2, radius: float) -> Dictionary:
	var d1: Vector2 = (p1 - corner).normalized()
	var d2: Vector2 = (p2 - corner).normalized()

	var dist1: float = corner.distance_to(p1)
	var dist2: float = corner.distance_to(p2)
	var actual_radius: float = min(radius, min(dist1 / 2.0, dist2 / 2.0))

	return {
		p1 = corner + d1 * actual_radius,
		p = corner,
		p2 = corner + d2 * actual_radius
	}
