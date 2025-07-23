@tool
class_name HenSignalBus extends Node


signal scripts_generation_finished
signal scripts_generation_started

#
#
#
#
#
#
func _init() -> void:
	HenGlobal.SIGNAL_BUS = self

#
#
#
#
#
#
static func get_singleton() -> HenSignalBus:
	return HenGlobal.HENGO_ROOT.get_node('%SignalBus') as HenSignalBus
