@tool
class_name HenSignalBus extends Node


signal script_generated
signal save_parse_finished
signal save_data_files_finished

#
#
#
#
#
#
static func get_singleton() -> HenSignalBus:
	return HenGlobal.HENGO_ROOT.get_node('%SignalBus') as HenSignalBus
