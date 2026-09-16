@tool
class_name TestHenProjectSearch extends HenTestSuite

# hengo/ is gitignored, so a run on a fresh checkout has no collection on disk: the
# tests that read the project write their own and take it out again
const FIXTURE_COLLECTION: StringName = &'search_disk_fixture'
const FIXTURE_SCRIPT: StringName = &'search_disk_script'
const FIXTURE_FUNCTION: String = 'disk_only_function'


func after_test() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')

	_remove_disk_collection()
	HenRoute.go_base()
	global.ROUTE_OWNER = ''
	global.ROUTE_VIEWS.clear()
	global.OPEN_SCRIPTS.clear()
	global.ACTIVE_COLLECTION = null
	await super ()


func _action(_macro_id: StringName, _phase: StringName = &'update') -> HenSaveAction:
	var action: HenSaveAction = HenSaveAction.new()

	action.id = save_data.new_counter_id()
	action.macro_id = _macro_id
	action.name = str(_macro_id)
	action.phase = _phase

	return action


func _records(_data: HenSaveData = null) -> Array[Dictionary]:
	return HenSearchIndex.records_of(_data if _data else save_data, &'col', 'Col', {
		print_text = {name = 'Print Text', icon = 'type', color = '#ffffff'},
		repeat = {name = 'Repeat', icon = 'repeat', color = '#ffffff'},
		get_node = {name = 'Get Node', icon = 'box', color = '#ffffff'}
	})


func _find(_records: Array[Dictionary], _kind: StringName, _title: String) -> Dictionary:
	for record: Dictionary in _records:
		if record.kind == _kind and record.title == _title:
			return record

	return {}


func _write_disk_collection() -> HenSaveCollection:
	var collection: HenSaveCollection = HenSaveCollection.create(FIXTURE_COLLECTION, 'Disk Fixture')
	var collection_dir: String = HenEnums.HENGO_COLLECTION_PATH.path_join(str(FIXTURE_COLLECTION))
	var script_dir: String = collection_dir.path_join(str(FIXTURE_SCRIPT))
	var data: HenSaveData = HenSaveData.new()

	data.identity = HenSaveDataIdentity.create(FIXTURE_SCRIPT, 'Node', 'disk_script')
	data.counter = 1
	(data.add_function() as HenSaveFunc).name = FIXTURE_FUNCTION
	collection.add_script(FIXTURE_SCRIPT)

	DirAccess.make_dir_recursive_absolute(script_dir)
	ResourceSaver.save(collection, collection_dir.path_join(HenEnums.COLLECTION_FILE))
	ResourceSaver.save(data.identity, script_dir.path_join(HenEnums.IDENTITY_FILE))
	ResourceSaver.save(data, script_dir.path_join(HenEnums.SAVE_FILE))

	HenUtils.rebuild_script_index()
	HenSearchIndex._disk_cache.clear()

	return collection


func _remove_disk_collection() -> void:
	var collection_dir: String = HenEnums.HENGO_COLLECTION_PATH.path_join(str(FIXTURE_COLLECTION))

	if not DirAccess.dir_exists_absolute(collection_dir):
		return

	_remove_tree(collection_dir)
	HenUtils.rebuild_script_index()
	HenSearchIndex._disk_cache.clear()


# move_to_trash needs a desktop, and the ci runner has none
func _remove_tree(_path: String) -> void:
	for dir_name: String in DirAccess.get_directories_at(_path):
		_remove_tree(_path.path_join(dir_name))

	for file_name: String in DirAccess.get_files_at(_path):
		DirAccess.remove_absolute(_path.path_join(file_name))

	DirAccess.remove_absolute(_path)


func _second_script(_name: String) -> HenSaveData:
	var data: HenSaveData = HenSaveData.new()

	data.identity = HenSaveDataIdentity.create(StringName('search_' + _name), 'Node', _name)
	data.counter = 1

	return data


