extends HenTestSuite


func _script(_name: String) -> HenSaveData:
	var data: HenSaveData = HenSaveData.new()

	data.identity = HenSaveDataIdentity.create(StringName('removal_' + _name), 'Node', _name)
	data.identity.script_path = 'res://temp/never_written_' + _name + '.gd'

	return data


func _open_collection(_scripts: Array[HenSaveData]) -> HenSaveCollection:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var collection: HenSaveCollection = HenSaveCollection.create(&'removal_collection', 'Removal')

	global.ACTIVE_COLLECTION = collection
	global.OPEN_SCRIPTS.clear()

	for data: HenSaveData in _scripts:
		collection.add_script(data.identity.id)
		global.OPEN_SCRIPTS.append(data)
		map_deps.update_project_data_from_save(data.identity.id, data)

	return collection


func test_deleting_a_script_forgets_it_everywhere() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var kept: HenSaveData = _script('kept')
	var doomed: HenSaveData = _script('doomed')
	var collection: HenSaveCollection = _open_collection([kept, doomed])

	global.SAVE_DATA = kept
	global.ROUTE_VIEWS['removal_doomed'] = [{kind = &'func', id = &'1'}]
	global.CAM_VIEWS['removal_doomed/func:1'] = {zoom = 1.0}

	HenCollectionManager.delete_script(doomed.identity.id)

	assert_array(global.OPEN_SCRIPTS).contains_exactly([kept])
	assert_array(collection.script_ids).contains_exactly([kept.identity.id])
	assert_bool(map_deps.ast_list.has(doomed.identity.id)).is_false()
	assert_bool(global.ROUTE_VIEWS.has('removal_doomed')).is_false()
	assert_bool(global.CAM_VIEWS.has('removal_doomed/func:1')).is_false()
	assert_object(global.SAVE_DATA).is_same(kept)


func test_deleting_the_last_script_leaves_nothing_active() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var only: HenSaveData = _script('only')

	_open_collection([only])
	global.SAVE_DATA = only

	HenCollectionManager.delete_script(only.identity.id)

	assert_object(global.SAVE_DATA).is_null()
	assert_array(global.OPEN_SCRIPTS).is_empty()


# a collection left active after its folder is gone would be written back by the next new script
func test_deleting_the_active_collection_clears_the_open_state() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var map_deps: HenMapDependencies = Engine.get_singleton(&'MapDependencies')
	var first: HenSaveData = _script('first')
	var second: HenSaveData = _script('second')

	_open_collection([first, second])
	global.SAVE_DATA = first

	HenCollectionManager.delete_collection(&'removal_collection')

	assert_object(global.ACTIVE_COLLECTION).is_null()
	assert_object(global.SAVE_DATA).is_null()
	assert_array(global.OPEN_SCRIPTS).is_empty()
	assert_bool(map_deps.ast_list.has(first.identity.id)).is_false()
	assert_bool(map_deps.ast_list.has(second.identity.id)).is_false()


func test_deleting_another_collection_keeps_the_open_one() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	var open: HenSaveData = _script('open')
	var collection: HenSaveCollection = _open_collection([open])

	global.SAVE_DATA = open

	HenCollectionManager.delete_collection(&'removal_not_open')

	assert_object(global.ACTIVE_COLLECTION).is_same(collection)
	assert_array(global.OPEN_SCRIPTS).contains_exactly([open])


func test_scripts_referencing_lists_the_holders_of_a_script_variable() -> void:
	var target: HenSaveData = _script('target')
	var holder: HenSaveData = _script('holder')
	var bystander: HenSaveData = _script('bystander')
	var variable: HenSaveVar = holder.add_var(false)

	variable.script_id = target.identity.id
	_open_collection([target, holder, bystander])

	assert_array(HenCollectionManager.scripts_referencing(target.identity.id)).contains_exactly(['holder'])
