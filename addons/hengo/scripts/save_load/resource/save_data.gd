@tool
class_name HenSaveData extends Resource

@export var id: int
@export var variables: Array[HenSaveVar]
@export var functions: Array[HenSaveFunc]
@export var signals: Array[HenSaveSignal]
@export var signals_callback: Array[HenSaveSignalCallback]