func test_steps_inside_bodies_branches_and_inputs_are_indexed() -> void:
	var state: HenSaveState = save_data.add_state(false)
	var loop: HenSaveAction = _action(&'repeat', &'enter')
	var in_body: HenSaveAction = _action(&'print_text')
	var in_branch: HenSaveAction = _action(&'print_text')
	var producer: HenSaveAction = _action(&'get_node')

	in_branch.label = 'Say done'
	loop.body_actions.append(in_body)
	loop.branch_actions[&'done'] = [in_branch]
	in_body.input_actions[&'text'] = {action = producer, output = &'node'}
	save_data.add_state_action(state.id, loop)

	var records: Array[Dictionary] = _records()
	var body_record: Dictionary = _find(records, HenSearchIndex.KIND_ACTION, 'Print Text')

	assert_dict(body_record).is_not_empty()
	assert_str(str(body_record.state_id)).is_equal(str(state.id))
	assert_str(str(body_record.phase)).is_equal('enter')
	assert_str(str(_find(records, HenSearchIndex.KIND_ACTION, 'Say done').detail)).is_equal('Print Text')
	assert_dict(_find(records, HenSearchIndex.KIND_ACTION, 'Get Node')).is_not_empty()


# HenFunctionMacro.macro_for would read the active script, which is not the one indexed
func test_a_function_call_is_named_by_the_script_it_lives_in() -> void:
	var other: HenSaveData = _second_script('other')
	var func_res: HenSaveFunc = other.add_function()

	func_res.name = 'jump'

	var action: HenSaveAction = _action(HenFunctionMacro.call_id(func_res))

	other.add_state_action(func_res.id, action)

	var record: Dictionary = _find(_records(other), HenSearchIndex.KIND_ACTION, 'jump')

	assert_dict(record).is_not_empty()
	assert_str(str(record.script_id)).is_equal('search_other')
	assert_str(str(record.phase)).is_empty()


func test_ids_repeated_in_two_scripts_keep_their_script() -> void:
	var first: HenSaveData = _second_script('first')
	var second: HenSaveData = _second_script('second')

	(first.add_function() as HenSaveFunc).name = 'shared'
	(second.add_function() as HenSaveFunc).name = 'shared'

	var records: Array[Dictionary] = _records(first) + _records(second)
	var found: Array[Dictionary] = HenSearchIndex.search(records, 'shared')

	assert_int(found.size()).is_equal(2)
	assert_str(str(found[0].id)).is_equal(str(found[1].id))
	assert_str(str(found[0].script_id)).is_not_equal(str(found[1].script_id))


func test_the_closest_title_ranks_first() -> void:
	(save_data.add_function() as HenSaveFunc).name = 'reload_weapon'
	(save_data.add_function() as HenSaveFunc).name = 'reload'
	(save_data.add_function() as HenSaveFunc).name = 'auto_reload'

	var found: Array[Dictionary] = HenSearchIndex.search(_records(), 'reload')

	assert_str(str(found[0].title)).is_equal('reload')
	assert_str(str(found[1].title)).is_equal('reload_weapon')
	assert_str(str(found[2].title)).is_equal('auto_reload')


func test_an_empty_query_lists_the_scripts_only() -> void:
	save_data.add_state(false)
	(save_data.add_function() as HenSaveFunc).name = 'helper'

	var found: Array[Dictionary] = HenSearchIndex.search(_records(), '  ')

	assert_int(found.size()).is_equal(1)
	assert_str(str(found[0].kind)).is_equal(str(HenSearchIndex.KIND_SCRIPT))


# resource _init runs while a save is deserialized, and it used to renumber the active script
func test_a_quiet_thread_leaves_the_active_counter_alone() -> void:
	var before: int = save_data.counter
	var task: int = WorkerThreadPool.add_task(func() -> void:
		HenGlobal.set_thread_quiet(true)
		HenSaveParam.new()
		HenSaveVar.new()
		HenGlobal.set_thread_quiet(false)
	)

	WorkerThreadPool.wait_for_task_completion(task)

	assert_int(save_data.counter).is_equal(before)


func test_a_quiet_main_thread_leaves_the_active_counter_alone() -> void:
	var before: int = save_data.counter

	HenGlobal.set_thread_quiet(true)
	HenSaveParam.new()
	HenGlobal.set_thread_quiet(false)

	assert_int(save_data.counter).is_equal(before)
	HenSaveParam.new()
	assert_int(save_data.counter).is_equal(before + 1)


