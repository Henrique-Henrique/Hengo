extends GdUnitTestSuite

const SCRIPT_DATA_COMPLETE = preload("res://tests/assets/script_data_complete.json")
const SCRIPT_DATA_SCHEMA = preload('res://addons/hengo/assets/data/script_data_schema.json')

func test_script_data_schema() -> void:
	var errors: Array = HenJSONSchema.validate(SCRIPT_DATA_COMPLETE.data, SCRIPT_DATA_SCHEMA.data)
	assert_array(errors).is_empty()


func test_script_data_schema_from_save() -> void:
	HenTest.set_global_config()

	# adding a function to the side bar list
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.FUNC
	HenGlobal.SIDE_BAR_LIST.add()

	# adding a macro to the side bar list
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.MACRO
	HenGlobal.SIDE_BAR_LIST.add()

	# adding a signal to the side bar list
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.SIGNAL
	HenGlobal.SIDE_BAR_LIST.add()

	# adding a variable to the side bar list
	HenGlobal.SIDE_BAR_LIST.type = HenSideBar.AddType.VAR
	HenGlobal.SIDE_BAR_LIST.add()

	var script_data: Dictionary = HenSaver.generate_script_data().get_save()
	var errors: Array = HenJSONSchema.validate(script_data, SCRIPT_DATA_SCHEMA.data)
	assert_array(errors).is_empty()