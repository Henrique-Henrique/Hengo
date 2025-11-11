extends GdUnitTestSuite

const SCRIPT_DATA_COMPLETE = preload("res://tests/assets/script_data_complete.json")
const SCRIPT_DATA_SCHEMA = preload('res://addons/hengo/assets/data/script_data_schema.json')

func test_script_data_schema() -> void:
	var errors: Array = HenJSONSchema.validate(SCRIPT_DATA_COMPLETE.data, SCRIPT_DATA_SCHEMA.data)
	assert_array(errors).is_empty()


func test_script_data_schema_from_save() -> void:
	var global: HenGlobal = Engine.get_singleton(&'Global')
	HenTest.set_global_config()

	# adding a signal to the side bar list
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL
	global.SIDE_BAR_LIST.add()

	# adding a function to the side bar list
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.FUNC
	global.SIDE_BAR_LIST.add()

	# adding a macro to the side bar list
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	global.SIDE_BAR_LIST.add()

	# adding a signal callback to the side bar list
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL_CALLBACK
	global.SIDE_BAR_LIST.add()

	# adding a variable to the side bar list
	global.SIDE_BAR_LIST.type = HenSideBar.AddType.VAR
	global.SIDE_BAR_LIST.add()

	var script_data: Dictionary = HenSaver.generate_script_data().get_save()
	var errors: Array = HenJSONSchema.validate(script_data, SCRIPT_DATA_SCHEMA.data)
	assert_array(errors).is_empty()