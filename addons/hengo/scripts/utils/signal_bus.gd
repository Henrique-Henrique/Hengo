@tool
class_name HenSignalBus extends Node

#
#
#
#
#
#
static func get_singleton() -> HenSignalBus:
	return HenGlobal.HENGO_ROOT.get_node('%SignalBus') as HenSignalBus
