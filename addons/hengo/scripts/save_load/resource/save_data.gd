@tool
class_name HenSaveData extends Resource

@export var id: StringName
@export var type: StringName
@export var counter: int
@export var variables: Array[HenSaveVar]
@export var functions: Array[HenSaveFunc]
@export var signals: Array[HenSaveSignal]
@export var signals_callback: Array[HenSaveSignalCallback]
@export var macros: Array[HenSaveMacro]
@export var virtual_cnode_list: Array[Dictionary]
@export var connections: Array[Dictionary]
@export var flow_connections: Array[Dictionary]
@export var state_event_list: Array[Dictionary]