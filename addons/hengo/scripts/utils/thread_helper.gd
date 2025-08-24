class_name HenThreadHelper extends RefCounted

static var task_id_list: Array[int] = []


static func add_task(_task: Callable) -> int:
	var task_id: int = WorkerThreadPool.add_task(_task)
	task_id_list.append(task_id)
	return task_id


static func remove_task(_task_id: int) -> void:
	task_id_list.erase(_task_id)


static func clear() -> void:
	task_id_list.clear()
