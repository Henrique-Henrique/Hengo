@tool
class_name HenSaveData extends Resource

@export var counter: int
@export var macros: Array[HenSaveMacro]
@export var variables: Array[HenSaveVar]
@export var functions: Array[HenSaveFunc]
@export var identity: HenSaveDataIdentity
@export var signals: Array[HenSaveSignal]
@export var connections: Array[Dictionary]
@export var flow_connections: Array[Dictionary]
@export var state_event_list: Array[Dictionary]
@export var virtual_cnode_list: Array[Dictionary]
@export var signals_callback: Array[HenSaveSignalCallback]


func add_var() -> void:
    var v: HenSaveVar = HenSaveVar.create()

    if not v:
        return
    
    variables.append(v)


func add_func() -> void:
    var f: HenSaveFunc = HenSaveFunc.create()

    if not f:
        return
    
    functions.append(f)


func add_signal() -> void:
    var s: HenSaveSignal = HenSaveSignal.create()

    if not s:
        return
    
    signals.append(s)


func add_signals_callback() -> void:
    var sc: HenSaveSignalCallback = HenSaveSignalCallback.create()

    if not sc:
        return
    
    signals_callback.append(sc)


func add_macro() -> void:
    var m: HenSaveMacro = HenSaveMacro.create()

    if not m:
        return
    
    macros.append(m)