func test_going_to_a_step_inside_a_function_opens_the_function() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var other: HenSaveData = _second_script('target')
	var func_res: HenSaveFunc = other.add_function()
	var collection: HenSaveCollection = HenSaveCollection.create(&'search_collection', 'Search')

	func_res.name = 'shoot'
	other.add_state_action(func_res.id, _action(&'print_text'))

	collection.add_script(save_data.identity.id)
	collection.add_script(other.identity.id)
	global.ACTIVE_COLLECTION = collection
	global.OPEN_SCRIPTS.assign([save_data, other])
	# set_active_script needs the editor theme, which a headless run does not have
	global.SAVE_DATA = other

	var records: Array[Dictionary] = HenSearchIndex.records_of(other, collection.id, collection.name, {
		print_text = {name = 'Print Text', icon = '', color = ''}
	})

	assert_bool(HenSearchNavigator.go(_find(records, HenSearchIndex.KIND_ACTION, 'Print Text'))).is_true()
	assert_object(global.SAVE_DATA).is_same(other)
	assert_str(str(HenRoute.current_kind())).is_equal(str(HenRoute.KIND_FUNCTION))
	assert_str(str(HenRoute.current_id())).is_equal(str(func_res.id))


func _view() -> HenProjectSearch:
	var view: HenProjectSearch = auto_free(
		(load('res://addons/hengo/scenes/project_search.tscn') as PackedScene).instantiate()
	)

	add_child(view)

	return view


# the suite root is never in the tree, so the helper that hands results back is pumped by hand
func _drain_jobs() -> void:
	var helper: HenThreadHelper = Engine.get_singleton(&'ThreadHelper')

	for attempt: int in 200:
		helper._process(0.0)
		await get_tree().process_frame

		if helper.task_list.is_empty():
			await get_tree().process_frame

			if helper.task_list.is_empty():
				return


func test_the_view_lists_matches_and_moves_with_the_arrows() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var collection: HenSaveCollection = HenSaveCollection.create(&'search_view', 'View')

	(save_data.add_function() as HenSaveFunc).name = 'alpha'
	(save_data.add_function() as HenSaveFunc).name = 'alpha_two'
	collection.add_script(save_data.identity.id)
	global.ACTIVE_COLLECTION = collection
	global.OPEN_SCRIPTS.assign([save_data])

	var view: HenProjectSearch = _view()

	assert_int(view._tabs.current_tab).is_equal(HenProjectSearch.TAB_COLLECTION)

	view._search.text = 'alpha'
	view._refresh()
	await _drain_jobs()

	assert_int(view._results.size()).is_equal(2)
	assert_int(view.selected_index).is_equal(0)

	var down: InputEventKey = InputEventKey.new()

	down.pressed = true
	down.keycode = KEY_DOWN
	view._on_search_input(down)
	view._on_search_input(down)

	assert_int(view.selected_index).is_equal(1)


func test_without_a_collection_only_the_project_tab_is_offered() -> void:
	_write_disk_collection()

	var view: HenProjectSearch = _view()

	assert_bool(view._tabs.is_tab_disabled(HenProjectSearch.TAB_COLLECTION)).is_true()
	assert_int(view._tabs.current_tab).is_equal(HenProjectSearch.TAB_PROJECT)

	# a script row asks the editor theme for its class icon, and a headless run has none
	view._search.text = 'no_record_is_named_like_this'

	for frame: int in 600:
		if view._project_ready:
			break

		await get_tree().process_frame

	await _drain_jobs()

	assert_bool(view._project_ready).is_true()
	assert_array(view._project_records.map(func(_record: Dictionary) -> String: return _record.title)) 		.contains(['Disk Fixture', 'disk_script', FIXTURE_FUNCTION])


func test_the_collection_tab_also_finds_other_collections_by_name() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var collection: HenSaveCollection = HenSaveCollection.create(&'search_tab', 'Tab')

	_write_disk_collection()
	collection.add_script(save_data.identity.id)
	global.ACTIVE_COLLECTION = collection
	global.OPEN_SCRIPTS.assign([save_data])

	var view: HenProjectSearch = _view()

	view._search.text = 'Disk Fixture'
	view._refresh()
	await _drain_jobs()

	var titles: Array = view._results.map(func(_record: Dictionary) -> String: return _record.title)

	assert_array(titles).contains(['Disk Fixture'])
