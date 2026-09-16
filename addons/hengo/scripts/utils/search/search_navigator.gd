@tool
class_name HenSearchNavigator extends RefCounted


static func go(_record: Dictionary) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global') if Engine.has_singleton(&'Global') else null
	var general_popup: HenGeneralPopup = Engine.get_singleton(&'GeneralPopup') if Engine.has_singleton(&'GeneralPopup') else null

	if not global or _record.is_empty():
		return false

	if general_popup:
		general_popup.hide_all()

	if not _ensure_collection(StringName(str(_record.collection_id))):
		return false

	if _record.kind == HenSearchIndex.KIND_COLLECTION:
		return true

	var save_data: HenSaveData = _open_script(StringName(str(_record.script_id)))

	if not save_data:
		_notify('This script is no longer in its collection.')
		return false

	(Engine.get_singleton(&'Loader') as HenLoader).set_active_script(save_data)

	if global.DASHBOARD:
		global.DASHBOARD.hide_dashboard()

	var id: StringName = StringName(str(_record.id))

	match _record.kind:
		HenSearchIndex.KIND_STATE:
			var state: HenSaveState = HenGeneratorAction.find_state(save_data, id)
			var flow: HenFlowViewer = _flow()

			if not state:
				return false

			HenRoute.set_stack(HenRoute.stack_for(save_data, id))

			if flow:
				flow.focus_state.call_deferred(state)
		HenSearchIndex.KIND_ACTION:
			var flow: HenFlowViewer = _flow()

			# focus_action does not change scope, so a step inside a definition needs the route first
			HenRoute.set_stack(HenRoute.stack_for(save_data, StringName(str(_record.state_id))))

			if flow:
				flow.focus_action.call_deferred(str(id), false)
		HenSearchIndex.KIND_FUNCTION:
			HenRoute.enter(HenRoute.KIND_FUNCTION, id)
		HenSearchIndex.KIND_MACRO:
			HenRoute.enter(HenRoute.KIND_MACRO, id)
		HenSearchIndex.KIND_VARIABLE:
			_inspect_variable.call_deferred(save_data, id)

	return true


static func _ensure_collection(_collection_id: StringName) -> bool:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	if str(_collection_id).is_empty():
		return false

	if global.ACTIVE_COLLECTION and global.ACTIVE_COLLECTION.id == _collection_id:
		return true

	var signal_bus: HenSignalBus = Engine.get_singleton(&'SignalBus') if Engine.has_singleton(&'SignalBus') else null

	if signal_bus and signal_bus.is_batch_loading:
		_notify('Wait for the compile to finish before opening another collection.')
		return false

	# load_collection reads from disk, so an edit left in memory would be lost
	HenSaver.save_new()

	if not (Engine.get_singleton(&'Loader') as HenLoader).load_collection(_collection_id):
		_notify('Failed to open the collection.')
		return false

	return true


static func _open_script(_script_id: StringName) -> HenSaveData:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	for save_data: HenSaveData in global.OPEN_SCRIPTS:
		if save_data and save_data.identity and save_data.identity.id == _script_id:
			return save_data

	return null


static func _inspect_variable(_save_data: HenSaveData, _id: StringName) -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var side_bar: HenSideBar = global.SIDE_BAR if global else null

	if not side_bar:
		return

	for variable: HenSaveVar in _save_data.variables:
		if variable.id == _id:
			HenInspector.edit_resource(
				variable,
				side_bar.get_inspect_title(variable),
				side_bar.get_inspect_actions(variable),
				side_bar.get_inspect_popup_opts()
			)
			return


static func _flow() -> HenFlowViewer:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	return global.HENGO_ROOT.get_node_or_null('%FlowViewer') as HenFlowViewer if global and global.HENGO_ROOT else null


static func _notify(_message: String) -> void:
	if Engine.has_singleton(&'ToastContainer'):
		(Engine.get_singleton(&'ToastContainer') as HenToast).notify.call_deferred(_message, HenToast.MessageType.ERROR)
