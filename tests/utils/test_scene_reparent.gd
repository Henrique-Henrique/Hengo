@tool
class_name TestHenSceneReparent extends GdUnitTestSuite

# taking an inner node out of its scene drops the owner link '%Name' resolves through


func _build_scene() -> Control:
	var scene_root: Control = Control.new()
	var branch: Control = Control.new()
	var target: Control = Control.new()

	target.name = 'Target'
	branch.add_child(target)
	scene_root.add_child(branch)

	branch.owner = scene_root
	target.owner = scene_root
	target.unique_name_in_owner = true

	return scene_root


func test_reparenting_an_inner_node_loses_the_unique_name() -> void:
	var scene_root: Control = auto_free(_build_scene())
	var host: Control = auto_free(Control.new())
	add_child(scene_root)
	add_child(host)

	assert_object(scene_root.get_node_or_null('%Target')).is_not_null()

	var branch: Node = scene_root.get_child(0)
	scene_root.remove_child(branch)
	host.add_child(branch)
	host.remove_child(branch)
	scene_root.add_child(branch)

	assert_object(scene_root.get_node_or_null('%Target')).is_null()


# moving the scene root keeps every owner an ancestor
func test_reparenting_the_scene_root_keeps_the_unique_name() -> void:
	var scene_root: Control = auto_free(_build_scene())
	var host: Control = auto_free(Control.new())
	add_child(scene_root)
	add_child(host)

	remove_child(scene_root)
	host.add_child(scene_root)
	host.remove_child(scene_root)
	add_child(scene_root)

	assert_object(scene_root.get_node_or_null('%Target')).is_not_null()
