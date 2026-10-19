@tool
class_name PopochiuWorker
extends RefCounted

## Runs a blocking [Callable] on a [WorkerThreadPool] task so editor code (Aseprite
## CLI exports, JSON parsing) never freezes the UI. The caller awaits the result and
## resumes on the main thread once the task is done.


#region Public #####################################################################################
## Runs [param work] off the main thread and returns its result. The caller must
## await this method. The callable runs on a worker thread, so it must not touch the
## scene tree or any main-thread-only API.
static func run(work: Callable) -> Variant:
	# The task writes its result into this shared holder. Arrays are captured by
	# reference, so the write is visible once the task completes.
	var result: Array = [null]
	var task_id := WorkerThreadPool.add_task(
		func() -> void: result[0] = work.call(),
		false,
		"Popochiu worker task"
	)

	while not WorkerThreadPool.is_task_completed(task_id):
		await PopochiuEditorHelper.frame_processed()

	# The task is done, so this returns at once; it lets the pool release it.
	WorkerThreadPool.wait_for_task_completion(task_id)
	return result[0]


#endregion
