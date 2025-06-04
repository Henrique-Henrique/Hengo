class_name HenTest extends RefCounted


static func get_base_route() -> Dictionary:
	return {
		name = 'Base',
		type = HenRouter.ROUTE_TYPE.BASE,
		id = '0',
		ref = HenLoader.BaseRouteRef.new()
	}