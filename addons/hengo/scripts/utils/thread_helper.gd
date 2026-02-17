@tool
class_name HenThreadHelper extends Node

class TaskEntry extends RefCounted:
	var id: int
	var on_completed: Callable


var task_list: Array[TaskEntry] = []

func add_task(_task: Callable, _on_completed: Callable = Callable()) -> int:
	var task_id: int = WorkerThreadPool.add_task(_task)
	var entry := TaskEntry.new()
	entry.id = task_id
	entry.on_completed = _on_completed
	task_list.append(entry)
	return task_id


func remove_task(_task_id: int) -> void:
	for idx: int in range(task_list.size() - 1, -1, -1):
		if (task_list[idx] as TaskEntry).id == _task_id:
			task_list.remove_at(idx)
			return


func clear() -> void:
	task_list.clear()


func _process(_delta: float) -> void:
	for idx: int in range(task_list.size() - 1, -1, -1):
		var entry: TaskEntry = task_list[idx]
		if WorkerThreadPool.is_task_completed(entry.id):
			WorkerThreadPool.wait_for_task_completion(entry.id)
			task_list.remove_at(idx)
			if entry.on_completed.is_valid():
				entry.on_completed.call_deferred()
