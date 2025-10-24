@tool
class_name HenThreadHelper extends Node

var task_id_list: Array[int] = []

func add_task(_task: Callable) -> int:
	var task_id: int = WorkerThreadPool.add_task(_task)
	task_id_list.append(task_id)
	return task_id


func remove_task(_task_id: int) -> void:
	task_id_list.erase(_task_id)


func clear() -> void:
	task_id_list.clear()


func _process(_delta: float) -> void:
	for id in task_id_list:
		if WorkerThreadPool.is_task_completed(id):
			WorkerThreadPool.wait_for_task_completion(id)
			task_id_list.erase(id)